import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/debt/domain/entities/debt_entity.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_cubit.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_state.dart';

class PartialPaymentDialog extends StatefulWidget {
  final String customerName;
  final double totalRemaining;
  final DebtEntity? debt;

  const PartialPaymentDialog({
    super.key,
    required this.customerName,
    required this.totalRemaining,
    this.debt,
  });

  @override
  State<PartialPaymentDialog> createState() => _PartialPaymentDialogState();
}

class _PartialPaymentDialogState extends State<PartialPaymentDialog> {
  final TextEditingController _amountController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      setState(() => _errorText = AppStrings.requiredField.tr());
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _errorText = AppStrings.invalidValue.tr());
      return;
    }

    if (amount > widget.totalRemaining) {
      setState(() => _errorText = AppStrings.paymentExceedsRemaining.tr());
      return;
    }

    final uid = sl<FirebaseAuth>().currentUser?.uid;
    if (uid != null) {
      if (widget.debt != null) {
        context.read<DebtCubit>().payItemDebt(widget.debt!, amount);
      } else {
        context.read<DebtCubit>().payDebt(uid, widget.customerName, amount);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DebtCubit, DebtState>(
      listener: (context, state) {
        if (state is DebtPaymentSuccess) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: Duration(milliseconds: 500),
              content: Text(AppStrings.paymentSuccess.tr()),
            ),
          );
        } else if (state is DebtFailure) {
          setState(() => _errorText = state.message);
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.scafoldBackGround,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.partialPayment.tr(),
                style: TextStyles.customStyle(
                  color: AppColors.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${AppStrings.amountPaid.tr()} (${AppStrings.remainingDebt.tr()}: ${widget.totalRemaining.toStringAsFixed(1)})',
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
                    const SizedBox(width: 16),
                    Text(
                      AppStrings.currencyEgp.tr(),
                      style: TextStyles.customStyle(
                        color: AppColors.disabledColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: TextStyles.customStyle(
                          color: AppColors.textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyles.customStyle(
                            color: AppColors.disabledColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                      child: state is DebtLoading
                          ? CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            )
                          : Text(
                              AppStrings.confirm.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
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
    );
  }
}
