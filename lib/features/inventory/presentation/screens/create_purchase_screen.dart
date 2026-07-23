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

import '../../domain/entities/inventory_product_entity.dart';
import '../../domain/entities/inventory_purchase_entity.dart';
import '../../domain/entities/inventory_supplier_entity.dart';
import '../cubits/inventory_products_cubit.dart';
import '../cubits/inventory_purchases_cubit.dart';
import '../cubits/inventory_suppliers_cubit.dart';
import '../widgets/searchable_dropdown_field.dart';

class CreatePurchaseScreen extends StatefulWidget {
  const CreatePurchaseScreen({super.key});

  @override
  State<CreatePurchaseScreen> createState() => _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends State<CreatePurchaseScreen> {
  InventorySupplierEntity? _selectedSupplier;
  final List<InventoryPurchaseItemEntity> _selectedItems = [];
  final TextEditingController _notesController = TextEditingController();
  List<InventorySupplierEntity> _suppliers = [];
  List<InventoryProductEntity> _allProducts = [];

  @override
  void initState() {
    super.initState();
    context.read<InventorySuppliersCubit>().fetchSuppliers();
    context.read<InventoryProductsCubit>().fetchProducts();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    double total = 0;
    for (final item in _selectedItems) {
      total += item.totalPrice;
    }
    return total;
  }

  void _addItem(InventoryProductEntity product, double qty, double price) {
    setState(() {
      _selectedItems.add(
        InventoryPurchaseItemEntity(
          productId: product.id,
          productName: product.name,
          quantity: qty,
          purchasePrice: price,
          totalPrice: qty * price,
        ),
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
  }

  void _savePurchase() {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.selectSupplier.tr())));
      return;
    }
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.pleaseAddAtLeastOneItem.tr())),
      );
      return;
    }

    final purchase = InventoryPurchaseEntity(
      id: 'pur_${DateTime.now().millisecondsSinceEpoch}',
      supplierId: _selectedSupplier!.id,
      supplierName: _selectedSupplier!.name,
      items: _selectedItems,
      totalAmount: _totalAmount,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: DateTime.now(),
      isSynced: false,
    );

    context.read<InventoryPurchasesCubit>().createPurchase(purchase).then((
      success,
    ) {
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.purchaseSavedSuccess.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<InventorySuppliersCubit, InventorySuppliersState>(
          listener: (context, state) {
            if (state is InventorySuppliersLoaded) {
              setState(() {
                _suppliers = state.suppliers;
                if (_suppliers.isNotEmpty && _selectedSupplier == null) {
                  _selectedSupplier = _suppliers.first;
                }
              });
            }
          },
        ),
        BlocListener<InventoryProductsCubit, InventoryProductsState>(
          listener: (context, state) {
            if (state is InventoryProductsLoaded) {
              setState(() => _allProducts = state.products);
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
          title: Text(
            AppStrings.newPurchase.tr(),
            style: TextStyles.customStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 950 : double.infinity,
              ),
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? 24 : 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 1: Select Supplier (Searchable)
                    SearchableDropdownField<InventorySupplierEntity>(
                      label: AppStrings.supplier.tr(),
                      items: _suppliers,
                      selectedId: _selectedSupplier?.id,
                      getName: (s) => s.name,
                      getId: (s) => s.id,
                      onSelected: (s) => setState(() => _selectedSupplier = s),
                      onCleared: () => setState(() => _selectedSupplier = null),
                    ),
                    SizedBox(height: isDesktop ? 20 : 20.h),

                    // Step 2: Add Items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.inventoryProducts.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blackReal,
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                isDesktop ? 10 : 10.r,
                              ),
                            ),
                          ),
                          onPressed: _showAddItemDialog,
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            AppStrings.addPurchaseItem.tr(),
                            style: TextStyles.customStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isDesktop ? 10 : 10.h),

                    // Items List
                    Expanded(
                      child: _selectedItems.isEmpty
                          ? Center(
                              child: Text(
                                AppStrings.noProductsFound.tr(),
                                style: TextStyles.customStyle(
                                  color: AppColors.disabledColor,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _selectedItems.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: isDesktop ? 8 : 8.h),
                              itemBuilder: (context, index) {
                                final item = _selectedItems[index];
                                return Container(
                                  padding: EdgeInsets.all(
                                    isDesktop ? 12 : 12.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(
                                      isDesktop ? 12 : 12.r,
                                    ),
                                    border: Border.all(
                                      color: AppColors.dividerColor,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productName,
                                              style: TextStyles.customStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.blackReal,
                                              ),
                                            ),
                                            SizedBox(
                                              height: isDesktop ? 4 : 4.h,
                                            ),
                                             Wrap(
                                               spacing: 6,
                                               runSpacing: 4,
                                               crossAxisAlignment:
                                                   WrapCrossAlignment.center,
                                               children: [
                                                 Container(
                                                   padding: EdgeInsets.symmetric(
                                                     horizontal:
                                                         isDesktop ? 6 : 6.w,
                                                     vertical:
                                                         isDesktop ? 2 : 2.h,
                                                   ),
                                                   decoration: BoxDecoration(
                                                     color: AppColors.primaryColor
                                                         .withValues(
                                                           alpha: 0.1,
                                                         ),
                                                     borderRadius:
                                                         BorderRadius.circular(
                                                           4.r,
                                                         ),
                                                   ),
                                                   child: Text(
                                                     '${AppStrings.quantity.tr()}: ${item.quantity.toSmartAmount()}',
                                                     style: TextStyles.customStyle(
                                                       fontSize: 12,
                                                       fontWeight:
                                                           FontWeight.bold,
                                                       color: AppColors.primaryColor,
                                                     ),
                                                   ),
                                                 ),
                                                 Text(
                                                   '×',
                                                   style: TextStyles.customStyle(
                                                     fontSize: 13,
                                                     color: AppColors.sandText,
                                                   ),
                                                 ),
                                                 Text(
                                                   '${item.purchasePrice.toSmartAmount()} ${AppStrings.egp.tr()}',
                                                   style: TextStyles.customStyle(
                                                     fontSize: 13,
                                                     color: AppColors.sandText,
                                                   ),
                                                 ),
                                                 Text(
                                                   '=',
                                                   style: TextStyles.customStyle(
                                                     fontSize: 13,
                                                     fontWeight: FontWeight.bold,
                                                     color: AppColors.blackReal,
                                                   ),
                                                 ),
                                                 Text(
                                                   '${item.totalPrice.toSmartAmount()} ${AppStrings.egp.tr()}',
                                                   style: TextStyles.customStyle(
                                                     fontSize: 14,
                                                     fontWeight: FontWeight.bold,
                                                     color: AppColors.success,
                                                   ),
                                                 ),
                                               ],
                                             ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: AppColors.deleteRed,
                                        ),
                                        onPressed: () => _removeItem(index),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    SizedBox(height: isDesktop ? 16 : 16.h),

                    // Total & Save Button
                    Container(
                      padding: EdgeInsets.all(isDesktop ? 16 : 16.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          isDesktop ? 16 : 16.r,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.totalAmount.tr(),
                                style: TextStyles.customStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.blackReal,
                                ),
                              ),
                              Text(
                                _totalAmount.toSmartAmount(),
                                style: TextStyles.customStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isDesktop ? 14 : 14.h),
                          SizedBox(
                            width: double.infinity,
                            height: isDesktop ? 48 : 48.h,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    isDesktop ? 12 : 12.r,
                                  ),
                                ),
                              ),
                              onPressed: _savePurchase,
                              child: Text(
                                AppStrings.savePurchase.tr(),
                                style: TextStyles.customStyle(
                                  fontSize: 16,
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    if (_allProducts.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.noProductsFound.tr())));
      return;
    }

    final isDesktop = ResponsiveLayout.isDesktop(context);
    InventoryProductEntity selectedProd = _allProducts.first;
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController(
      text: selectedProd.purchasePrice.toSmartAmount(),
    );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 20 : 20.w),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.addPurchaseItem.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.blackLight),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const Divider(),
                    SizedBox(height: isDesktop ? 12 : 12.h),

                    // Content Body
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SearchableDropdownField<InventoryProductEntity>(
                              label: AppStrings.selectProduct.tr(),
                              items: _allProducts,
                              selectedId: selectedProd.id,
                              getName: (p) => p.name,
                              getId: (p) => p.id,
                              onSelected: (p) {
                                setDialogState(() {
                                  selectedProd = p;
                                  priceController.text = p.purchasePrice
                                      .toSmartAmount();
                                });
                              },
                              onCleared: () {},
                            ),
                            SizedBox(height: isDesktop ? 12 : 12.h),
                            Text(
                              AppStrings.quantity.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.blackReal,
                              ),
                            ),
                            SizedBox(height: isDesktop ? 6 : 6.h),
                            QuickAddTextField(
                              controller: qtyController,
                              isNumber: true,
                              hint: AppStrings.quantity.tr(),
                            ),
                            SizedBox(height: isDesktop ? 12 : 12.h),
                            Text(
                              AppStrings.purchasePrice.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.blackReal,
                              ),
                            ),
                            SizedBox(height: isDesktop ? 6 : 6.h),
                            QuickAddTextField(
                              controller: priceController,
                              isNumber: true,
                              hint: AppStrings.purchasePrice.tr(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: isDesktop ? 16 : 16.h),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            AppStrings.cancel.tr(),
                            style: TextStyles.customStyle(
                              color: AppColors.blackLight,
                            ),
                          ),
                        ),
                        SizedBox(width: isDesktop ? 12 : 12.w),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 24 : 24.w,
                              vertical: isDesktop ? 12 : 12.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                isDesktop ? 10 : 10.r,
                              ),
                            ),
                          ),
                          onPressed: () {
                            final qty =
                                double.tryParse(qtyController.text.trim()) ?? 1;
                            final price =
                                double.tryParse(priceController.text.trim()) ??
                                selectedProd.purchasePrice;
                            _addItem(selectedProd, qty, price);
                            Navigator.of(ctx).pop();
                          },
                          child: Text(
                            AppStrings.invoiceAddItem.tr(),
                            style: TextStyles.customStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
