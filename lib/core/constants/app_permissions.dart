import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_strings.dart';

/// App permissions catalog and role presets for Tahsel RBAC system.
class AppPermissions {
  AppPermissions._();

  // Wildcard for full super-access (Owner default)
  static const String all = '*';

  // ── 1. POS & Operations ──────────────────────────────────────────
  static const String posAccess = 'pos.access';
  static const String posQuickSale = 'pos.quick_sale';
  static const String posManageSessions = 'pos.manage_sessions';
  static const String posAddDebt = 'pos.add_debt';

  // ── 2. Invoices & Sales ───────────────────────────────────────────
  static const String invoicesView = 'invoices.view';
  static const String invoicesCreate = 'invoices.create';
  static const String invoicesEdit = 'invoices.edit';
  static const String invoicesRecordPayment = 'invoices.record_payment';
  static const String invoicesDelete = 'invoices.delete';
  static const String invoicesPrintShare = 'invoices.print_share';

  // ── 3. Expenses ───────────────────────────────────────────────────
  static const String expensesView = 'expenses.view';
  static const String expensesAdd = 'expenses.add';
  static const String expensesDelete = 'expenses.delete';

  // ── 4. Customers & Customer Debts ─────────────────────────────────
  static const String customersView = 'customers.view';
  static const String customersAdd = 'customers.add';
  static const String customersSettleDebt = 'customers.settle_debt';
  static const String customersDeleteDebt = 'customers.delete_debt';
  static const String customersSendWhatsapp = 'customers.send_whatsapp';
  static const String customersViewReports = 'customers.view_reports';

  // ── 5. My Debts (Supplier Liabilities) ────────────────────────────
  static const String myDebtsView = 'my_debts.view';
  static const String myDebtsAdd = 'my_debts.add';
  static const String myDebtsPay = 'my_debts.pay';
  static const String myDebtsDelete = 'my_debts.delete';

  // ── 6. Vault & Cash Register ──────────────────────────────────────
  static const String vaultViewBalance = 'vault.view_balance';
  static const String vaultDeposit = 'vault.deposit';
  static const String vaultWithdraw = 'vault.withdraw';
  static const String vaultViewHistory = 'vault.view_history';

  // ── 7. Inventory Management ───────────────────────────────────────
  static const String inventoryView = 'inventory.view';
  static const String inventoryManageProducts = 'inventory.manage_products';
  static const String inventoryManageSuppliers = 'inventory.manage_suppliers';
  static const String inventoryManagePurchases = 'inventory.manage_purchases';
  static const String inventoryStockAdjustments = 'inventory.stock_adjustments';
  static const String inventoryViewAnalytics = 'inventory.view_analytics';

  // ── 8. HR & Employee Management ───────────────────────────────────
  static const String employeesView = 'employees.view';
  static const String employeesRecordAttendance = 'employees.record_attendance';
  static const String employeesManagePayroll = 'employees.manage_payroll';
  static const String employeesManageAppUsers = 'employees.manage_app_users';

  // ── 9. Reports & Financial Insights ───────────────────────────────
  static const String reportsViewNetProfit = 'reports.view_net_profit';
  static const String reportsViewSales = 'reports.view_sales';
  static const String reportsViewTax = 'reports.view_tax';
  static const String reportsExport = 'reports.export';

  // ── 10. Shipping Reconciliation ───────────────────────────────────
  static const String shippingView = 'shipping.view';

  // ── 11. Settings & Business ───────────────────────────────────────
  static const String settingsEditProfile = 'settings.edit_profile';
  static const String settingsManageSubscription =
      'settings.manage_subscription';
  static const String settingsDeleteAccount = 'settings.delete_account';

  // ── Convenient Aliases ───────────────────────────────────────────
  static const String customersCreate = customersAdd;
  static const String customersEdit = customersAdd;
  static const String debtsAdd = customersAdd;
  static const String debtsView = customersView;
  static const String debtsDelete = customersDeleteDebt;
  static const String debtsDeleteOrEdit = customersDeleteDebt;
  static const String myDebtsDeleteOrEdit = myDebtsDelete;
  static const String vaultAccess = vaultViewBalance;
  static const String hrEmployeesManage = employeesView;
  static const String shippingReconciliationView = shippingView;
  static const String teamManage = employeesManageAppUsers;
  static const String inventoryManageCategories = inventoryManageProducts;
  static const String inventoryPurchases = inventoryManagePurchases;
  static const String inventoryAnalytics = inventoryViewAnalytics;

