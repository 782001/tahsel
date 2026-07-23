import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/routes/app_routes.dart';
import '../cubits/inventory_dashboard_cubit.dart';

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

    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      appBar: AppBar(
        backgroundColor: AppColors.scafoldBackGround,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppStrings.inventoryManagementVIP.tr(),
          style: TextStyles.customStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 16, color: Colors.black),
                SizedBox(width: 4.w),
                Text(
                  'VIP',
                  style: TextStyles.customStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
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
              maxWidth: isDesktop ? 900 : double.infinity,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 16.w,
                vertical: 16.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Overview Cards
                  BlocBuilder<InventoryDashboardCubit, InventoryDashboardState>(
                    builder: (context, state) {
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
                            child: _buildKpiCard(
                              title: AppStrings.totalProductsCount.tr(),
                              value: '$totalProducts',
                              icon: Icons.inventory_2_rounded,
                              color: AppColors.primaryColor,
                              isDesktop: isDesktop,
                            ),
                          ),
                          SizedBox(width: isDesktop ? 16 : 10.w),
                          Expanded(
                            child: _buildKpiCard(
                              title: AppStrings.lowStockCount.tr(),
                              value: '$lowStockCount',
                              icon: Icons.warning_amber_rounded,
                              color: lowStockCount > 0 ? AppColors.warning : AppColors.success,
                              isDesktop: isDesktop,
                            ),
                          ),
                          SizedBox(width: isDesktop ? 16 : 10.w),
                          Expanded(
                            child: _buildKpiCard(
                              title: AppStrings.totalInventoryValue.tr(),
                              value: totalValue.toStringAsFixed(0),
                              subtitle: 'ج.م',
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
                    'أقسام إدارة المخزون',
                    style: TextStyles.customStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Sub-modules Navigation Grid/List
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isDesktop ? 3 : 2,
                    mainAxisSpacing: isDesktop ? 16 : 12.h,
                    crossAxisSpacing: isDesktop ? 16 : 12.w,
                    childAspectRatio: isDesktop ? 1.4 : 1.1,
                    children: [
                      _buildModuleTile(
                        context,
                        title: AppStrings.inventoryProducts.tr(),
                        subtitle: AppStrings.inventoryManagementVIPDesc.tr(),
                        icon: Icons.shopping_bag_rounded,
                        color: const Color(0xFF1E56A0),
                        route: AppRoutes.inventoryProducts,
                      ),
                      _buildModuleTile(
                        context,
                        title: AppStrings.inventoryCategories.tr(),
                        subtitle: AppStrings.categoryDescription.tr(),
                        icon: Icons.category_rounded,
                        color: const Color(0xFF834600),
                        route: AppRoutes.inventoryCategories,
                      ),
                      _buildModuleTile(
                        context,
                        title: AppStrings.inventorySuppliers.tr(),
                        subtitle: AppStrings.supplierDetails.tr(),
                        icon: Icons.local_shipping_rounded,
                        color: const Color(0xFF00796B),
                        route: AppRoutes.inventorySuppliers,
                      ),
                      _buildModuleTile(
                        context,
                        title: AppStrings.inventoryPurchases.tr(),
                        subtitle: AppStrings.purchaseHistory.tr(),
                        icon: Icons.receipt_long_rounded,
                        color: const Color(0xFF6B11B0),
                        route: AppRoutes.inventoryPurchases,
                      ),
                      _buildModuleTile(
                        context,
                        title: AppStrings.inventoryStockMovements.tr(),
                        subtitle: AppStrings.stockMovementsHistory.tr(),
                        icon: Icons.history_rounded,
                        color: const Color(0xFFD32F2F),
                        route: AppRoutes.inventoryStockMovements,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    required bool isDesktop,
  }) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 18 : 12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.dividerColor),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.customStyle(
              fontSize: isDesktop ? 13 : 11,
              color: AppColors.sandText,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
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
        ],
      ),
    );
  }

  Widget _buildModuleTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(isDesktop ? 16 : 12.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.12),
                    radius: isDesktop ? 20.r : 18.r,
                    child: Icon(icon, color: color, size: isDesktop ? 20 : 18),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.sandText),
                ],
              ),
              SizedBox(height: 6.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 15 : 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackReal,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 12 : 10,
                        color: AppColors.sandText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
