import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_state.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyAddDebtDialog extends StatefulWidget {
  final String personName;
  final String? phoneNumber;

  const MyAddDebtDialog({
    super.key,
    required this.personName,
    this.phoneNumber,
  });

  @override
  State<MyAddDebtDialog> createState() => _MyAddDebtDialogState();
}

class _MyAddDebtDialogState extends State<MyAddDebtDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _paidAmountFocus = FocusNode();
  final FocusNode _notesFocus = FocusNode();
  String? _errorText;

  @override
  void dispose() {
    _amountController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    _amountFocus.dispose();
    _paidAmountFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final amountText = _amountController.text.trim();
    final paidText = _paidAmountController.text.trim();

    if (amountText.isEmpty) {
      setState(() => _errorText = AppStrings.requiredField.tr());
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _errorText = AppStrings.invalidValue.tr());
      return;
    }

    final paidAmount = double.tryParse(paidText) ?? 0;
    if (paidAmount < 0) {
      setState(() => _errorText = AppStrings.invalidValue.tr());
      return;
    }

    if (paidAmount > amount) {
      setState(() => _errorText = AppStrings.paymentExceedsRemaining.tr());
      return;
    }

    final uid = AppStrings.userToken;
    if (uid.isNotEmpty) {
      context.read<MyDebtDetailsCubit>().addDebt(
        uid: uid,
        personName: widget.personName,
        totalAmount: amount,
        paidAmount: paidAmount,
        description: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : AppStrings.newDebt.tr(),
        phone: widget.phoneNumber,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MyDebtDetailsCubit, MyDebtDetailsState>(
      listener: (context, state) {
        if (state.status == MyDebtDetailsStatus.loaded) {
          Navigator.pop(context);
        } else if (state.status == MyDebtDetailsStatus.error) {
          setState(() => _errorText = state.message);
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.scafoldBackGround,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.addNewDebt.tr(),
                  style: TextStyles.customStyle(
                    color: AppColors.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.totalDueLabel.tr(),
                            style: TextStyles.customStyle(
                              color: AppColors.disabledColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildField(
                            controller: _amountController,
                            focusNode: _amountFocus,
                            nextFocusNode: _paidAmountFocus,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.paidAmount.tr(),
                            style: TextStyles.customStyle(
                              color: AppColors.disabledColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildField(
                            controller: _paidAmountController,
                            focusNode: _paidAmountFocus,
                            nextFocusNode: _notesFocus,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.notes.tr(),
                  style: TextStyles.customStyle(
                    color: AppColors.disabledColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _notesController,
                    focusNode: _notesFocus,
                    maxLines: 2,
                    cursorColor: AppColors.primaryColor,
                    decoration: InputDecoration(
                      hintText: AppStrings.notes.tr(),
                      hintStyle: TextStyles.customStyle(
                        color: AppColors.disabledColor,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorText!,
                    style: TextStyles.customStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: BlocBuilder<MyDebtDetailsCubit, MyDebtDetailsState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state.status == MyDebtDetailsStatus.loading
                            ? null
                            : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (state.status ==
                                  MyDebtDetailsStatus.loading) ...[
                                ShimmerLoading(
                                  child: Container(
                                    height: 20,
                                    width: 20,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                AppStrings.confirm.tr(),
                                style: TextStyles.customStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.disabledColor,
                    ),
                    child: Text(
                      AppStrings.cancel.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.disabledColor,
                      ),
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

  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Text(
            AppStrings.currencyEgp.tr(),
            style: TextStyles.customStyle(
              color: AppColors.disabledColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              textInputAction: nextFocusNode != null
                  ? TextInputAction.next
                  : TextInputAction.done,
              onSubmitted: (_) {
                if (nextFocusNode != null) {
                  focusNode.unfocus();
                  FocusScope.of(context).requestFocus(nextFocusNode);
                } else {
                  _submit();
                }
              },
              style: TextStyles.customStyle(
                color: AppColors.textColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
              cursorColor: AppColors.primaryColor,
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyles.customStyle(
                  color: AppColors.disabledColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
