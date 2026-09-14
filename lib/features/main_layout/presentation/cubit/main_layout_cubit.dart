import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/storage/cashhelper.dart';
import 'package:tahsel/core/storage/secure_storage_helper.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/services/permission_service.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_cubit.dart';
import 'package:tahsel/features/invoice/presentation/screens/invoices_screen.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_state.dart';
import 'package:tahsel/features/my_debts/presentation/screens/unified_debts_screen.dart';
import 'package:tahsel/features/operation/presentation/screens/home_screen.dart';
import 'package:tahsel/features/reports/domain/usecases/cleanup_old_reports_usecase.dart';
import 'package:tahsel/features/cashbox/presentation/cubit/vault_cubit.dart';
import 'package:tahsel/features/cashbox/presentation/screens/vault_screen.dart';
import 'package:tahsel/features/customer/presentation/screens/customers_list_screen.dart';
import 'package:tahsel/features/employee/presentation/cubit/employee_cubit.dart';
import 'package:tahsel/features/employee/presentation/screens/employee_list_screen.dart';
import 'package:tahsel/features/inventory/presentation/cubits/inventory_dashboard_cubit.dart';
import 'package:tahsel/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:tahsel/features/inventory/presentation/screens/inventory_main_screen.dart';
import 'package:tahsel/features/reports/presentation/screens/reports_screen.dart';
import 'package:tahsel/features/settings/presentation/screens/more_screen.dart';
import 'package:tahsel/features/shipping_reconciliation/presentation/screens/shipping_reconciliation_screen.dart';
import 'package:tahsel/features/employee/presentation/cubit/team_management_cubit.dart';
import 'package:tahsel/features/employee/presentation/screens/team_management_screen.dart';

class MainLayoutCubit extends Cubit<MainLayoutState> {
  final CleanupOldReportsUseCase cleanupOldReportsUseCase;
  final CashHelper cashHelper;
  final SecureStorageHelper secureStorage;
  final FirebaseFirestore firestore;

  MainLayoutCubit({
    required this.cleanupOldReportsUseCase,
    required this.cashHelper,
    required this.secureStorage,
    required this.firestore,
  }) : super(MainLayoutInitial()) {
    _init();
  }

  String _userType = AppStrings.cafe;
  String get userType => _userType;

  bool get isShop => _userType == AppStrings.shop;
  bool get isCafe => _userType == AppStrings.cafe;

  void _init() async {
    await _loadUserType();
    if (!isShop) {
      _initCleanup();
    }
    loadLowStockCount();
    _ensureValidInitialIndex();
  }

  void _ensureValidInitialIndex() {
    if (!isIndexAllowed(currentIndex)) {
      final safeIndex = firstAllowedIndex;
      currentIndex = safeIndex;
      emit(MainLayoutChangeBottomNavIndex(currentIndex));
      AppLogger.printMessage(
        '[MainLayoutCubit] Initialized landing tab to index $safeIndex based on RBAC permissions.',
      );
    }
  }

  bool isIndexAllowed(int index) {
    final permissions = PermissionService.instance;
    if (permissions.isOwner) return true;

    switch (index) {
      case 0:
        return permissions.hasPermission(AppPermissions.posAccess);
      case 1:
        return permissions.hasPermission(AppPermissions.expensesView);
      case 2:
        return permissions.hasPermission(AppPermissions.customersView) ||
            permissions.hasPermission(AppPermissions.myDebtsView);
      case 3:
        return isShop && permissions.hasPermission(AppPermissions.invoicesView);
      case 4:
        return permissions.hasPermission(AppPermissions.reportsViewSales) ||
            permissions.hasPermission(AppPermissions.reportsViewNetProfit);
      case 5:
        return true; // MoreScreen / Settings is always accessible
      case 6:
        return permissions.hasPermission(AppPermissions.customersView);
      case 7:
        return permissions.hasPermission(AppPermissions.vaultAccess);
      case 8:
        return permissions.hasPermission(AppPermissions.inventoryView);
      case 9:
        return permissions.hasPermission(AppPermissions.hrEmployeesManage);
      case 10:
        return isShop &&
            permissions.hasPermission(AppPermissions.shippingReconciliationView);
      case 11:
        return permissions.hasPermission(AppPermissions.teamManage);
      default:
        return false;
    }
  }

  int get firstAllowedIndex {
    for (int i = 0; i <= 4; i++) {
      if (isIndexAllowed(i)) return i;
    }
    if (isIndexAllowed(8)) return 8;
    if (isIndexAllowed(7)) return 7;
    if (isIndexAllowed(9)) return 9;
    if (isIndexAllowed(11)) return 11;
    if (isIndexAllowed(6)) return 6;
    if (isIndexAllowed(10)) return 10;
    return 5;
  }

  int lowStockCount = 0;

  Future<void> loadLowStockCount() async {
    if (AppStrings.isVip && sl.isRegistered<InventoryRepository>()) {
      try {
        final result = await sl<InventoryRepository>().getLowStockProducts();
        result.fold((_) {}, (products) {
          lowStockCount = products.length;
          emit(MainLayoutLowStockCountLoaded(lowStockCount));
        });
      } catch (_) {}
    }
  }

  Future<void> _loadUserType() async {
    final storedType = await secureStorage.getData(key: AppStrings.userTypeKey);
    if (storedType != null) {
      _userType = storedType;
      emit(MainLayoutUserTypeLoaded(_userType));
    } else {
      // Fallback: Fetch from Firestore if we have a current token
      final uid = AppStrings.userToken;
      if (uid.isNotEmpty) {
        try {
          final doc = await firestore.collection('users').doc(uid).get();
          if (doc.exists) {
            final type = doc.get(AppStrings.userTypeKey) ?? AppStrings.cafe;
            _userType = type;
            await secureStorage.saveData(
              key: AppStrings.userTypeKey,
              value: type,
            );
            emit(MainLayoutUserTypeLoaded(_userType));
          }
        } catch (e) {
          AppLogger.printMessage('Error fetching user type from Firestore: $e');
        }
      }
    }
  }

  void _initCleanup() async {
    await cleanupOldReportsUseCase();
  }

  int currentIndex = 0;

  List<Widget> get screens => [
    const HomeScreen(),
    const ExpensesScreen(),
    const UnifiedDebtsScreen(),
    BlocProvider.value(
      value: sl<InvoiceCubit>(),
      child: const InvoicesScreen(),
    ),
    const ReportsScreen(),
    const MoreScreen(),
    CustomersListScreen(uid: AppStrings.userToken),
    BlocProvider(
      create: (_) => sl<VaultCubit>(),
      child: VaultScreen(uid: AppStrings.userToken),
    ),
    BlocProvider(
      create: (_) => sl<InventoryDashboardCubit>(),
      child: const InventoryMainScreen(),
    ),
    BlocProvider.value(
      value: sl<EmployeeCubit>(),
      child: const EmployeeListScreen(),
    ),
    const ShippingReconciliationScreen(),
    BlocProvider(
      create: (_) => sl<TeamManagementCubit>(),
      child: const TeamManagementScreen(),
    ),
  ];

  void changeBottomNav(int index) {
    if (!isIndexAllowed(index)) {
      AppLogger.printMessage(
        '[MainLayoutCubit] Access to tab $index denied by RBAC.',
      );
      return;
    }
    currentIndex = index;
    emit(MainLayoutChangeBottomNavIndex(currentIndex));
    if (index == 5 || index == 8) {
      loadLowStockCount();
    }
  }
}
