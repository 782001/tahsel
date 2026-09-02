import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/expenses/presentation/cubit/expense_cubit.dart';
import 'package:tahsel/features/expenses/presentation/cubit/expense_state.dart';

class ExpensesBalance extends StatelessWidget {
  const ExpensesBalance({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, state) {
        double totalAmount = 0.0;
        double previousMonthAmount = 0.0;

        if (state is ExpenseFetchSuccess) {
          totalAmount = state.stats.totalAmount;
          previousMonthAmount = state.stats.previousMonthAmount;
        } else if (state is ExpenseMonthDetailsSuccess) {
          totalAmount = state.stats?.totalAmount ?? 0.0;
          previousMonthAmount = state.stats?.previousMonthAmount ?? 0.0;
        } else if (state is ExpenseLoading && state.previousStats != null) {
          totalAmount = state.previousStats!.totalAmount;
          previousMonthAmount = state.previousStats!.previousMonthAmount;
        }

        final amountString = totalAmount.toStringAsFixed(1);
        final parts = amountString.split('.');
        final amountMain = parts[0];
        final amountDecimal = ".${parts[1]}";
        final currency = AppStrings.currencyEgp.tr();

        final hasPrevData = previousMonthAmount > 0;
        final diffAmount = (totalAmount - previousMonthAmount).abs();
        final isEqual = hasPrevData && diffAmount < 0.01;
        final isIncrease =
            hasPrevData && !isEqual && totalAmount > previousMonthAmount;
        final isDecrease =
            hasPrevData && !isEqual && totalAmount < previousMonthAmount;

        final Color themeColor = isIncrease
            ? AppColors.error
            : (isDecrease ? AppColors.green : AppColors.primaryColor);

        final Color bgColor = isIncrease
            ? AppColors.errorContainer.withValues(alpha: 0.6)
            : (isDecrease
                  ? AppColors.green.withValues(alpha: 0.1)
                  : AppColors.primaryColor.withValues(alpha: 0.08));

        final IconData statusIcon = isIncrease
            ? Icons.trending_up_rounded
            : (isDecrease
                  ? Icons.trending_down_rounded
                  : Icons.balance_rounded);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.totalExpensesThisMonth.tr(),
                style: TextStyles.customStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.blackLight,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 12.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      amountMain,
                      style: TextStyles.customStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      amountDecimal,
                      style: TextStyles.customStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackLight,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      currency,
                      style: TextStyles.customStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasPrevData) ...[
                SizedBox(height: 16.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: themeColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Numbers row: Old (Previous Month) vs New (Current Month)
                      Row(
                        children: [
                          _buildMonthPill(
                            label: AppStrings.previousMonthLabel.tr(),
                            amount: previousMonthAmount,
                            currency: currency,
                            color: AppColors.blackLight,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 18.r,
                              color: themeColor,
                            ),
                          ),
                          _buildMonthPill(
                            label: AppStrings.currentMonthLabel.tr(),
                            amount: totalAmount,
                            currency: currency,
                            color: themeColor,
                            isHighlight: true,
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      // Explanatory note
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 2.h),
                            child: Icon(
                              statusIcon,
                              color: themeColor,
                              size: 16.r,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              isIncrease
                                  ? AppStrings.expensesComparisonExplHigher
                                        .tr()
                                        .replaceAll(
                                          '{current}',
                                          totalAmount.toSmartAmount(),
                                        )
                                        .replaceAll(
                                          '{prev}',
                                          previousMonthAmount.toSmartAmount(),
                                        )
                                        .replaceAll(
                                          '{diff}',
                                          diffAmount.toSmartAmount(),
                                        )
                                        .replaceAll('{currency}', currency)
                                  : (isDecrease
                                        ? AppStrings.expensesComparisonExplLower
                                              .tr()
                                              .replaceAll(
                                                '{current}',
                                                totalAmount.toSmartAmount(),
                                              )
                                              .replaceAll(
                                                '{prev}',
                                                previousMonthAmount
                                                    .toSmartAmount(),
                                              )
                                              .replaceAll(
                                                '{diff}',
                                                diffAmount.toSmartAmount(),
                                              )
                                              .replaceAll(
                                                '{currency}',
                                                currency,
                                              )
                                        : AppStrings.expensesEqualCompared
                                              .tr()
                                              .replaceAll(
                                                '{amount}',
                                                totalAmount.toSmartAmount(),
                                              )
                                              .replaceAll(
                                                '{currency}',
                                                currency,
                                              )),
                              style: TextStyles.customStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: themeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthPill({
    required String label,
    required double amount,
    required String currency,
    required Color color,
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.customStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.blackLight,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          '${amount.toSmartAmount()} $currency',
          style: TextStyles.customStyle(
            fontSize: 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
