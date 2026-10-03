import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/services/currency/currency_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/employee/domain/entities/employee_activity_entity.dart';
import 'package:tahsel/features/employee/presentation/cubit/employee_activity_cubit.dart';
import 'package:tahsel/features/employee/presentation/cubit/employee_activity_state.dart';
import 'package:tahsel/features/employee/presentation/cubit/team_management_cubit.dart';
import 'package:tahsel/features/employee/presentation/cubit/team_management_state.dart';
import 'package:tahsel/features/employee/data/models/app_employee_model.dart';
import 'package:tahsel/features/employee/presentation/utils/activity_field_localizer.dart';
import 'package:tahsel/features/employee/presentation/utils/activity_navigation_helper.dart';
import 'package:tahsel/features/employee/presentation/utils/employee_activity_export_service.dart';
import 'package:tahsel/shared/widgets/custom_app_bar/custom_app_bar.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

class TeamActivityScreen extends StatefulWidget {
  const TeamActivityScreen({super.key});

  @override
  State<TeamActivityScreen> createState() => _TeamActivityScreenState();
}

class _TeamActivityScreenState extends State<TeamActivityScreen> {
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
        centerTitle: AppStrings.teamActivityLogTitle.tr(),
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
                AppEmployeeModel? selectedEmp;
                if (state.selectedEmployeeUid != 'all') {
                  for (final e in context.read<TeamManagementCubit>().employees) {
                    if (e.authUid == state.selectedEmployeeUid) {
                      selectedEmp = e;
                      break;
                    }
                  }
                }

