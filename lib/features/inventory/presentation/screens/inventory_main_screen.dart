import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';
import 'package:tahsel/routes/app_routes.dart';

import '../cubits/inventory_dashboard_cubit.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

class InventoryMainScreen extends StatefulWidget {
  const InventoryMainScreen({super.key});

  @override
  State<InventoryMainScreen> createState() => _InventoryMainScreenState();
}

class _InventoryMainScreenState extends State<InventoryMainScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InventoryDashboardCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isPushed = !(ModalRoute.of(context)?.isFirst ?? true);
    final showBackButton = isPushed || !isDesktop;

    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.scafoldBackGround,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: showBackButton
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.primaryColor,
                ),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    try {
                      context.read<MainLayoutCubit>().changeBottomNav(0);
                    } catch (_) {}
                  }
                },
              )
            : null,
        centerTitle: true,
        title: Text(
          AppStrings.inventoryManagementVIP.tr(),
          style: TextStyles.customStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: isDesktop ? 16 : 16.w,
              vertical: isDesktop ? 10 : 10.h,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 12 : 10.w,
              vertical: isDesktop ? 6 : 5.h,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.vipGoldStart, AppColors.vipGoldEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.vipGoldStart.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  size: 16,
                  color: Colors.black87,
                ),
                SizedBox(width: isDesktop ? 4 : 4.w),
                Text(
                  'VIP',
                  style: TextStyles.customStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 950 : double.infinity,
            ),
            child: RefreshIndicator(
              color: AppColors.primaryColor,
              backgroundColor: AppColors.surface,
              onRefresh: () =>
                  context.read<InventoryDashboardCubit>().loadDashboard(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 16.w,
                  vertical: isDesktop ? 16 : 16.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tahsel Primary Theme Hero Card
                    _buildTahselHeroCard(context, isDesktop: isDesktop),

                    SizedBox(height: isDesktop ? 24 : 20.h),

                    // KPI Summary Cards with Tahsel Theme AppColors
                    BlocBuilder<
                      InventoryDashboardCubit,
                      InventoryDashboardState
                    >(
                      builder: (context, state) {
                        if (state is InventoryDashboardLoading) {
                          return Row(
                            children: [
                              Expanded(
                                child: _buildTahselKpiCardSkeleton(
                                  isDesktop: isDesktop,
                                ),
                              ),
                              SizedBox(width: isDesktop ? 14 : 10.w),
                              Expanded(
                                child: _buildTahselKpiCardSkeleton(
                                  isDesktop: isDesktop,
                                ),
                              ),
                              SizedBox(width: isDesktop ? 14 : 10.w),
                              Expanded(
                                child: _buildTahselKpiCardSkeleton(
                                  isDesktop: isDesktop,
                                ),
                              ),
                            ],
                          );
                        }

                        int totalProducts = 0;
                        int lowStockCount = 0;
                        double totalValue = 0.0;

                        if (state is InventoryDashboardLoaded) {
                          totalProducts = state.totalProductsCount;
                          lowStockCount = state.lowStockCount;
                          totalValue = state.totalInventoryValue;
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18.r),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.inventoryProducts,
                                  );
                                },
                                child: _buildTahselKpiCard(
                                  title: AppStrings.totalProductsCount.tr(),
                                  value: '$totalProducts',
                                  icon: Icons.inventory_2_rounded,
                                  color: AppColors.primaryColor,
                                  isDesktop: isDesktop,
                                ),
                              ),
                            ),
                            SizedBox(width: isDesktop ? 14 : 10.w),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.inventoryProducts,
                                    arguments: true,
                                  );
                                },
                                borderRadius: BorderRadius.circular(18.r),
                                child: _buildTahselKpiCard(
                                  title: AppStrings.lowStockCount.tr(),
                                  value: '$lowStockCount',
                                  icon: Icons.warning_amber_rounded,
                                  color: lowStockCount > 0
                                      ? AppColors.warning
                                      : AppColors.success,
                                  isDesktop: isDesktop,
                                ),
                              ),
                            ),
                            SizedBox(width: isDesktop ? 14 : 10.w),
                            Expanded(
                              child: _buildTahselKpiCard(
                                title: AppStrings.totalInventoryValue.tr(),
                                value: totalValue.toStringAsFixed(0),
                                subtitle: AppStrings.currencyEgp.tr(),
                                icon: Icons.account_balance_wallet_rounded,
                                color: AppColors.success,
                                isDesktop: isDesktop,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    SizedBox(height: isDesktop ? 32 : 24.h),

                    Text(
                      AppStrings.inventorySubmodulesTitle.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 16 : 16.h),

                    _buildModulesGrid(context, isDesktop),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTahselHeroCard(BuildContext context, {required bool isDesktop}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Background Glow Circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 130.w,
              height: 130.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.vipGoldStart.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 100.w,
              height: 100.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isDesktop ? 22 : 18.w),
            child: Row(
              children: [
                // Icon Frame
                Container(
                  padding: EdgeInsets.all(isDesktop ? 14 : 12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(isDesktop ? 16 : 14.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: AppColors.vipGoldStart,
                    size: 28,
                  ),
                ),
                SizedBox(width: isDesktop ? 16 : 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.inventoryManagementVIP.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 4 : 4.h),
                      Text(
                        AppStrings.inventoryManagementVIPDesc.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isDesktop ? 12 : 8.w),
                // VIP Golden Metallic Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 12 : 10.w,
                    vertical: isDesktop ? 6 : 5.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.vipGoldStart, AppColors.vipGoldEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.vipGoldStart.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        size: 16,
                        color: Colors.black87,
                      ),
                      SizedBox(width: isDesktop ? 4 : 4.w),
                      Text(
                        'VIP',
                        style: TextStyles.customStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTahselKpiCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    required bool isDesktop,
  }) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            radius: isDesktop ? 22.r : 18.r,
            child: Icon(icon, color: color, size: isDesktop ? 22 : 18),
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.customStyle(
              fontSize: isDesktop ? 14 : 12,
              color: AppColors.sandText,
            ),
          ),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyles.customStyle(
                    fontSize: isDesktop ? 20 : 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blackReal,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(width: 4.w),
                  Text(
                    subtitle,
                    style: TextStyles.customStyle(
                      fontSize: 11,
                      color: AppColors.sandText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTahselKpiCardSkeleton({required bool isDesktop}) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: const [AppColors.shadow],
      ),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerPlaceholder(
              width: isDesktop ? 44.r : 36.r,
              height: isDesktop ? 44.r : 36.r,
              shape: BoxShape.circle,
            ),
            SizedBox(height: 10.h),
            ShimmerPlaceholder(
              width: isDesktop ? 70 : 60.w,
              height: isDesktop ? 14 : 12,
              borderRadius: 4,
            ),
            SizedBox(height: 6.h),
            ShimmerPlaceholder(
              width: isDesktop ? 50 : 40.w,
              height: isDesktop ? 18 : 16,
              borderRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesGrid(BuildContext context, bool isDesktop) {
    final modules = [
      _InventoryModuleItem(
        title: AppStrings.inventoryProducts.tr(),
        subtitle: AppStrings.inventoryManagementVIPDesc.tr(),
        icon: Icons.shopping_bag_rounded,
        color: AppColors.primaryColor,
        route: AppRoutes.inventoryProducts,
      ),
      _InventoryModuleItem(
        title: AppStrings.inventoryCategories.tr(),
        subtitle: AppStrings.categoryDescription.tr(),
        icon: Icons.category_rounded,
        color: AppColors.inventoryCategoryBrown,
        route: AppRoutes.inventoryCategories,
      ),
      _InventoryModuleItem(
        title: AppStrings.inventorySuppliers.tr(),
        subtitle: AppStrings.supplierDetails.tr(),
        icon: Icons.local_shipping_rounded,
        color: AppColors.inventorySupplierTeal,
        route: AppRoutes.inventorySuppliers,
      ),
      _InventoryModuleItem(
        title: AppStrings.inventoryPurchases.tr(),
        subtitle: AppStrings.purchaseHistory.tr(),
        icon: Icons.receipt_long_rounded,
        color: AppColors.inventoryPurchasePurple,
        route: AppRoutes.inventoryPurchases,
      ),
      _InventoryModuleItem(
        title: AppStrings.inventoryStockMovements.tr(),
        subtitle: AppStrings.stockMovementsHistory.tr(),
        icon: Icons.history_rounded,
        color: AppColors.error,
        route: AppRoutes.inventoryStockMovements,
      ),
      _InventoryModuleItem(
        title: AppStrings.inventoryAnalytics.tr(),
        subtitle: AppStrings.inventoryAnalyticsDesc.tr(),
        icon: Icons.analytics_rounded,
        color: AppColors.creditAmberStart,
        route: AppRoutes.inventoryAnalytics,
      ),
    ];

    final int columns = isDesktop ? 3 : 2;
    final List<Widget> rows = [];

    for (int i = 0; i < modules.length; i += columns) {
      final end = (i + columns < modules.length) ? i + columns : modules.length;
      final rowItems = modules.sublist(i, end);

      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int j = 0; j < rowItems.length; j++) ...[
                if (j > 0) SizedBox(width: isDesktop ? 16 : 12.w),
                Expanded(
                  child: _buildTahselModuleTile(
                    context,
                    title: rowItems[j].title,
                    subtitle: rowItems[j].subtitle,
                    icon: rowItems[j].icon,
                    color: rowItems[j].color,
                    route: rowItems[j].route,
                    isDesktop: isDesktop,
                  ),
                ),
              ],
              for (int k = 0; k < columns - rowItems.length; k++) ...[
                SizedBox(width: isDesktop ? 16 : 12.w),
                const Expanded(child: SizedBox.shrink()),
              ],
            ],
          ),
        ),
      );

      if (i + columns < modules.length) {
        rows.add(SizedBox(height: isDesktop ? 16 : 12.h));
      }
    }

    return Column(children: rows);
  }

  Widget _buildTahselModuleTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
    required bool isDesktop,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.all(isDesktop ? 16 : 14.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    radius: isDesktop ? 20.r : 18.r,
                    child: Icon(icon, color: color, size: isDesktop ? 20 : 18),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.sandText,
                  ),
                ],
              ),
              SizedBox(height: isDesktop ? 12 : 8.h),
              Text(
                title,
                style: TextStyles.customStyle(
                  fontSize: isDesktop ? 15 : 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blackReal,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyles.customStyle(
                  fontSize: isDesktop ? 11.5 : 10.5,
                  color: AppColors.sandText,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryModuleItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _InventoryModuleItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}
