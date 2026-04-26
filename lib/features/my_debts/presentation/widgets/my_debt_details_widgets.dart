import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/my_debts/data/models/my_debt_item_model.dart';

class MyDebtHeaderBanner extends StatelessWidget {
  final MyDebtDetail detail;

  const MyDebtHeaderBanner({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final totalDebt = detail.totalDebt + detail.totalPaid;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20.w,
            top: -20.h,
            child: CircleAvatar(
              radius: 60.r,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20.h),
                Text(
                  AppStrings.totalDueLabel.tr(),
                  style: TextStyles.customStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '${totalDebt.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                  style: TextStyles.customStyle(
                    color: Colors.white,
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
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

class MyDebtSummaryRow extends StatelessWidget {
  final MyDebtDetail detail;

  const MyDebtSummaryRow({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            AppStrings.paid.tr(),
            detail.totalPaid,
            AppColors.success,
            Icons.check_circle_outline_rounded,
          ),
          Container(
            width: 1,
            height: 40.h,
            color: AppColors.disabledColor.withOpacity(0.2),
          ),
          _buildSummaryItem(
            AppStrings.remainingDebt.tr(),
            detail.totalDebt,
            AppColors.error,
            Icons.timer_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14.sp, color: color),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyles.customStyle(
                color: AppColors.subTitleColor,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          '${amount.toStringAsFixed(1)} ${AppStrings.currencyEgp.tr()}',
          style: TextStyles.customStyle(
            color: color,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