                EmployeeActivityExportService.showExportOptions(
                  context,
                  title: AppStrings.teamActivityLogTitle.tr(),
                  subtitle: selectedEmp != null
                      ? '${AppStrings.employeeSpecificActivity.tr()}: ${selectedEmp.name}'
                      : AppStrings.teamActivityLogSubtitle.tr(),
                  activities: state.activities,
                  stats: state.stats,
                  dateRange: state.selectedDateRange,
                  employee: selectedEmp,
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
                    maxWidth: isDesktop ? 1000 : double.infinity,
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
                                _buildTeamHeaderCard(),
                                SizedBox(height: 12.h),
                                _buildEmployeeSelectorChips(context, state),
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

  Widget _buildTeamHeaderCard() {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.lightGreyColor),
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
            child: Icon(
              Icons.groups_rounded,
              color: AppColors.primaryColor,
              size: 26,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.teamActivityTimeline.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  AppStrings.teamActivityTimelineDesc.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 11.5,
                    color: AppColors.sandText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeSelectorChips(
    BuildContext context,
    EmployeeActivityLoaded state,
  ) {
    return BlocBuilder<TeamManagementCubit, TeamManagementState>(
      builder: (context, teamState) {
        final cubit = context.read<TeamManagementCubit>();
        final employees = cubit.employees;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_pin_outlined,
                  size: 16,
                  color: AppColors.sandText,
                ),
                SizedBox(width: 6.w),
                Text(
                  AppStrings.filterByEmployee.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(
                      AppStrings.allEmployees.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 12,
                        fontWeight: state.selectedEmployeeUid == 'all'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: state.selectedEmployeeUid == 'all'
                            ? Colors.white
                            : AppColors.sandText,
                      ),
                    ),
                    selected: state.selectedEmployeeUid == 'all',
                    selectedColor: AppColors.primaryColor,
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      side: BorderSide(
                        color: state.selectedEmployeeUid == 'all'
                            ? AppColors.primaryColor
                            : AppColors.lightGreyColor,
                      ),
                    ),
                    showCheckmark: false,
                    onSelected: (_) {
                      context.read<EmployeeActivityCubit>().changeEmployee(
                        'all',
                      );
                    },
                  ),
                  SizedBox(width: 8.w),
                  ...employees.map((emp) {
                    final isSelected = state.selectedEmployeeUid == emp.authUid;
                    return Padding(
                      padding: EdgeInsetsDirectional.only(end: 8.w),
                      child: ChoiceChip(
                        avatar: CircleAvatar(
                          radius: 10.r,
                          backgroundColor: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : AppColors.primaryColor.withValues(alpha: 0.12),
                          child: Text(
                            emp.name.isNotEmpty
                                ? emp.name[0].toUpperCase()
                                : '؟',
                            style: TextStyles.customStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primaryColor,
                            ),
                          ),
                        ),
                        label: Text(
                          emp.name,
                          style: TextStyles.customStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : AppColors.sandText,
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
                          context.read<EmployeeActivityCubit>().changeEmployee(
                            emp.authUid,
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryStats(EmployeeActivityLoaded state, String currency) {
    final stats = state.stats;

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
                ? '${stats.totalSalesAmount.toStringAsFixed(1)} $currency'
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
                ? '${stats.totalExpensesAmount.toStringAsFixed(1)} $currency'
                : null,
            icon: Icons.money_off_csred_rounded,
            color: AppColors.error,
          ),
        ),
      ],
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
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    activity.employeeName,
                                    style: TextStyles.customStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.sandText.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    ActivityFieldLocalizer.formatRole(activity.rolePreset),
                                    style: TextStyles.customStyle(
                                      fontSize: 9.5,
                                      color: AppColors.sandText,
                                    ),
                                  ),
                                ),
                              ],
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
                      SizedBox(height: 3.h),
                      Text(
                        activity.actionTitle,
                        style: TextStyles.customStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        activity.details,
                        style: TextStyles.customStyle(
                          fontSize: 11.5,
                          color: AppColors.sandText,
                        ),
                        maxLines: 4,
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
                                '${activity.employeeName} (${ActivityFieldLocalizer.formatRole(activity.rolePreset)}) • ${DateFormat('yyyy-MM-dd • hh:mm a', 'ar').format(activity.timestamp)}',
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
                    _buildDetailRow(
                      AppStrings.employeeName.tr(),
                      activity.employeeName,
                    ),
                    _buildDetailRow(AppStrings.category.tr(), meta.label),
                    if (activity.amount != null && activity.amount! > 0)
                      _buildDetailRow(
                        AppStrings.amount.tr(),
                        '${activity.amount!.toStringAsFixed(2)} $currency',
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
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyles.customStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? AppColors.black,
              ),
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
              Icons.feed_outlined,
              size: 56.r,
              color: AppColors.sandText.withValues(alpha: 0.5),
            ),
            SizedBox(height: 14.h),
            Text(
              AppStrings.noActivityLogged.tr(),
              style: TextStyles.customStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              AppStrings.noActivityLoggedDesc.tr(),
              textAlign: TextAlign.center,
              style: TextStyles.customStyle(
                fontSize: 12,
                color: AppColors.sandText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialLoading() {
    return ShimmerLoading(
      child: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          ShimmerPlaceholder(height: 70.h, borderRadius: 16.r),
          SizedBox(height: 14.h),
          ShimmerPlaceholder(height: 50.h, borderRadius: 12.r),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: ShimmerPlaceholder(height: 60.h, borderRadius: 12.r),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ShimmerPlaceholder(height: 60.h, borderRadius: 12.r),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ShimmerPlaceholder(height: 60.h, borderRadius: 12.r),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          for (int i = 0; i < 4; i++) ...[
            ShimmerPlaceholder(height: 75.h, borderRadius: 14.r),
            SizedBox(height: 10.h),
          ],
        ],
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
            Icon(
              Icons.error_outline_rounded,
              size: 48.r,
              color: AppColors.error,
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyles.customStyle(
                fontSize: 14,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => context.read<EmployeeActivityCubit>().refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text(
                AppStrings.retry.tr(),
                style: TextStyles.customStyle(
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _CategoryMeta _getCategoryMeta(String category) {
    switch (category) {
      case 'sales':
        return _CategoryMeta(
          color: AppColors.success,
          icon: Icons.point_of_sale_rounded,
          label: AppStrings.sales.tr(),
        );
      case 'invoices':
        return _CategoryMeta(
          color: AppColors.primaryColor,
          icon: Icons.receipt_long_rounded,
          label: AppStrings.invoices.tr(),
        );
      case 'debts':
        return _CategoryMeta(
          color: const Color(0xFFE65100),
          icon: Icons.account_balance_wallet_outlined,
          label: AppStrings.debts.tr(),
        );
      case 'expenses':
        return _CategoryMeta(
          color: AppColors.error,
          icon: Icons.money_off_csred_rounded,
          label: AppStrings.expenses.tr(),
        );
      case 'vault':
        return _CategoryMeta(
          color: const Color(0xFF00897B),
          icon: Icons.savings_outlined,
          label: AppStrings.vault.tr(),
        );
      case 'inventory':
        return _CategoryMeta(
          color: const Color(0xFF5E35B1),
          icon: Icons.inventory_2_outlined,
          label: AppStrings.inventory.tr(),
        );
      case 'employees':
        return _CategoryMeta(
          color: const Color(0xFF1E88E5),
          icon: Icons.badge_outlined,
          label: AppStrings.permGroupEmployees.tr(),
        );
      case 'reports':
        return _CategoryMeta(
          color: const Color(0xFF8E24AA),
          icon: Icons.analytics_outlined,
          label: AppStrings.permGroupReports.tr(),
        );
      case 'settings':
        return _CategoryMeta(
          color: const Color(0xFF546E7A),
          icon: Icons.settings_outlined,
          label: AppStrings.permGroupSettings.tr(),
        );
      default:
        return _CategoryMeta(
          color: AppColors.sandText,
          icon: Icons.history_rounded,
          label: AppStrings.all.tr(),
        );
    }
  }
}

class _CategoryMeta {
  final Color color;
  final IconData icon;
  final String label;

  const _CategoryMeta({
    required this.color,
    required this.icon,
    required this.label,
  });
}
