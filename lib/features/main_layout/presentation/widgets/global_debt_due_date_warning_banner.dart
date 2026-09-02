import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';

class GlobalDebtDueDateWarningBanner extends StatefulWidget {
  const GlobalDebtDueDateWarningBanner({super.key});

  @override
  State<GlobalDebtDueDateWarningBanner> createState() =>
      _GlobalDebtDueDateWarningBannerState();
}

class _GlobalDebtDueDateWarningBannerState
    extends State<GlobalDebtDueDateWarningBanner> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    final String uid = AppStrings.userToken;
    if (uid.isEmpty || _isDismissed) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final alertThreshold = today.add(const Duration(days: 4)); // In the next 3 days (inclusive)

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('debts')
          .where('isPaid', isEqualTo: false)
          .where(
            'dueDate',
            isLessThanOrEqualTo: Timestamp.fromDate(alertThreshold),
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Map customer name -> list of due debts
        final Map<String, List<Map<String, dynamic>>> dueDebtsByCustomer = {};
        bool hasOverdue = false;
        double totalDueAmount = 0;

        for (final doc in snapshot.data!.docs) {
          final data = doc.data();
          final remaining = (data['remainingAmount'] ?? data['remainingDebt'] ?? 0.0) as num;
          if (remaining <= 0) continue;

          DateTime? dueDate;
          final dueDateRaw = data['dueDate'];
          if (dueDateRaw is Timestamp) {
            dueDate = dueDateRaw.toDate();
          } else if (dueDateRaw is String) {
            dueDate = DateTime.tryParse(dueDateRaw);
          }
          if (dueDate == null) continue;

          final dueNormalized = DateTime(dueDate.year, dueDate.month, dueDate.day);

          if (!dueNormalized.isBefore(alertThreshold)) continue;

          // Check if already reminded in this cycle
          DateTime? lastReminder;
          final lastReminderRaw = data['lastReminderSentAt'];
          if (lastReminderRaw is Timestamp) {
            lastReminder = lastReminderRaw.toDate();
          } else if (lastReminderRaw is String) {
            lastReminder = DateTime.tryParse(lastReminderRaw);
          }

          if (lastReminder != null) {
            final alertWindowStart =
                dueNormalized.subtract(const Duration(days: 3));
            if (lastReminder.isAfter(alertWindowStart)) {
              continue;
            }
          }

          final customerName = (data['customerName'] as String?)?.trim() ?? 'عميل';
          dueDebtsByCustomer.putIfAbsent(customerName, () => []).add(data);
          totalDueAmount += remaining.toDouble();

          if (today.isAfter(dueNormalized)) {
            hasOverdue = true;
          }
        }

        if (dueDebtsByCustomer.isEmpty) {
          return const SizedBox.shrink();
        }

        final isDesktop = ResponsiveLayout.isDesktop(context);
        final customerCount = dueDebtsByCustomer.length;
        final isSingleCustomer = customerCount == 1;

        String bannerText;
        if (isSingleCustomer) {
          final customerName = dueDebtsByCustomer.keys.first;
          final statusText = hasOverdue ? "(متأخر)" : "(مستحق)";
          bannerText = AppStrings.globalDueBannerSingle
              .tr()
              .replaceAll('{customer}', customerName)
              .replaceAll('{amount}', totalDueAmount.toSmartAmount())
              .replaceAll('{status}', statusText);
        } else {
          bannerText = AppStrings.globalDueBannerMultiple
              .tr()
              .replaceAll('{count}', '$customerCount')
              .replaceAll('{amount}', totalDueAmount.toSmartAmount());
        }

        final gradientColors = hasOverdue
            ? [
                AppColors.error,
                const Color(0xFFC0392B),
              ]
            : [
                const Color(0xFFE67E22),
                const Color(0xFFD35400),
              ];

        return Material(
          elevation: 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 20 : 14.w,
              vertical: isDesktop ? 10 : 10.h,
            ),
            child: Row(
              children: [
                Icon(
                  hasOverdue
                      ? Icons.notification_important_rounded
                      : Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: isDesktop ? 22 : 20.r,
                ),
                SizedBox(width: isDesktop ? 10 : 8.w),
                Expanded(
                  child: Text(
                    bannerText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.customStyle(
                      fontSize: isDesktop ? 13 : 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: isDesktop ? 10 : 8.w),
                InkWell(
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 20.r),
                  onTap: () {
                    // Navigate to debts tab in main layout
                    context.read<MainLayoutCubit>().changeBottomNav(2);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 12 : 10.w,
                      vertical: isDesktop ? 6 : 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(
                        isDesktop ? 12 : 20.r,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.viewAndRemind.tr(),
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 12 : 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isDismissed = true;
                    });
                  },
                  borderRadius: BorderRadius.circular(20.r),
                  child: Padding(
                    padding: EdgeInsets.all(4.r),
                    child: Icon(
                      Icons.close_rounded,
                      size: isDesktop ? 18 : 16.r,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
