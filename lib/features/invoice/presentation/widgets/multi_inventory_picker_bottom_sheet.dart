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
import 'package:tahsel/features/inventory/domain/utils/best_seller_helper.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';

class SelectedInventoryItem {
  final InventoryProductEntity product;
  final double quantity;

  SelectedInventoryItem({required this.product, required this.quantity});

  double get totalPrice => quantity * product.sellingPrice;
}

class MultiInventoryPickerBottomSheet extends StatefulWidget {
  final Function(List<SelectedInventoryItem> selectedItems) onItemsConfirmed;

  const MultiInventoryPickerBottomSheet({
    super.key,
    required this.onItemsConfirmed,
  });

  @override
  State<MultiInventoryPickerBottomSheet> createState() =>
      _MultiInventoryPickerBottomSheetState();
}

class _MultiInventoryPickerBottomSheetState
    extends State<MultiInventoryPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<InventoryProductEntity> _allProducts = [];
  List<InventoryProductEntity> _filteredProducts = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;

  /// Map of productId -> selected quantity
  final Map<String, double> _selectedQuantities = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final localDataSource = GetIt.I<InventoryLocalDataSource>();
      final models = await localDataSource.getProducts();
      final products = models
          .map((m) => m as InventoryProductEntity)
          .where((p) => p.currentQuantity > 0)
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
        final hasStock = p.currentQuantity > 0;
        final matchesQuery =
            q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            (p.barcode?.toLowerCase().contains(q) ?? false);

        final matchesCategory =
            _selectedCategory == null || p.categoryName == _selectedCategory;

        return hasStock && matchesQuery && matchesCategory;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateQuantity(InventoryProductEntity product, double delta) {
    setState(() {
      final current = _selectedQuantities[product.id] ?? 0.0;
      final newQty = (current + delta).clamp(0.0, product.currentQuantity);
      if (newQty <= 0) {
        _selectedQuantities.remove(product.id);
      } else {
        _selectedQuantities[product.id] = newQty;
      }
    });
  }

  void _toggleProductSelection(InventoryProductEntity product) {
    setState(() {
      if (_selectedQuantities.containsKey(product.id)) {
        _selectedQuantities.remove(product.id);
      } else {
        _selectedQuantities[product.id] = 1.0;
      }
    });
  }

  List<SelectedInventoryItem> _getSelectedItemsList() {
    final List<SelectedInventoryItem> result = [];
    for (final p in _allProducts) {
      final qty = _selectedQuantities[p.id];
      if (qty != null && qty > 0) {
        result.add(SelectedInventoryItem(product: p, quantity: qty));
      }
    }
    return result;
  }

  double get _totalAmount {
    double sum = 0;
    for (final item in _getSelectedItemsList()) {
      sum += item.totalPrice;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final selectedItems = _getSelectedItemsList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.scafoldBackGround,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          SizedBox(height: isDesktop ? 12 : 12.h),
          Center(
            child: Container(
              width: isDesktop ? 48 : 48.w,
              height: isDesktop ? 5 : 5.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(height: isDesktop ? 12 : 12.h),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 20.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isDesktop ? 8 : 8.r),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.storefront_outlined,
                    color: AppColors.primaryColor,
                    size: isDesktop ? 22 : 22 ,
                  ),
                ),
                SizedBox(width: isDesktop ? 12 : 12.w),
                Expanded(
                  child: Text(
                    AppStrings.selectFromInventory.tr(),
                    style: TextStyles.customStyle(
                      fontSize: isDesktop ? 18 : 18 ,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          SizedBox(height: isDesktop ? 12 : 12.h),

          // Search input
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 20.w),
            child: QuickAddTextField(
              controller: _searchController,
              hint: AppStrings.searchInventory.tr(),
              icon: Icons.search_rounded,
              onChanged: (_) => _applyFilter(),
            ),
          ),
          SizedBox(height: isDesktop ? 10 : 10.h),

          // Category Chips Filter
          if (_categories.isNotEmpty)
            SizedBox(
              height: isDesktop ? 38 : 38.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 20 : 20.w,
                ),
                itemCount: _categories.length + 1,
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final category = isAll ? null : _categories[index - 1];
                  final isSelected = _selectedCategory == category;

                  return Padding(
                    padding: EdgeInsets.only(left: isDesktop ? 8 : 8.w),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(
                        isAll ? AppStrings.all.tr() : category!,
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 13 : 13 ,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : AppColors.blackLight,
                        ),
                      ),
                      selectedColor: AppColors.primaryColor,
                      backgroundColor: AppColors.surface,
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryColor
                              : AppColors.dividerColor,
                        ),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = category;
                          _applyFilter();
                        });
                      },
                    ),
                  );
                },
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
                    child: Text(
                      AppStrings.noProductsFound.tr(),
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 14 : 14 ,
                        color: AppColors.disabledColor,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 20 : 20.w,
                      vertical: 6,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final top20Ids = BestSellerHelper.getTop20BestSellerIds(
                        _allProducts,
                      );
                      final product = _filteredProducts[index];
                      final isBestSeller =
                          product.totalSoldQuantity > 0 &&
                          top20Ids.contains(product.id);
                      final selectedQty =
                          _selectedQuantities[product.id] ?? 0.0;
                      final isSelected = selectedQty > 0;
                      final maxQty = product.currentQuantity;

                      return Container(
                        margin: EdgeInsets.only(bottom: isDesktop ? 10 : 10.h),
                        padding: EdgeInsets.all(isDesktop ? 12 : 12.r),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryColor.withValues(alpha: 0.05)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryColor
                                : AppColors.dividerColor,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  activeColor: AppColors.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  onChanged: (_) =>
                                      _toggleProductSelection(product),
                                ),
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
                                              style: TextStyles.customStyle(
                                                fontSize: isDesktop
                                                    ? 15
                                                    : 15 ,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.black,
                                              ),
                                            ),
                                          ),
                                          if (isBestSeller) ...[
                                            SizedBox(
                                              width: isDesktop ? 6 : 6.w,
                                            ),
                                            Transform.rotate(
                                              angle: -0.10,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: isDesktop
                                                      ? 7
                                                      : 7.w,
                                                  vertical: isDesktop ? 3 : 3.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                        colors: [
                                                          AppColors.bestSellerStart,
                                                          AppColors.bestSellerEnd,
                                                        ],
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        isDesktop ? 6 : 6.r,
                                                      ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppColors.bestSellerStart
                                                          .withValues(alpha: 0.35),
                                                      blurRadius: 6,
                                                      offset: const Offset(
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
                                                    Icon(
                                                      Icons
                                                          .local_fire_department_rounded,
                                                      color: Colors.white,
                                                      size: isDesktop
                                                          ? 11
                                                          : 11 ,
                                                    ),
                                                    SizedBox(
                                                      width: isDesktop
                                                          ? 2
                                                          : 2.w,
                                                    ),
                                                    Text(
                                                      AppStrings.bestSeller
                                                          .tr(),
                                                      style:
                                                          TextStyles.customStyle(
                                                            fontSize: 9,
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w900,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      SizedBox(height: isDesktop ? 4 : 4.h),
                                      Row(
                                        children: [
                                          Text(
                                            '${product.sellingPrice.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                                            style: TextStyles.customStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isDesktop ? 8 : 8.w,
                                              vertical: isDesktop ? 2 : 2.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.success
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                            ),
                                            child: Text(
                                              '${AppStrings.availableInStock.tr()}: ${maxQty.toSmartAmount()}',
                                              style: TextStyles.customStyle(
                                                fontSize:  11
                                                    ,
                                                color: AppColors.success,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Quantity Controls if selected
                            if (isSelected) ...[
                              SizedBox(height: isDesktop ? 10 : 10.h),
                              const Divider(height: 1),
                              SizedBox(height: isDesktop ? 8 : 8.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppStrings.requestedQuantity.tr(),
                                    style: TextStyles.customStyle(
                                      fontSize: isDesktop ? 13 : 13 ,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.blackLight,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () =>
                                            _updateQuantity(product, -1),
                                        icon: Icon(
                                          Icons.remove_circle_outline,
                                          color: AppColors.error,
                                          size: isDesktop ? 22 : 22 ,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14.w,
                                          vertical: 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                          border: Border.all(
                                            color: AppColors.dividerColor,
                                          ),
                                        ),
                                        child: Text(
                                          selectedQty.toSmartAmount(),
                                          style: TextStyles.customStyle(
                                            fontSize: isDesktop ? 15 : 15 ,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.black,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: selectedQty >= maxQty
                                            ? null
                                            : () => _updateQuantity(product, 1),
                                        icon: Icon(
                                          Icons.add_circle_outline,
                                          color: selectedQty >= maxQty
                                              ? AppColors.disabledColor
                                              : AppColors.primaryColor,
                                          size: isDesktop ? 22 : 22 ,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action Footer
          if (selectedItems.isNotEmpty)
            Container(
              padding: EdgeInsets.all(isDesktop ? 16 : 16.r),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: const [AppColors.shadow],
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.selectedItemsCount.tr(
                          namedArgs: {'count': selectedItems.length.toString()},
                        ),
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 14 : 14 ,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blackLight,
                        ),
                      ),
                      Text(
                        '${AppStrings.totalLabel.tr()} ${_totalAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 16 : 16 ,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isDesktop ? 12 : 12.h),
                  SizedBox(
                    width: double.infinity,
                    height: isDesktop ? 48 : 48.h,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        widget.onItemsConfirmed(selectedItems);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                      ),
                      label: Text(
                        AppStrings.addSelectedItemsToInvoice.tr(),
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 15 : 15 ,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