  // ── Role Presets ──────────────────────────────────────────────────
  static const String roleCashier = 'cashier';
  static const String roleStorekeeper = 'storekeeper';
  static const String roleAccountant = 'accountant';
  static const String roleSupervisor = 'supervisor';
  static const String roleCustom = 'custom';

  /// Returns permissions list for a predefined role preset.
  static List<String> permissionsForPreset(String preset) {
    switch (preset) {
      case roleCashier:
        return [
          posAccess,
          posQuickSale,
          posManageSessions,
          posAddDebt,
          invoicesView,
          invoicesCreate,
          invoicesRecordPayment,
          invoicesPrintShare,
          customersView,
          customersAdd,
          customersSettleDebt,
          inventoryView,
        ];
      case roleStorekeeper:
        return [
          inventoryView,
          inventoryManageProducts,
          inventoryManageSuppliers,
          inventoryManagePurchases,
          inventoryStockAdjustments,
          myDebtsView,
          myDebtsAdd,
        ];
      case roleAccountant:
        return [
          invoicesView,
          invoicesCreate,
          invoicesEdit,
          invoicesRecordPayment,
          invoicesPrintShare,
          expensesView,
          expensesAdd,
          customersView,
          customersAdd,
          customersSettleDebt,
          customersViewReports,
          myDebtsView,
          myDebtsAdd,
          myDebtsPay,
          vaultViewBalance,
          vaultDeposit,
          vaultWithdraw,
          vaultViewHistory,
          reportsViewSales,
          reportsViewTax,
          reportsExport,
          shippingView,
        ];
      case roleSupervisor:
        return [
          posAccess,
          posQuickSale,
          posManageSessions,
          posAddDebt,
          invoicesView,
          invoicesCreate,
          invoicesEdit,
          invoicesRecordPayment,
          invoicesDelete,
          invoicesPrintShare,
          expensesView,
          expensesAdd,
          customersView,
          customersAdd,
          customersSettleDebt,
          customersDeleteDebt,
          customersSendWhatsapp,
          customersViewReports,
          myDebtsView,
          myDebtsAdd,
          myDebtsPay,
          vaultViewBalance,
          vaultDeposit,
          vaultWithdraw,
          vaultViewHistory,
          inventoryView,
          inventoryManageProducts,
          inventoryManageSuppliers,
          inventoryManagePurchases,
          inventoryStockAdjustments,
          employeesView,
          employeesRecordAttendance,
          shippingView,
        ];
      default:
        return [];
    }
  }

