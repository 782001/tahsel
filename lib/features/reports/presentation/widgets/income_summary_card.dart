import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class IncomeSummaryCard extends StatelessWidget {
  final double totalIncome;
  final int count;
  final String dateRange;

  const IncomeSummaryCard({
    super.key,
    required this.totalIncome,
    required this.count,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 24 : 24.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 24 : 24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.totalIncome.tr(),
                style: TextStyles.customStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.whiteOpacity(0.9),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 12 : 12.w,
                  vertical: isDesktop ? 6 : 6.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.whiteOpacity(0.2),
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "$count ${AppStrings.operations.tr()}",
                    style: TextStyles.customStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 12 : 12.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  totalIncome.toSmartAmount(),
                  style: TextStyles.customStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: isDesktop ? 8 : 8.w),
                Text(
                  AppStrings.currencyEgp.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.whiteOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isDesktop ? 16 : 16.h),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: AppColors.whiteOpacity(0.7),
                size: 14,
              ),
              SizedBox(width: isDesktop ? 8 : 8.w),
              Expanded(
                child: Text(
                  dateRange,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.customStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.whiteOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
