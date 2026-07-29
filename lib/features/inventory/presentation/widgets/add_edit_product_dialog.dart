import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';

import '../../domain/entities/inventory_category_entity.dart';
import '../../domain/entities/inventory_product_entity.dart';
import '../../domain/entities/inventory_supplier_entity.dart';
import 'barcode_scanner_dialog.dart';
import 'searchable_dropdown_field.dart';

class AddEditProductDialog extends StatefulWidget {
  final InventoryProductEntity? product;
  final List<InventoryCategoryEntity> categories;
  final List<InventorySupplierEntity> suppliers;
  final Function(InventoryProductEntity product) onSave;

  const AddEditProductDialog({
    super.key,
    this.product,
    required this.categories,
    required this.suppliers,
    required this.onSave,
  });

  @override
  State<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _initialQtyController;
  late TextEditingController _minQtyController;
  late TextEditingController _unitController;
  late TextEditingController _notesController;

  String? _selectedCategoryId;
  String _selectedCategoryName = '';
  String? _selectedSupplierId;
  String _selectedSupplierName = '';
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(
      text:
          p?.sku ??
          'SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _purchasePriceController = TextEditingController(
      text: p != null ? p.purchasePrice.toSmartAmount() : '0',
    );
    _sellingPriceController = TextEditingController(
      text: p != null ? p.sellingPrice.toSmartAmount() : '0',
    );
    _initialQtyController = TextEditingController(
      text: p != null ? p.currentQuantity.toSmartAmount() : '0',
    );
    _minQtyController = TextEditingController(
      text: p != null ? p.minQuantity.toSmartAmount() : '5',
    );
    _unitController = TextEditingController(
      text: p?.unit ?? AppStrings.piece.tr(),
    );
    _notesController = TextEditingController(text: p?.notes ?? '');

    _selectedCategoryId =
        p?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _selectedCategoryName =
        p?.categoryName ??
        (widget.categories.isNotEmpty ? widget.categories.first.name : '');

    _selectedSupplierId =
        p?.supplierId ??
        (widget.suppliers.isNotEmpty ? widget.suppliers.first.id : null);
    _selectedSupplierName =
        p?.supplierName ??
        (widget.suppliers.isNotEmpty ? widget.suppliers.first.name : '');

