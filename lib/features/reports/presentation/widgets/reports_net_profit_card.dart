import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

class ReportsNetProfitCard extends StatelessWidget {
  final String amount;
  final String difference;
  final bool isPositive;
  final String comparisonText;

  const ReportsNetProfitCard({
    super.key,
    required this.amount,
    required this.difference,
    required this.comparisonText,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppStrings.netProfit.tr(),
            style: TextStyles.customStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.blackLight.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                amount,
                style: TextStyles.customStyle(
                  fontSize: 42.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                AppStrings.currencyEgp.tr(),
                style: TextStyles.customStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blackLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.primaryColor : AppColors.error)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${isPositive ? '+' : '-'}$difference ${AppStrings.currencyEgp.tr()}  $comparisonText  ${isPositive ? '↑↑' : '↓↓'}",
                  style: TextStyles.customStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: isPositive
                        ? AppColors.primaryColor
                        : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
