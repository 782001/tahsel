import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/extensions/number_extensions.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/styles.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../data/services/shipping_reconciliation_excel_service.dart';
import '../cubit/shipping_reconciliation_cubit.dart';
import '../cubit/shipping_reconciliation_state.dart';
import 'order_result_tile.dart';

class ReconciliationResultStep extends StatefulWidget {
  final ShippingReconciliationSuccessState successState;

  const ReconciliationResultStep({super.key, required this.successState});

  @override
  State<ReconciliationResultStep> createState() =>
      _ReconciliationResultStepState();
}

class _ReconciliationResultStepState extends State<ReconciliationResultStep> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.successState.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isExporting = false;

  Future<void> _exportToExcel(BuildContext context) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final dashboard = widget.successState.dashboard;
      final items = widget.successState.allItems;

      final path =
          await ShippingReconciliationExcelService.exportReconciliationReport(
            dashboard: dashboard,
            items: items,
          );

      if (context.mounted) {
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.exportExcelSuccess.tr()),
              backgroundColor: const Color(0xFF1D6F42),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.exportExcelFailure.tr()),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.exportExcelFailure.tr()),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final dashboard = widget.successState.dashboard;
    final cubit = context.read<ShippingReconciliationCubit>();

    return Column(
      children: [
        // KPI Summary Dashboard Carousel / Grid
        Container(
          color: Theme.of(context).cardColor,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 20 : 14.w,
            vertical: isDesktop ? 16 : 12.h,
          ),
          child: Column(
            children: [
              // Financial Summary Row with Brand Colors & Gradient
              Container(
                padding: EdgeInsets.all(isDesktop ? 20 : 14.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFinancialSummaryCol(
                      AppStrings.totalRequiredAmount.tr(),
                      '${dashboard.totalRequiredAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                    ),
                    Container(height: 32.h, width: 1, color: Colors.white30),
                    _buildFinancialSummaryCol(
                      AppStrings.totalCollectedAmount.tr(),
                      '${dashboard.totalCollectedAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                    ),
                    Container(height: 32.h, width: 1, color: Colors.white30),
                    _buildFinancialSummaryCol(
                      AppStrings.totalRemainingAmount.tr(),
                      '${dashboard.totalRemainingAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // KPI Metrics Horizontal Scroll
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildKpiCard(
                      AppStrings.totalShipments.tr(),
                      '${dashboard.totalReconciledRecords}',
                      Icons.inventory_rounded,
                      AppColors.primaryColor,
                    ),
                    _buildKpiCard(
                      AppStrings.matchedCount.tr(),
                      '${dashboard.matchedOrdersCount}',
                      Icons.check_circle_rounded,
                      AppColors.reconciliationMatched,
                    ),
                    _buildKpiCard(
                      AppStrings.missingFromShippingCount.tr(),
                      '${dashboard.missingFromShippingCount}',
                      Icons.cancel_rounded,
                      AppColors.reconciliationMissing,
                    ),
                    _buildKpiCard(
                      AppStrings.deliveredCount.tr(),
                      '${dashboard.deliveredCount}',
                      Icons.local_shipping_rounded,
                      AppColors.shippingDelivered,
                    ),
                    _buildKpiCard(
                      AppStrings.returnedCount.tr(),
                      '${dashboard.returnedCount}',
                      Icons.replay_rounded,
                      AppColors.shippingReturned,
                    ),
                    _buildKpiCard(
                      AppStrings.fullyCollectedCount.tr(),
                      '${dashboard.fullyCollectedCount}',
                      Icons.price_check_rounded,
                      AppColors.reconciliationMatched,
                    ),
                    _buildKpiCard(
                      AppStrings.partiallyCollectedCount.tr(),
                      '${dashboard.partiallyCollectedCount}',
                      Icons.pie_chart_rounded,
                      AppColors.reconciliationConflict,
                    ),
                    _buildKpiCard(
                      AppStrings.conflictsCount.tr(),
                      '${dashboard.dataConflictsCount + dashboard.duplicateOrdersCount}',
                      Icons.warning_rounded,
                      AppColors.reconciliationConflict,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // Search Bar & Export Excel Action Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: AppStrings.searchReconciliationPlaceholder
                            .tr(),
                        hintStyle: TextStyles.customStyle(
                          fontSize: 12,
                          color: AppColors.sandText,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.primaryColor,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  cubit.applySearchAndFilter(query: '');
                                },
                              )
                            : null,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: AppColors.sandText.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: AppColors.sandText.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: AppColors.primaryColor,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.scafoldBackGround,
                      ),
                      onChanged: (val) {
                        cubit.applySearchAndFilter(query: val);
                      },
                    ),
                  ),

                  SizedBox(width: 8.w),

                  // Export Excel Button
                  ElevatedButton.icon(
                    onPressed: _isExporting
                        ? null
                        : () => _exportToExcel(context),
                    icon: _isExporting
                        ? SizedBox(
                            width: 16.r,
                            height: 16.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            Icons.table_chart_rounded,
                            size: isDesktop ? 18 : 18.r,
                            color: Colors.white,
                          ),
                    label: Text(
                      AppStrings.exportExcelReport.tr(),
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 12 : 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D6F42), // Excel green!
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 14 : 12.w,
                        vertical: isDesktop ? 14 : 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10.h),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip(
                      cubit,
                      ReconciliationFilterChip.all,
                      '${AppStrings.allFilter.tr()} (${widget.successState.allItems.length})',
                    ),
                    _buildFilterChip(
                      cubit,
                      ReconciliationFilterChip.delivered,
                      '${AppStrings.deliveredFilter.tr()} (${dashboard.deliveredCount})',
                    ),
                    _buildFilterChip(
                      cubit,
                      ReconciliationFilterChip.returned,
                      '${AppStrings.returnedFilter.tr()} (${dashboard.returnedCount})',
                    ),
                    _buildFilterChip(
                      cubit,
                      ReconciliationFilterChip.notShipped,
                      '${AppStrings.notShippedFilter.tr()} (${dashboard.notShippedCount})',
                    ),
                    _buildFilterChip(
                      cubit,
                      ReconciliationFilterChip.fullyCollected,
                      '${AppStrings.fullyCollectedCount.tr()} (${dashboard.fullyCollectedCount})',
                    ),
                    _buildFilterChip(
                      cubit,
                      ReconciliationFilterChip.partiallyCollected,
                      '${AppStrings.partiallyCollectedCount.tr()} (${dashboard.partiallyCollectedCount})',
                    ),
                    _buildFilterChip(
                      cubit,
                      ReconciliationFilterChip.notCollected,
                      '${AppStrings.notCollectedCount.tr()} (${dashboard.notCollectedCount})',
                    ),
                    _buildFilterChip(
                      cubit,
                      ReconciliationFilterChip.conflicts,
                      '${AppStrings.conflictsCount.tr()} (${dashboard.dataConflictsCount + dashboard.duplicateOrdersCount})',
                    ),
                    _buildFilterChip(
                      cubit,
                      ReconciliationFilterChip.missing,
                      '${AppStrings.missingFromShippingCount.tr()} (${dashboard.missingFromShippingCount})',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Virtualized Results List
        Expanded(
          child: widget.successState.filteredItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 54.r,
                        color: AppColors.sandText,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        AppStrings.noResultsMatchingFilter.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 13,
                          color: AppColors.sandText,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(14.r),
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.successState.filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = widget.successState.filteredItems[index];
                    return OrderResultTile(item: item);
                  },
                ),
        ),

        // Bottom Reset Bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 14 : 10.w,
                    vertical: isDesktop ? 8 : 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.format_list_bulleted_rounded,
                        size: isDesktop ? 16 : 14.r,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: isDesktop ? 8 : 6.w),
                      Flexible(
                        child: Text(
                          '${AppStrings.selectedItemsCount.tr()}: ',
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 13 : 12,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${widget.successState.filteredItems.length}',
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 13 : 12,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' / ${widget.successState.allItems.length}',
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 12 : 11,
                          color: AppColors.sandText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: isDesktop ? 16 : 10.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => cubit.resetSession(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(AppStrings.newReconciliation.tr()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                    side: BorderSide(color: AppColors.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 16 : 12.w,
                      vertical: isDesktop ? 10 : 8.h,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSummaryCol(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyles.customStyle(fontSize: 11, color: Colors.white70),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyles.customStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String count, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(left: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18.r),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyles.customStyle(
                  fontSize: 10,
                  color: AppColors.sandText,
                ),
              ),
              Text(
                count,
                style: TextStyles.customStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    ShippingReconciliationCubit cubit,
    ReconciliationFilterChip chip,
    String label,
  ) {
    final isSelected = widget.successState.selectedFilter == chip;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Padding(
      padding: EdgeInsets.only(left: isDesktop ? 6 : 6.w),
      child: FilterChip(
        showCheckmark: false,
        selected: isSelected,
        label: Text(
          label,
          style: TextStyles.customStyle(
            fontSize: 11,
            color: isSelected ? Colors.white : AppColors.blackReal,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        labelStyle: TextStyles.customStyle(
          fontSize: 11,
          color: isSelected ? Colors.white : AppColors.blackReal,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        selectedColor: AppColors.primaryColor,
        backgroundColor: AppColors.scafoldBackGround,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
          side: BorderSide(
            color: isSelected
                ? AppColors.primaryColor
                : AppColors.sandText.withValues(alpha: 0.3),
          ),
        ),
        onSelected: (_) {
          cubit.applySearchAndFilter(filter: chip);
        },
      ),
    );
  }
}