    _isAvailable = p?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _initialQtyController.dispose();
    _minQtyController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final isEdit = widget.product != null;
      final newProduct = InventoryProductEntity(
        id: isEdit
            ? widget.product!.id
            : 'prod_${DateTime.now().millisecondsSinceEpoch}',
        sku: _skuController.text.trim(),
        barcode: _barcodeController.text.trim().isNotEmpty
            ? _barcodeController.text.trim()
            : null,
        name: _nameController.text.trim(),
        categoryId: _selectedCategoryId ?? '',
        categoryName: _selectedCategoryName,
        supplierId: _selectedSupplierId ?? '',
        supplierName: _selectedSupplierName,
        purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0.0,
        sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0.0,
        currentQuantity: isEdit
            ? widget.product!.currentQuantity
            : (double.tryParse(_initialQtyController.text) ?? 0.0),
        minQuantity: double.tryParse(_minQtyController.text) ?? 0.0,
        unit: _unitController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        isAvailable: _isAvailable,
        createdAt: isEdit ? widget.product!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      widget.onSave(newProduct);
      Navigator.of(context).pop();
    }
  }

  Future<void> _scanBarcode() async {
    final scannedCode = await BarcodeScannerDialog.scan(context);
    if (scannedCode != null && scannedCode.isNotEmpty) {
      setState(() {
        _barcodeController.text = scannedCode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 550,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 20 : 20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit
                        ? AppStrings.editProduct.tr()
                        : AppStrings.addProduct.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.blackLight),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              SizedBox(height: isDesktop ? 12 : 12.h),

              // Form fields
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        _buildTextField(
                          controller: _nameController,
                          label: AppStrings.productName.tr(),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? AppStrings.validationFieldRequired.tr()
                              : null,
                        ),
                        //  Barcode
                        _buildTextField(
                          controller: _barcodeController,
                          label: AppStrings.barcode.tr(),
                          suffixIcon: Icons.qr_code_scanner_rounded,
                          onSuffixIconPressed: _scanBarcode,
                        ),
                        SizedBox(height: isDesktop ? 12 : 12.h),

                        // SKU
                        _buildTextField(
                          controller: _skuController,
                          label: AppStrings.sku.tr(),
                        ),

                        SizedBox(height: isDesktop ? 12 : 12.h),

                        // Category Dropdown (Searchable)
                        SearchableDropdownField<InventoryCategoryEntity>(
                          label: AppStrings.category.tr(),
                          items: widget.categories,
                          selectedId: _selectedCategoryId,
                          getName: (c) => c.name,
                          getId: (c) => c.id,
                          onSelected: (c) {
                            setState(() {
                              _selectedCategoryId = c.id;
                              _selectedCategoryName = c.name;
                            });
                          },
                          onCleared: () {
                            setState(() {
                              _selectedCategoryId = null;
                              _selectedCategoryName = '';
                            });
                          },
                        ),
                        SizedBox(height: isDesktop ? 12 : 12.h),

                        // Supplier Dropdown (Searchable)
                        SearchableDropdownField<InventorySupplierEntity>(
                          label: AppStrings.supplier.tr(),
                          items: widget.suppliers,
                          selectedId: _selectedSupplierId,
                          getName: (s) => s.name,
                          getId: (s) => s.id,
                          onSelected: (s) {
                            setState(() {
                              _selectedSupplierId = s.id;
                              _selectedSupplierName = s.name;
                            });
                          },
                          onCleared: () {
                            setState(() {
                              _selectedSupplierId = null;
                              _selectedSupplierName = '';
                            });
                          },
                        ),
                        SizedBox(height: isDesktop ? 12 : 12.h),

                        // Purchase Price
                        _buildTextField(
                          controller: _purchasePriceController,
                          label: AppStrings.purchasePrice.tr(),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        SizedBox(height: isDesktop ? 12 : 12.h),
                        // Selling Price
                        _buildTextField(
                          controller: _sellingPriceController,
                          label: AppStrings.sellingPrice.tr(),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        SizedBox(height: isDesktop ? 12 : 12.h),

                        // Initial Quantity & Minimum Quantity
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _initialQtyController,
                                label: AppStrings.currentQuantity.tr(),
                                enabled:
                                    !isEdit, // Quantity locked on edit (changes via movements)
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),
                            SizedBox(width: isDesktop ? 12 : 12.w),
                            Expanded(
                              child: _buildTextField(
                                controller: _minQtyController,
                                label: AppStrings.minQuantity.tr(),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isDesktop ? 12 : 12.h),

                        // Unit
                        _buildTextField(
                          controller: _unitController,
                          label: AppStrings.unit.tr(),
                        ),
                        SizedBox(height: isDesktop ? 12 : 12.h),

                        // Notes
                        _buildTextField(
                          controller: _notesController,
                          label: AppStrings.notes.tr(),
                          maxLines: 2,
                        ),
                        SizedBox(height: isDesktop ? 12 : 12.h),

                        // Availability Toggle
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            AppStrings.isAvailable.tr(),
                            style: TextStyles.customStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blackReal,
                            ),
                          ),
                          value: _isAvailable,
                          activeTrackColor: AppColors.primaryColor,
                          activeThumbColor: AppColors.white,
                          onChanged: (val) =>
                              setState(() => _isAvailable = val),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: isDesktop ? 16 : 16.h),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      AppStrings.cancel.tr(),
                      style: TextStyles.customStyle(
                        color: AppColors.blackLight,
                      ),
                    ),
                  ),
                  SizedBox(width: isDesktop ? 12 : 12.w),
                  ElevatedButton(
                    onPressed: _submit,
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
                    child: Text(
                      isEdit ? AppStrings.edit.tr() : AppStrings.save.tr(),
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
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconPressed,
  }) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.customStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.blackReal,
          ),
        ),
        SizedBox(height: isDesktop ? 6 : 6.h),
        QuickAddTextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          hint: label,
          suffixIcon: suffixIcon,
          onSuffixIconPressed: onSuffixIconPressed,
        ),
      ],
    );
  }
}
