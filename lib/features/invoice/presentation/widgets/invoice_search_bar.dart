import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class InvoiceSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final DateTimeRange? selectedDateRange;
  final VoidCallback onSelectDateRange;
  final VoidCallback onClearFilters;

  const InvoiceSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.selectedDateRange,
    required this.onSelectDateRange,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final hasDate = selectedDateRange != null;
    final hasText = controller.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 16.w,
        vertical: isDesktop ? 8 : 8.h,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: AppColors.isDark ? 0.2 : 0.03,
              ),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          cursorColor: AppColors.primaryColor,
          style: TextStyles.customStyle(
            fontSize: 13,
            color: AppColors.textColor,
          ),
          decoration: InputDecoration(
            hintText: AppStrings.searchInvoices.tr(),
            hintStyle: TextStyles.customStyle(
              color: AppColors.disabledColor,
              fontSize: 12,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: (hasText || hasDate)
                  ? AppColors.primaryColor
                  : AppColors.disabledColor,
              size: 22.r,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date Range Filter Button / Active Chip
                InkWell(
                  onTap: onSelectDateRange,
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: hasDate
                          ? (isDesktop ? 10 : 8.w)
                          : (isDesktop ? 8 : 6.w),
                      vertical: isDesktop ? 8 : 6.h,
                    ),
                    margin:
                        EdgeInsets.symmetric(horizontal: isDesktop ? 6 : 4.w),
                    decoration: BoxDecoration(
                      color: hasDate
                          ? AppColors.primaryColor.withValues(alpha: 0.12)
                          : AppColors.scafoldBackGround,
                      borderRadius: BorderRadius.circular(8.r),
                      border: hasDate
                          ? Border.all(
                              color:
                                  AppColors.primaryColor.withValues(alpha: 0.3),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.date_range_rounded,
                          size: 16.r,
                          color: hasDate
                              ? AppColors.primaryColor
                              : AppColors.blackLight,
                        ),
                        if (hasDate) ...[
                          SizedBox(width: 4.w),
                          Text(
                            '${DateFormat('MM/dd').format(selectedDateRange!.start)} - ${DateFormat('MM/dd').format(selectedDateRange!.end)}',
                            style: TextStyles.customStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Clear Button (if any filter is active)
                if (hasText || hasDate)
                  IconButton(
                    icon: Icon(
                      Icons.cancel_rounded,
                      color: AppColors.error,
                      size: 20.r,
                    ),
                    tooltip: AppStrings.clearFilter.tr(),
                    onPressed: onClearFilters,
                  ),
                SizedBox(width: 4.w),
              ],
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 16 : 16.w,
              vertical: isDesktop ? 12 : 12.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(
                color: (hasText || hasDate)
                    ? AppColors.primaryColor.withValues(alpha: 0.3)
                    : AppColors.dividerColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(
                color: (hasText || hasDate)
                    ? AppColors.primaryColor.withValues(alpha: 0.3)
                    : AppColors.dividerColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(
                color: AppColors.primaryColor,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
