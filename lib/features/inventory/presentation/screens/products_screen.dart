import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';

import '../../domain/entities/inventory_category_entity.dart';
import '../../domain/entities/inventory_product_entity.dart';
import '../../domain/entities/inventory_supplier_entity.dart';
import '../cubits/inventory_categories_cubit.dart';
import '../cubits/inventory_products_cubit.dart';
import '../cubits/inventory_stock_movements_cubit.dart';
import '../cubits/inventory_suppliers_cubit.dart';
import '../widgets/add_edit_product_dialog.dart';
import '../widgets/inventory_empty_state.dart';
import '../widgets/manual_stock_adjustment_dialog.dart';
import '../widgets/product_details_dialog.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<InventoryCategoryEntity> _categories = [];
  List<InventorySupplierEntity> _suppliers = [];
  String? _selectedCategory;
  String? _selectedSupplier;

  @override
  void initState() {
    super.initState();
    context.read<InventoryProductsCubit>().fetchProducts();
    context.read<InventoryCategoriesCubit>().fetchCategories();
    context.read<InventorySuppliersCubit>().fetchSuppliers();
  }

  @override
  void dispose() {
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
                    SizedBox(height: isDesktop ? 16 : 16.h),

                    // Products List View
                    Expanded(
                      child: BlocBuilder<InventoryProductsCubit, InventoryProductsState>(
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
                                icon: Icons.inventory_2_outlined,
                                title: AppStrings.noProductsFound.tr(),
                                description: AppStrings.emptyProductsDesc.tr(),
                                actionLabel: AppStrings.addProduct.tr(),
                                onAction: () => _openAddEditProductDialog(),
                              );
                            }

                            return ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: products.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: isDesktop ? 12 : 12.h),
                              itemBuilder: (context, index) {
                                final p = products[index];
                                final isOut = p.currentQuantity <= 0;
                                final isLow = p.isLowStock && !isOut;

                                final statusColor = isOut
                                    ? AppColors.error
                                    : isLow
                                        ? AppColors.lowStockOrange
                                        : AppColors.success;

                                final statusLabel = isOut
                                    ? AppStrings.outOfStock.tr()
                                    : isLow
                                        ? AppStrings.lowStockAlert.tr()
                                        : AppStrings.stableStock.tr();

                                return InkWell(
                                  onTap: () => _openProductDetailsDialog(p),
                                  borderRadius: BorderRadius.circular(
                                    isDesktop ? 14 : 14.r,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(
                                      isDesktop ? 14 : 14.w,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(
                                        isDesktop ? 14 : 14.r,
                                      ),
                                      border: Border.all(
                                        color: isOut || isLow
                                            ? statusColor.withValues(alpha: 0.5)
                                            : AppColors.dividerColor,
                                        width: isOut || isLow ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: statusColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          radius: isDesktop ? 24 : 24.r,
                                          child: Icon(
                                            Icons.inventory_2_rounded,
                                            color: statusColor,
                                          ),
                                        ),
                                        SizedBox(width: isDesktop ? 14 : 14.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      p.name,
                                                      style:
                                                          TextStyles.customStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: AppColors
                                                                .blackReal,
                                                          ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: isDesktop
                                                              ? 8
                                                              : 8.w,
                                                          vertical: isDesktop
                                                              ? 2
                                                              : 2.h,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: statusColor.withValues(
                                                        alpha: 0.12,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            isDesktop ? 6 : 6.r,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      statusLabel,
                                                      style: TextStyles.customStyle(
                                                        fontSize: 11,
                                                        color: statusColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: isDesktop ? 4 : 4.h,
                                              ),
                                              Text(
                                                'SKU: ${p.sku}  |  ${AppStrings.category.tr()}: ${p.categoryName.isNotEmpty ? p.categoryName : "-"}',
                                                style: TextStyles.customStyle(
                                                  fontSize: 12,
                                                  color: AppColors.sandText,
                                                ),
                                              ),
                                              SizedBox(
                                                height: isDesktop ? 4 : 4.h,
                                              ),
                                              Text(
                                                '${AppStrings.quantity.tr()}: ${p.currentQuantity.toSmartAmount()} ${p.unit}  |  ${AppStrings.sellingPrice.tr()}: ${p.sellingPrice.toSmartAmount()} ${AppStrings.egp.tr()}',
                                                style: TextStyles.customStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.tune_rounded,
                                            color: AppColors.lowStockOrange,
                                          ),
                                          onPressed: () =>
                                              _openManualAdjustmentDialog(p),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit_rounded,
                                            color: AppColors.primaryColor,
                                          ),
                                          onPressed: () =>
                                              _openAddEditProductDialog(p),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
