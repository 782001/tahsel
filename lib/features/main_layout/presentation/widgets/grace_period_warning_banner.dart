// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/whatsapp_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class GracePeriodWarningBanner extends StatelessWidget {
  const GracePeriodWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = AppStrings.userToken;
    if (uid.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data();
        if (data == null) return const SizedBox.shrink();

        final subscriptionEnd = data['subscriptionEnd'] != null
            ? (data['subscriptionEnd'] as Timestamp).toDate()
            : null;

        if (subscriptionEnd == null) return const SizedBox.shrink();

        final now = DateTime.now();
        // If not expired yet, don't show the warning banner
        if (now.isBefore(subscriptionEnd)) return const SizedBox.shrink();

        final gracePeriodEnd = subscriptionEnd.add(const Duration(days: 10));
        // If past grace period, the app will redirect to the expired screen on startup/reload
        if (now.isAfter(gracePeriodEnd)) return const SizedBox.shrink();

        // Calculate remaining grace period days
        final remainingGraceDays = gracePeriodEnd.difference(now).inDays;
        final displayDays = remainingGraceDays < 0 ? 0 : remainingGraceDays;
        final isDesktop = ResponsiveLayout.isDesktop(context);
        return Material(
          elevation: 2,
          color: AppColors.warning,
          child: InkWell(
            onTap: () async {
              final success = await WhatsAppService.sendMessage(
                phoneNumber: AppStrings.supportPhoneNumber,
                message: "مرحبا اريد تجديد الحساب في برنامج تحصيل",
              );
              if (!success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppStrings.whatsappNotInstalled.tr())),
                );
              }
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 16 : 16.w,
                vertical: isDesktop ? 12 : 12.h,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: isDesktop ? 24 : 24 
                  ),
                  SizedBox(width: isDesktop ? 12 : 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'banner_subscription_expired'.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: isDesktop ? 2 : 2.h),
                        Text(
                          'banner_grace_body'.tr().replaceAll(
                            '{days}',
                            '$displayDays',
                          ),
                          style: TextStyles.customStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isDesktop ? 8 : 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 12 : 12.w,
                      vertical: isDesktop ? 6 : 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(
                        isDesktop ? 12 : 20.r,
                      ),
                    ),
                    child: Text(
                      'banner_renew'.tr(),
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 14 : 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
