import 'package:firebase_auth/firebase_auth.dart';
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

class MyPartialPaymentDialog extends StatefulWidget {
  final String personName;
  final double totalRemaining;

  final String? debtId;

  const MyPartialPaymentDialog({
    super.key,
    required this.personName,
    required this.totalRemaining,
    this.debtId,
  });

  @override
  State<MyPartialPaymentDialog> createState() => _MyPartialPaymentDialogState();
}

class _MyPartialPaymentDialogState extends State<MyPartialPaymentDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
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

    if (amount > widget.totalRemaining + 0.01) {
      setState(() => _errorText = AppStrings.paymentExceedsRemaining.tr());
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      if (widget.debtId != null) {
        context.read<MyDebtDetailsCubit>().payItem(
          uid: uid,
          debtId: widget.debtId!,
          amount: amount,
          personName: widget.personName,
          note: _noteController.text.trim().isEmpty
              ? AppStrings.partialPayment.tr()
              : _noteController.text.trim(),
        );
      } else {
        context.read<MyDebtDetailsCubit>().payDebt(
          uid: uid,
          personName: widget.personName,
          amount: amount,
          note: _noteController.text.trim().isEmpty
              ? AppStrings.partialPayment.tr()
              : _noteController.text.trim(),
        );
      }
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: _errorText != null
                        ? Border.all(color: AppColors.error)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(
                        AppStrings.currencyEgp.tr(),
                        style: TextStyles.customStyle(
                          color: AppColors.disabledColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          cursorColor: AppColors.primaryColor,
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: TextStyles.customStyle(
                            color: AppColors.textColor,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyles.customStyle(
                              color: AppColors.disabledColor,
                              fontSize: 24.sp,
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
                const SizedBox(height: 16),

                // Text(
                //   AppStrings.notes.tr(),
                //   style: TextStyles.customStyle(
                //     color: AppColors.disabledColor,
                //     fontSize: 12.sp,
                //     fontWeight: FontWeight.bold,
                //     letterSpacing: 1.1,
                //   ),
                // ),
                // const SizedBox(height: 8),
                // Container(
                //   decoration: BoxDecoration(
                //     color: AppColors.surfaceContainerHigh,
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   child: TextField(
                //     controller: _noteController,
                //     maxLines: 2,
                //     cursorColor: AppColors.primaryColor,
                //     style: TextStyles.customStyle(
                //       color: AppColors.textColor,
                //       fontSize: 16.sp,
                //       fontWeight: FontWeight.bold,
                //     ),
                //     decoration: InputDecoration(
                //       hintText: AppStrings.notes.tr(),
                //       hintStyle: TextStyles.customStyle(
                //         color: AppColors.disabledColor,
                //         fontSize: 16.sp,
                //         fontWeight: FontWeight.bold,
                //       ),
                //       border: InputBorder.none,
                //       contentPadding: const EdgeInsets.all(16),
                //     ),
                //   ),
                // ),
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
}
