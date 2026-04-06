import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/shared/widgets/buttons/theme_toggle_button.dart';
import 'package:tahsel/shared/widgets/fields/text_widget.dart';

class ErrorScreen extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const ErrorScreen({super.key, required this.errorDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
    
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 80.h,
                color: AppColors.redColor,
              ),
              SizedBox(height: 24.h),
              TextWidget(
                AppStrings.errorScreenTitle.tr(),
                style: TextStyles.font28WeightBoldWhite().copyWith(
                  color: AppColors.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.h),
                  decoration: BoxDecoration(
                    color: AppColors.cardCustomer,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.redColor.withOpacity(0.3),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          AppStrings.errorScreenDetailsLabel.tr(),
                          style: TextStyles.font16WeightBoldText(),
                        ),
                        SizedBox(height: 8.h),
                        SelectableText(
                          errorDetails.toString(),
                          style: TextStyles.font14Weight400RightAligned()
                              .copyWith(color: AppColors.textColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () {
                  // You might want to restart the app or navigate back
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: 48.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: TextWidget(
                  AppStrings.errorScreenGoBackButton.tr(),
                  style: TextStyles.font18Weight500White(),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
