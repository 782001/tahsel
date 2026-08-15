// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/whatsapp_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class SubscriptionInfoWidget extends StatefulWidget {
  const SubscriptionInfoWidget({super.key});

  @override
  State<SubscriptionInfoWidget> createState() => _SubscriptionInfoWidgetState();
}

class _SubscriptionInfoWidgetState extends State<SubscriptionInfoWidget> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionData();
  }

  Future<void> _fetchSubscriptionData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String uid = AppStrings.userToken;
      if (uid.isEmpty) {
        throw Exception('User UID is empty');
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists) {
        throw Exception('User document not found');
      }

      if (mounted) {
        final data = doc.data();
        if (data != null) {
          AppStrings.isVip = (data['isVip'] as bool?) ?? false;
        }
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    if (_isLoading) {
      return Card(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 20 : 20.w),
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null || _userData == null) {
      return Card(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 20 : 20.w),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: isDesktop ? 40 : 40.w,
              ),
              SizedBox(height: isDesktop ? 12 : 12.h),
              Text(
                'could_not_load_subscription'.tr(),
                style: TextStyles.customStyle(
                  fontSize: isDesktop ? 14 : 14,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isDesktop ? 12 : 12.h),
              TextButton.icon(
                onPressed: _fetchSubscriptionData,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('retry'.tr()),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final data = _userData!;

    // Extract raw fields
    final isVip = (data['isVip'] as bool?) ?? false;
    final accountStatus = (data['accountStatus'] as String?) ?? 'active';
    final userType = (data['userType'] as String?) ?? 'cafe';
    final platformType = (data['platformType'] as String?) ?? 'mobile';

    final subscriptionStart = data['subscriptionStart'] != null
        ? (data['subscriptionStart'] as Timestamp).toDate()
        : null;
    final subscriptionEnd = data['subscriptionEnd'] != null
        ? (data['subscriptionEnd'] as Timestamp).toDate()
        : null;
    final email = data['email'] as String? ?? '';
    final fullName = data['fullName'] as String? ?? '';

    final now = DateTime.now();

    // Calculate dates
    DateTime? gracePeriodEnd;
    if (subscriptionEnd != null) {
      gracePeriodEnd = subscriptionEnd.add(const Duration(days: 10));
    }

    // Determine status
    String subStatus = 'status_active';
    Color statusColor = AppColors.success;
    if (subscriptionEnd != null) {
      if (now.isAfter(subscriptionEnd)) {
        if (gracePeriodEnd != null && now.isBefore(gracePeriodEnd)) {
          subStatus = 'status_expired'; // within grace period
          statusColor = AppColors.warning;
        } else {
          subStatus = 'status_expired'; // fully expired
          statusColor = AppColors.error;
        }
      }
    }

    // Calculate Remaining Days
    int remainingSubscriptionDays = 0;
    if (subscriptionEnd != null) {
      remainingSubscriptionDays = subscriptionEnd.difference(now).inDays;
      if (remainingSubscriptionDays < 0) remainingSubscriptionDays = 0;
    }

    int remainingGraceDays = 0;
    if (gracePeriodEnd != null &&
        subscriptionEnd != null &&
        now.isAfter(subscriptionEnd)) {
      remainingGraceDays = gracePeriodEnd.difference(now).inDays;
      if (remainingGraceDays < 0) remainingGraceDays = 0;
    }

    // Format Dates
    final df = DateFormat('dd/MM/yyyy');
    String fmtDate(DateTime? d) =>
        d != null ? df.format(d) : AppStrings.notSet.tr();

    return Card(
      color: isDark ? AppColors.surface : AppColors.whiteColor,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: AppColors.veryLightGrey),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 32 : 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.card_membership_rounded,
                  color: AppColors.primaryColor,
                  size: isDesktop ? 22 : 22,
                ),
                SizedBox(width: isDesktop ? 8 : 8.w),
                Text(
                  AppStrings.subscriptionSection.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const Spacer(),
                // VIP Badge Chip
                if (isVip)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 8 : 8.w,
                      vertical: isDesktop ? 4 : 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: isVip
                          ? AppColors.vipGoldStart.withValues(alpha: 0.15)
                          : AppColors.dividerColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20.r),
                      border: isVip
                          ? Border.all(
                              color: AppColors.vipGoldStart.withValues(
                                alpha: 0.5,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVip
                              ? Icons.workspace_premium_rounded
                              : Icons.star_border_rounded,
                          size: isDesktop ? 14 : 14,
                          color: isVip
                              ? AppColors.vipGoldStart
                              : AppColors.sandText,
                        ),
                        SizedBox(width: 4.w),
                        if (isVip)
                          Text(
                            'VIP',
                            style: TextStyles.customStyle(
                              fontSize: isDesktop ? 13 : 12,
                              fontWeight: FontWeight.bold,
                              color: isVip
                                  ? AppColors.vipGoldStart
                                  : AppColors.sandText,
                            ),
                          ),
                      ],
                    ),
                  ),
                SizedBox(width: isDesktop ? 8 : 6.w),
                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 12 : 12.w,
                    vertical: isDesktop ? 6 : 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    subStatus.tr(),
                    style: TextStyles.customStyle(
                      fontSize: isDesktop ? 13 : 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 32 : 20.h),

            // Rows
            _buildDetailRow(
              icon: Icons.workspace_premium_rounded,
              label: AppStrings.vipAccount.tr(),
              value: isVip ? 'VIP ✨' : 'Standard',
              valueColor: isVip ? AppColors.vipGoldStart : AppColors.sandText,
              isDesktop: isDesktop,
            ),
            _buildDivider(),
            _buildDetailRow(
              icon: Icons.shield_outlined,
              label: AppStrings.accountStatus.tr(),
              value: _localizedAccountStatus(accountStatus),
              valueColor: _accountStatusColor(accountStatus),
              isDesktop: isDesktop,
            ),
            _buildDivider(),
            _buildDetailRow(
              icon: Icons.storefront_rounded,
              label: AppStrings.userTypeLabel.tr(),
              value: _localizedUserType(userType),
              isDesktop: isDesktop,
            ),
            _buildDivider(),
            _buildDetailRow(
              icon: Icons.devices_rounded,
              label: AppStrings.platformTypeLabel.tr(),
              value: _localizedPlatformType(platformType),
              isDesktop: isDesktop,
            ),
            _buildDivider(),
            _buildDetailRow(
              icon: Icons.date_range_outlined,
              label: AppStrings.subscriptionStart.tr(),
              value: fmtDate(subscriptionStart),
              isDesktop: isDesktop,
            ),
            _buildDivider(),
            _buildDetailRow(
              icon: Icons.event_busy_outlined,
              label: AppStrings.subscriptionEnd.tr(),
              value: fmtDate(subscriptionEnd),
              valueColor: now.isAfter(subscriptionEnd ?? now)
                  ? AppColors.error
                  : null,
              isDesktop: isDesktop,
            ),
            _buildDivider(),
            _buildDetailRow(
              icon: Icons.hourglass_bottom_rounded,
              label: AppStrings.gracePeriodEnd.tr(),
              value: fmtDate(gracePeriodEnd),
              valueColor: AppColors.error,
              isDesktop: isDesktop,
            ),
            _buildDivider(),
            _buildDetailRow(
              icon: Icons.timelapse_rounded,
              label: AppStrings.remainingDays.tr(),
              value: '$remainingSubscriptionDays ${AppStrings.days.tr()}',
              valueColor: remainingSubscriptionDays <= 5
                  ? AppColors.warning
                  : AppColors.success,
              isDesktop: isDesktop,
            ),
            if (subscriptionEnd != null && now.isAfter(subscriptionEnd)) ...[
              _buildDivider(),
              _buildDetailRow(
                icon: Icons.warning_amber_rounded,
                label: AppStrings.graceDaysRemaining.tr(),
                // ignore: prefer_interpolation_to_compose_strings
                value: '$remainingGraceDays ${AppStrings.days.tr()}',
                valueColor: AppColors.error,
                isDesktop: isDesktop,
              ),
            ],

            SizedBox(height: isDesktop ? 32 : 24.h),

            // WhatsApp Renewal Button
            SizedBox(
              width: double.infinity,
              height: isDesktop ? 60 : 48.h,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final success = await WhatsAppService.sendMessage(
                    phoneNumber: AppStrings.supportPhoneNumber,
                    message:
                        "مرحبا اريد تجديد الحساب في برنامج تحصيل\n ودا الايميل بتاعي  : $email\n ودا الاسم بتاعي $fullName",
                  );
                  if (mounted && !success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppStrings.whatsappNotInstalled.tr()),
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
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required bool isDesktop,
  }) {
    return Row(
      children: [
        Icon(icon, size: isDesktop ? 18 : 18, color: AppColors.sandText),
        SizedBox(width: isDesktop ? 12 : 10.w),
        Text(
          label,
          style: TextStyles.customStyle(
            fontSize: isDesktop ? 16 : 14,
            fontWeight: FontWeight.w500,
            color: AppColors.sandText,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyles.customStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.blackReal,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(color: AppColors.veryLightGrey, height: 20, thickness: 0.8);
  }

  String _localizedAccountStatus(String status) {
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

  Color _accountStatusColor(String status) {
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

  String _localizedUserType(String type) {
    switch (type) {
      case 'cafe':
        return 'type_cafe'.tr();
      case 'shop':
        return 'type_shop'.tr();
      default:
        return type;
    }
  }

  String _localizedPlatformType(String platform) {
    switch (platform) {
      case 'mobile':
        return 'platform_mobile'.tr();
      case 'desktop':
        return 'platform_desktop'.tr();
      case 'both':
        return 'platform_both'.tr();
      default:
        return platform;
    }
  }
}
