import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/permission_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/debt/presentation/cubit/total_debts/total_debts_cubit.dart';
import 'package:tahsel/features/debt/presentation/cubit/total_debts/total_debts_state.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';
import 'package:tahsel/core/services/profile/business_profile_service.dart';
import 'package:tahsel/features/settings/data/models/user_profile_model.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/routes/app_routes.dart';

/// Representation of an executive dashboard card item.
class _DashboardCardItem {
  final int index;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String? tag;
  final int? badgeCount;
  final VoidCallback onTap;

  const _DashboardCardItem({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.tag,
    this.badgeCount,
    required this.onTap,
  });
}

/// Clean, minimalist executive dashboard designed to match Tahsel's visual identity.
/// Exhibited exclusively when the logged-in user is an Owner AND has active team members.
class OwnerSmartDashboard extends StatefulWidget {
  final int activeEmployeesCount;
  final VoidCallback onOpenPos;

  const OwnerSmartDashboard({
    super.key,
    required this.activeEmployeesCount,
    required this.onOpenPos,
  });

  @override
  State<OwnerSmartDashboard> createState() => _OwnerSmartDashboardState();
}

class _OwnerSmartDashboardState extends State<OwnerSmartDashboard> {
  @override
  void initState() {
    super.initState();
    final uid = AppStrings.userToken;
    if (uid.isNotEmpty) {
      sl<TotalDebtsCubit>().getTotalDebts(uid);
    }
    BusinessProfileService.instance.getProfile();
  }

