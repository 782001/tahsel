import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

enum BusinessReportType { income, expense, cafe, playstation, debts }

class ReportsDashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final BusinessReportType type;
  final String? badgeText;
  final bool hasActiveStatus;
  final VoidCallback? onTap;

  const ReportsDashboardCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
    this.badgeText,
    this.hasActiveStatus = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color cardColor = _getCardColor();
    Color contentColor = _getContentColor();
    IconData icon = _getIcon();

    bool isAccentCard = type == BusinessReportType.playstation;
    bool isSummaryCard =
        type == BusinessReportType.income || type == BusinessReportType.expense;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: isAccentCard
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
              border: isSummaryCard
                  ? BorderDirectional(
                      end: BorderSide(color: contentColor, width: 10.w),
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (badgeText != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: isAccentCard
                              ? AppColors.whiteColor.withOpacity(0.1)
                              : contentColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          badgeText!,
                          style: TextStyles.customStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: isAccentCard
                                ? AppColors.whiteColor.withOpacity(0.8)
                                : contentColor.withOpacity(0.8),
                          ),
                        ),
                      )
                    else if (hasActiveStatus)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          AppStrings.activeSessions.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.whiteColor,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: isAccentCard
                            ? AppColors.whiteColor.withOpacity(0.2)
                            : contentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isAccentCard
                            ? AppColors.whiteColor
                            : contentColor,
                        size: 20.r,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Text(
                  title,
                  style: TextStyles.customStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isAccentCard
                        ? AppColors.whiteColor.withOpacity(0.7)
                        : AppColors.blackLight.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      amount,
                      style: TextStyles.customStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: isAccentCard
                            ? AppColors.whiteColor
                            : AppColors.black,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      AppStrings.currencyEgp.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: isAccentCard
                            ? AppColors.whiteColor.withOpacity(0.6)
                            : AppColors.blackLight.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCardColor() {
    switch (type) {
      case BusinessReportType.playstation:
        return AppColors.primaryColor;
      case BusinessReportType.debts:
        return AppColors.warning.withOpacity(0.05);
      case BusinessReportType.cafe:
        return AppColors.primaryColor.withOpacity(0.05);
      case BusinessReportType.income:
        return AppColors.primaryColor.withOpacity(0.08); // Stronger tint
      case BusinessReportType.expense:
        return AppColors.error.withOpacity(0.08); // Stronger tint
    }
  }

  Color _getContentColor() {
    switch (type) {
      case BusinessReportType.playstation:
        return AppColors.whiteColor;
      case BusinessReportType.expense:
        return AppColors.error;
      case BusinessReportType.income:
        return AppColors.primaryColor;
      case BusinessReportType.debts:
        return AppColors.warning;
      case BusinessReportType.cafe:
        return AppColors.primaryColor;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case BusinessReportType.playstation:
        return Icons.videogame_asset_outlined;
      case BusinessReportType.cafe:
        return Icons.coffee_outlined;
      case BusinessReportType.debts:
        return Icons.warning_amber_rounded;
      case BusinessReportType.income:
        return Icons.trending_up;
      case BusinessReportType.expense:
        return Icons.payments_outlined;
    }
  }
}
