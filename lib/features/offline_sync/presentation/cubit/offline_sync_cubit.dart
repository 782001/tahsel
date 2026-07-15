import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/features/invoice/data/datasources/offline_invoice_local_data_source.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_cubit.dart';

import '../../../standard_features/no-internet/logic/connectivity_cubit.dart';
import '../../../standard_features/no-internet/logic/connectivity_state.dart';
import '../../domain/usecases/offline_sync_usecases.dart';
import 'package:equatable/equatable.dart';

part 'offline_sync_state.dart';

class OfflineSyncCubit extends Cubit<OfflineSyncState> {
  final SyncPendingOperationsUseCase syncPendingOperationsUseCase;
  final GetPendingItemsUseCase getPendingItemsUseCase;
  final ConnectivityCubit connectivityCubit;
  late StreamSubscription connectivitySubscription;
  bool _isSyncing = false;

  OfflineSyncCubit({
    required this.syncPendingOperationsUseCase,
    required this.getPendingItemsUseCase,
    required this.connectivityCubit,
  }) : super(OfflineSyncInitial()) {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    connectivitySubscription = connectivityCubit.stream.listen((state) {
      if (state is ConnectivityConnected) {
        syncPendingData();
      }
    });

    // Check on init if we have pending data and are connected
    if (connectivityCubit.state is ConnectivityConnected) {
      syncPendingData();
    }
  }

  Future<void> syncPendingData() async {
    if (_isSyncing) return;

    // 1. First check if there is data.
    final pendingResult = await getPendingItemsUseCase.call(null);
    bool hasData = false;
    pendingResult.fold(
      (_) => hasData = false,
      (records) => hasData = records.isNotEmpty,
    );

    // Also check for pending invoices
    final invoiceLocal = sl<OfflineInvoiceLocalDataSource>();
    final pendingInvoices = await invoiceLocal.getPendingInvoices();
    final hasInvoices = pendingInvoices.isNotEmpty;

    if (!hasData && !hasInvoices) return;

    // 2. Second check if we are actually online. NO CONNECTION -> SILENT EXIT.
    // This prevents "Sync Failed" snackbar when just blipping the network or pulling drawer.
    if (connectivityCubit.state is! ConnectivityConnected) return;

    _isSyncing = true;
    emit(OfflineSyncInProgress());

    final result = await syncPendingOperationsUseCase.call(null);
    
    // Sync invoices silently in the same transaction context
    if (hasInvoices) {
      await sl<InvoiceCubit>().syncOfflineInvoices();
    }

    result.fold(
      (failure) {
        // If the generic sync fails, we still consider it a failure.
        // Even if generic sync has no data but invoices failed/succeeded,
        // we'll just emit success if there's no generic error.
        if (hasData) {
          _isSyncing = false;
          emit(OfflineSyncFailure(failure.toString()));
        } else {
          _isSyncing = false;
          emit(OfflineSyncSuccess());
        }
      },
      (_) {
        _isSyncing = false;
        emit(OfflineSyncSuccess());
      },
    );
  }

  @override
  Future<void> close() {
    connectivitySubscription.cancel();
    return super.close();
  }
}
