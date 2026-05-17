import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class ReportsNetProfitCard extends StatelessWidget {
  final String amount;
  final String comparisonText;
  final bool isPositive;

  const ReportsNetProfitCard({
    super.key,
    required this.amount,
    required this.comparisonText,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 24.w,
          vertical: isDesktop ? 16 : 16.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppStrings.netProfit.tr(),
              style: TextStyles.customStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.blackLight.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: isDesktop ? 16 : 8.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    amount,
                    style: TextStyles.customStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(width: isDesktop ? 12 : 8.w),
                  Text(
                    AppStrings.currencyEgp.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackLight,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isDesktop ? 12 : 8.h),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 12 : 10.w,
                vertical: isDesktop ? 8 : 4.h,
              ),
              decoration: BoxDecoration(
                color: (isPositive ? AppColors.primaryColor : AppColors.error)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "$comparisonText  ${isPositive ? '↑↑' : '↓↓'}",
                  textAlign: TextAlign.center,
                  style: TextStyles.customStyle(
                    fontSize: isDesktop ? 18 : 15,
                    fontWeight: FontWeight.bold,
                    color: isPositive
                        ? AppColors.primaryColor
                        : AppColors.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
