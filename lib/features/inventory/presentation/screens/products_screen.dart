import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';

import '../../domain/entities/inventory_category_entity.dart';
import '../../domain/entities/inventory_product_entity.dart';
import '../../domain/entities/inventory_supplier_entity.dart';
import '../../domain/utils/best_seller_helper.dart';
import '../cubits/inventory_categories_cubit.dart';
import '../cubits/inventory_products_cubit.dart';
import '../cubits/inventory_stock_movements_cubit.dart';
import '../cubits/inventory_suppliers_cubit.dart';
import '../widgets/add_edit_product_dialog.dart';
import '../widgets/inventory_empty_state.dart';
import '../widgets/manual_stock_adjustment_dialog.dart';
import '../widgets/product_card_item.dart';
import '../widgets/product_details_dialog.dart';

class ProductsScreen extends StatefulWidget {
  final bool showLowStockOnly;
  const ProductsScreen({super.key, this.showLowStockOnly = false});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<InventoryCategoryEntity> _categories = [];
  List<InventorySupplierEntity> _suppliers = [];
  String? _selectedCategory;
  String? _selectedSupplier;
  bool _showLowStockOnly = false;
  bool _showBestSellersOnly = false;

  @override
  void initState() {
    super.initState();
    _showLowStockOnly = widget.showLowStockOnly;
    _scrollController.addListener(_onScroll);
    context.read<InventoryProductsCubit>().fetchProducts();
    context.read<InventoryCategoriesCubit>().fetchCategories();
    context.read<InventorySuppliersCubit>().fetchSuppliers();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<InventoryProductsCubit>().fetchMoreProducts(
        query: _searchController.text,
        categoryId: _selectedCategory,
        supplierId: _selectedSupplier,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAddEditProductDialog([InventoryProductEntity? product]) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditProductDialog(
        product: product,
        categories: _categories,
        suppliers: _suppliers,
        onSave: (savedProduct) {
          context.read<InventoryProductsCubit>().saveProduct(savedProduct).then(
            (success) {
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.productSavedSuccess.tr()),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  void _openManualAdjustmentDialog(InventoryProductEntity product) {
    showDialog(
      context: context,
      builder: (ctx) => ManualStockAdjustmentDialog(
        product: product,
        onAdjust: (delta, reason) {
          context
              .read<InventoryStockMovementsCubit>()
              .createManualAdjustment(
                productId: product.id,
                adjustmentQuantity: delta,
                reason: reason,
              )
              .then((success) {
                if (success && mounted) {
                  context.read<InventoryProductsCubit>().fetchProducts(
                    query: _searchController.text,
                    categoryId: _selectedCategory,
                    supplierId: _selectedSupplier,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.stockAdjustedSuccess.tr()),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              });
        },
      ),
    );
  }

  void _openProductDetailsDialog(InventoryProductEntity product) {
    showDialog(
      context: context,
      builder: (ctx) => ProductDetailsDialog(
        product: product,
        onEdit: () => _openAddEditProductDialog(product),
        onAdjustStock: () => _openManualAdjustmentDialog(product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<InventoryCategoriesCubit, InventoryCategoriesState>(
          listener: (context, state) {
            if (state is InventoryCategoriesLoaded) {
              setState(() => _categories = state.categories);
            }
          },
        ),
        BlocListener<InventorySuppliersCubit, InventorySuppliersState>(
          listener: (context, state) {
            if (state is InventorySuppliersLoaded) {
              setState(() => _suppliers = state.suppliers);
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.scafoldBackGround,
        appBar: AppBar(
          backgroundColor: AppColors.scafoldBackGround,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primaryColor,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: Text(
            AppStrings.inventoryProducts.tr(),
            style: TextStyles.customStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.table_chart_rounded,
                color: AppColors.success,
                size: isDesktop ? 26 : 26.w,
              ),
              tooltip: AppStrings.exportToExcel.tr(),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.exportingExcel.tr()),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppColors.primaryColor,
                  ),
                );
                final savedPath = await context
                    .read<InventoryProductsCubit>()
                    .exportAllProductsToExcel();
                if (mounted) {
                  if (savedPath != null && savedPath.isNotEmpty) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          '${AppStrings.exportSuccess.tr()}\n$savedPath',
                        ),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  } else {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(AppStrings.exportFailed.tr()),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),
            SizedBox(width: 8.w),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primaryColor,
          onPressed: () => _openAddEditProductDialog(),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            AppStrings.addProduct.tr(),
            style: TextStyles.customStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 1000 : double.infinity,
              ),
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? 24 : 16.w),
                child: Column(
                  children: [
                    // Low Stock Active Filter Banner
                    if (_showLowStockOnly)
                      Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.warning,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    AppStrings.lowStockWarning.tr(),
                                    style: TextStyles.customStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () {
                                  setState(() => _showLowStockOnly = false);
                                },
                                child: Container(
                                  padding: EdgeInsets.all(4.r),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(
                                      alpha: 0.2,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: AppColors.warning,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Search Bar
                    QuickAddTextField(
                      controller: _searchController,
                      hint: AppStrings.searchInventory.tr(),
                      icon: Icons.search,
                      onChanged: (val) {
                        context.read<InventoryProductsCubit>().fetchProducts(
                          query: val,
                          categoryId: _selectedCategory,
                          supplierId: _selectedSupplier,
                        );
                      },
                    ),
                    SizedBox(height: isDesktop ? 12 : 12.h),

                    // Quick Filter Chips Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          ChoiceChip(
                            showCheckmark: false,
                            selected: _showBestSellersOnly,
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_fire_department_rounded,
                                  color: AppColors.blackLight,
                                  size: 14,
                                ),
                                SizedBox(width: isDesktop ? 4 : 4.w),
                                Text(
                                  AppStrings.bestSellersOnly.tr(),
                                  style: TextStyles.customStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _showBestSellersOnly
                                        ? Colors.white
                                        : AppColors.bestSellerStart,
                                  ),
                                ),
                              ],
                            ),
                            selectedColor: AppColors.bestSellerStart,
                            backgroundColor: AppColors.bestSellerStart
                                .withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                isDesktop ? 20 : 20.r,
                              ),
                              side: BorderSide(
                                color: _showBestSellersOnly
                                    ? AppColors.bestSellerStart
                                    : AppColors.bestSellerStart.withValues(
                                        alpha: 0.3,
                                      ),
                              ),
                            ),
                            onSelected: (selected) {
                              setState(() => _showBestSellersOnly = selected);
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isDesktop ? 12 : 12.h),

                    // Products List View
                    Expanded(
                      child:
                          BlocBuilder<
                            InventoryProductsCubit,
                            InventoryProductsState
                          >(
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
                                var products = state.products;
                                final top20Ids =
                                    BestSellerHelper.getTop20BestSellerIds(
                                      state.products,
                                    );

                                if (_showLowStockOnly) {
                                  products = products
                                      .where(
                                        (p) =>
                                            p.currentQuantity <= p.minQuantity,
                                      )
                                      .toList();
                                }

                                if (_showBestSellersOnly) {
                                  products = products
                                      .where((p) => top20Ids.contains(p.id))
                                      .toList();
                                }

                                if (products.isEmpty) {
                                  return InventoryEmptyState(
                                    icon: Icons.inventory_2_outlined,
                                    title: AppStrings.noProductsFound.tr(),
                                    description: AppStrings.emptyProductsDesc
                                        .tr(),
                                    actionLabel: AppStrings.addProduct.tr(),
                                    onAction: () => _openAddEditProductDialog(),
                                  );
                                }

                                return RefreshIndicator(
                                  color: AppColors.primaryColor,
                                  onRefresh: () async {
                                    await context
                                        .read<InventoryProductsCubit>()
                                        .fetchProducts(
                                          query: _searchController.text,
                                          categoryId: _selectedCategory,
                                          supplierId: _selectedSupplier,
                                        );
                                  },
                                  child: ListView.separated(
                                    controller: _scrollController,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(
                                          parent: BouncingScrollPhysics(),
                                        ),
                                    itemCount:
                                        products.length +
                                        (state.isPaginationLoading ? 1 : 0),
                                    separatorBuilder: (_, __) =>
                                        SizedBox(height: isDesktop ? 12 : 12.h),
                                    itemBuilder: (context, index) {
                                      if (index == products.length) {
                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: isDesktop ? 16 : 16.h,
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 4,
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                        );
                                      }
                                      final p = products[index];
                                      return ProductCardItem(
                                        product: p,
                                        index: index,
                                        isBestSeller: top20Ids.contains(p.id),
                                        onTap: () =>
                                            _openProductDetailsDialog(p),
                                        onManualAdjustment: () =>
                                            _openManualAdjustmentDialog(p),
                                        onEdit: () =>
                                            _openAddEditProductDialog(p),
                                      );
                                    },
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