  @override
  Widget build(BuildContext context) {
    final activeEmployeesCount = widget.activeEmployeesCount;
    final onOpenPos = widget.onOpenPos;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final cubit = context.watch<MainLayoutCubit>();
    final isShop = cubit.isShop;
    final isVip = AppStrings.isVip;
    final permissions = PermissionService.instance;

    // Permissions mirroring side_nav_bar.dart conditions
    final canViewHome = permissions.hasPermission(AppPermissions.posAccess);
    final canViewExpenses = permissions.hasPermission(
      AppPermissions.expensesView,
    );
    final canViewDebts =
        permissions.hasPermission(AppPermissions.customersView) ||
        permissions.hasPermission(AppPermissions.myDebtsView);
    final canViewInvoices =
        isShop && permissions.hasPermission(AppPermissions.invoicesView);
    final canViewReports =
        permissions.hasPermission(AppPermissions.reportsViewSales) ||
        permissions.hasPermission(AppPermissions.reportsViewNetProfit);
    final canViewVault =
        isVip &&
        isShop &&
        permissions.hasPermission(AppPermissions.vaultAccess);
    final canViewInventory =
        isVip &&
        isShop &&
        permissions.hasPermission(AppPermissions.inventoryView);
    final canManageProducts =
        canViewInventory &&
        permissions.hasPermission(AppPermissions.inventoryManageProducts);
    final canManageCategories =
        canViewInventory &&
        (permissions.hasPermission(AppPermissions.inventoryManageCategories) ||
            permissions.hasPermission(AppPermissions.inventoryView));
    final canManageSuppliers =
        canViewInventory &&
        permissions.hasPermission(AppPermissions.inventoryManageSuppliers);
    final canManagePurchases =
        canViewInventory &&
        permissions.hasPermission(AppPermissions.inventoryPurchases);
    final canViewStockMovements =
        canViewInventory &&
        permissions.hasPermission(AppPermissions.inventoryStockAdjustments);
    final canManageHREmployees =
        isVip && permissions.hasPermission(AppPermissions.hrEmployeesManage);
    final canViewCustomers = permissions.hasPermission(
      AppPermissions.customersView,
    );
    final canViewShipping =
        isShop &&
        permissions.hasPermission(AppPermissions.shippingReconciliationView);
    final canManageTeam = isVip && permissions.isOwner;
    final canManageCustodies = isShop && isVip && permissions.isOwner;

    // Cohesive, quiet color palette aligned with Tahsel's primary identity
    final List<_DashboardCardItem> items = [];

    // 0: POS / Quick Add
    if (canViewHome) {
      items.add(
        _DashboardCardItem(
          index: 0,
          title: AppStrings.quickAdd.tr(),
          subtitle: isShop
              ? AppStrings.directSaleAndQuickAdd.tr()
              : AppStrings.timeSessionsAndQuickAdd.tr(),
          icon: isShop
              ? Icons.point_of_sale_rounded
              : Icons.sports_esports_rounded,
          accentColor: AppColors.primaryColor,
          onTap: onOpenPos,
        ),
      );
    }

    // 1: Expenses
    if (canViewExpenses) {
      items.add(
        _DashboardCardItem(
          index: 1,
          title: AppStrings.allExpenses.tr(),
          subtitle: AppStrings.trackDailyExpenses.tr(),
          icon: Icons.account_balance_wallet_rounded,
          accentColor: AppColors.error,
          onTap: () => cubit.changeBottomNav(1),
        ),
      );
    }

    // 2: Debts
    if (canViewDebts) {
      items.add(
        _DashboardCardItem(
          index: 2,
          title: AppStrings.totalDebts.tr(),
          subtitle: AppStrings.manageDebtsAndPayments.tr(),
          icon: Icons.people_alt_rounded,
          accentColor: AppColors.warning,
          onTap: () => cubit.changeBottomNav(2),
        ),
      );
    }

    // 3: Invoices (Shop only)
    if (isShop && canViewInvoices) {
      items.add(
        _DashboardCardItem(
          index: 3,
          title: AppStrings.invoices.tr(),
          subtitle: AppStrings.salesInvoicesAndQuotes.tr(),
          icon: Icons.receipt_long_rounded,
          accentColor: AppColors.info,
          onTap: () => cubit.changeBottomNav(3),
        ),
      );
    }

    // 4: Reports
    if (canViewReports) {
      items.add(
        _DashboardCardItem(
          index: 4,
          title: AppStrings.reports.tr(),
          subtitle: AppStrings.salesAndProfitAnalytics.tr(),
          icon: Icons.bar_chart_rounded,
          accentColor: AppColors.primaryColor,
          onTap: () => cubit.changeBottomNav(4),
        ),
      );
    }

    // 6: Customers
    if (canViewCustomers) {
      items.add(
        _DashboardCardItem(
          index: 6,
          title: AppStrings.myCustomers.tr(),
          subtitle: AppStrings.customerDatabaseAndRecords.tr(),
          icon: Icons.contacts_rounded,
          accentColor: AppColors.primaryColor,
          onTap: () => cubit.changeBottomNav(6),
        ),
      );
    }

    // 7: Vault (VIP & Shop)
    if (canViewVault) {
      items.add(
        _DashboardCardItem(
          index: 7,
          title: AppStrings.vaultTitle.tr(),
          subtitle: AppStrings.cashFlowAndVaultTransactions.tr(),
          icon: Icons.account_balance_rounded,
          accentColor: AppColors.warning,
          tag: 'VIP ✨',
          onTap: () => cubit.changeBottomNav(7),
        ),
      );
    }

    // 8: Inventory (VIP & Shop)
    if (canViewInventory) {
      items.add(
        _DashboardCardItem(
          index: 8,
          title: AppStrings.inventoryManagementVIP.tr(),
          subtitle: AppStrings.trackProductsAndStockMovement.tr(),
          icon: Icons.inventory_2_rounded,
          accentColor: AppColors.inventorySupplierTeal,
          tag: 'VIP ✨',
          badgeCount: cubit.lowStockCount > 0 ? cubit.lowStockCount : null,
          onTap: () => cubit.changeBottomNav(8),
        ),
      );
    }

    // 81: Total Products (VIP & Shop)
    if (canManageProducts) {
      items.add(
        _DashboardCardItem(
          index: 81,
          title: AppStrings.totalProductsCount.tr(),
          subtitle: AppStrings.totalProductsCatalogDesc.tr(),
          icon: Icons.shopping_bag_rounded,
          accentColor: AppColors.primaryColor,
          tag: 'VIP ✨',
          onTap: () => Navigator.pushNamed(context, AppRoutes.inventoryProducts),
        ),
      );
    }

    // 82: Product Categories (VIP & Shop)
    if (canManageCategories) {
      items.add(
        _DashboardCardItem(
          index: 82,
          title: AppStrings.inventoryCategories.tr(),
          subtitle: AppStrings.inventoryCategoriesCardDesc.tr(),
          icon: Icons.category_rounded,
          accentColor: AppColors.inventoryCategoryBrown,
          tag: 'VIP ✨',
          onTap: () => Navigator.pushNamed(context, AppRoutes.inventoryCategories),
        ),
      );
    }

    // 83: Suppliers (VIP & Shop)
    if (canManageSuppliers) {
      items.add(
        _DashboardCardItem(
          index: 83,
          title: AppStrings.inventorySuppliers.tr(),
          subtitle: AppStrings.inventorySuppliersCardDesc.tr(),
          icon: Icons.local_shipping_rounded,
          accentColor: AppColors.inventorySupplierTeal,
          tag: 'VIP ✨',
          onTap: () => Navigator.pushNamed(context, AppRoutes.inventorySuppliers),
        ),
      );
    }

    // 84: Purchase Invoices (VIP & Shop)
    if (canManagePurchases) {
      items.add(
        _DashboardCardItem(
          index: 84,
          title: AppStrings.inventoryPurchases.tr(),
          subtitle: AppStrings.inventoryPurchasesCardDesc.tr(),
          icon: Icons.receipt_long_rounded,
          accentColor: AppColors.inventoryPurchasePurple,
          tag: 'VIP ✨',
          onTap: () => Navigator.pushNamed(context, AppRoutes.inventoryPurchases),
        ),
      );
    }

    // 85: Stock Movements History (VIP & Shop)
    if (canViewStockMovements) {
      items.add(
        _DashboardCardItem(
          index: 85,
          title: AppStrings.inventoryStockMovements.tr(),
          subtitle: AppStrings.inventoryStockMovementsCardDesc.tr(),
          icon: Icons.history_rounded,
          accentColor: AppColors.error,
          tag: 'VIP ✨',
          onTap: () => Navigator.pushNamed(context, AppRoutes.inventoryStockMovements),
        ),
      );
    }

    // 11: Team & Permissions (VIP & Owner)
    if (canManageTeam) {
      items.add(
        _DashboardCardItem(
          index: 11,
          title: AppStrings.teamAndPermissions.tr(),
          subtitle: AppStrings.manageTeamAccountsAndPermissions.tr(),
          icon: Icons.admin_panel_settings_rounded,
          accentColor: AppColors.primaryColor,
          tag: 'VIP ✨',
          badgeCount: activeEmployeesCount > 0 ? activeEmployeesCount : null,
          onTap: () => cubit.changeBottomNav(11),
        ),
      );
    }

    // 12: Custodies (VIP & Owner & Shop)
    if (canManageCustodies) {
      items.add(
        _DashboardCardItem(
          index: 12,
          title: AppStrings.employeeCustodies.tr(),
          subtitle: AppStrings.handoverAndSettleCustodies.tr(),
          icon: Icons.account_balance_wallet_outlined,
          accentColor: AppColors.warning,
          tag: 'VIP ✨',
          onTap: () => cubit.changeBottomNav(12),
        ),
      );
    }

    // 9: HR Employees (VIP)
    if (canManageHREmployees) {
      items.add(
        _DashboardCardItem(
          index: 9,
          title: AppStrings.employeeManagement.tr(),
          subtitle: AppStrings.attendancePayrollAndAdvances.tr(),
          icon: Icons.badge_rounded,
          accentColor: AppColors.primaryColor,
          tag: 'VIP ✨',
          onTap: () => cubit.changeBottomNav(9),
        ),
      );
    }

    // 10: Shipping Reconciliation (Shop only)
    if (canViewShipping) {
      items.add(
        _DashboardCardItem(
          index: 10,
          title: AppStrings.shippingReportsReconciliationOffline.tr(),
          subtitle: AppStrings.shippingPolicyReconciliation.tr(),
          icon: Icons.local_shipping_rounded,
          accentColor: AppColors.info,
          onTap: () => cubit.changeBottomNav(10),
        ),
      );
    }

    // 5: MoreScreen
    items.add(
      _DashboardCardItem(
        index: 5,
        title: AppStrings.more.tr(),
        subtitle: AppStrings.generalSettingsAndBackup.tr(),
        icon: Icons.grid_view_rounded,
        accentColor: AppColors.blackLight,
        onTap: () => cubit.changeBottomNav(5),
      ),
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 960 : double.infinity,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 10,
            vertical: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Clean Executive Summary Header
              _buildExecutiveHeader(context, cubit, canViewDebts),
              const SizedBox(height: 16),

              // Responsive, Overflow-Free Adaptive Grid Layout (strictly 2 columns on mobile)
              LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final int crossAxisCount = (isDesktop && totalWidth >= 700)
                      ? (totalWidth >= 1050 ? 4 : 3)
                      : 2;
                  final double spacing = isDesktop ? 12.0 : 8.0;
                  final double cardHeight = isDesktop ? 122.0 : 118.0;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      mainAxisExtent: cardHeight,
                    ),
                    itemBuilder: (context, index) {
                      return _DashboardCard(item: items[index]);
                    },
                  );
                },
              ),

              const SizedBox(height: 90), // Spacing for bottom navigation bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExecutiveHeader(
    BuildContext context,
    MainLayoutCubit cubit,
    bool canViewDebts,
  ) {
    final isDark = AppColors.isDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Status Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Owner Identity Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(
                    alpha: isDark ? 0.2 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      color: AppColors.primaryColor,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      AppStrings.ownerAccount.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Activity Type / Project Name Pill
              BlocConsumer<ConnectivityCubit, ConnectivityState>(
                listenWhen: (prev, curr) =>
                    prev is ConnectivityDisconnected &&
                    curr is ConnectivityConnected,
                listener: (context, state) {
                  BusinessProfileService.instance.getProfile(forceRemote: true);
                },
                builder: (context, connectivityState) {
                  final isOffline =
                      connectivityState is ConnectivityDisconnected;

                  return ValueListenableBuilder<UserProfileModel?>(
                    valueListenable:
                        BusinessProfileService.instance.profileNotifier,
                    builder: (context, profile, _) {
                      final activeProfile = profile ??
                          BusinessProfileService.instance.cachedProfile;
                      final projectName =
                          activeProfile?.projectName.trim() ?? '';
                      final hasValidName = projectName.isNotEmpty;

                      final String displayName = (!isOffline && hasValidName)
                          ? projectName
                          : (cubit.isShop
                              ? AppStrings.businessTypeShop.tr()
                              : AppStrings.businessTypeCafe.tr());

                      final isDesktop = ResponsiveLayout.isDesktop(context);

                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isDesktop ? 260 : 180,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blackLight.withValues(
                              alpha: isDark ? 0.12 : 0.07,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cubit.isShop
                                    ? Icons.storefront_rounded
                                    : Icons.local_cafe_rounded,
                                color: AppColors.blackLight,
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyles.customStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.blackLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              // VIP Badge
              if (AppStrings.isVip)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.vipGoldStart.withValues(
                      alpha: isDark ? 0.2 : 0.14,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.vipGoldStart.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'VIP ✨',
                    style: TextStyles.customStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.vipGoldStart
                          : const Color(0xFF8A5A00),
                    ),
                  ),
                ),

              // Live Team Status Pill
              InkWell(
                onTap: () => cubit.changeBottomNav(11),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(
                      alpha: isDark ? 0.18 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        AppStrings.teamMembersActiveCount.tr(
                          namedArgs: {
                            'count': '${widget.activeEmployeesCount}',
                          },
                        ),
                        style: TextStyles.customStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main Title & Subtitle
          Text(
            AppStrings.dashboardAndOperations.tr(),
            style: TextStyles.customStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppStrings.dashboardOperationsSubtitle.tr(),
            style: TextStyles.customStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.blackLight,
            ),
          ),
          const SizedBox(height: 14),

          // Total Customer Debts Summary KPI Card
          if (canViewDebts) ...[
            BlocBuilder<TotalDebtsCubit, TotalDebtsState>(
              bloc: sl<TotalDebtsCubit>(),
              builder: (context, state) {
                if (state is TotalDebtsError) {
                  return const SizedBox.shrink();
                }

                final isLoading =
                    state is TotalDebtsLoading || state is TotalDebtsInitial;
                final totalAmountText = state is TotalDebtsLoaded
                    ? '${state.totalAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}'
                    : '...';

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(
                      alpha: isDark ? 0.12 : 0.05,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.error.withValues(
                        alpha: isDark ? 0.25 : 0.16,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => cubit.changeBottomNav(2),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(
                                  alpha: isDark ? 0.22 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_outlined,
                                color: AppColors.error,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        AppStrings.totalDebts.tr(),
                                        style: TextStyles.customStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.blackLight,
                                        ),
                                      ),
                                      if (state is TotalDebtsLoaded &&
                                          state.customerCount > 0) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withValues(
                                              alpha: isDark ? 0.2 : 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '${state.customerCount} ${AppStrings.customers.tr()}',
                                            style: TextStyles.customStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  if (isLoading)
                                    SizedBox(
                                      height: 18,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Text(
                                      totalAmountText,
                                      style: TextStyles.customStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.error,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: AppColors.error.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],

          // Quick Action Bar
          Row(
            children: [
              Expanded(
                child: Material(
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: widget.onOpenPos,
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryGradientStart,
                            AppColors.primaryGradientEnd,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.onPrimary.withValues(
                                alpha: isDark ? 0.16 : 0.2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.point_of_sale_rounded,
                              size: 16,
                              color: AppColors.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              cubit.isShop
                                  ? AppStrings.quickPosAction.tr()
                                  : AppStrings.quickSessionsAction.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyles.customStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.onPrimary.withValues(
                                alpha: isDark ? 0.14 : 0.16,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (cubit.lowStockCount > 0 && cubit.isShop) ...[
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => cubit.changeBottomNav(8),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(
                          alpha: isDark ? 0.2 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                            size: 17,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            AppStrings.shortagesCount.tr(
                              namedArgs: {'count': '${cubit.lowStockCount}'},
                            ),
                            style: TextStyles.customStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A minimalist, overflow-free dashboard card matching Tahsel's identity.
class _DashboardCard extends StatefulWidget {
  final _DashboardCardItem item;

  const _DashboardCard({required this.item});

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final accent = item.accentColor;
    final isDark = AppColors.isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        onHover: (hovered) {
          if (mounted) setState(() => _isHovered = hovered);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? AppColors.primaryColor.withValues(alpha: 0.45)
                  : AppColors.dividerColor,
              width: _isHovered ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: _isHovered
                      ? (isDark ? 0.25 : 0.08)
                      : (isDark ? 0.12 : 0.03),
                ),
                blurRadius: _isHovered ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Soft-tinted icon + Badge/Tag + Arrow
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.18 : 0.09),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, color: accent, size: 16),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (item.badgeCount != null) ...[
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (item.index == 8
                                            ? AppColors.warning
                                            : AppColors.success)
                                        .withValues(
                                          alpha: isDark ? 0.22 : 0.12,
                                        ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                item.index == 8
                                    ? AppStrings.shortagesCount.tr(
                                        namedArgs: {
                                          'count': '${item.badgeCount}',
                                        },
                                      )
                                    : AppStrings.activeMembersCount.tr(
                                        namedArgs: {
                                          'count': '${item.badgeCount}',
                                        },
                                      ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyles.customStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: item.index == 8
                                      ? AppColors.warning
                                      : AppColors.success,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                        ] else if (item.tag != null) ...[
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.vipGoldStart,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                item.tag!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyles.customStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                        ],
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 9.5,
                          color: AppColors.blackLight.withValues(alpha: 0.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Title & Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.customStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.customStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.w400,
                      color: AppColors.blackLight,
                      height: 1.22,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
