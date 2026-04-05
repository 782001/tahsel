import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

class LanguageInfoBox extends StatelessWidget {
  const LanguageInfoBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.primaryColor, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              AppStrings.languageChangeInfo.tr(),
              style: TextStyles.customStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.sandText,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
