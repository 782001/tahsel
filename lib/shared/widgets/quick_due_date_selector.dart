import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/date_formatter.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class QuickDueDateSelector extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateChanged;
  final bool showLabel;

  const QuickDueDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.showLabel = true,
  });

  DateTime get _now => DateTime.now();
  DateTime get _today => DateTime(_now.year, _now.month, _now.day);

  DateTime get _in3Days => _today.add(const Duration(days: 3));
  DateTime get _in1Week => _today.add(const Duration(days: 7));
  DateTime get _in2Weeks => _today.add(const Duration(days: 14));
  DateTime get _endOfMonth {
    final nextMonth = DateTime(_today.year, _today.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1));
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _pickCustomDate(BuildContext context) async {
    final DateTime minDate = DateTime(2000);
    final DateTime initialDate = selectedDate ?? _today;
    final DateTime finalInitialDate =
        initialDate.isBefore(minDate) ? minDate : initialDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: finalInitialDate,
      firstDate: minDate,
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: AppColors.isDark
                ? ColorScheme.dark(primary: AppColors.primaryColor)
                : ColorScheme.light(
                    primary: AppColors.primaryColor,
                    onPrimary: AppColors.white,
                    onSurface: AppColors.black,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final is3Days = _isSameDay(selectedDate, _in3Days);
    final is1Week = _isSameDay(selectedDate, _in1Week);
    final is2Weeks = _isSameDay(selectedDate, _in2Weeks);
    final isEndOfMonth = _isSameDay(selectedDate, _endOfMonth);
    final isCustom = selectedDate != null &&
        !is3Days &&
        !is1Week &&
        !is2Weeks &&
        !isEndOfMonth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.paymentDueDate.tr(),
                style: TextStyles.customStyle(
                  fontSize: isDesktop ? 14 : 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackLight,
                ),
              ),
              if (selectedDate != null)
                InkWell(
                  onTap: () => onDateChanged(null),
                  borderRadius: BorderRadius.circular(8.r),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      AppStrings.clear.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 12,
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isDesktop ? 8 : 6.h),
        ],

        // Horizontal scrolling chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildChip(
                label: AppStrings.after3Days.tr(),
                isSelected: is3Days,
                onTap: () => onDateChanged(is3Days ? null : _in3Days),
                isDesktop: isDesktop,
              ),
              SizedBox(width: 8.w),
              _buildChip(
                label: AppStrings.after1Week.tr(),
                isSelected: is1Week,
                onTap: () => onDateChanged(is1Week ? null : _in1Week),
                isDesktop: isDesktop,
              ),
              SizedBox(width: 8.w),
              _buildChip(
                label: AppStrings.after2Weeks.tr(),
                isSelected: is2Weeks,
                onTap: () => onDateChanged(is2Weeks ? null : _in2Weeks),
                isDesktop: isDesktop,
              ),
              SizedBox(width: 8.w),
              _buildChip(
                label: AppStrings.endOfMonth.tr(),
                isSelected: isEndOfMonth,
                onTap: () => onDateChanged(isEndOfMonth ? null : _endOfMonth),
                isDesktop: isDesktop,
              ),
              SizedBox(width: 8.w),
              _buildChip(
                label: isCustom
                    ? DateFormatter.formatNumericDate(selectedDate!)
                    : AppStrings.customDate.tr(),
                isSelected: isCustom,
                icon: Icons.calendar_month_rounded,
                onTap: () => _pickCustomDate(context),
                isDesktop: isDesktop,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDesktop,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 14 : 12.w,
          vertical: isDesktop ? 8 : 6.h,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor
              : AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : AppColors.primaryColor.withValues(alpha: 0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: isDesktop ? 16 : 14,
                color: isSelected ? Colors.white : AppColors.primaryColor,
              ),
              SizedBox(width: 4.w),
            ],
            Text(
              label,
              style: TextStyles.customStyle(
                fontSize: isDesktop ? 13 : 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
