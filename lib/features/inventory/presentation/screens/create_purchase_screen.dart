import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import '../../domain/entities/inventory_product_entity.dart';
import '../../domain/entities/inventory_purchase_entity.dart';
import '../../domain/entities/inventory_supplier_entity.dart';
import '../cubits/inventory_products_cubit.dart';
import '../cubits/inventory_purchases_cubit.dart';
import '../cubits/inventory_suppliers_cubit.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.selectSupplier.tr())),
      );
      return;
    }
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إضافة منتج واحد على الأقل')),
      );
      return;
    }

    final purchase = InventoryPurchaseEntity(
      id: 'pur_${DateTime.now().millisecondsSinceEpoch}',
      supplierId: _selectedSupplier!.id,
      supplierName: _selectedSupplier!.name,
      items: _selectedItems,
      totalAmount: _totalAmount,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      createdAt: DateTime.now(),
      isSynced: false,
    );

    context.read<InventoryPurchasesCubit>().createPurchase(purchase).then((success) {
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
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryColor),
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
              constraints: BoxConstraints(maxWidth: isDesktop ? 950 : double.infinity),
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? 24 : 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 1: Select Supplier
                    Text(
                      AppStrings.supplier.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackReal,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    DropdownButtonFormField<InventorySupplierEntity>(
                      initialValue: _selectedSupplier,
                      dropdownColor: AppColors.surface,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.dividerColor),
                        ),
                      ),
                      items: _suppliers
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedSupplier = val),
                    ),
                    SizedBox(height: 20.h),

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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          ),
                          onPressed: _showAddItemDialog,
                          icon: const Icon(Icons.add, color: Colors.white, size: 18),
                          label: Text(
                            AppStrings.addPurchaseItem.tr(),
                            style: TextStyles.customStyle(fontSize: 13, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),

                    // Items List
                    Expanded(
                      child: _selectedItems.isEmpty
                          ? Center(
                              child: Text(
                                AppStrings.noProductsFound.tr(),
                                style: TextStyles.customStyle(color: AppColors.sandText),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _selectedItems.length,
                              separatorBuilder: (_, __) => SizedBox(height: 8.h),
                              itemBuilder: (context, index) {
                                final item = _selectedItems[index];
                                return Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(color: AppColors.dividerColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productName,
                                              style: TextStyles.customStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.blackReal,
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              '${item.quantity} x ${item.purchasePrice}  = ${item.totalPrice}',
                                              style: TextStyles.customStyle(
                                                fontSize: 13,
                                                color: AppColors.sandText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _removeItem(index),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    SizedBox(height: 16.h),

                    // Total & Save Button
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.dividerColor),
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
                                '$_totalAmount',
                                style: TextStyles.customStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 14.h),
                          SizedBox(
                            width: double.infinity,
                            height: 48.h,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.noProductsFound.tr())),
      );
      return;
    }

    InventoryProductEntity selectedProd = _allProducts.first;
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController(text: selectedProd.purchasePrice.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          AppStrings.addPurchaseItem.tr(),
          style: TextStyles.customStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<InventoryProductEntity>(
                  initialValue: selectedProd,
                  dropdownColor: AppColors.surface,
                  items: _allProducts
                      .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedProd = val;
                        priceController.text = val.purchasePrice.toString();
                      });
                    }
                  },
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: AppStrings.quantity.tr()),
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: AppStrings.purchasePrice.tr()),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(qtyController.text.trim()) ?? 1;
              final price = double.tryParse(priceController.text.trim()) ?? selectedProd.purchasePrice;
              _addItem(selectedProd, qty, price);
              Navigator.of(ctx).pop();
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}
