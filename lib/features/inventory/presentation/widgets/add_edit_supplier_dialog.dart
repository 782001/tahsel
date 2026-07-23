import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import '../../domain/entities/inventory_supplier_entity.dart';

import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';

class AddEditSupplierDialog extends StatefulWidget {
  final InventorySupplierEntity? supplier;
  final Function(InventorySupplierEntity supplier) onSave;

  const AddEditSupplierDialog({
    super.key,
    this.supplier,
    required this.onSave,
  });

  @override
  State<AddEditSupplierDialog> createState() => _AddEditSupplierDialogState();
}

class _AddEditSupplierDialogState extends State<AddEditSupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final s = widget.supplier;
    _nameController = TextEditingController(text: s?.name ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _addressController = TextEditingController(text: s?.address ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final isEdit = widget.supplier != null;
      final newSupplier = InventorySupplierEntity(
        id: isEdit ? widget.supplier!.id : 'sup_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: isEdit ? widget.supplier!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      widget.onSave(newSupplier);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.supplier != null;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 20 : 18.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? AppStrings.editSupplier.tr() : AppStrings.addSupplier.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 18,
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

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      controller: _nameController,
                      label: AppStrings.supplierName.tr(),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? AppStrings.validationFieldRequired.tr()
                          : null,
                    ),
                    SizedBox(height: isDesktop ? 12 : 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: _phoneController,
                            label: AppStrings.supplierPhone.tr(),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        SizedBox(width: isDesktop ? 12 : 12.w),
                        Expanded(
                          child: _buildField(
                            controller: _emailController,
                            label: AppStrings.supplierEmail.tr(),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isDesktop ? 12 : 12.h),
                    _buildField(
                      controller: _addressController,
                      label: AppStrings.supplierAddress.tr(),
                    ),
                    SizedBox(height: isDesktop ? 12 : 12.h),
                    _buildField(
                      controller: _notesController,
                      label: AppStrings.notes.tr(),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              SizedBox(height: isDesktop ? 20 : 20.h),

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
                  SizedBox(width: isDesktop ? 12 : 12.w),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 24.w, vertical: isDesktop ? 12 : 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isDesktop ? 10 : 10.r)),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
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
        QuickAddTextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          hint: label,
        ),
      ],
    );
  }
}
