import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/customer/domain/entities/customer_entity.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';
import '../cubit/customer_reports/customer_reports_cubit.dart';

class AddCustomerDialog extends StatefulWidget {
  final String uid;
  final CustomerEntity? customer;

  const AddCustomerDialog({
    super.key,
    required this.uid,
    this.customer,
  });

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ledgerController = TextEditingController();
  final TextEditingController _taxNumberController = TextEditingController();
  final TextEditingController _commercialRegistrationController =
      TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phoneNumber ?? '';
      _ledgerController.text = widget.customer!.ledgerNumber ?? '';
      _taxNumberController.text = widget.customer!.taxNumber ?? '';
      _commercialRegistrationController.text =
          widget.customer!.commercialRegistration ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ledgerController.dispose();
    _taxNumberController.dispose();
    _commercialRegistrationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final cubit = context.read<CustomerReportsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final isEdit = widget.customer != null;
    final bool success;

    if (isEdit) {
      success = await cubit.updateCustomerDetails(
        uid: widget.uid,
        customerId: widget.customer!.id,
        name: widget.customer!.name,
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        ledgerNumber: _ledgerController.text.trim().isNotEmpty
            ? _ledgerController.text.trim()
            : null,
        taxNumber: _taxNumberController.text.trim().isNotEmpty
            ? _taxNumberController.text.trim()
            : null,
        commercialRegistration:
            _commercialRegistrationController.text.trim().isNotEmpty
                ? _commercialRegistrationController.text.trim()
                : null,
      );
    } else {
      success = await cubit.addCustomer(
        uid: widget.uid,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        ledgerNumber: _ledgerController.text.trim().isNotEmpty
            ? _ledgerController.text.trim()
            : null,
        taxNumber: _taxNumberController.text.trim().isNotEmpty
            ? _taxNumberController.text.trim()
            : null,
        commercialRegistration:
            _commercialRegistrationController.text.trim().isNotEmpty
                ? _commercialRegistrationController.text.trim()
                : null,
      );
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        Navigator.of(context).pop(true);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              (isEdit
                      ? AppStrings.customerUpdatedSuccess
                      : AppStrings.customerAddedSuccess)
                  .tr(),
              style: TextStyles.customStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.unexpectedError.tr(),
              style: TextStyles.customStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isEdit = widget.customer != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 20.r),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 24 : 20.w),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isDesktop ? 10 : 10.w),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEdit
                            ? Icons.edit_note_rounded
                            : Icons.person_add_alt_1_rounded,
                        color: AppColors.primaryColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 12 : 12.w),
                    Expanded(
                      child: Text(
                        (isEdit
                                ? AppStrings.editCustomer
                                : AppStrings.addCustomer)
                            .tr(),
                        style: TextStyles.customStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blackReal,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.blackLight),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 16),

                // Form with QuickAdd styled fields
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Name
                      Text(
                        AppStrings.customerName.tr(),
                        style: TextStyles.customStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      QuickAddTextField(
                        hint: AppStrings.customerNameHint.tr(),
                        controller: _nameController,
                        icon: Icons.person_outline_rounded,
                        readOnly: isEdit,
                        suffixIcon: isEdit ? Icons.lock_outline_rounded : null,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings
                                .validationCustomerNameRequired
                                .tr();
                          }
                          return null;
                        },
                      ),
                      if (isEdit) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 13,
                              color: AppColors.blackLight,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                AppStrings.customerNameLockedHint.tr(),
                                style: TextStyles.customStyle(
                                  color: AppColors.blackLight,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Customer Phone (Optional)
                      Text(
                        '${AppStrings.customerPhone.tr()} (${AppStrings.optional.tr()})',
                        style: TextStyles.customStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      QuickAddTextField(
                        hint: '${AppStrings.customerPhone.tr()}...',
                        controller: _phoneController,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Ledger Number (Optional)
                      Text(
                        '${AppStrings.ledgerNumber.tr()} (${AppStrings.optional.tr()})',
                        style: TextStyles.customStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      QuickAddTextField(
                        hint: '${AppStrings.ledgerNumber.tr()}...',
                        controller: _ledgerController,
                        icon: Icons.menu_book_outlined,
                        isNumber: true,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Tax Number / VAT (Optional)
                      Text(
                        '${AppStrings.taxNumber.tr()} (${AppStrings.optional.tr()})',
                        style: TextStyles.customStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      QuickAddTextField(
                        hint: '${AppStrings.taxNumber.tr()}...',
                        controller: _taxNumberController,
                        icon: Icons.receipt_outlined,
                        isNumber: true,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Commercial Registration (Optional)
                      Text(
                        '${AppStrings.commercialRegistration.tr()} (${AppStrings.optional.tr()})',
                        style: TextStyles.customStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      QuickAddTextField(
                        hint: '${AppStrings.commercialRegistration.tr()}...',
                        controller: _commercialRegistrationController,
                        icon: Icons.badge_outlined,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: Text(
                        AppStrings.cancel.tr(),
                        style: TextStyles.customStyle(
                          color: AppColors.blackLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: isDesktop ? 12 : 12.w),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 26 : 22.w,
                          vertical: isDesktop ? 14 : 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              (isEdit
                                      ? AppStrings.saveChanges
                                      : AppStrings.addCustomer)
                                  .tr(),
                              style: TextStyles.customStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
