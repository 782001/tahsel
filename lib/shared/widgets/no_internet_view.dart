import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';

class NoInternetView extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoInternetView({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 80.sp,
                color: AppColors.error.withValues(alpha: 0.8),
              ),
            ),
            24.verticalSpace,
            Text(
              "noInternetTitle".tr(),
              style: TextStyles.customStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            12.verticalSpace,
            Text(
              "noInternetDescription".tr(),
              style: TextStyles.customStyle(
                fontSize: 14.sp,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,

                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            // if (onRetry != null) ...[
            // 32.verticalSpace,
            // SizedBox(
            //   width: 180.w,
            //   child: ElevatedButton(
            //     onPressed: onRetry,
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: AppColors.primaryColor,
            //       foregroundColor: Colors.white,
            //       padding: EdgeInsets.symmetric(vertical: 12.h),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(12.r),
            //       ),
            //       elevation: 0,
            //     ),
            //     child: Text(
            //       "tryAgain".tr(),
            //       style: TextStyles.customStyle(
            //         fontSize: 16.sp,
            //         fontWeight: FontWeight.bold,
            //         color: Colors.white,
            //       ),
            //     ),
            //   ),
            // ),

            // ],
          ],
        ),
      ),
    );
  }
}
