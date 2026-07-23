import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import '../../domain/entities/inventory_category_entity.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';

class AddEditCategoryDialog extends StatefulWidget {
  final InventoryCategoryEntity? category;
  final Function(InventoryCategoryEntity category) onSave;

  const AddEditCategoryDialog({
    super.key,
    this.category,
    required this.onSave,
  });

  @override
  State<AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<AddEditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _descController = TextEditingController(text: widget.category?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final category = InventoryCategoryEntity(
        id: widget.category?.id ?? 'cat_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        createdAt: widget.category?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      widget.onSave(category);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 20 : 18.w),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? AppStrings.editCategory.tr() : AppStrings.addCategory.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackReal,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 16 : 16.h),
                QuickAddTextField(
                  controller: _nameController,
                  labelText: AppStrings.categoryName.tr(),
                  hint: AppStrings.categoryName.tr(),
                  validator: (v) => v == null || v.trim().isEmpty ? 'الرجاء إدخال اسم القسم' : null,
                ),
                SizedBox(height: isDesktop ? 12 : 12.h),
                QuickAddTextField(
                  controller: _descController,
                  labelText: AppStrings.categoryDescription.tr(),
                  hint: AppStrings.categoryDescription.tr(),
                  maxLines: 2,
                ),
                SizedBox(height: isDesktop ? 20 : 20.h),
                SizedBox(
                  width: double.infinity,
                  height: isDesktop ? 46 : 46.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r)),
                    ),
                    onPressed: _submit,
                    child: Text(
                      isEdit ? AppStrings.update.tr() : AppStrings.save.tr(),
                      style: TextStyles.customStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
