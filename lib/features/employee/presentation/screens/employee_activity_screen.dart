import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/services/currency/currency_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/custom_app_bar/custom_app_bar.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

import '../../data/models/app_employee_model.dart';
import '../../domain/entities/employee_activity_entity.dart';
import '../cubit/employee_activity_cubit.dart';
import '../cubit/employee_activity_state.dart';
import '../utils/activity_field_localizer.dart';
import '../utils/activity_navigation_helper.dart';
import '../utils/employee_activity_export_service.dart';

class EmployeeActivityScreen extends StatefulWidget {
  final AppEmployeeModel employee;

  const EmployeeActivityScreen({super.key, required this.employee});

  @override
  State<EmployeeActivityScreen> createState() => _EmployeeActivityScreenState();
}

class _EmployeeActivityScreenState extends State<EmployeeActivityScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      context.read<EmployeeActivityCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(
    BuildContext context,
    DateTimeRange? currentRange,
  ) async {
    final cubit = context.read<EmployeeActivityCubit>();
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime(now.year + 2),
      initialDateRange: currentRange,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      cubit.changeDateRange(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = CurrencyService.instance.currentSymbol;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      appBar: CustomAppBar(
        centerTitle: AppStrings.employeeActivityLog.tr(),
        leadingIcon: const Icon(Icons.arrow_back_ios_new_rounded),
        onLeadingTap: () => Navigator.of(context).pop(),
        actionIcon: BlocBuilder<EmployeeActivityCubit, EmployeeActivityState>(
          builder: (context, state) {
            if (state is! EmployeeActivityLoaded || state.activities.isEmpty) {
              return const SizedBox.shrink();
            }
            return IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: AppStrings.exportReport.tr(),
              onPressed: () {
                EmployeeActivityExportService.showExportOptions(
                  context,
                  title:
                      '${AppStrings.employeeActivityLog.tr()}: ${widget.employee.name}',
                  subtitle:
                      '${AppStrings.rolePreset.tr()}: ${ActivityFieldLocalizer.formatRole(widget.employee.rolePreset)}',
                  activities: state.activities,
                  stats: state.stats,
                  dateRange: state.selectedDateRange,
                  employee: widget.employee,
                  hasMore: state.hasMore,
                  onFetchAllForExport: () => context
                      .read<EmployeeActivityCubit>()
                      .getAllActivitiesForExport(),
                );
              },
            );
          },
        ),
      ),
      body: BlocConsumer<EmployeeActivityCubit, EmployeeActivityState>(
        listener: (context, state) {
          if (state is EmployeeActivityLoaded && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage!,
                  style: TextStyles.customStyle(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is EmployeeActivityLoading) {
            return _buildInitialLoading();
          }

          if (state is EmployeeActivityError) {
            return _buildErrorState(context, state.message);
          }

          if (state is EmployeeActivityLoaded) {
            return SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 900 : double.infinity,
                  ),
                  child: RefreshIndicator(
                    onRefresh: () =>
                        context.read<EmployeeActivityCubit>().refresh(),
                    color: AppColors.primaryColor,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 24 : 16.w,
                              vertical: isDesktop ? 16 : 12.h,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildEmployeeHeaderCard(widget.employee),
                                SizedBox(height: 14.h),
                                _buildSummaryStats(state, currency),
                                SizedBox(height: 14.h),
                                _buildFilterHeader(context, state),
                                SizedBox(height: 10.h),
                                _buildCategoryChips(context, state),
                                SizedBox(height: 12.h),
                              ],
                            ),
                          ),
                        ),
                        if (state.activities.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 24 : 16.w,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final activity = state.activities[index];
                                return _buildActivityCard(
                                  context,
                                  activity,
                                  currency,
                                );
                              }, childCount: state.activities.length),
                            ),
                          ),
                        if (state.isLoadingMore)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.h),
                              child: Center(
                                child: SizedBox(
                                  width: 24.r,
                                  height: 24.r,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        SliverToBoxAdapter(child: SizedBox(height: 30.h)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmployeeHeaderCard(AppEmployeeModel emp) {
    final bool isActive = emp.isActive;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isActive
              ? AppColors.lightGreyColor
              : AppColors.error.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundColor: AppColors.primaryColor.withValues(alpha: 0.12),
            child: Text(
              emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '؟',
              style: TextStyles.customStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        emp.name,
                        style: TextStyles.customStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    _buildRoleBadge(emp.rolePreset),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  emp.email,
                  style: TextStyles.customStyle(
                    fontSize: 12,
                    color: AppColors.sandText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              isActive ? AppStrings.active.tr() : AppStrings.disabled.tr(),
              style: TextStyles.customStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? AppColors.success : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(EmployeeActivityLoaded state, String currency) {
    final stats = state.stats;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: _buildStatItem(
                title: AppStrings.operationsCount.tr(),
                value: '${stats.totalCount}',
                icon: Icons.checklist_rounded,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildStatItem(
                title: AppStrings.sales.tr(),
                value: '${stats.salesCount}',
                subtitle: stats.totalSalesAmount > 0
                    ? '${stats.totalSalesAmount.toSmartAmount()} $currency'
                    : null,
                icon: Icons.shopping_bag_outlined,
                color: AppColors.success,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildStatItem(
                title: AppStrings.expenses.tr(),
                value: '${stats.expensesCount}',
                subtitle: stats.totalExpensesAmount > 0
                    ? '${stats.totalExpensesAmount.toSmartAmount()} $currency'
                    : null,
                icon: Icons.money_off_csred_rounded,
                color: AppColors.error,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.lightGreyColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyles.customStyle(
                    fontSize: 10.5,
                    color: AppColors.sandText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(icon, size: 15, color: color),
            ],
          ),
          SizedBox(height: 6.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyles.customStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: TextStyles.customStyle(
                fontSize: 9.5,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterHeader(
    BuildContext context,
    EmployeeActivityLoaded state,
  ) {
    final range = state.selectedDateRange;
    final dateText = range == null
        ? AppStrings.allTime.tr()
        : '${DateFormat('yyyy/MM/dd').format(range.start)} - ${DateFormat('yyyy/MM/dd').format(range.end)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            AppStrings.activityFeed.tr(),
            style: TextStyles.customStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: InkWell(
            onTap: () => _pickDateRange(context, range),
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: range != null
                    ? AppColors.primaryColor.withValues(alpha: 0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: range != null
                      ? AppColors.primaryColor
                      : AppColors.lightGreyColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: range != null
                        ? AppColors.primaryColor
                        : AppColors.sandText,
                  ),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: Text(
                      dateText,
                      style: TextStyles.customStyle(
                        fontSize: 10.5,
                        fontWeight: range != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: range != null
                            ? AppColors.primaryColor
                            : AppColors.sandText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (range != null) ...[
                    SizedBox(width: 4.w),
                    GestureDetector(
                      onTap: () => context
                          .read<EmployeeActivityCubit>()
                          .changeDateRange(null),
                      child: Icon(
                        Icons.close,
                        size: 13,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips(
    BuildContext context,
    EmployeeActivityLoaded state,
  ) {
    final categories = [
      {'key': 'all', 'label': AppStrings.all.tr()},
      {'key': 'sales', 'label': AppStrings.sales.tr()},
      {'key': 'invoices', 'label': AppStrings.invoices.tr()},
      {'key': 'debts', 'label': AppStrings.debts.tr()},
      {'key': 'expenses', 'label': AppStrings.expenses.tr()},
      {'key': 'vault', 'label': AppStrings.vault.tr()},
      {'key': 'inventory', 'label': AppStrings.inventory.tr()},
      {'key': 'employees', 'label': AppStrings.permGroupEmployees.tr()},
      {'key': 'reports', 'label': AppStrings.permGroupReports.tr()},
      {'key': 'settings', 'label': AppStrings.permGroupSettings.tr()},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((cat) {
          final isSelected = state.selectedCategory == cat['key'];
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: ChoiceChip(
              label: Text(
                cat['label']!,
                style: TextStyles.customStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.sandText,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primaryColor,
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.lightGreyColor,
                ),
              ),
              showCheckmark: false,
              onSelected: (_) {
                context.read<EmployeeActivityCubit>().changeCategory(
                  cat['key']!,
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    EmployeeActivityEntity activity,
    String currency,
  ) {
    final meta = _getCategoryMeta(activity.actionCategory);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.lightGreyColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () => _showDetailsBottomSheet(context, activity, currency),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: meta.color.withValues(alpha: 0.12),
                  child: Icon(meta.icon, color: meta.color, size: 20),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              activity.actionTitle,
                              style: TextStyles.customStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (activity.amount != null && activity.amount! > 0)
                            Text(
                              '${activity.amount!.toSmartAmount()} $currency',
                              style: TextStyles.customStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: meta.color,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        activity.details,
                        style: TextStyles.customStyle(
                          fontSize: 12,
                          color: AppColors.sandText,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: AppColors.sandText,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            DateFormat(
                              'yyyy-MM-dd • hh:mm a',
                              'ar',
                            ).format(activity.timestamp),
                            style: TextStyles.customStyle(
                              fontSize: 10.5,
                              color: AppColors.sandText,
                            ),
                          ),
                          if (activity.isOfflineSync) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.stitchOrange.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cloud_done_outlined,
                                    size: 11,
                                    color: AppColors.stitchOrange,
                                  ),
                                  SizedBox(width: 3.w),
                                  Text(
                                    AppStrings.offlineSyncBadge.tr(),
                                    style: TextStyles.customStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.stitchOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailsBottomSheet(
    BuildContext context,
    EmployeeActivityEntity activity,
    String currency,
  ) {
    final meta = _getCategoryMeta(activity.actionCategory);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 650 : double.infinity,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Container(
              padding: EdgeInsets.all(isDesktop ? 24 : 20.r),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: isDesktop
                    ? BorderRadius.circular(20)
                    : BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: AppColors.lightGreyColor,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22.r,
                          backgroundColor: meta.color.withValues(alpha: 0.12),
                          child: Icon(meta.icon, color: meta.color, size: 22),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.actionTitle,
                                style: TextStyles.customStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                '${activity.employeeName} • ${DateFormat('yyyy-MM-dd • hh:mm a', 'ar').format(activity.timestamp)}',
                                style: TextStyles.customStyle(
                                  fontSize: 11,
                                  color: AppColors.sandText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Divider(color: AppColors.lightGreyColor),
                    SizedBox(height: 10.h),
                    _buildDetailRow(AppStrings.category.tr(), meta.label),
                    if (activity.amount != null && activity.amount! > 0)
                      _buildDetailRow(
                        AppStrings.amount.tr(),
                        '${activity.amount!.toSmartAmount()} $currency',
                        valueColor: meta.color,
                        isBold: true,
                      ),
                    _buildDetailRow(AppStrings.details.tr(), activity.details),
                    _buildDetailRow(
                      AppStrings.syncType.tr(),
                      activity.isOfflineSync
                          ? AppStrings.offlineSynced.tr()
                          : AppStrings.directOnline.tr(),
                    ),
                    if (activity.extraData != null &&
                        activity.extraData!.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Text(
                        AppStrings.additionalDetails.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: AppColors.scafoldBackGround,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Column(
                          children: activity.extraData!.entries.map((e) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 3.h),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    ActivityFieldLocalizer.localizeKey(
                                      context,
                                      e.key,
                                    ),
                                    style: TextStyles.customStyle(
                                      fontSize: 11,
                                      color: AppColors.sandText,
                                    ),
                                  ),
                                  Text(
                                    '${e.value}',
                                    style: TextStyles.customStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    if (ActivityNavigationHelper.hasLinkedEntity(activity)) ...[
                      SizedBox(height: 16.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ActivityNavigationHelper.navigateToLinkedEntity(
                              context,
                              activity,
                            );
                          },
                          icon: Icon(
                            ActivityNavigationHelper.getLinkedEntityIcon(
                              activity,
                            ),
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            ActivityNavigationHelper.getLinkedEntityLabel(
                              activity,
                            ),
                            style: TextStyles.customStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 10.h),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.lightGreyColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: Text(
                          AppStrings.close.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    String title,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyles.customStyle(
              fontSize: 12,
              color: AppColors.sandText,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyles.customStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? AppColors.black,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: AppColors.sandText.withValues(alpha: 0.5),
            ),
            SizedBox(height: 12.h),
            Text(
              AppStrings.noActivitiesFound.tr(),
              style: TextStyles.customStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.sandText,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              AppStrings.noActivitiesHint.tr(),
              style: TextStyles.customStyle(
                fontSize: 12,
                color: AppColors.sandText.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            SizedBox(height: 12.h),
            Text(
              message,
              style: TextStyles.customStyle(
                fontSize: 14,
                color: AppColors.sandText,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () => context.read<EmployeeActivityCubit>().refresh(),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(
                AppStrings.retry.tr(),
                style: TextStyles.customStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialLoading() {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: ShimmerLoading(
              child: ShimmerPlaceholder(
                height: 75.h,
                width: double.infinity,
                borderRadius: 14.r,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String preset) {
    String label = preset;
    Color color = AppColors.primaryColor;

    switch (preset) {
      case AppPermissions.roleCashier:
        label = AppStrings.roleCashierLabel.tr();
        color = AppColors.primaryColor;
        break;
      case AppPermissions.roleAccountant:
        label = AppStrings.roleAccountantLabel.tr();
        color = AppColors.stitchBlue;
        break;
      case AppPermissions.roleSupervisor:
        label = AppStrings.roleSupervisorLabel.tr();
        color = AppColors.error;
        break;
      case AppPermissions.roleStorekeeper:
        label = AppStrings.roleStorekeeperLabel.tr();
        color = AppColors.stitchOrange;
        break;
      default:
        label = AppStrings.roleCustomLabel.tr();
        color = AppColors.sandText;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyles.customStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  _CategoryMeta _getCategoryMeta(String category) {
    switch (category) {
      case 'sales':
        return _CategoryMeta(
          label: AppStrings.sales.tr(),
          icon: Icons.shopping_bag_outlined,
          color: AppColors.success,
        );
      case 'invoices':
        return _CategoryMeta(
          label: AppStrings.invoices.tr(),
          icon: Icons.receipt_long_outlined,
          color: AppColors.primaryColor,
        );
      case 'debts':
        return _CategoryMeta(
          label: AppStrings.debts.tr(),
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.stitchBlue,
        );
      case 'expenses':
        return _CategoryMeta(
          label: AppStrings.expenses.tr(),
          icon: Icons.money_off_csred_rounded,
          color: AppColors.error,
        );
      case 'vault':
        return _CategoryMeta(
          label: AppStrings.vault.tr(),
          icon: Icons.savings_outlined,
          color: AppColors.stitchOrange,
        );
      case 'inventory':
        return _CategoryMeta(
          label: AppStrings.inventory.tr(),
          icon: Icons.inventory_2_outlined,
          color: const Color(0xFF7B1FA2),
        );
      case 'employees':
        return _CategoryMeta(
          label: AppStrings.permGroupEmployees.tr(),
          icon: Icons.people_outline_rounded,
          color: const Color(0xFF00897B),
        );
      case 'reports':
        return _CategoryMeta(
          label: AppStrings.permGroupReports.tr(),
          icon: Icons.analytics_outlined,
          color: const Color(0xFFE65100),
        );
      case 'settings':
        return _CategoryMeta(
          label: AppStrings.permGroupSettings.tr(),
          icon: Icons.settings_outlined,
          color: const Color(0xFF5E35B1),
        );
      default:
        return _CategoryMeta(
          label: AppStrings.other.tr(),
          icon: Icons.history_rounded,
          color: AppColors.sandText,
        );
    }
  }
}

class _CategoryMeta {
  final String label;
  final IconData icon;
  final Color color;

  const _CategoryMeta({
    required this.label,
    required this.icon,
    required this.color,
  });
}
