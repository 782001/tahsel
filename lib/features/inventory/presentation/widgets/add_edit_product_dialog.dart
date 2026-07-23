import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import '../../domain/entities/inventory_category_entity.dart';
import '../../domain/entities/inventory_product_entity.dart';
import '../../domain/entities/inventory_supplier_entity.dart';

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
      text: p?.sku ?? 'SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _purchasePriceController = TextEditingController(
      text: p != null ? p.purchasePrice.toStringAsFixed(2) : '0.00',
    );
    _sellingPriceController = TextEditingController(
      text: p != null ? p.sellingPrice.toStringAsFixed(2) : '0.00',
    );
    _initialQtyController = TextEditingController(
      text: p != null ? p.currentQuantity.toStringAsFixed(0) : '0',
    );
    _minQtyController = TextEditingController(
      text: p != null ? p.minQuantity.toStringAsFixed(0) : '5',
    );
    _unitController = TextEditingController(text: p?.unit ?? 'قطعة');
    _notesController = TextEditingController(text: p?.notes ?? '');

    _selectedCategoryId = p?.categoryId ?? (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _selectedCategoryName = p?.categoryName ?? (widget.categories.isNotEmpty ? widget.categories.first.name : '');

    _selectedSupplierId = p?.supplierId ?? (widget.suppliers.isNotEmpty ? widget.suppliers.first.id : null);
    _selectedSupplierName = p?.supplierName ?? (widget.suppliers.isNotEmpty ? widget.suppliers.first.name : '');

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
        id: isEdit ? widget.product!.id : 'prod_${DateTime.now().millisecondsSinceEpoch}',
        sku: _skuController.text.trim(),
        barcode: _barcodeController.text.trim().isNotEmpty ? _barcodeController.text.trim() : null,
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
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        isAvailable: _isAvailable,
        createdAt: isEdit ? widget.product!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      widget.onSave(newProduct);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 550, maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? AppStrings.editProduct.tr() : AppStrings.addProduct.tr(),
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
              SizedBox(height: 12.h),

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
                        SizedBox(height: 12.h),

                        // SKU & Barcode
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _skuController,
                                label: AppStrings.sku.tr(),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildTextField(
                                controller: _barcodeController,
                                label: AppStrings.barcode.tr(),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),

                        // Category Dropdown
                        Text(
                          AppStrings.category.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blackReal,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategoryId,
                          dropdownColor: AppColors.surface,
                          decoration: _inputDecoration(),
                          items: widget.categories
                              .map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(
                                      c.name,
                                      style: TextStyles.customStyle(color: AppColors.blackReal),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCategoryId = val;
                              _selectedCategoryName = widget.categories
                                  .firstWhere((c) => c.id == val,
                                      orElse: () => InventoryCategoryEntity(
                                          id: '', name: '', createdAt: DateTime.now(), updatedAt: DateTime.now()))
                                  .name;
                            });
                          },
                        ),
                        SizedBox(height: 12.h),

                        // Supplier Dropdown
                        Text(
                          AppStrings.supplier.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blackReal,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedSupplierId,
                          dropdownColor: AppColors.surface,
                          decoration: _inputDecoration(),
                          items: widget.suppliers
                              .map((s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(
                                      s.name,
                                      style: TextStyles.customStyle(color: AppColors.blackReal),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedSupplierId = val;
                              _selectedSupplierName = widget.suppliers
                                  .firstWhere((s) => s.id == val,
                                      orElse: () => InventorySupplierEntity(
                                          id: '',
                                          name: '',
                                          phone: '',
                                          address: '',
                                          createdAt: DateTime.now(),
                                          updatedAt: DateTime.now()))
                                  .name;
                            });
                          },
                        ),
                        SizedBox(height: 12.h),

                        // Purchase Price & Selling Price
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _purchasePriceController,
                                label: AppStrings.purchasePrice.tr(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildTextField(
                                controller: _sellingPriceController,
                                label: AppStrings.sellingPrice.tr(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),

                        // Initial Quantity & Minimum Quantity
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _initialQtyController,
                                label: AppStrings.currentQuantity.tr(),
                                enabled: !isEdit, // Quantity locked on edit (changes via movements)
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildTextField(
                                controller: _minQtyController,
                                label: AppStrings.minQuantity.tr(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),

                        // Unit
                        _buildTextField(
                          controller: _unitController,
                          label: AppStrings.unit.tr(),
                        ),
                        SizedBox(height: 12.h),

                        // Notes
                        _buildTextField(
                          controller: _notesController,
                          label: AppStrings.notes.tr(),
                          maxLines: 2,
                        ),
                        SizedBox(height: 12.h),

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
                          onChanged: (val) => setState(() => _isAvailable = val),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'إلغاء',
                      style: TextStyles.customStyle(color: AppColors.blackLight),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                    child: Text(
                      isEdit ? 'تعديل' : 'حفظ',
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
  }) {
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
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyles.customStyle(color: AppColors.blackReal),
          decoration: _inputDecoration(),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.veryLightGrey,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: AppColors.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: AppColors.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
      ),
    );
  }
}
