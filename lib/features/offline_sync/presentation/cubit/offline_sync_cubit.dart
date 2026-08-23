import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/cashbox/presentation/cubit/vault_cubit.dart';
import 'package:tahsel/features/inventory/data/datasources/inventory_local_data_source.dart';
import 'package:tahsel/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:tahsel/features/inventory/presentation/cubits/inventory_products_cubit.dart';
import 'package:tahsel/features/inventory/presentation/cubits/inventory_purchases_cubit.dart';
import 'package:tahsel/features/invoice/data/datasources/offline_invoice_local_data_source.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_cubit.dart';

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

    // 1. First check if there is data.
    final pendingResult = await getPendingItemsUseCase.call(null);
    bool hasData = false;
    pendingResult.fold(
      (_) => hasData = false,
      (records) => hasData = records.isNotEmpty,
    );

    // Also check for pending invoices
    bool hasInvoices = false;
    if (sl.isRegistered<OfflineInvoiceLocalDataSource>()) {
      try {
        final invoiceLocal = sl<OfflineInvoiceLocalDataSource>();
        final pendingInvoices = await invoiceLocal.getPendingInvoices();
        hasInvoices = pendingInvoices.isNotEmpty;
      } catch (_) {}
    }

    // Also check for pending inventory data (purchases, products, movements, suppliers, categories)
    bool hasInventory = false;
    if (sl.isRegistered<InventoryLocalDataSource>()) {
      try {
        final invLocal = sl<InventoryLocalDataSource>();
        final unsyncedPurchases = await invLocal.getUnsyncedPurchases();
        final unsyncedProducts = await invLocal.getUnsyncedProducts();
        final unsyncedMovements = await invLocal.getUnsyncedStockMovements();
        final unsyncedSuppliers = await invLocal.getUnsyncedSuppliers();
        final unsyncedCategories = await invLocal.getUnsyncedCategories();
        hasInventory =
            unsyncedPurchases.isNotEmpty ||
            unsyncedProducts.isNotEmpty ||
            unsyncedMovements.isNotEmpty ||
            unsyncedSuppliers.isNotEmpty ||
            unsyncedCategories.isNotEmpty;
      } catch (_) {}
    }

    if (!hasData && !hasInvoices && !hasInventory) return;

    // 2. Second check if we are actually online. NO CONNECTION -> SILENT EXIT.
    // This prevents "Sync Failed" snackbar when just blipping the network or pulling drawer.
    if (connectivityCubit.state is! ConnectivityConnected) return;

    _isSyncing = true;
    emit(OfflineSyncInProgress());

    final result = await syncPendingOperationsUseCase.call(null);

    // Sync invoices silently in the same transaction context
    if (hasInvoices && sl.isRegistered<InvoiceCubit>()) {
      try {
        await sl<InvoiceCubit>().syncOfflineInvoices();
      } catch (_) {}
    }

    // Sync inventory data (purchases, stock movements, products, vault, expenses, my debts)
    if (hasInventory && sl.isRegistered<InventoryRepository>()) {
      try {
        await sl<InventoryRepository>().syncInventoryData();
        if (sl.isRegistered<InventoryPurchasesCubit>()) {
          sl<InventoryPurchasesCubit>().fetchPurchases();
        }
        if (sl.isRegistered<InventoryProductsCubit>()) {
          sl<InventoryProductsCubit>().fetchProducts();
        }
        if (sl.isRegistered<VaultCubit>() &&
            AppStrings.userToken.isNotEmpty &&
            AppStrings.isVaultEnabled()) {
          sl<VaultCubit>().loadVaultData(AppStrings.userToken);
        }
      } catch (_) {}
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
