import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/services/permission_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/currency_helper.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/custody/domain/entities/custody_entity.dart';
import 'package:tahsel/features/custody/presentation/cubit/custody_cubit.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';
import 'package:tahsel/shared/widgets/text_fields/custom_text_form_field.dart';

class AddCustodyExpenseDialog extends StatefulWidget {
  final CustodyEntity custody;
  final CustodyCubit cubit;

  const AddCustodyExpenseDialog({
    super.key,
    required this.custody,
    required this.cubit,
  });

  static Future<void> show(
    BuildContext context, {
    required CustodyEntity custody,
    required CustodyCubit cubit,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddCustodyExpenseDialog(custody: custody, cubit: cubit),
    );
  }

  @override
  State<AddCustodyExpenseDialog> createState() =>
      _AddCustodyExpenseDialogState();
}

class _AddCustodyExpenseDialogState extends State<AddCustodyExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedCategory = 'expenses';
  bool _isSubmitting = false;

  final List<Map<String, String>> _categories = [
    {'key': 'purchases', 'label': AppStrings.custodyCategoryPurchases},
    {'key': 'expenses', 'label': AppStrings.custodyCategoryExpenses},
    {'key': 'change_return', 'label': AppStrings.custodyCategoryChangeReturn},
    {'key': 'emergency', 'label': AppStrings.custodyCategoryEmergency},
    {'key': 'other', 'label': AppStrings.custodyCategoryOther},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  double get _enteredAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0.0;

  bool get _exceedsRemaining =>
      _enteredAmount > widget.custody.remainingAmount &&
      widget.custody.remainingAmount > 0;

  double get _excessAmount => _enteredAmount - widget.custody.remainingAmount;

  Future<void> _submit() async {
    // ── Permission Guard ──
    final canAdd =
        PermissionService.instance.isOwner ||
        PermissionService.instance.hasPermission(AppPermissions.expensesAdd) ||
        (widget.custody.recipientEmployeeId != null &&
            widget.custody.recipientEmployeeId == AppStrings.employeeAuthUid);
    if (!canAdd) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.noPermissionForAction.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => _isSubmitting = true);

    final selectedCatItem = _categories.firstWhere(
      (c) => c['key'] == _selectedCategory,
      orElse: () => _categories[1],
    );
    final categoryLabel = selectedCatItem['label']!.tr();
    final customDesc = _descController.text.trim();
    final finalDesc = customDesc.isNotEmpty ? customDesc : categoryLabel;

    final success = await widget.cubit.addCustodyExpense(
      custodyId: widget.custody.id,
      amount: amount,
      category: _selectedCategory,
      description: finalDesc,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 16.w,
        vertical: isDesktop ? 24 : 24.h,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 20.r),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 500 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 24 : 18.r),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isDesktop ? 10 : 10.r),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.orange,
                          size: isDesktop ? 24 : 24.r,
                        ),
                      ),
                      SizedBox(width: isDesktop ? 12 : 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.addCustodyExpense.tr(),
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 18 : 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            Text(
                              '${widget.custody.recipientName} • ${AppStrings.remainingInCustody.tr()}: ${CurrencyHelper.formatCurrency(widget.custody.remainingAmount)}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 12 : 11.5,
                                color: AppColors.sandText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.sandText,
                          size: isDesktop ? 22 : 22.r,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isDesktop ? 16 : 14.h),

                  // Informative Notice (Vault vs Custody)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 12 : 10.w,
                      vertical: isDesktop ? 9 : 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(isDesktop ? 10 : 8.r),
                      border: Border.all(
                        color: AppColors.primaryColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: isDesktop ? 16 : 16.r,
                          color: AppColors.primaryColor,
                        ),
                        SizedBox(width: isDesktop ? 8 : 8.w),
                        Expanded(
                          child: Text(
                            AppStrings.custodyExpenseVaultNotice.tr(),
                            style: TextStyles.customStyle(
                              fontSize: isDesktop ? 11.5 : 11,
                              color: AppColors.blackLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isDesktop ? 16 : 14.h),

                  // Amount Field
                  CustomTextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    labelText: AppStrings.amount.tr(),
                    hintText: '0.00',
                    prefixText: AppStrings.currencyEgp.tr(),
                    prefixIcon: Icons.payments_outlined,
                    onChanged: (_) => setState(() {}),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return AppStrings.validationInvalidAmount.tr();
                      }
                      final num = double.tryParse(val.trim());
                      if (num == null || num <= 0) {
                        return AppStrings.validationInvalidAmount.tr();
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: isDesktop ? 12 : 12.h),

                  // Warning alert if expense exceeds remaining custody
                  if (_exceedsRemaining) ...[
                    Container(
                      padding: EdgeInsets.all(isDesktop ? 12 : 12.r),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          isDesktop ? 10 : 10.r,
                        ),
                        border: Border.all(
                          color: AppColors.orange.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.orange,
                            size: isDesktop ? 20 : 20.r,
                          ),
                          SizedBox(width: isDesktop ? 8 : 8.w),
                          Expanded(
                            child: Text(
                              AppStrings.expenseExceedsCustodyWarning.tr(
                                namedArgs: {
                                  'amount': _excessAmount.toSmartAmount(),
                                },
                              ),
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 11.5 : 11,
                                color: AppColors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isDesktop ? 12 : 12.h),
                  ],

                  // Category Selector
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.stitchSurfaceHigh.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(
                        isDesktop ? 12 : 12.r,
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 15 : 14.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textColor,
                      ),
                      dropdownColor: AppColors.surface,
                      decoration: InputDecoration(
                        labelText: AppStrings.category.tr(),
                        labelStyle: TextStyles.customStyle(
                          fontSize: isDesktop ? 14 : 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColor,
                        ),
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: AppColors.primaryColor,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            isDesktop ? 12 : 12.r,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 16 : 16.w,
                          vertical: isDesktop ? 14 : 14.h,
                        ),
                      ),
                      items: _categories.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['key'],
                          child: Text(
                            c['label']!.tr(),
                            style: TextStyles.customStyle(
                              fontSize: isDesktop ? 14 : 13.5,
                              color: AppColors.textColor,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                        }
                      },
                    ),
                  ),
                  SizedBox(height: isDesktop ? 14 : 14.h),

                  // Description / Statement Field
                  CustomTextFormField(
                    controller: _descController,
                    maxLines: 2,
                    labelText: AppStrings.description.tr(),
                    hintText: AppStrings.expenseDetailsHint.tr(),
                    prefixIcon: Icons.edit_note_rounded,
                  ),
                  SizedBox(height: isDesktop ? 22 : 22.h),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: EdgeInsets.symmetric(
                        vertical: isDesktop ? 14 : 14.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isDesktop ? 12 : 12.r,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? ShimmerLoading(
                            child: Container(
                              height: 16,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          )
                        : Text(
                            AppStrings.addCustodyExpense.tr(),
                            style: TextStyles.customStyle(
                              fontSize: isDesktop ? 15.5 : 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
