import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/whatsapp_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/routes/app_routes.dart';

/// The reason why access was restricted, determines the icon & body text.
enum AccessRestrictionReason {
  suspended,
  expired,
  platformNotAllowed,
  disabled,
}

class AccessRestrictedScreen extends StatelessWidget {
  final AccessRestrictionReason reason;

  const AccessRestrictedScreen({super.key, required this.reason});

  // ── Strings ───────────────────────────────────────────────────────────────

  String get _title => 'access_restricted_title'.tr();

  String get _body {
    switch (reason) {
      case AccessRestrictionReason.suspended:
        return 'access_restricted_suspended_body'.tr();
      case AccessRestrictionReason.expired:
        return 'access_restricted_expired_body'.tr();
      case AccessRestrictionReason.platformNotAllowed:
        return 'access_restricted_platform_body'.tr();
      case AccessRestrictionReason.disabled:
        return 'access_restricted_disabled_body'.tr();
    }
  }

  IconData get _icon {
    switch (reason) {
      case AccessRestrictionReason.suspended:
        return Icons.pause_circle_outline_rounded;
      case AccessRestrictionReason.expired:
        return Icons.timer_off_rounded;
      case AccessRestrictionReason.platformNotAllowed:
        return Icons.devices_other_rounded;
      case AccessRestrictionReason.disabled:
        return Icons.block_rounded;
    }
  }

  Color _iconColor(BuildContext context) {
    switch (reason) {
      case AccessRestrictionReason.suspended:
        return Colors.orange;
      case AccessRestrictionReason.expired:
        return Colors.deepOrange;
      case AccessRestrictionReason.platformNotAllowed:
        return Colors.blue;
      case AccessRestrictionReason.disabled:
        return AppColors.redColor;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveLayout.isDesktop(context);
    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 28 : 28.w,
              vertical: isDesktop ? 40 : 40.h,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Icon ────────────────────────────────────────────────────
                Container(
                  width: isDesktop ? 120 : 120.w,
                  height: isDesktop ? 120 : 120.w,
                  decoration: BoxDecoration(
                    color: _iconColor(context).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _icon,
                    size: isDesktop ? 64 : 64.sp,
                    color: _iconColor(context),
                  ),
                ),
                SizedBox(height: isDesktop ? 32 : 32.h),

                // ── Title ────────────────────────────────────────────────────
                Text(
                  _title,
                  style: TextStyles.font28WeightBoldWhite().copyWith(
                    color: AppColors.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isDesktop ? 16 : 16.h),

                // ── Body ─────────────────────────────────────────────────────
                Container(
                  padding: EdgeInsets.all(isDesktop ? 20 : 20.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: AppColors.isDark ? 0.3 : 0.05,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _body,
                    style: TextStyles.font16Weight400Text().copyWith(
                      color: AppColors.subTitleColor,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: isDesktop ? 32 : 40.h),

                // ── Contact Support Button ───────────────────────────────────
                SizedBox(
                  width: isDesktop ? 300 : double.infinity,
                  height: isDesktop ? 52 : 52.h,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final success = await WhatsAppService.sendMessage(
                        phoneNumber: AppStrings.supportPhoneNumber,
                        message: "مرحبا اريد تجديد الاشتراك في برنامج تحصيل",
                      );// ignore_for_file: use_build_context_synchronously

                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.whatsappNotInstalled.tr()),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.support_agent_rounded),
                    label: Text(
                      'access_restricted_contact'.tr(),
                      style: TextStyles.font16WeightBoldText().copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isDesktop ? 16 : 16.h),

                // ── Back to Login ────────────────────────────────────────────
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => false,
                    );
                  },
                  child: Text(
                    'logout'.tr(),
                    style: TextStyles.font14Weight400RightAligned().copyWith(
                      color: AppColors.disabledColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
