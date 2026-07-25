import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class PurchaseSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final DateTimeRange? selectedDateRange;
  final VoidCallback onSelectDateRange;
  final VoidCallback onClearFilters;

  const PurchaseSearchBar({
    super.key,
    required this.searchController,
    required this.selectedDateRange,
    required this.onSelectDateRange,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Container(
      padding: EdgeInsets.all(isDesktop ? 12 : 12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: AppStrings.searchInvoiceHint.tr(),
              hintStyle: TextStyles.customStyle(
                fontSize: 12,
                color: AppColors.blackLight,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.blackLight,
              ),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        searchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.scafoldBackGround,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 16 : 16.w,
                vertical: isDesktop ? 12 : 12.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: isDesktop ? 10 : 10.h),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onSelectDateRange,
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 12 : 12.w,
                      vertical: isDesktop ? 10 : 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: selectedDateRange != null
                          ? AppColors.primaryColor.withValues(alpha: 0.1)
                          : AppColors.scafoldBackGround,
                      borderRadius: BorderRadius.circular(10.r),
                      border: selectedDateRange != null
                          ? Border.all(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                          color: selectedDateRange != null
                              ? AppColors.primaryColor
                              : AppColors.blackLight,
                        ),
                        SizedBox(width: isDesktop ? 8 : 8.w),
                        Expanded(
                          child: Text(
                            selectedDateRange != null
                                ? '${DateFormat('yyyy/MM/dd').format(selectedDateRange!.start)} - ${DateFormat('yyyy/MM/dd').format(selectedDateRange!.end)}'
                                : AppStrings.selectDatePeriod.tr(),
                            style: TextStyles.customStyle(
                              fontSize: 12,
                              fontWeight: selectedDateRange != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: selectedDateRange != null
                                  ? AppColors.primaryColor
                                  : AppColors.sandText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (searchController.text.isNotEmpty ||
                  selectedDateRange != null) ...[
                SizedBox(width: isDesktop ? 8 : 8.w),
                InkWell(
                  onTap: onClearFilters,
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 12 : 12.w,
                      vertical: isDesktop ? 10 : 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          AppStrings.clearFilter.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
