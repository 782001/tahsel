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
  final InventoryPurchaseEntity? initialPurchase;
  const CreatePurchaseScreen({super.key, this.initialPurchase});

  @override
  State<CreatePurchaseScreen> createState() => _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends State<CreatePurchaseScreen> {
  InventorySupplierEntity? _selectedSupplier;
  final List<InventoryPurchaseItemEntity> _selectedItems = [];
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  String _selectedPaymentMethod = 'cash';
  List<InventorySupplierEntity> _suppliers = [];
  List<InventoryProductEntity> _allProducts = [];
  final List<InventoryProductEntity> _newProductsToCreate = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialPurchase != null) {
      _selectedItems.addAll(widget.initialPurchase!.items);
      _notesController.text = widget.initialPurchase!.notes ?? '';
      _selectedPaymentMethod = widget.initialPurchase!.paymentMethod;
      _paidAmountController.text = widget.initialPurchase!.paidAmount
          .toSmartAmount();
    } else {
      _paidAmountController.text = '0';
    }
    context.read<InventorySuppliersCubit>().fetchSuppliers();
    context.read<InventoryProductsCubit>().fetchProducts();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _paidAmountController.dispose();
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

  Future<void> _savePurchase() async {
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

    final productsCubit = context.read<InventoryProductsCubit>();
    final purchasesCubit = context.read<InventoryPurchasesCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // 1. Save all new products first so they exist in database
    final selectedProductIds = _selectedItems.map((e) => e.productId).toSet();
    for (final newProd in _newProductsToCreate) {
      if (selectedProductIds.contains(newProd.id)) {
        await productsCubit.saveProduct(newProd);
      }
    }

    // Parse paid amount for debt payments
    final double parsedPaid =
        double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
    final double actualPaidAmount = _selectedPaymentMethod == 'debt'
        ? parsedPaid.clamp(0.0, _totalAmount)
        : _totalAmount;

    // 2. Create or Update the purchase invoice
    final bool isEdit = widget.initialPurchase != null;
    bool success = false;

    if (isEdit) {
      final updatedPurchase = widget.initialPurchase!.copyWith(
        supplierId: _selectedSupplier!.id,
        supplierName: _selectedSupplier!.name,
        items: List.from(_selectedItems),
        totalAmount: _totalAmount,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        paymentMethod: widget.initialPurchase!.paymentMethod,
        paidAmount: widget.initialPurchase!.paidAmount,
        isSynced: false,
      );
      success = await purchasesCubit.updatePurchase(
        oldPurchase: widget.initialPurchase!,
        newPurchase: updatedPurchase,
      );
    } else {
      final newPurchase = InventoryPurchaseEntity(
        id: 'pur_${DateTime.now().millisecondsSinceEpoch}',
        supplierId: _selectedSupplier!.id,
        supplierName: _selectedSupplier!.name,
        items: List.from(_selectedItems),
        totalAmount: _totalAmount,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: DateTime.now(),
        isSynced: false,
        paymentMethod: _selectedPaymentMethod,
        paidAmount: actualPaidAmount,
      );
      success = await purchasesCubit.createPurchase(newPurchase);
    }

    if (success && mounted) {
      // 3. Refresh products data so all quantities & new products are re-fetched cleanly
      await productsCubit.fetchProducts();

      messenger.showSnackBar(
        SnackBar(
          content: Text(AppStrings.purchaseSavedSuccess.tr()),
          backgroundColor: AppColors.success,
        ),
      );
      navigator.pop();
    }
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
                  if (widget.initialPurchase != null) {
                    _selectedSupplier = _suppliers.firstWhere(
                      (s) => s.id == widget.initialPurchase!.supplierId,
                      orElse: () => _suppliers.first,
                    );
                  } else {
                    _selectedSupplier = _suppliers.first;
                  }
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
            widget.initialPurchase != null
                ? '${AppStrings.edit.tr()} ${AppStrings.purchaseInvoiceNum.tr()} #${widget.initialPurchase!.id.replaceAll("pur_", "")}'
                : AppStrings.newPurchase.tr(),
            style: TextStyles.customStyle(
              fontSize: widget.initialPurchase != null ? 15 : 22,
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
                                                    horizontal: isDesktop
                                                        ? 6
                                                        : 6.w,
                                                    vertical: isDesktop
                                                        ? 2
                                                        : 2.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors
                                                        .primaryColor
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4.r,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${AppStrings.quantity.tr()}: ${item.quantity.toSmartAmount()}',
                                                    style:
                                                        TextStyles.customStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppColors
                                                              .primaryColor,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                '${_totalAmount.toSmartAmount()} ${AppStrings.egp.tr()}',
                                style: TextStyles.customStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isDesktop ? 14 : 14.h),
                          if (widget.initialPurchase == null) ...[
                            const Divider(),
                            SizedBox(height: isDesktop ? 10 : 10.h),
                            _buildPaymentMethodSection(isDesktop),
                            SizedBox(height: isDesktop ? 16 : 16.h),
                          ],
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
    final isDesktop = ResponsiveLayout.isDesktop(context);
    bool isNewProductMode = _allProducts.isEmpty;
    InventoryProductEntity? selectedProd = _allProducts.isNotEmpty
        ? _allProducts.first
        : null;

    // Controllers for existing product
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController(
      text: selectedProd != null
          ? selectedProd.purchasePrice.toSmartAmount()
          : '',
    );

    // Controllers for new product
    final newProductNameController = TextEditingController();
    final newSkuController = TextEditingController();
    final newPurchasePriceController = TextEditingController();
    final newSellingPriceController = TextEditingController();
    final newQtyController = TextEditingController(text: '1');
    final newUnitController = TextEditingController(text: 'قطعة');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                    SizedBox(height: isDesktop ? 8 : 8.h),

                    // Mode Toggle (Existing Product vs New Product)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.scafoldBackGround,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: AppColors.dividerColor),
                      ),
                      padding: EdgeInsets.all(isDesktop ? 4 : 4.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                if (_allProducts.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppStrings.noProductsFound.tr(),
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                setDialogState(() {
                                  isNewProductMode = false;
                                  selectedProd ??= _allProducts.first;
                                  priceController.text = selectedProd!
                                      .purchasePrice
                                      .toSmartAmount();
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: isDesktop ? 8 : 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: !isNewProductMode
                                      ? AppColors.primaryColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  AppStrings.availableProduct.tr(),
                                  textAlign: TextAlign.center,
                                  style: TextStyles.customStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: !isNewProductMode
                                        ? Colors.white
                                        : AppColors.blackLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  isNewProductMode = true;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: isDesktop ? 8 : 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isNewProductMode
                                      ? AppColors.primaryColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  AppStrings.newProduct.tr(),
                                  textAlign: TextAlign.center,
                                  style: TextStyles.customStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isNewProductMode
                                        ? Colors.white
                                        : AppColors.blackLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isDesktop ? 14 : 14.h),

                    // Body
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: !isNewProductMode
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (selectedProd != null)
                                    SearchableDropdownField<
                                      InventoryProductEntity
                                    >(
                                      label: AppStrings.selectProduct.tr(),
                                      items: _allProducts,
                                      selectedId: selectedProd!.id,
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
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${AppStrings.productName.tr()} *',
                                    style: TextStyles.customStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.blackReal,
                                    ),
                                  ),
                                  SizedBox(height: isDesktop ? 6 : 6.h),
                                  QuickAddTextField(
                                    controller: newProductNameController,
                                    hint: AppStrings.productName.tr(),
                                  ),
                                  SizedBox(height: isDesktop ? 10 : 10.h),
                                  Text(
                                    AppStrings.sku.tr(),
                                    style: TextStyles.customStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.blackReal,
                                    ),
                                  ),
                                  SizedBox(height: isDesktop ? 6 : 6.h),
                                  QuickAddTextField(
                                    controller: newSkuController,
                                    hint: AppStrings.skuCodeOptional.tr(),
                                  ),
                                  SizedBox(height: isDesktop ? 10 : 10.h),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${AppStrings.purchasePrice.tr()} *',
                                              style: TextStyles.customStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.blackReal,
                                              ),
                                            ),
                                            SizedBox(
                                              height: isDesktop ? 6 : 6.h,
                                            ),
                                            QuickAddTextField(
                                              controller:
                                                  newPurchasePriceController,
                                              isNumber: true,
                                              hint: AppStrings.purchasePrice
                                                  .tr(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: isDesktop ? 10 : 10.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppStrings.sellingPrice.tr(),
                                              style: TextStyles.customStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.blackReal,
                                              ),
                                            ),
                                            SizedBox(
                                              height: isDesktop ? 6 : 6.h,
                                            ),
                                            QuickAddTextField(
                                              controller:
                                                  newSellingPriceController,
                                              isNumber: true,
                                              hint: AppStrings.sellingPrice
                                                  .tr(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isDesktop ? 10 : 10.h),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${AppStrings.quantity.tr()} *',
                                              style: TextStyles.customStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.blackReal,
                                              ),
                                            ),
                                            SizedBox(
                                              height: isDesktop ? 6 : 6.h,
                                            ),
                                            QuickAddTextField(
                                              controller: newQtyController,
                                              isNumber: true,
                                              hint: AppStrings.quantity.tr(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: isDesktop ? 10 : 10.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppStrings.unit.tr(),
                                              style: TextStyles.customStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.blackReal,
                                              ),
                                            ),
                                            SizedBox(
                                              height: isDesktop ? 6 : 6.h,
                                            ),
                                            QuickAddTextField(
                                              controller: newUnitController,
                                              hint: AppStrings.unitPlaceholder
                                                  .tr(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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
                        Flexible(
                          child: TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(
                              AppStrings.cancel.tr(),
                              style: TextStyles.customStyle(
                                color: AppColors.blackLight,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isDesktop ? 8 : 8.w),
                        Flexible(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 16 : 12.w,
                                vertical: isDesktop ? 10 : 10.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  isDesktop ? 10 : 10.r,
                                ),
                              ),
                            ),
                            onPressed: () {
                              if (!isNewProductMode) {
                                if (selectedProd == null) return;
                                final qty =
                                    double.tryParse(
                                      qtyController.text.trim(),
                                    ) ??
                                    1;
                                final price =
                                    double.tryParse(
                                      priceController.text.trim(),
                                    ) ??
                                    selectedProd!.purchasePrice;
                                _addItem(selectedProd!, qty, price);
                                Navigator.of(ctx).pop();
                              } else {
                                final name = newProductNameController.text
                                    .trim();
                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppStrings.pleaseEnterProductName.tr(),
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final purchasePrice =
                                    double.tryParse(
                                      newPurchasePriceController.text.trim(),
                                    ) ??
                                    0.0;
                                final sellingPrice =
                                    double.tryParse(
                                      newSellingPriceController.text.trim(),
                                    ) ??
                                    purchasePrice;
                                final qty =
                                    double.tryParse(
                                      newQtyController.text.trim(),
                                    ) ??
                                    1.0;
                                final unit = newUnitController.text.trim();

                                final newProduct = InventoryProductEntity(
                                  id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
                                  sku: newSkuController.text.trim(),
                                  name: name,
                                  categoryId: '',
                                  categoryName: '',
                                  supplierId: _selectedSupplier?.id ?? '',
                                  supplierName: _selectedSupplier?.name ?? '',
                                  purchasePrice: purchasePrice,
                                  sellingPrice: sellingPrice > 0
                                      ? sellingPrice
                                      : purchasePrice,
                                  currentQuantity: 0.0,
                                  minQuantity: 5.0,
                                  unit: unit.isNotEmpty
                                      ? unit
                                      : AppStrings.piece.tr(),
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                  isSynced: false,
                                );

                                setState(() {
                                  _newProductsToCreate.add(newProduct);
                                  _allProducts.add(newProduct);
                                  _selectedItems.add(
                                    InventoryPurchaseItemEntity(
                                      productId: newProduct.id,
                                      productName: newProduct.name,
                                      quantity: qty,
                                      purchasePrice: purchasePrice,
                                      totalPrice: qty * purchasePrice,
                                    ),
                                  );
                                });
                                Navigator.of(ctx).pop();
                              }
                            },
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                AppStrings.invoiceAddItem.tr(),
                                style: TextStyles.customStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
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

  Widget _buildPaymentMethodSection(bool isDesktop) {
    final double parsedPaid =
        double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
    final double remainingDebt = (_totalAmount - parsedPaid).clamp(
      0.0,
      double.infinity,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.paymentMethod.tr(),
          style: TextStyles.customStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.blackReal,
          ),
        ),
        SizedBox(height: isDesktop ? 8 : 8.h),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                showCheckmark: false,
                label: Center(
                  child: Text(
                    AppStrings.paymentCash.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _selectedPaymentMethod == 'cash'
                          ? Colors.white
                          : AppColors.blackReal,
                    ),
                  ),
                ),
                selected: _selectedPaymentMethod == 'cash',
                selectedColor: AppColors.success,
                backgroundColor: AppColors.scafoldBackGround,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedPaymentMethod = 'cash';
                    });
                  }
                },
              ),
            ),
            SizedBox(width: isDesktop ? 8 : 8.w),
            Expanded(
              child: ChoiceChip(
                showCheckmark: false,
                label: Center(
                  child: Text(
                    AppStrings.paymentCard.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _selectedPaymentMethod == 'card'
                          ? Colors.white
                          : AppColors.blackReal,
                    ),
                  ),
                ),
                selected: _selectedPaymentMethod == 'card',
                selectedColor: AppColors.primaryColor,
                backgroundColor: AppColors.scafoldBackGround,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedPaymentMethod = 'card';
                    });
                  }
                },
              ),
            ),
            SizedBox(width: isDesktop ? 8 : 8.w),
            Expanded(
              child: ChoiceChip(
                showCheckmark: false,
                label: Center(
                  child: Text(
                    AppStrings.paymentDebt.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _selectedPaymentMethod == 'debt'
                          ? Colors.white
                          : AppColors.blackReal,
                    ),
                  ),
                ),
                selected: _selectedPaymentMethod == 'debt',
                selectedColor: AppColors.warning,
                backgroundColor: AppColors.scafoldBackGround,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedPaymentMethod = 'debt';
                    });
                  }
                },
              ),
            ),
          ],
        ),
        if (_selectedPaymentMethod == 'debt') ...[
          SizedBox(height: isDesktop ? 12 : 12.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.paidAmount.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blackReal,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 6 : 6.h),
                    QuickAddTextField(
                      controller: _paidAmountController,
                      isNumber: true,
                      hint: AppStrings.paidAmount.tr(),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isDesktop ? 12 : 12.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isDesktop ? 12 : 12.w),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.remainingDebt.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 12,
                          color: AppColors.sandText,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 2 : 2.h),
                      Text(
                        '${remainingDebt.toSmartAmount()} ${AppStrings.egp.tr()}',
                        style: TextStyles.customStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
