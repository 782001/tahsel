import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/translation_helper.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/shared/widgets/fields/text_widget.dart';
import 'package:tahsel/shared/widgets/buttons/theme_toggle_button.dart';

class SecurityWarningScreen extends StatelessWidget {
  final bool isRooted;
  final bool isDevMode;

  const SecurityWarningScreen({
    super.key,
    required this.isRooted,
    required this.isDevMode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [ThemeToggleButton()],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security_update_warning_rounded,
                size: 100.h,
                color: AppColors.redColor,
              ),
              SizedBox(height: 32.h),
              TextWidget(
                 AppStrings.securityWarningTitle.tr(),
                style: TextStyles.font28WeightBoldWhite().copyWith(
                  color: AppColors.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              TextWidget(
                 AppStrings.securityWarningDescription.tr(),
                style: TextStyles.font16Weight400Text(),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40.h),
              Container(
                padding: EdgeInsets.all(20.h),
                decoration: BoxDecoration(
                  color: AppColors.cardCustomer,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (isRooted)
                      _buildConditionItem(
                        context,
                        icon: Icons.dangerous_rounded,
                        title: Loc.tr(
                          context,
                          AppStrings.securityWarningRootedTitle,
                        ),
                        subtitle: Loc.tr(
                          context,
                          AppStrings.securityWarningRootedSubtitle,
                        ),
                      ),
                    if (isRooted && isDevMode) Divider(height: 32.h),
                    if (isDevMode)
                      _buildConditionItem(
                        context,
                        icon: Icons.developer_mode_rounded,
                        title: Loc.tr(
                          context,
                          AppStrings.securityWarningDevModeTitle,
                        ),
                        subtitle: Loc.tr(
                          context,
                          AppStrings.securityWarningDevModeSubtitle,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 48.h),
              TextWidget(
                 AppStrings.securityWarningFooter.tr(),
                style: TextStyles.font14Weight400RightAligned().copyWith(
                  color: AppColors.textColor2.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConditionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.redColor, size: 32.h),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(title, style: TextStyles.font16WeightBoldText()),
              SizedBox(height: 4.h),
              TextWidget(
                subtitle,
                style: TextStyles.font14Weight400RightAligned().copyWith(
                  color: AppColors.textColor2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