  /// All permission definitions grouped by category for UI selection.
  static final List<PermissionGroup> allGroups = [
    const PermissionGroup(
      id: 'pos',
      titleKey: AppStrings.permGroupPos,
      items: [
        PermissionItem(posAccess, AppStrings.permPosAccess),
        PermissionItem(posQuickSale, AppStrings.permPosQuickSale),
        PermissionItem(posManageSessions, AppStrings.permPosManageSessions),
        PermissionItem(posAddDebt, AppStrings.permPosAddDebt),
      ],
    ),
    const PermissionGroup(
      id: 'invoices',
      titleKey: AppStrings.permGroupInvoices,
      items: [
        PermissionItem(invoicesView, AppStrings.permInvoicesView),
        PermissionItem(invoicesCreate, AppStrings.permInvoicesCreate),
        PermissionItem(invoicesEdit, AppStrings.permInvoicesEdit),
        PermissionItem(invoicesRecordPayment, AppStrings.permInvoicesRecordPayment),
        PermissionItem(invoicesDelete, AppStrings.permInvoicesDelete),
        PermissionItem(invoicesPrintShare, AppStrings.permInvoicesPrintShare),
      ],
    ),
    const PermissionGroup(
      id: 'expenses',
      titleKey: AppStrings.permGroupExpenses,
      items: [
        PermissionItem(expensesView, AppStrings.permExpensesView),
        PermissionItem(expensesAdd, AppStrings.permExpensesAdd),
        PermissionItem(expensesDelete, AppStrings.permExpensesDelete),
      ],
    ),
    const PermissionGroup(
      id: 'customers',
      titleKey: AppStrings.permGroupCustomers,
      items: [
        PermissionItem(customersView, AppStrings.permCustomersView),
        PermissionItem(customersAdd, AppStrings.permCustomersAdd),
        PermissionItem(customersSettleDebt, AppStrings.permCustomersSettleDebt),
        PermissionItem(customersDeleteDebt, AppStrings.permCustomersDeleteDebt),
        PermissionItem(customersSendWhatsapp, AppStrings.permCustomersSendWhatsapp),
        PermissionItem(customersViewReports, AppStrings.permCustomersViewReports),
      ],
    ),
    const PermissionGroup(
      id: 'my_debts',
      titleKey: AppStrings.permGroupMyDebts,
      items: [
        PermissionItem(myDebtsView, AppStrings.permMyDebtsView),
        PermissionItem(myDebtsAdd, AppStrings.permMyDebtsAdd),
        PermissionItem(myDebtsPay, AppStrings.permMyDebtsPay),
        PermissionItem(myDebtsDelete, AppStrings.permMyDebtsDelete),
      ],
    ),
    const PermissionGroup(
      id: 'vault',
      titleKey: AppStrings.permGroupVault,
      items: [
        PermissionItem(vaultViewBalance, AppStrings.permVaultViewBalance),
        PermissionItem(vaultDeposit, AppStrings.permVaultDeposit),
        PermissionItem(vaultWithdraw, AppStrings.permVaultWithdraw),
        PermissionItem(vaultViewHistory, AppStrings.permVaultViewHistory),
      ],
    ),
    const PermissionGroup(
      id: 'inventory',
      titleKey: AppStrings.permGroupInventory,
      items: [
        PermissionItem(inventoryView, AppStrings.permInventoryView),
        PermissionItem(inventoryManageProducts, AppStrings.permInventoryManageProducts),
        PermissionItem(inventoryManageSuppliers, AppStrings.permInventoryManageSuppliers),
        PermissionItem(inventoryManagePurchases, AppStrings.permInventoryManagePurchases),
        PermissionItem(inventoryStockAdjustments, AppStrings.permInventoryStockAdjustments),
        PermissionItem(inventoryViewAnalytics, AppStrings.permInventoryViewAnalytics),
      ],
    ),
    const PermissionGroup(
      id: 'employees',
      titleKey: AppStrings.permGroupEmployees,
      items: [
        PermissionItem(employeesView, AppStrings.permEmployeesView),
        PermissionItem(employeesRecordAttendance, AppStrings.permEmployeesRecordAttendance),
        PermissionItem(employeesManagePayroll, AppStrings.permEmployeesManagePayroll),
        PermissionItem(employeesManageAppUsers, AppStrings.permEmployeesManageAppUsers),
      ],
    ),
    const PermissionGroup(
      id: 'reports',
      titleKey: AppStrings.permGroupReports,
      items: [
        PermissionItem(reportsViewNetProfit, AppStrings.permReportsViewNetProfit),
        PermissionItem(reportsViewSales, AppStrings.permReportsViewSales),
        PermissionItem(reportsViewTax, AppStrings.permReportsViewTax),
        PermissionItem(reportsExport, AppStrings.permReportsExport),
      ],
    ),
    const PermissionGroup(
      id: 'shipping',
      titleKey: AppStrings.permGroupShipping,
      items: [
        PermissionItem(shippingView, AppStrings.permShippingView),
      ],
    ),
    const PermissionGroup(
      id: 'settings',
      titleKey: AppStrings.permGroupSettings,
      items: [
        PermissionItem(settingsEditProfile, AppStrings.permSettingsEditProfile),
      ],
    ),
  ];
}

class PermissionGroup {
  final String id;
  final String titleKey;
  final List<PermissionItem> items;

  const PermissionGroup({
    required this.id,
    required this.titleKey,
    required this.items,
  });

  String get titleAr => titleKey.tr();
  String get titleEn => titleKey.tr();
}

class PermissionItem {
  final String key;
  final String labelKey;

  const PermissionItem(this.key, this.labelKey);

  String get labelAr => labelKey.tr();
  String get labelEn => labelKey.tr();
}
