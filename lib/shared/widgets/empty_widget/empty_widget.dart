import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/services/translation_helper.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_constants.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/shared/widgets/fields/text_widget.dart';

class EmptyWidget extends StatelessWidget {
  const EmptyWidget({super.key, this.topHeight, this.subTitle, this.title});

  final double? topHeight;

  final String? subTitle;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.appHorizontalPadding,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: topHeight, width: double.infinity),
            SizedBox(height: 24.h),
            TextWidget(
              title ?? Loc.tr(context, AppStrings.no_data),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.blackLight,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            TextWidget(
              subTitle ?? Loc.tr(context, AppStrings.sorry_no_data),
              style: TextStyle(color: AppColors.blackLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
