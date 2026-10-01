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
  static const String customersViewPhone = 'customers.view_phone';
  static const String customersAdd = 'customers.add';
  static const String customersSettleDebt = 'customers.settle_debt';
  static const String customersDeleteDebt = 'customers.delete_debt';
  static const String customersSendWhatsapp = 'customers.send_whatsapp';
  static const String customersViewReports = 'customers.view_reports';
  static const String customersPrintShare = 'customers.print_share';

  // ── 5. My Debts (Supplier Liabilities) ────────────────────────────
  static const String myDebtsView = 'my_debts.view';
  static const String myDebtsAdd = 'my_debts.add';
  static const String myDebtsPay = 'my_debts.pay';
  static const String myDebtsDelete = 'my_debts.delete';

  // ── 6. Vault & Cash Register ──────────────────────────────────────
  static const String vaultAccess = 'vault.access';
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
  static const String customersViewContactInfo = customersViewPhone;
  static const String customersPrintShareStatement = customersPrintShare;
  static const String customersPrintStatement = customersPrintShare;
  static const String customersCreate = customersAdd;
  static const String customersEdit = customersAdd;
  static const String debtsAdd = customersAdd;
  static const String debtsView = customersView;
  static const String debtsDelete = customersDeleteDebt;
  static const String debtsDeleteOrEdit = customersDeleteDebt;
  static const String myDebtsDeleteOrEdit = myDebtsDelete;
  static const String hrEmployeesManage = employeesView;
  static const String shippingReconciliationView = shippingView;
  static const String teamManage = employeesManageAppUsers;
  static const String inventoryManageCategories = inventoryManageProducts;
  static const String inventoryPurchases = inventoryManagePurchases;
  static const String inventoryAnalytics = inventoryViewAnalytics;

  // ── Permission Group IDs ─────────────────────────────────────────
  static const String groupPos = 'pos';
  static const String groupInvoices = 'invoices';
  static const String groupExpenses = 'expenses';
  static const String groupCustomers = 'customers';
  static const String groupMyDebts = 'my_debts';
  static const String groupVault = 'vault';
  static const String groupInventory = 'inventory';
  static const String groupEmployees = 'employees';
  static const String groupReports = 'reports';
  static const String groupShipping = 'shipping';
  static const String groupSettings = 'settings';

  /// Whether current business type is shop (vs cafe).
  static bool get isShop => AppStrings.userType == AppStrings.shop;

  // ── Role Presets ──────────────────────────────────────────────────
  static const String roleCashier = 'cashier';
  static const String roleStorekeeper = 'storekeeper';
  static const String roleAccountant = 'accountant';
  static const String roleSupervisor = 'supervisor';
  static const String roleCustom = 'custom';

  /// Returns permissions list for a predefined role preset, filtered for the business type.
  static List<String> permissionsForPreset(String preset, {bool? isShop}) {
    final shop = isShop ?? (AppStrings.userType == AppStrings.shop);
    List<String> raw;
    switch (preset) {
      case roleCashier:
        raw = [
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
        break;
      case roleStorekeeper:
        raw = [
          inventoryView,
          inventoryManageProducts,
          inventoryManageSuppliers,
          inventoryManagePurchases,
          inventoryStockAdjustments,
          myDebtsView,
          myDebtsAdd,
        ];
        break;
      case roleAccountant:
        raw = [
          invoicesView,
          invoicesCreate,
          invoicesEdit,
          invoicesRecordPayment,
          invoicesPrintShare,
          expensesView,
          expensesAdd,
          customersView,
          customersViewPhone,
          customersAdd,
          customersSettleDebt,
          customersViewReports,
          customersPrintShare,
          myDebtsView,
          myDebtsAdd,
          myDebtsPay,
          vaultAccess,
          vaultViewBalance,
          vaultDeposit,
          vaultWithdraw,
          vaultViewHistory,
          reportsViewSales,
          reportsViewTax,
          reportsExport,
          shippingView,
        ];
        break;
      case roleSupervisor:
        raw = [
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
          customersViewPhone,
          customersAdd,
          customersSettleDebt,
          customersDeleteDebt,
          customersSendWhatsapp,
          customersViewReports,
          customersPrintShare,
          myDebtsView,
          myDebtsAdd,
          myDebtsPay,
          vaultAccess,
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
        break;
      default:
        return [];
    }

    final allowedKeys = getGroupsForBusinessType(isShop: shop)
        .expand((g) => g.items.map((i) => i.key))
        .toSet();

    return raw.where((p) => allowedKeys.contains(p)).toList();
  }

  /// Returns permission groups filtered for the specific business type (Shop vs Cafe).
  ///
  /// Shop accounts have access to:
  /// - Invoices & Sales (`groupInvoices`)
  /// - Vault (`groupVault`)
  /// - Inventory & Warehouse (`groupInventory`)
  /// - Shipping Reconciliation (`groupShipping`)
  /// But do NOT have access to PS / Cafe session management (`posManageSessions`).
  ///
  /// Cafe accounts have access to PS / Cafe session management (`posManageSessions`),
  /// but do NOT have access to Invoices, Vault, Inventory, or Shipping Reconciliation.
  static List<PermissionGroup> getGroupsForBusinessType({bool? isShop}) {
    final shop = isShop ?? (AppStrings.userType == AppStrings.shop);
    final List<PermissionGroup> result = [];

    for (final group in allGroups) {
      // 1. Shop-only groups: excluded for cafe accounts
      if (!shop &&
          (group.id == groupInvoices ||
              group.id == groupVault ||
              group.id == groupInventory ||
              group.id == groupShipping)) {
        continue;
      }

      // 2. Filter items within each group
      final filteredItems = group.items.where((item) {
        // PS / Cafe session management is cafe-only (excluded for shop)
        if (shop && item.key == posManageSessions) {
          return false;
        }
        return true;
      }).toList();

      if (filteredItems.isNotEmpty) {
        result.add(
          PermissionGroup(
            id: group.id,
            titleKey: group.titleKey,
            items: filteredItems,
          ),
        );
      }
    }

    return result;
  }

  /// All permission definitions grouped by category for UI selection.
  static final List<PermissionGroup> allGroups = [
    const PermissionGroup(
      id: groupPos,
      titleKey: AppStrings.permGroupPos,
      items: [
        PermissionItem(posAccess, AppStrings.permPosAccess),
        PermissionItem(posQuickSale, AppStrings.permPosQuickSale),
        PermissionItem(posManageSessions, AppStrings.permPosManageSessions),
        PermissionItem(posAddDebt, AppStrings.permPosAddDebt),
      ],
    ),
    const PermissionGroup(
      id: groupInvoices,
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
      id: groupExpenses,
      titleKey: AppStrings.permGroupExpenses,
      items: [
        PermissionItem(expensesView, AppStrings.permExpensesView),
        PermissionItem(expensesAdd, AppStrings.permExpensesAdd),
        PermissionItem(expensesDelete, AppStrings.permExpensesDelete),
      ],
    ),
    const PermissionGroup(
      id: groupCustomers,
      titleKey: AppStrings.permGroupCustomers,
      items: [
        PermissionItem(customersView, AppStrings.permCustomersView),
        PermissionItem(customersViewPhone, AppStrings.permCustomersViewPhone),
        PermissionItem(customersAdd, AppStrings.permCustomersAdd),
        PermissionItem(customersSettleDebt, AppStrings.permCustomersSettleDebt),
        PermissionItem(customersDeleteDebt, AppStrings.permCustomersDeleteDebt),
        PermissionItem(customersSendWhatsapp, AppStrings.permCustomersSendWhatsapp),
        PermissionItem(customersViewReports, AppStrings.permCustomersViewReports),
        PermissionItem(customersPrintShare, AppStrings.permCustomersPrintShare),
      ],
    ),
    const PermissionGroup(
      id: groupMyDebts,
      titleKey: AppStrings.permGroupMyDebts,
      items: [
        PermissionItem(myDebtsView, AppStrings.permMyDebtsView),
        PermissionItem(myDebtsAdd, AppStrings.permMyDebtsAdd),
        PermissionItem(myDebtsPay, AppStrings.permMyDebtsPay),
        PermissionItem(myDebtsDelete, AppStrings.permMyDebtsDelete),
      ],
    ),
    const PermissionGroup(
      id: groupVault,
      titleKey: AppStrings.permGroupVault,
      items: [
        PermissionItem(vaultAccess, AppStrings.permVaultAccess),
        PermissionItem(vaultViewBalance, AppStrings.permVaultViewBalance),
        PermissionItem(vaultDeposit, AppStrings.permVaultDeposit),
        PermissionItem(vaultWithdraw, AppStrings.permVaultWithdraw),
        PermissionItem(vaultViewHistory, AppStrings.permVaultViewHistory),
      ],
    ),
    const PermissionGroup(
      id: groupInventory,
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
      id: groupEmployees,
      titleKey: AppStrings.permGroupEmployees,
      items: [
        PermissionItem(employeesView, AppStrings.permEmployeesView),
        PermissionItem(employeesRecordAttendance, AppStrings.permEmployeesRecordAttendance),
        PermissionItem(employeesManagePayroll, AppStrings.permEmployeesManagePayroll),
        // PermissionItem(employeesManageAppUsers, AppStrings.permEmployeesManageAppUsers),
      ],
    ),
    const PermissionGroup(
      id: groupReports,
      titleKey: AppStrings.permGroupReports,
      items: [
        PermissionItem(reportsViewNetProfit, AppStrings.permReportsViewNetProfit),
        PermissionItem(reportsViewSales, AppStrings.permReportsViewSales),
        PermissionItem(reportsViewTax, AppStrings.permReportsViewTax),
        PermissionItem(reportsExport, AppStrings.permReportsExport),
      ],
    ),
    const PermissionGroup(
      id: groupShipping,
      titleKey: AppStrings.permGroupShipping,
      items: [
        PermissionItem(shippingView, AppStrings.permShippingView),
      ],
    ),
    const PermissionGroup(
      id: groupSettings,
      titleKey: AppStrings.permGroupSettings,
      items: [
        PermissionItem(settingsEditProfile, AppStrings.permSettingsEditProfile),
      ],
    ),
  ];

  /// Mapping of action/sub-permissions to their mandatory prerequisite permissions.
  static const Map<String, List<String>> permissionDependencies = {
    // POS
    posQuickSale: [posAccess],
    posManageSessions: [posAccess],
    posAddDebt: [posAccess, customersView],

    // Invoices
    invoicesCreate: [invoicesView],
    invoicesEdit: [invoicesView],
    invoicesRecordPayment: [invoicesView],
    invoicesDelete: [invoicesView],
    invoicesPrintShare: [invoicesView],

    // Expenses
    expensesAdd: [expensesView],
    expensesDelete: [expensesView],

    // Customers
    customersViewPhone: [customersView],
    customersAdd: [customersView],
    customersSettleDebt: [customersView],
    customersDeleteDebt: [customersView],
    customersSendWhatsapp: [customersView, customersViewPhone],
    customersViewReports: [customersView],
    customersPrintShare: [customersView, customersViewReports],

    // My Debts
    myDebtsAdd: [myDebtsView],
    myDebtsPay: [myDebtsView],
    myDebtsDelete: [myDebtsView],

    // Vault
    vaultViewBalance: [vaultAccess],
    vaultDeposit: [vaultAccess],
    vaultWithdraw: [vaultAccess],
    vaultViewHistory: [vaultAccess],

    // Inventory
    inventoryManageProducts: [inventoryView],
    inventoryManageSuppliers: [inventoryView],
    inventoryManagePurchases: [inventoryView],
    inventoryStockAdjustments: [inventoryView],
    inventoryViewAnalytics: [inventoryView],

    // Employees / HR
    employeesRecordAttendance: [employeesView],
    employeesManagePayroll: [employeesView],

    // Reports
    reportsExport: [reportsViewSales],
  };

  /// Returns all direct and indirect prerequisites required by [permission].
  static Set<String> getPrerequisites(String permission) {
    final result = <String>{};
    void addReqs(String p) {
      final reqs = permissionDependencies[p];
      if (reqs != null) {
        for (final req in reqs) {
          if (result.add(req)) {
            addReqs(req);
          }
        }
      }
    }
    addReqs(permission);
    return result;
  }

  /// Returns all permissions that directly or indirectly depend on [permission].
  static Set<String> getDependents(String permission) {
    final result = <String>{};
    void addDeps(String p) {
      for (final entry in permissionDependencies.entries) {
        if (entry.value.contains(p)) {
          if (result.add(entry.key)) {
            addDeps(entry.key);
          }
        }
      }
    }
    addDeps(permission);
    return result;
  }

  /// Resolves an iterable of permissions by including all their prerequisites.
  static Set<String> resolveDependencies(Iterable<String> permissions) {
    final resolved = Set<String>.from(permissions);
    for (final perm in permissions) {
      resolved.addAll(getPrerequisites(perm));
    }
    return resolved;
  }

  /// Checks if [permission] has any prerequisite dependencies.
  static bool hasPrerequisites(String permission) =>
      permissionDependencies.containsKey(permission) &&
      permissionDependencies[permission]!.isNotEmpty;

  /// Returns the localized label for a permission by [key].
  static String getPermissionLabel(String key) {
    for (final group in allGroups) {
      for (final item in group.items) {
        if (item.key == key) return item.labelKey.tr();
      }
    }
    return key;
  }

  /// Returns a comma-separated localized string of prerequisite labels for [permission].
  static String getPrerequisiteLabels(String permission) {
    final reqs = permissionDependencies[permission];
    if (reqs == null || reqs.isEmpty) return '';
    return reqs.map((k) => getPermissionLabel(k)).join('، ');
  }
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
