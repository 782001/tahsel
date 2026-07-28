import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/currency/currency_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import '../../domain/entities/inventory_category_entity.dart';
import '../../domain/entities/inventory_product_entity.dart';
import '../../domain/entities/inventory_supplier_entity.dart';
import '../cubits/inventory_categories_cubit.dart';
import '../cubits/inventory_products_cubit.dart';
import '../cubits/inventory_suppliers_cubit.dart';
import '../widgets/add_edit_product_dialog.dart';
import '../widgets/inventory_empty_state.dart';
import '../widgets/inventory_tab_selector.dart';

class InventoryAnalyticsScreen extends StatefulWidget {
  const InventoryAnalyticsScreen({super.key});

  @override
  State<InventoryAnalyticsScreen> createState() =>
      _InventoryAnalyticsScreenState();
}

class _InventoryAnalyticsScreenState extends State<InventoryAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging &&
          _tabController.index != _selectedTabIndex) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
    context.read<InventoryProductsCubit>().fetchProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openEditProductDialog(InventoryProductEntity product) {
    List<InventoryCategoryEntity> categories = [];
    List<InventorySupplierEntity> suppliers = [];

    try {
      final catState = context.read<InventoryCategoriesCubit>().state;
      if (catState is InventoryCategoriesLoaded) {
        categories = catState.categories;
      }
    } catch (_) {}

    try {
      final supState = context.read<InventorySuppliersCubit>().state;
      if (supState is InventorySuppliersLoaded) {
        suppliers = supState.suppliers;
      }
    } catch (_) {}

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<InventoryProductsCubit>(),
        child: AddEditProductDialog(
          product: product,
          categories: categories,
          suppliers: suppliers,
          onSave: (updated) {
            context.read<InventoryProductsCubit>().saveProduct(updated);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.scafoldBackGround,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          AppStrings.inventoryAnalytics.tr(),
          style: TextStyles.customStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 1000 : double.infinity,
            ),
            child:
                BlocBuilder<InventoryProductsCubit, InventoryProductsState>(
                  builder: (context, state) {
                    if (state is InventoryProductsLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                          strokeWidth: 4,
                        ),
                      );
                    }

                    if (state is InventoryProductsLoaded) {
                      final products = state.products;

                      if (products.isEmpty) {
                        return InventoryEmptyState(
                          icon: Icons.analytics_outlined,
                          title: AppStrings.noProductsFound.tr(),
                          description: AppStrings.emptyProductsDesc.tr(),
                        );
                      }

                      // KPI Calculations
                      double totalExpectedProfit = 0.0;
                      double totalPurchaseValue = 0.0;
                      double totalSellingValue = 0.0;
                      double totalTiedUpCapital = 0.0;

                      final List<InventoryProductEntity> deadStockProducts = [];
                      final List<InventoryProductEntity> sortedProfitable = products
                          .where((p) => (p.sellingPrice - p.purchasePrice) > 0)
                          .toList();

                      for (final p in products) {
                        final unitProfit = p.sellingPrice - p.purchasePrice;
                        if (p.currentQuantity > 0) {
                          totalExpectedProfit += unitProfit * p.currentQuantity;
                          totalPurchaseValue += p.purchasePrice * p.currentQuantity;
                          totalSellingValue += p.sellingPrice * p.currentQuantity;
                        }

                        if (p.totalSoldQuantity <= 0) {
                          deadStockProducts.add(p);
                          totalTiedUpCapital += p.purchasePrice * p.currentQuantity;
                        }
                      }

                      sortedProfitable.sort((a, b) {
                        final profitA = a.sellingPrice - a.purchasePrice;
                        final profitB = b.sellingPrice - b.purchasePrice;
                        return profitB.compareTo(profitA);
                      });

                      final double avgProfitMarginPct = totalPurchaseValue > 0
                          ? ((totalSellingValue - totalPurchaseValue) /
                                  totalPurchaseValue) *
                              100
                          : 0.0;

                      return RefreshIndicator(
                        color: AppColors.primaryColor,
                        onRefresh: () async {
                          await context
                              .read<InventoryProductsCubit>()
                              .fetchProducts();
                        },
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(isDesktop ? 20 : 16.w),
                              child: Column(
                                children: [
                                  // Top Analytics Cards
                                  FadeInDown(
                                    duration: const Duration(milliseconds: 300),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildMetricCard(
                                            title: AppStrings
                                                .expectedInventoryProfit
                                                .tr(),
                                            value:
                                                '${totalExpectedProfit.toSmartAmount()} ${CurrencyService.instance.currentSymbol}',
                                            icon: Icons.trending_up_rounded,
                                            color: AppColors.success,
                                            isDesktop: isDesktop,
                                          ),
                                        ),
                                        SizedBox(width: isDesktop ? 12 : 10.w),
                                        Expanded(
                                          child: _buildMetricCard(
                                            title: AppStrings.avgProfitMargin.tr(),
                                            value:
                                                '${avgProfitMarginPct.toStringAsFixed(1)}%',
                                            icon: Icons.percent_rounded,
                                            color: AppColors.actionButton,
                                            isDesktop: isDesktop,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: isDesktop ? 12 : 10.h),
                                  FadeInDown(
                                    duration: const Duration(milliseconds: 350),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildMetricCard(
                                            title: AppStrings.tiedUpCapital.tr(),
                                            value:
                                                '${totalTiedUpCapital.toSmartAmount()} ${CurrencyService.instance.currentSymbol}',
                                            subtitle:
                                                '${deadStockProducts.length} ${AppStrings.deadStock.tr()}',
                                            icon: Icons.ac_unit_rounded,
                                            color: AppColors.creditAmberStart,
                                            isDesktop: isDesktop,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: isDesktop ? 16 : 14.h),

                                  // Smart Animated Tab Selector
                                  InventoryTabSelector(
                                    tabs: [
                                      AppStrings.topProfitableProducts.tr(),
                                      '${AppStrings.deadStock.tr()} (${deadStockProducts.length})',
                                    ],
                                    selectedIndex: _selectedTabIndex,
                                    onTabChanged: (index) {
                                      setState(() => _selectedTabIndex = index);
                                      _tabController.animateTo(index);
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Tab Views
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  // Tab 1: Top Profitable Products
                                  _buildProfitableProductsList(
                                    sortedProfitable,
                                    isDesktop: isDesktop,
                                  ),

                                  // Tab 2: Dead Stock List
                                  _buildDeadStockList(
                                    deadStockProducts,
                                    isDesktop: isDesktop,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    required bool isDesktop,
  }) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 14 : 12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 14.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            radius: isDesktop ? 18 : 18.r,
            child: Icon(icon, color: color, size: isDesktop ? 20 : 18.r),
          ),
          SizedBox(width: isDesktop ? 10 : 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.customStyle(
                    fontSize: 11,
                    color: AppColors.subTitleColor,
                  ),
                ),
                SizedBox(height: isDesktop ? 2 : 2.h),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.customStyle(
                    fontSize: isDesktop ? 15 : 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: isDesktop ? 2 : 2.h),
                  Text(
                    subtitle,
                    style: TextStyles.customStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.subTitleColor,
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

  Widget _buildProfitableProductsList(
    List<InventoryProductEntity> products, {
    required bool isDesktop,
  }) {
    if (products.isEmpty) {
      return InventoryEmptyState(
        icon: Icons.trending_up_rounded,
        title: AppStrings.noProfitableProducts.tr(),
        description: AppStrings.noProfitableProductsDesc.tr(),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20 : 16.w,
        vertical: 10,
      ),
      itemCount: products.length,
      separatorBuilder: (_, __) => SizedBox(height: isDesktop ? 12 : 10.h),
      itemBuilder: (context, index) {
        final p = products[index];
        final unitProfit = p.sellingPrice - p.purchasePrice;
        final profitMargin = p.purchasePrice > 0
            ? (unitProfit / p.purchasePrice) * 100
            : 0.0;
        final totalPotentialProfit = unitProfit * p.currentQuantity;

        return Container(
          padding: EdgeInsets.all(isDesktop ? 14 : 12.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 14.r),
            border: Border.all(
              color: index == 0
                  ? AppColors.vipGoldStart.withValues(alpha: 0.5)
                  : AppColors.dividerColor,
            ),
            boxShadow: [
              BoxShadow(
                color: (index == 0 ? AppColors.vipGoldStart : Colors.black)
                    .withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: isDesktop ? 34 : 32.w,
                    height: isDesktop ? 34 : 32.w,
                    decoration: BoxDecoration(
                      gradient: index < 3
                          ? const LinearGradient(
                              colors: [
                                AppColors.vipGoldStart,
                                AppColors.vipGoldEnd,
                              ],
                            )
                          : null,
                      color: index >= 3 ? AppColors.surfaceContainerHigh : null,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#${index + 1}',
                        style: TextStyles.customStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: index < 3
                              ? Colors.black87
                              : AppColors.subTitleColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isDesktop ? 12 : 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: TextStyles.customStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blackReal,
                          ),
                        ),
                        SizedBox(height: isDesktop ? 4 : 4.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 8 : 6.w,
                                vertical: isDesktop ? 3 : 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                '${AppStrings.sellingPrice.tr()}: ${p.sellingPrice.toSmartAmount()} ${CurrencyService.instance.currentSymbol}',
                                style: TextStyles.customStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.blackLight,
                                ),
                              ),
                            ),
                            SizedBox(width: isDesktop ? 8 : 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 8 : 6.w,
                                vertical: isDesktop ? 3 : 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                '${p.currentQuantity.toSmartAmount()} ${p.unit}',
                                style: TextStyles.customStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isDesktop ? 8 : 6.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+${unitProfit.toSmartAmount()} ${CurrencyService.instance.currentSymbol}',
                        style: TextStyles.customStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 4 : 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 8 : 6.w,
                          vertical: isDesktop ? 3 : 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '${profitMargin.toStringAsFixed(0)}% ${AppStrings.profitMarginRatio.tr()}',
                          style: TextStyles.customStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (totalPotentialProfit > 0) ...[
                SizedBox(height: isDesktop ? 8 : 6.h),
                Divider(height: 1, color: AppColors.dividerColor),
                SizedBox(height: isDesktop ? 6 : 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppStrings.expectedInventoryProfit.tr()}:',
                      style: TextStyles.customStyle(
                        fontSize: 11,
                        color: AppColors.subTitleColor,
                      ),
                    ),
                    Text(
                      '${totalPotentialProfit.toSmartAmount()} ${CurrencyService.instance.currentSymbol}',
                      style: TextStyles.customStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeadStockList(
    List<InventoryProductEntity> deadProducts, {
    required bool isDesktop,
  }) {
    if (deadProducts.isEmpty) {
      return InventoryEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: AppStrings.allMovements.tr(),
        description: AppStrings.emptyProductsDesc.tr(),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20 : 16.w,
        vertical: 10,
      ),
      itemCount: deadProducts.length,
      separatorBuilder: (_, __) => SizedBox(height: isDesktop ? 12 : 10.h),
      itemBuilder: (context, index) {
        final p = deadProducts[index];
        final tiedCapital = p.purchasePrice * p.currentQuantity;

        return Container(
          padding: EdgeInsets.all(isDesktop ? 14 : 12.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 14.r),
            border: Border.all(
              color: AppColors.creditAmberStart.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.creditAmberStart.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.creditAmberStart.withValues(
                  alpha: 0.12,
                ),
                radius: isDesktop ? 18 : 18.r,
                child: Icon(
                  Icons.ac_unit_rounded,
                  color: AppColors.creditAmberStart,
                  size: isDesktop ? 18 : 18.r,
                ),
              ),
              SizedBox(width: isDesktop ? 12 : 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: TextStyles.customStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackReal,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 4 : 4.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 8 : 6.w,
                            vertical: isDesktop ? 3 : 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.creditAmberStart.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            '${AppStrings.tiedUpCapital.tr()}: ${tiedCapital.toSmartAmount()} ${CurrencyService.instance.currentSymbol}',
                            style: TextStyles.customStyle(
                              fontSize: 11,
                              color: AppColors.creditAmberStart,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: isDesktop ? 8 : 6.w),
                        Text(
                          '${p.currentQuantity.toSmartAmount()} ${p.unit}',
                          style: TextStyles.customStyle(
                            fontSize: 11,
                            color: AppColors.subTitleColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: isDesktop ? 8 : 6.w),
              ElevatedButton.icon(
                onPressed: () => _openEditProductDialog(p),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bestSellerStart.withValues(
                    alpha: 0.12,
                  ),
                  foregroundColor: AppColors.bestSellerStart,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 10 : 8.w,
                    vertical: isDesktop ? 6 : 4.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    side: BorderSide(
                      color: AppColors.bestSellerStart.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: Text(
                  AppStrings.edit.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
