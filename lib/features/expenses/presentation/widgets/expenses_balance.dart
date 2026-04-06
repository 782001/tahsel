import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        double percentage = 0.0;
        bool isIncrease = false;

        if (state is ExpenseFetchSuccess) {
          totalAmount = state.stats.totalAmount;
          percentage = state.stats.percentageChange;
          isIncrease = state.stats.isIncrease;
        }

        final amountString = totalAmount.toStringAsFixed(1);
        final parts = amountString.split('.');
        final amountMain = parts[0];
        final amountDecimal = ".${parts[1]}";

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.totalExpensesThisMonth.tr(),
                style: TextStyles.customStyle(
                  fontSize: 14.sp,
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
                        fontSize: 56.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      amountDecimal,
                      style: TextStyles.customStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackLight,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      AppStrings.currencyEgp.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (percentage > 0) ...[
                SizedBox(height: 20.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isIncrease 
                        ? AppColors.errorContainer.withOpacity(0.8) 
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isIncrease ? Icons.trending_up : Icons.trending_down, 
                        color: isIncrease ? AppColors.error : Colors.green, 
                        size: 18.r
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        isIncrease 
                          ? "${AppStrings.comparisonLastMonth.tr()} $percentage%" 
                          : "${AppStrings.comparisonLastMonth.tr()} $percentage%",
                        style: TextStyles.customStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: isIncrease ? AppColors.error : Colors.green,
                        ),
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
}
