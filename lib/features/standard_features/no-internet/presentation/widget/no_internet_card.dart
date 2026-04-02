import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/services/translation_helper.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/shared/widgets/fields/text_widget.dart';

import '../../../../../core/utils/styles.dart';
import '../../../../../shared/widgets/buttons/custom_button.dart';

class NoInternetCard extends StatelessWidget {
  final Animation<Color?> colorAnimation;
  final bool isChecking;
  final VoidCallback onRetry;

  const NoInternetCard({
    super.key,
    required this.colorAnimation,
    required this.isChecking,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300.w,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(Assets.imagesAppLogo, width: 90.w, height: 90.w),
          SizedBox(height: 20.h),
          AnimatedBuilder(
            animation: colorAnimation,
            builder: (context, _) => TextWidget(
              Loc.tr(context, "noInternetTitle"),
              style: TextStyles.appbartext().copyWith(
                color: colorAnimation.value,
                fontWeight: FontWeight.w600,
                fontSize: 22,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          TextWidget(
            Loc.tr(context, "noInternetDescription"),
            textAlign: TextAlign.center,
            style: TextStyles.font14Weight400RightAligned().copyWith(
              color: const Color(0xFF616161),
              height: 1.5,
            ),
          ),
          SizedBox(height: 28.h),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isChecking
                ? SizedBox(
                    key: const ValueKey('loading'),
                    width: 40.w,
                    height: 40.w,
                    child: const CupertinoActivityIndicator(),
                  )
                : CustomButton(
                    key: const ValueKey('retry'),
                    text: Loc.tr(context, "tryAgain"),
                    height: 48.h,
                    width: 200.w,
                    onPressed: onRetry,
                  ),
          ),
        ],
      ),
    );
  }
}
