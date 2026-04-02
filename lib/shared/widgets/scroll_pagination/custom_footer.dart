import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/services/translation_helper.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/shared/widgets/fields/text_widget.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class CustomFooterWidget extends StatelessWidget {
  const CustomFooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomFooter(
      height: 40.h,
      builder: (context, mode) {
        var body = '';
        if (mode == LoadStatus.idle) {
          body = Loc.tr(context, AppStrings.swipe_down);
        } else if (mode == LoadStatus.loading) {
          return Padding(
            padding: EdgeInsets.only(top: 5.h, bottom: 30.h),
            child: CupertinoActivityIndicator(color: AppColors.primaryColor),
          );
        } else if (mode == LoadStatus.failed) {
          body = Loc.tr(context, AppStrings.download_failed);
        } else if (mode == LoadStatus.canLoading) {
          body = Loc.tr(context, AppStrings.slide_to_load_more);
        } else {
          body = '';
        }

        return Center(
          child: Padding(
            padding: EdgeInsets.only(top: 5.h, bottom: 30.h),
            child: TextWidget(
              body,
              style: TextStyle(color: AppColors.blackLight, fontSize: 14.sp),
            ),
          ),
        );
      },
    );
  }
}
