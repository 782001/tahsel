import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/inventory/data/datasources/inventory_local_data_source.dart';
import 'package:tahsel/features/inventory/domain/entities/inventory_product_entity.dart';
import 'package:tahsel/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:tahsel/features/inventory/domain/utils/best_seller_helper.dart';
import 'package:tahsel/features/inventory/presentation/widgets/barcode_scanner_dialog.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';

class QuickInventoryPickerBottomSheet extends StatefulWidget {
  final Function(
    InventoryProductEntity product,
    double quantity,
    double totalPrice,
  )
  onProductSelected;

  const QuickInventoryPickerBottomSheet({
    super.key,
    required this.onProductSelected,
  });

  @override
  State<QuickInventoryPickerBottomSheet> createState() =>
      _QuickInventoryPickerBottomSheetState();
}

class _QuickInventoryPickerBottomSheetState
    extends State<QuickInventoryPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<InventoryProductEntity> _allProducts = [];
  List<InventoryProductEntity> _filteredProducts = [];
  List<String> _categories = [];
  String? _selectedCategory;
  InventoryProductEntity? _selectedProduct;
  double _quantity = 1.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final localDataSource = GetIt.I<InventoryLocalDataSource>();
      var models = await localDataSource.getProducts();

      if (models.isEmpty) {
        final repository = GetIt.I<InventoryRepository>();
        await repository.fetchAllProductsFromRemoteWithoutLimit();
        models = await localDataSource.getProducts();
      }

      final products = models
          .map((m) => m as InventoryProductEntity)
          .where((p) => p.isAvailable && p.currentQuantity > 0)
          .toList();
      products.sort((a, b) => a.name.compareTo(b.name));

      final uniqueCategories = products
          .map((p) => p.categoryName)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();
      uniqueCategories.sort();

      if (mounted) {
        setState(() {
          _allProducts = products;
          _filteredProducts = products;
          _categories = uniqueCategories;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final isAvailable = p.isAvailable;
        final hasStock = p.currentQuantity > 0;
        final matchesQuery =
            q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            (p.barcode?.toLowerCase().contains(q) ?? false);

        final matchesCategory =
            _selectedCategory == null || p.categoryName == _selectedCategory;

        return isAvailable && hasStock && matchesQuery && matchesCategory;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildStockBadge(InventoryProductEntity p, bool isDesktop) {
    if (p.currentQuantity <= 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Text(
          AppStrings.outOfStockKey.tr(),
          style: TextStyles.customStyle(
            fontSize: isDesktop ? 11 : 11,
            color: AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (p.currentQuantity <= p.minQuantity) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Text(
          '${AppStrings.availableInStock.tr()}: ${p.currentQuantity.toSmartAmount()} ${p.unit} (${AppStrings.lowStockAlertKey.tr()})',
          style: TextStyles.customStyle(
            fontSize: isDesktop ? 11 : 11,
            color: AppColors.warning,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          '${AppStrings.availableInStock.tr()}: ${p.currentQuantity.toSmartAmount()} ${p.unit}',
          style: TextStyles.customStyle(
            fontSize: isDesktop ? 11 : 11,
            color: AppColors.success,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.88;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      padding: EdgeInsets.only(
        top: isDesktop ? 16 : 16.h,
        left: isDesktop ? 16 : 16.w,
        right: isDesktop ? 16 : 16.w,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + (isDesktop ? 16 : 16.h),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isDesktop ? 24 : 24.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: isDesktop ? 40 : 40.w,
              height: isDesktop ? 4 : 4.h,
              decoration: BoxDecoration(
                color: AppColors.blackLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: isDesktop ? 12 : 12.h),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      color: AppColors.primaryColor,
                      size: isDesktop ? 22 : 22.r,
                    ),
                  ),
                  SizedBox(width: isDesktop ? 10 : 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.selectFromInventory.tr(),
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      Text(
                        AppStrings.selectProductAndQty.tr(),
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 12 : 11,
                          color: AppColors.subTitleColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 12 : 12.h),

          // Search Field
          QuickAddTextField(
            controller: _searchController,
            hint: AppStrings.searchInventory.tr(),
            icon: Icons.search,
            suffixIcon: (!kIsWeb && Platform.isWindows)
                ? null
                : Icons.qr_code_scanner_rounded,
            onSuffixIconPressed: (!kIsWeb && Platform.isWindows)
                ? null
                : () async {
                    final scannedCode = await BarcodeScannerDialog.scan(
                      context,
                    );
                    if (scannedCode != null && scannedCode.isNotEmpty) {
                      _searchController.text = scannedCode;
                      _applyFilter();
                      final target = scannedCode.trim().toLowerCase();
                      for (final p in _allProducts) {
                        if ((p.barcode?.trim().toLowerCase() == target) ||
                            (p.sku.trim().toLowerCase() == target)) {
                          setState(() {
                            _selectedProduct = p;
                            _quantity = 1.0;
                          });
                          break;
                        }
                      }
                    }
                  },
            autofocus: true,
            onChanged: (_) => _applyFilter(),
            onSubmitted: (scannedCode) {
              if (scannedCode.isNotEmpty) {
                _applyFilter();
                final target = scannedCode.trim().toLowerCase();
                for (final p in _allProducts) {
                  if ((p.barcode?.trim().toLowerCase() == target) ||
                      (p.sku.trim().toLowerCase() == target)) {
                    setState(() {
                      _selectedProduct = p;
                      _quantity = 1.0;
                    });
                    break;
                  }
                }
              }
            },
          ),
          SizedBox(height: isDesktop ? 10 : 10.h),

          // Category Chips Row (Smart Filtering)
          if (_categories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 6.w),
                    child: ChoiceChip(
                      showCheckmark: false,
                      selectedColor: AppColors.primaryColor,
                      backgroundColor: AppColors.primaryColor.withValues(
                        alpha: 0.08,
                      ),
                      label: Text(
                        AppStrings.all.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 12,
                          color: _selectedCategory == null
                              ? Colors.white
                              : AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      selected: _selectedCategory == null,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = null);
                          _applyFilter();
                        }
                      },
                    ),
                  ),
                  ..._categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: EdgeInsets.only(left: 6.w),
                      child: ChoiceChip(
                        showCheckmark: false,
                        selectedColor: AppColors.primaryColor,
                        backgroundColor: AppColors.primaryColor.withValues(
                          alpha: 0.08,
                        ),
                        label: Text(
                          cat,
                          style: TextStyles.customStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? cat : null;
                          });
                          _applyFilter();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          SizedBox(height: isDesktop ? 10 : 10.h),

          // Products List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  )
                : _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48.r,
                          color: AppColors.subTitleColor.withValues(alpha: 0.5),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          AppStrings.noProductsFound.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 14,
                            color: AppColors.subTitleColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredProducts.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: isDesktop ? 10 : 10.h),
                    itemBuilder: (context, index) {
                      final top20Ids = BestSellerHelper.getTop20BestSellerIds(
                        _allProducts,
                      );
                      final product = _filteredProducts[index];
                      final isBestSeller =
                          product.totalSoldQuantity > 0 &&
                          top20Ids.contains(product.id);
                      final isSelected = _selectedProduct?.id == product.id;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedProduct = null;
                            } else {
                              _selectedProduct = product;
                              _quantity = 1.0;
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(16.r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.all(isDesktop ? 12 : 12.r),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryColor.withValues(alpha: 0.08)
                                : AppColors.surfaceContainerHigh.withValues(
                                    alpha: 0.3,
                                  ),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : Colors.transparent,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8.r),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primaryColor
                                                : AppColors.primaryColor
                                                      .withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isSelected
                                                ? Icons.check_rounded
                                                : Icons.inventory_2_rounded,
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.primaryColor,
                                            size: 16.r,
                                          ),
                                        ),
                                        SizedBox(width: isDesktop ? 10 : 10.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      product.name,
                                                      style:
                                                          TextStyles.customStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: AppColors
                                                                .blackReal,
                                                          ),
                                                    ),
                                                  ),
                                                  if (isBestSeller) ...[
                                                    SizedBox(
                                                      width: isDesktop
                                                          ? 4
                                                          : 4.w,
                                                    ),
                                                    Transform.rotate(
                                                      angle: -0.10,
                                                      child: Container(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal:
                                                                  isDesktop
                                                                  ? 6
                                                                  : 6.w,
                                                              vertical:
                                                                  isDesktop
                                                                  ? 2
                                                                  : 2.h,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          gradient: const LinearGradient(
                                                            colors: [
                                                              AppColors
                                                                  .bestSellerStart,
                                                              AppColors
                                                                  .bestSellerEnd,
                                                            ],
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                isDesktop
                                                                    ? 6
                                                                    : 6.r,
                                                              ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: AppColors
                                                                  .bestSellerStart
                                                                  .withValues(
                                                                    alpha: 0.35,
                                                                  ),
                                                              blurRadius: 6,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    2,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .local_fire_department_rounded,
                                                              color:
                                                                  Colors.white,
                                                              size: 11,
                                                            ),
                                                            SizedBox(
                                                              width: isDesktop
                                                                  ? 2
                                                                  : 2.w,
                                                            ),
                                                            Text(
                                                              AppStrings
                                                                  .bestSeller
                                                                  .tr(),
                                                              style: TextStyles.customStyle(
                                                                fontSize: 9,
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              if (product
                                                  .categoryName
                                                  .isNotEmpty)
                                                Text(
                                                  product.categoryName,
                                                  style: TextStyles.customStyle(
                                                    fontSize: 11,
                                                    color:
                                                        AppColors.subTitleColor,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: isDesktop ? 8 : 8.w),
                                  Text(
                                    '${product.sellingPrice.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                                    style: TextStyles.customStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isDesktop ? 8 : 8.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStockBadge(product, isDesktop),
                                  if (product.unit.isNotEmpty)
                                    Text(
                                      '${AppStrings.unitKey.tr()}: ${product.unit}',
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
                      );
                    },
                  ),
          ),
          SizedBox(height: isDesktop ? 12 : 12.h),

          // Sticky Smart Selection Bar
          if (_selectedProduct != null) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.all(isDesktop ? 14 : 14.r),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Quantity Counter & Quick Increment Buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.quantity.tr(),
                                  style: TextStyles.customStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blackReal,
                                  ),
                                ),
                                if (_selectedProduct != null &&
                                    _quantity >=
                                        _selectedProduct!.currentQuantity)
                                  Text(
                                    AppStrings.maxQuantityReached.tr(),
                                    style: TextStyles.customStyle(
                                      fontSize: isDesktop ? 11 : 11,
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                color: _quantity > 1
                                    ? AppColors.primaryColor
                                    : AppColors.blackLight.withValues(
                                        alpha: 0.3,
                                      ),
                                onPressed: _quantity > 1
                                    ? () => setState(() => _quantity--)
                                    : null,
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 16 : 14.w,
                                  vertical: isDesktop ? 6 : 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: AppColors.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _quantity.toInt().toString(),
                                  style: TextStyles.customStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                color:
                                    _selectedProduct != null &&
                                        _quantity <
                                            _selectedProduct!.currentQuantity
                                    ? AppColors.primaryColor
                                    : AppColors.blackLight.withValues(
                                        alpha: 0.3,
                                      ),
                                onPressed:
                                    _selectedProduct != null &&
                                        _quantity <
                                            _selectedProduct!.currentQuantity
                                    ? () => setState(() => _quantity++)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      // Quick increment shortcuts (+1, +5, +10)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Wrap(
                            spacing: 6.w,
                            children: [1, 5, 10].map((inc) {
                              final maxAvailable =
                                  _selectedProduct?.currentQuantity ?? 1.0;
                              final canAdd =
                                  _selectedProduct != null &&
                                  _quantity < maxAvailable;
                              return InkWell(
                                onTap: canAdd
                                    ? () {
                                        setState(() {
                                          _quantity = (_quantity + inc).clamp(
                                            1.0,
                                            maxAvailable,
                                          );
                                        });
                                      }
                                    : null,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isDesktop ? 10 : 8.w,
                                    vertical: isDesktop ? 4 : 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: canAdd
                                        ? AppColors.primaryColor.withValues(
                                            alpha: 0.08,
                                          )
                                        : AppColors.blackLight.withValues(
                                            alpha: 0.05,
                                          ),
                                    borderRadius: BorderRadius.circular(
                                      isDesktop ? 6 : 6.r,
                                    ),
                                  ),
                                  child: Text(
                                    '+$inc',
                                    style: TextStyles.customStyle(
                                      fontSize: isDesktop ? 11 : 11,
                                      fontWeight: FontWeight.bold,
                                      color: canAdd
                                          ? AppColors.primaryColor
                                          : AppColors.subTitleColor,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: isDesktop ? 10 : 10.h),

                  // Total calculation banner & Confirm Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.totalAmount.tr(),
                            style: TextStyles.customStyle(
                              fontSize: 12,
                              color: AppColors.subTitleColor,
                            ),
                          ),
                          Text(
                            '${(_quantity * _selectedProduct!.sellingPrice).toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                            style: TextStyles.customStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 46.h,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            elevation: 2,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 10.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          onPressed: () {
                            final total =
                                _quantity * _selectedProduct!.sellingPrice;
                            widget.onProductSelected(
                              _selectedProduct!,
                              _quantity,
                              total,
                            );
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                          ),
                          label: Text(
                            AppStrings.confirmSelection.tr(),
                            style: TextStyles.customStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
