import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class LogoutConfirmationDialog extends StatelessWidget {
  const LogoutConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),

        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 20.r),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: _buildDialogContent(context),
        ),
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Container(
      width: isDesktop ? 420 : null,
      padding: EdgeInsets.all(isDesktop ? 32 : 20.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20.0,
            offset: const Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 24 : 16.w),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: isDesktop ? 48 : 40,
            ),
          ),
          (isDesktop ? 24 : 20).verticalSpace,
          Text(
            AppStrings.logoutAppTitle.tr(),
            style: TextStyles.customStyle(
              fontSize: isDesktop ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          (isDesktop ? 16 : 12).verticalSpace,
          Text(
            AppStrings.logoutAppMessage.tr(),
            textAlign: TextAlign.center,
            style: TextStyles.customStyle(
              fontSize: isDesktop ? 16 : 14,
              fontWeight: FontWeight.normal,
              color: AppColors.blackLight,
            ),
          ),
          (isDesktop ? 40 : 30).verticalSpace,
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isDesktop ? 18 : 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        isDesktop ? 12 : 12.r,
                      ),
                      side: BorderSide(color: AppColors.veryLightGrey),
                    ),
                  ),
                  child: Text(
                    AppStrings.cancel.tr(),
                    style: TextStyles.customStyle(
                      fontSize: isDesktop ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blackLight,
                    ),
                  ),
                ),
              ),
              (isDesktop ? 20 : 16).horizontalSpace,
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: EdgeInsets.symmetric(
                      vertical: isDesktop ? 18 : 12.h,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        isDesktop ? 12 : 12.r,
                      ),
                    ),
                  ),
                  child: Text(
                    AppStrings.confirm.tr(),
                    style: TextStyles.customStyle(
                      fontSize: isDesktop ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
