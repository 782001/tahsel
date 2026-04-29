import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_cubit.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_state.dart';

class AddDebtDialog extends StatefulWidget {
  final String customerName;
  final bool isShop;
  final String? ledgerNumber;

  const AddDebtDialog({
    super.key,
    required this.customerName,
    required this.isShop,
    this.ledgerNumber,
  });

  @override
  State<AddDebtDialog> createState() => _AddDebtDialogState();
}

class _AddDebtDialogState extends State<AddDebtDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  final TextEditingController _debtNameController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _paidAmountFocus = FocusNode();
  final FocusNode _debtNameFocus = FocusNode();
  String _selectedType = AppStrings.shop;
  String? _errorText;

  @override
  void dispose() {
    _amountController.dispose();
    _paidAmountController.dispose();
    _debtNameController.dispose();
    _amountFocus.dispose();
    _paidAmountFocus.dispose();
    _debtNameFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final amountText = _amountController.text.trim();
    final paidText = _paidAmountController.text.trim();

    if (amountText.isEmpty) {
      setState(() => _errorText = AppStrings.validationFieldRequired.tr());
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _errorText = AppStrings.validationInvalidAmount.tr());
      return;
    }

    final paidAmount = double.tryParse(paidText) ?? 0;
    if (paidAmount < 0) {
      setState(() => _errorText = AppStrings.validationInvalidAmount.tr());
      return;
    }

    if (paidAmount > amount) {
      setState(() => _errorText = AppStrings.paymentExceedsRemaining.tr());
      return;
    }

    final remainingAmount = amount - paidAmount;

    final uid = AppStrings.userToken;
    if (uid.isNotEmpty) {
      context.read<DebtCubit>().addDebt(
        uid: uid,
        totalAmount: amount,
        paidAmount: paidAmount,
        customerName: widget.customerName,
        productOrSessionDetails: _debtNameController.text.trim(),
        operationType: _selectedType,
        ledgerNumber: widget.ledgerNumber,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DebtCubit, DebtState>(
      listener: (context, state) {
        if (state is DebtAddSuccess) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 500),
              content: Text(AppStrings.addDebtSuccess.tr()),
            ),
          );
        } else if (state is DebtFailure) {
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
                    // Amount Field
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
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                              border: _errorText != null
                                  ? Border.all(color: AppColors.error)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                // Text(
                                //   AppStrings.currencyEgp.tr(),
                                //   style: TextStyles.customStyle(
                                //     color: AppColors.disabledColor,
                                //     fontSize: 14,
                                //     fontWeight: FontWeight.bold,
                                //   ),
                                // ),
                                Expanded(
                                  child: TextField(
                                    cursorColor: AppColors.primaryColor,
                                    controller: _amountController,
                                    focusNode: _amountFocus,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) => FocusScope.of(
                                      context,
                                    ).requestFocus(_paidAmountFocus),
                                    style: TextStyles.customStyle(
                                      color: AppColors.textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: '0.00',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
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
                    const SizedBox(width: 12),
                    // Paid Amount Field
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
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                // Text(
                                //   AppStrings.currencyEgp.tr(),
                                //   style: TextStyles.customStyle(
                                //     color: AppColors.disabledColor,
                                //     fontSize: 14,
                                //     fontWeight: FontWeight.bold,
                                //   ),
                                // ),
                                Expanded(
                                  child: TextField(
                                    cursorColor: AppColors.primaryColor,
                                    controller: _paidAmountController,
                                    focusNode: _paidAmountFocus,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) => FocusScope.of(
                                      context,
                                    ).requestFocus(_debtNameFocus),
                                    style: TextStyles.customStyle(
                                      color: AppColors.textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: '0.00',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
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
                  ],
                ),

                if (!widget.isShop) ...[
                  const SizedBox(height: 16),
                  // Type Field
                  Text(
                    AppStrings.debtType.tr(),
                    style: TextStyles.customStyle(
                      color: AppColors.disabledColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTypeOption(AppStrings.shop, AppStrings.cafe.tr()),
                      const SizedBox(width: 12),
                      _buildTypeOption(
                        AppStrings.playStation,
                        AppStrings.playStation.tr(),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Debt Name Field
                Text(
                  AppStrings.debtName.tr(),
                  style: TextStyles.customStyle(
                    color: AppColors.disabledColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    cursorColor: AppColors.primaryColor,
                    controller: _debtNameController,
                    focusNode: _debtNameFocus,
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    style: TextStyles.customStyle(
                      color: AppColors.textColor,
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: AppStrings.debtNamePlaceholder.tr(),
                      hintStyle: TextStyles.customStyle(
                        fontWeight: FontWeight.w400,
                        color: AppColors.disabledColor,
                        fontSize: 14,
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
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ],

                const SizedBox(height: 24),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: BlocBuilder<DebtCubit, DebtState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state is DebtLoading ? null : _submit,
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
                              if (state is DebtLoading) ...[
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
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

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.disabledColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildTypeOption(String value, String label) {
    bool isSelected = _selectedType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryColor
                : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? null
                : Border.all(color: AppColors.disabledColor.withOpacity(0.2)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyles.customStyle(
                color: isSelected ? AppColors.white : AppColors.textColor,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
