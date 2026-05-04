import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../standard_features/no-internet/logic/connectivity_cubit.dart';
import '../../../standard_features/no-internet/logic/connectivity_state.dart';
import '../../domain/usecases/offline_sync_usecases.dart';

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

    // 1. First check if there is data. NO DATA -> SILENT EXIT.
    final pendingResult = await getPendingItemsUseCase.call(null);
    bool hasData = false;
    pendingResult.fold(
      (_) => hasData = false,
      (records) => hasData = records.isNotEmpty,
    );

    if (!hasData) return;

    // 2. Second check if we are actually online. NO CONNECTION -> SILENT EXIT.
    // This prevents "Sync Failed" snackbar when just blipping the network or pulling drawer.
    if (connectivityCubit.state is! ConnectivityConnected) return;

    _isSyncing = true;
    emit(OfflineSyncInProgress());

    final result = await syncPendingOperationsUseCase.call(null);

    result.fold(
      (failure) {
        _isSyncing = false;
        emit(OfflineSyncFailure(failure.toString()));
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
