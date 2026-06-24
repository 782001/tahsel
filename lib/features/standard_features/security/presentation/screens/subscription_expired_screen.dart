import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/whatsapp_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/auth/presentation/cubit/auth_cubit.dart';

/// Data container passed as route arguments to [SubscriptionExpiredScreen].
class SubscriptionExpiredArgs {
  final String accountStatus;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final DateTime? gracePeriodEnd;
  final String email;
  final String fullName;

  const SubscriptionExpiredArgs({
    required this.accountStatus,
    this.subscriptionStart,
    this.subscriptionEnd,
    this.gracePeriodEnd,
    required this.email,
    required this.fullName,
  });
}

class SubscriptionExpiredScreen extends StatelessWidget {
  final SubscriptionExpiredArgs args;

  const SubscriptionExpiredScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveLayout.isDesktop(context);
    final String dateFormat = 'dd/MM/yyyy';
    final df = DateFormat(dateFormat);

    String fmt(DateTime? d) =>
        d != null ? df.format(d) : AppStrings.notSet.tr();

    final double maxW = isDesktop ? 520 : double.infinity;
    final double hPad = isDesktop ? 48 : 28.w;
    final double vPad = isDesktop ? 48 : 40.h;

    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Icon ────────────────────────────────────────────────────
                  Container(
                    width: isDesktop ? 110 : 110.w,
                    height: isDesktop ? 110 : 110.w,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.timer_off_rounded,
                      size: isDesktop ? 56 : 56.sp,
                      color: AppColors.error,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 28 : 28.h),

                  // ── Title ────────────────────────────────────────────────────
                  Text(
                    AppStrings.subscriptionExpiredTitle.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isDesktop ? 8 : 8.h),
                  Text(
                    AppStrings.gracePeriodEnded.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.sandText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isDesktop ? 6 : 6.h),
                  Text(
                    AppStrings.renewToContinue.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.disabledColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isDesktop ? 32 : 32.h),

                  // ── Info Card ───────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isDesktop ? 24 : 20.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        isDesktop ? 16 : 16.r,
                      ),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.shield_outlined,
                          label: AppStrings.accountStatus.tr(),
                          value: _localizedStatus(args.accountStatus),
                          valueColor: _statusColor(args.accountStatus),
                          isDesktop: isDesktop,
                        ),
                        _divider(isDesktop),
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: AppStrings.subscriptionStart.tr(),
                          value: fmt(args.subscriptionStart),
                          isDesktop: isDesktop,
                        ),
                        _divider(isDesktop),
                        _InfoRow(
                          icon: Icons.event_outlined,
                          label: AppStrings.subscriptionEnd.tr(),
                          value: fmt(args.subscriptionEnd),
                          valueColor: AppColors.warning,
                          isDesktop: isDesktop,
                        ),
                        _divider(isDesktop),
                        _InfoRow(
                          icon: Icons.hourglass_empty_rounded,
                          label: AppStrings.gracePeriodEnd.tr(),
                          value: fmt(args.gracePeriodEnd),
                          valueColor: AppColors.error,
                          isDesktop: isDesktop,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isDesktop ? 36 : 36.h),

                  // ── Renew Button ────────────────────────────────────────────
                  SizedBox(
                    width: isDesktop ? 320 : double.infinity,
                    height: isDesktop ? 52 : 52.h,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final success = await WhatsAppService.sendMessage(
                          phoneNumber: AppStrings.supportPhoneNumber,
                          message:
                              "مرحبا اريد تجديد الحساب في برنامج تحصيل\n ${fmt(args.subscriptionStart)}  ${fmt(args.subscriptionEnd)} ${fmt(args.gracePeriodEnd)} \nودا الايميل الخاص بيا ${args.email} \nودا الاسم الخاص بيا ${args.fullName} \n",
                        );
                        // ignore_for_file: use_build_context_synchronously

                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppStrings.whatsappNotInstalled.tr(),
                              ),
                            ),
                          );
                        }
                      },
                      icon: Image.asset(
                        Assets.imagesWhatsapp,
                        width: isDesktop ? 25 : 25.w,
                        height: isDesktop ? 25 : 25.w,
                      ),
                      label: Text(
                        AppStrings.renewSubscription.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isDesktop ? 12 : 12.r,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isDesktop ? 16 : 16.h),

                  // ── Logout Button ───────────────────────────────────────────
                  SizedBox(
                    width: isDesktop ? 320 : double.infinity,
                    height: isDesktop ? 48 : 48.h,
                    child: OutlinedButton.icon(
                      onPressed: () => context.read<AuthCubit>().logout(),
                      icon: Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color: AppColors.error,
                      ),
                      label: Text(
                        AppStrings.logout.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.error, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isDesktop ? 12 : 12.r,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider(bool isDesktop) => Divider(
    color: AppColors.dividerColor,
    height: isDesktop ? 24 : 20.h,
    thickness: 0.5,
  );

  String _localizedStatus(String status) {
    switch (status) {
      case 'active':
        return 'status_active'.tr();
      case 'suspended':
        return 'status_suspended'.tr();
      case 'expired':
        return 'status_expired'.tr();
      case 'inactive':
        return 'status_inactive'.tr();
      case 'deleted':
        return 'status_deleted'.tr();
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'suspended':
        return AppColors.warning;
      case 'expired':
      case 'inactive':
      case 'deleted':
        return AppColors.error;
      default:
        return AppColors.sandText;
    }
  }
}

// ── Reusable info row ─────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDesktop;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: isDesktop ? 20 : 18.sp,
          color: AppColors.primaryColor.withValues(alpha: 0.7),
        ),
        SizedBox(width: isDesktop ? 12 : 10.w),
        Expanded(
          child: Text(
            label,
            style: TextStyles.customStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.sandText,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyles.customStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textColor,
          ),
        ),
      ],
    );
  }
}
