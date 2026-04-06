import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

class ReportsOperationalMarginCard extends StatelessWidget {
  final String amount;
  final double margin;

  const ReportsOperationalMarginCard({
    super.key,
    required this.amount,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: AppColors.stitchSurfaceLow.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.netProfit.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blackLight.withOpacity(0.5),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "$amount ${AppStrings.currencyEgp.tr()}",
                    style: TextStyles.customStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppStrings.operationalMargin.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blackLight.withOpacity(0.5),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "${(margin * 100).toInt()}%",
                    style: TextStyles.customStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: margin,
              minHeight: 8.h,
              backgroundColor: AppColors.whiteColor,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
