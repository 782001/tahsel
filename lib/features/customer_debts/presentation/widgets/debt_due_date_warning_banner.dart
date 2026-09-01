import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/customer_debts/data/models/debt_item_model.dart';

class DebtDueDateWarningBanner extends StatelessWidget {
  final DebtItem debtItem;
  final int dueDebtsCount;
  final VoidCallback onRemindTap;
  final VoidCallback? onDismiss;

  const DebtDueDateWarningBanner({
    super.key,
    required this.debtItem,
    this.dueDebtsCount = 1,
    required this.onRemindTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (debtItem.dueDate == null) return const SizedBox.shrink();

    final due = debtItem.dueDate!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);

    final isArabic = AppStrings.currentLang == 'ar';
    String dateStr;
    try {
      dateStr = DateFormat('EEEE yyyy/MM/dd', isArabic ? 'ar' : 'en').format(due);
    } catch (_) {
      dateStr = DateFormat('yyyy/MM/dd').format(due);
    }

    String bannerText;
    final isOverdue = today.isAfter(dueDay);
    final isToday = today.isAtSameMomentAs(dueDay);
    final isTomorrow = dueDay.difference(today).inDays == 1;

    final isMultiple = dueDebtsCount > 1;

    if (isOverdue) {
      final template = isMultiple
          ? AppStrings.dueDateOverdueBannerMultiple.tr()
          : AppStrings.dueDateOverdueBanner.tr();
      bannerText = template
          .replaceAll('{count}', '$dueDebtsCount')
          .replaceAll('{date}', dateStr);
    } else if (isToday) {
      final template = isMultiple
          ? AppStrings.dueDateTodayBannerMultiple.tr()
          : AppStrings.dueDateTodayBanner.tr();
      bannerText = template
          .replaceAll('{count}', '$dueDebtsCount')
          .replaceAll('{date}', dateStr);
    } else if (isTomorrow) {
      final template = isMultiple
          ? AppStrings.dueDateTomorrowBannerMultiple.tr()
          : AppStrings.dueDateTomorrowBanner.tr();
      bannerText = template
          .replaceAll('{count}', '$dueDebtsCount')
          .replaceAll('{date}', dateStr);
    } else {
      final template = isMultiple
          ? AppStrings.dueDateUpcomingBannerMultiple.tr()
          : AppStrings.dueDateUpcomingBanner.tr();
      bannerText = template
          .replaceAll('{count}', '$dueDebtsCount')
          .replaceAll('{date}', dateStr);
    }

    final isDesktop = ResponsiveLayout.isDesktop(context);
    final gradientColors = isOverdue
        ? [AppColors.error, const Color(0xFFC0392B)]
        : [const Color(0xFFE67E22), const Color(0xFFD35400)];

    return Material(
      elevation: 2,
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
          horizontal: isDesktop ? 24 : 16.w,
          vertical: isDesktop ? 12 : 12.h,
        ),
        child: Row(
          children: [
            Icon(
              isOverdue
                  ? Icons.notification_important_rounded
                  : Icons.warning_amber_rounded,
              color: Colors.white,
              size: isDesktop ? 24 : 22.r,
            ),
            SizedBox(width: isDesktop ? 12 : 10.w),
            Expanded(
              child: Text(
                bannerText,
                style: TextStyles.customStyle(
                  fontSize: isDesktop ? 14 : 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: isDesktop ? 10 : 8.w),
            InkWell(
              borderRadius: BorderRadius.circular(isDesktop ? 12 : 20.r),
              onTap: onRemindTap,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 14 : 12.w,
                  vertical: isDesktop ? 8 : 6.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 20.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_active_rounded,
                      size: isDesktop ? 16 : 14.r,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      AppStrings.remindPayment.tr(),
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 13 : 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onDismiss != null) ...[
              SizedBox(width: 6.w),
              InkWell(
                onTap: onDismiss,
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
          ],
        ),
      ),
    );
  }
}
