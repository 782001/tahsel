import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/permission_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/currency_helper.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/utils/vault_balance_helper.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/custody/domain/entities/custody_entity.dart';
import 'package:tahsel/features/custody/presentation/cubit/custody_cubit.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';
import 'package:tahsel/shared/widgets/text_fields/custom_text_form_field.dart';

class SettleCustodyDialog extends StatefulWidget {
  final CustodyEntity custody;
  final CustodyCubit cubit;

  const SettleCustodyDialog({
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
      builder: (_) => SettleCustodyDialog(custody: custody, cubit: cubit),
    );
  }

  @override
  State<SettleCustodyDialog> createState() => _SettleCustodyDialogState();
}

class _SettleCustodyDialogState extends State<SettleCustodyDialog> {
  late final TextEditingController _actualReturnedController;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customDeficitReasonController = TextEditingController();

  final List<String> _deficitOptions = [
    AppStrings.custodyDeficitReasonUnreceipted,
    AppStrings.custodyDeficitReasonCashShortage,
    AppStrings.custodyDeficitReasonLossDamage,
    AppStrings.other,
  ];
  String _selectedDeficitOption = AppStrings.custodyDeficitReasonUnreceipted;

  double _actualReturned = 0.0;
  double _variance = 0.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with remaining amount (or 0 if negative)
    _actualReturned = widget.custody.remainingAmount > 0
        ? widget.custody.remainingAmount
        : 0.0;
    _actualReturnedController = TextEditingController(
      text: _actualReturned.toSmartAmount(),
    );
    _calculateVariance();
  }

  @override
  void dispose() {
    _actualReturnedController.dispose();
    _customDeficitReasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateVariance() {
    if (widget.custody.isDeficit) {
      _actualReturned = 0.0;
      _variance = 0.0;
      return;
    }
    final returned =
        double.tryParse(_actualReturnedController.text.trim()) ?? 0.0;
    _actualReturned = returned.clamp(0.0, double.infinity);
    final expectedReturned = widget.custody.remainingAmount > 0
        ? widget.custody.remainingAmount
        : 0.0;
    _variance = _actualReturned - expectedReturned;
  }

  Future<void> _submit() async {
    // ── Permission Guard ──
    final canSettle =
        PermissionService.instance.isOwner ||
        PermissionService.instance.hasPermission(AppPermissions.vaultAccess) ||
        PermissionService.instance.hasPermission(AppPermissions.vaultDeposit);
    if (!canSettle) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.noPermissionForAction.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // If employee paid out of pocket, verify vault has enough balance to reimburse them
    final reimbursement = widget.custody.remainingAmount < 0
        ? widget.custody.remainingAmount.abs()
        : 0.0;
    if (VaultBalanceHelper.isEnabled() && reimbursement > 0) {
      final currentBalance = await VaultBalanceHelper.getCurrentBalance(
        context,
      );
      if (currentBalance < reimbursement) {
        if (mounted) {
          VaultBalanceHelper.showInsufficientBalanceDialog(context);
        }
        return;
      }
    }

    setState(() => _isSubmitting = true);

    if (widget.custody.isDeficit) {
      _actualReturned = 0.0;
      _variance = 0.0;
    }

    String finalNotes = _notesController.text.trim();
    final String? deficitReason = _variance < 0 && !widget.custody.isDeficit
        ? (_selectedDeficitOption == AppStrings.other
            ? (_customDeficitReasonController.text.trim().isNotEmpty
                ? _customDeficitReasonController.text.trim()
                : AppStrings.other.tr())
            : _selectedDeficitOption.tr())
        : null;

    final success = await widget.cubit.settleCustody(
      custodyId: widget.custody.id,
      actualReturnedAmount: _actualReturned,
      varianceAmount: _variance,
      settledBy: AppStrings.loggedInEmployeeName.isNotEmpty
          ? AppStrings.loggedInEmployeeName
          : (AppStrings.isEmployee
                ? AppStrings.employeeAuthUid
                : AppStrings.owner.tr()),
      settlementNotes: finalNotes.isNotEmpty ? finalNotes : null,
      deficitReason: deficitReason,
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
    final isDeficit = widget.custody.isDeficit;

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
          maxWidth: isDesktop ? 540 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 24 : 18.r),
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
                        color: AppColors.primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.price_check_rounded,
                        color: AppColors.primaryColor,
                        size: isDesktop ? 24 : 24.r,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 12 : 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.settleCustody.tr(),
                            style: TextStyles.customStyle(
                              fontSize: isDesktop ? 18 : 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          Text(
                            widget.custody.recipientName,
                            style: TextStyles.customStyle(
                              fontSize: isDesktop ? 13 : 12.5,
                              fontWeight: FontWeight.w600,
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
                SizedBox(height: isDesktop ? 18 : 18.h),

                // Summary Financial Card
                Container(
                  padding: EdgeInsets.all(isDesktop ? 14 : 14.r),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreyColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(isDesktop ? 14 : 14.r),
                    border: Border.all(
                      color: AppColors.lightGreyColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              AppStrings.originalCustodyAmount.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 13.5 : 13,
                                color: AppColors.sandText,
                              ),
                            ),
                          ),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerEnd,
                              child: Text(
                                CurrencyHelper.formatCurrency(
                                  widget.custody.initialAmount,
                                ),
                                style: TextStyles.customStyle(
                                  fontSize: isDesktop ? 14.5 : 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isDesktop ? 8 : 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              AppStrings.spentFromCustody.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 13.5 : 13,
                                color: AppColors.sandText,
                              ),
                            ),
                          ),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerEnd,
                              child: Text(
                                CurrencyHelper.formatCurrency(
                                  widget.custody.spentAmount,
                                ),
                                style: TextStyles.customStyle(
                                  fontSize: isDesktop ? 14.5 : 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.orange,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              isDeficit
                                  ? AppStrings.dueToEmployee.tr()
                                  : AppStrings.remainingInCustody.tr(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 14.5 : 14,
                                fontWeight: FontWeight.bold,
                                color: isDeficit
                                    ? AppColors.error
                                    : AppColors.primaryColor,
                              ),
                            ),
                          ),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerEnd,
                              child: Text(
                                CurrencyHelper.formatCurrency(
                                  widget.custody.remainingAmount.abs(),
                                ),
                                style: TextStyles.customStyle(
                                  fontSize: isDesktop ? 16.5 : 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDeficit
                                      ? AppColors.error
                                      : AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isDesktop ? 14 : 12.h),

                // Reassuring Simple Settlement Notice
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 12 : 10.w,
                    vertical: isDesktop ? 10 : 9.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(isDesktop ? 10 : 10.r),
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primaryColor,
                        size: isDesktop ? 18 : 18.r,
                      ),
                      SizedBox(width: isDesktop ? 8 : 8.w),
                      Expanded(
                        child: Text(
                          AppStrings.custodySettlementNoticeSimple.tr(),
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 12 : 11.5,
                            color: AppColors.blackLight,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isDesktop ? 16 : 14.h),

                if (isDeficit) ...[
                  // Deficit Reimbursement Information Banner
                  Container(
                    padding: EdgeInsets.all(isDesktop ? 16 : 14.r),
                    margin: EdgeInsets.only(bottom: isDesktop ? 16 : 14.h),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(
                        isDesktop ? 12 : 12.r,
                      ),
                      border: Border.all(
                        color: AppColors.orange.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              color: AppColors.orange,
                              size: isDesktop ? 22 : 20.r,
                            ),
                            SizedBox(width: isDesktop ? 8 : 8.w),
                            Expanded(
                              child: Text(
                                AppStrings.dueToEmployee.tr(),
                                style: TextStyles.customStyle(
                                  fontSize: isDesktop ? 14 : 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.orange,
                                ),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                CurrencyHelper.formatCurrency(
                                  widget.custody.remainingAmount.abs(),
                                ),
                                style: TextStyles.customStyle(
                                  fontSize: isDesktop ? 16 : 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isDesktop ? 8 : 8.h),
                        Text(
                          AppStrings.custodyDeficitSettlementReimburseNotice
                              .tr(),
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 12 : 11.5,
                            color: AppColors.blackLight,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Actual Cash Returned Input (Only when custody has remaining cash)
                  CustomTextFormField(
                    controller: _actualReturnedController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    labelText: AppStrings.actualReturnedAmount.tr(),
                    hintText: '0.00',
                    prefixText: AppStrings.currencyEgp.tr(),
                    prefixIcon: Icons.money_rounded,
                    onChanged: (_) => setState(_calculateVariance),
                  ),
                  SizedBox(height: isDesktop ? 12 : 12.h),

                  // Variance Badge / Status
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 14 : 14.w,
                      vertical: isDesktop ? 10 : 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: _variance == 0
                          ? AppColors.primaryColor.withValues(alpha: 0.1)
                          : _variance < 0
                          ? AppColors.error.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        isDesktop ? 10 : 10.r,
                      ),
                      border: Border.all(
                        color: _variance == 0
                            ? AppColors.primaryColor.withValues(alpha: 0.3)
                            : _variance < 0
                            ? AppColors.error.withValues(alpha: 0.3)
                            : Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _variance == 0
                              ? Icons.check_circle_rounded
                              : _variance < 0
                              ? Icons.warning_amber_rounded
                              : Icons.arrow_upward_rounded,
                          color: _variance == 0
                              ? AppColors.primaryColor
                              : _variance < 0
                              ? AppColors.error
                              : Colors.green,
                          size: isDesktop ? 20 : 20.r,
                        ),
                        SizedBox(width: isDesktop ? 8 : 8.w),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              _variance == 0
                                  ? AppStrings.custodyExactMatch.tr()
                                  : _variance < 0
                                  ? '${AppStrings.custodyDeficit.tr()}: ${CurrencyHelper.formatCurrency(_variance.abs())}'
                                  : '${AppStrings.custodySurplus.tr()}: ${CurrencyHelper.formatCurrency(_variance)}',
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 13.5 : 13,
                                fontWeight: FontWeight.bold,
                                color: _variance == 0
                                    ? AppColors.primaryColor
                                    : _variance < 0
                                    ? AppColors.error
                                    : Colors.green,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isDesktop ? 14 : 14.h),

                  // Deficit Reason & Explanatory Notice
                  if (_variance < 0) ...[
                    Container(
                      padding: EdgeInsets.all(isDesktop ? 12 : 10.r),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          isDesktop ? 10 : 10.r,
                        ),
                        border: Border.all(
                          color: AppColors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.orange,
                            size: isDesktop ? 18 : 18.r,
                          ),
                          SizedBox(width: isDesktop ? 8 : 8.w),
                          Expanded(
                            child: Text(
                              AppStrings.deficitAutoAddedNotice.tr(
                                namedArgs: {
                                  'amount': CurrencyHelper.formatCurrency(
                                    _variance.abs(),
                                  ),
                                },
                              ),
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 12 : 11.5,
                                color: AppColors.blackLight,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isDesktop ? 12 : 12.h),

                    // Deficit Reason Dropdown
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.stitchSurfaceHigh.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(
                          isDesktop ? 12 : 12.r,
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedDeficitOption,
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 14.5 : 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textColor,
                        ),
                        dropdownColor: AppColors.surface,
                        decoration: InputDecoration(
                          labelText: AppStrings.deficitReasonLabel.tr(),
                          labelStyle: TextStyles.customStyle(
                            fontSize: isDesktop ? 13.5 : 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textColor,
                          ),
                          prefixIcon: Icon(
                            Icons.help_outline_rounded,
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
                        items: _deficitOptions.map((optKey) {
                          return DropdownMenuItem<String>(
                            value: optKey,
                            child: Text(
                              optKey.tr(),
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 14 : 13.5,
                                color: AppColors.textColor,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedDeficitOption = val);
                          }
                        },
                      ),
                    ),

                    // Custom Reason Input (When "Other" is chosen)
                    if (_selectedDeficitOption == AppStrings.other) ...[
                      SizedBox(height: isDesktop ? 10 : 10.h),
                      CustomTextFormField(
                        controller: _customDeficitReasonController,
                        labelText: AppStrings.deficitReasonOtherLabel.tr(),
                        hintText: AppStrings.deficitReasonOtherHint.tr(),
                        prefixIcon: Icons.edit_note_rounded,
                      ),
                    ],
                    SizedBox(height: isDesktop ? 14 : 14.h),
                  ],
                ],

                // Settlement Notes Input
                CustomTextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  labelText: AppStrings.custodyNotes.tr(),
                  hintText: AppStrings.settlementNotesHint.tr(),
                  prefixIcon: Icons.notes_rounded,
                ),
                SizedBox(height: isDesktop ? 22 : 22.h),

                // Confirm Settlement Button
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
                          isDeficit
                              ? AppStrings.settleCustodyAndReimburse.tr()
                              : AppStrings.settleCustody.tr(),
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
    );
  }
}
