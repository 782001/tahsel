import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/employee/presentation/cubit/employee_cubit.dart';
import 'package:tahsel/features/employee/presentation/cubit/employee_state.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/no_internet_view.dart';

class EmployeeReportsScreen extends StatefulWidget {
  const EmployeeReportsScreen({super.key});

  @override
  State<EmployeeReportsScreen> createState() => _EmployeeReportsScreenState();
}

class _EmployeeReportsScreenState extends State<EmployeeReportsScreen> {
  String? _selectedMonthKey;
  final List<Map<String, String>> _monthsList = [];

  @override
  void initState() {
    super.initState();
    _generateMonthsList();
    if (_monthsList.isNotEmpty) {
      _selectedMonthKey = _monthsList.first['key'];
    }
    _fetchReportData();
  }

  void _generateMonthsList() {
    final now = DateTime.now();
    final localeCode = AppStrings.currentLang;
    for (int i = 0; i < 6; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('yyyy-MM', 'en').format(date);
      final monthName = DateFormat('MMMM', localeCode).format(date);
      final yearName = DateFormat('yyyy', 'en').format(date);
      final label = '$monthName $yearName';
      _monthsList.add({'key': key, 'label': label});
    }
  }

  void _fetchReportData() {
    context.read<EmployeeCubit>().fetchReports(
      AppStrings.userToken,
      monthKey: _selectedMonthKey,
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.reports.tr(),
          style: TextStyles.customStyle(
            fontSize: isDesktop ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, connectivityState) {
          if (connectivityState is ConnectivityDisconnected) {
            return NoInternetView(
              onRetry: () =>
                  context.read<ConnectivityCubit>().checkConnectivity(),
            );
          }
          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 800 : double.infinity,
                ),
                child: Column(
                  children: [
                    // Month Picker Banner
                    _buildMonthPicker(isDesktop),

                    Expanded(
                      child: BlocBuilder<EmployeeCubit, EmployeeState>(
                        buildWhen: (previous, current) =>
                            current is EmployeeLoading ||
                            current is EmployeeReportsSuccess ||
                            current is EmployeeFailure,
                        builder: (context, state) {
                          if (state is EmployeeLoading) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryColor,
                                strokeWidth: 3,
                              ),
                            );
                          } else if (state is EmployeeFailure) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    state.message,
                                    style: TextStyles.customStyle(
                                      fontSize: 14,
                                      color: AppColors.error,
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  ElevatedButton(
                                    onPressed: _fetchReportData,
                                    child: Text(AppStrings.retry.tr()),
                                  ),
                                ],
                              ),
                            );
                          } else if (state is EmployeeReportsSuccess) {
                            return _buildReportsDashboard(state, isDesktop);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthPicker(bool isDesktop) {
    return Container(
      color: AppColors.whiteColor,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16.w,
        vertical: isDesktop ? 12 : 12.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppStrings.filterByMonth.tr(),
            style: TextStyles.customStyle(
              fontSize: isDesktop ? 15 : 14,
              fontWeight: FontWeight.bold,
              color: AppColors.blackReal,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 12 : 12.w),
            decoration: BoxDecoration(
              color: AppColors.veryLightGrey,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMonthKey,
                dropdownColor: AppColors.whiteColor,
                style: TextStyles.customStyle(
                  fontSize: isDesktop ? 14 : 13,
                  color: AppColors.blackReal,
                  fontWeight: FontWeight.bold,
                ),
                items: _monthsList.map((m) {
                  return DropdownMenuItem(
                    value: m['key'],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(m['label']!),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedMonthKey = val;
                    });
                    _fetchReportData();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsDashboard(EmployeeReportsSuccess report, bool isDesktop) {
    if (isDesktop) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: Total Salary & Gauge Banner
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      _buildTotalSalaryPaidCard(report, true),
                      const SizedBox(height: 16),
                      _buildGaugeBanner(report, true),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Right side: Grid of Metrics
                Expanded(
                  flex: 6,
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildMetricCard(
                        title: AppStrings.totalOvertimeComp.tr(),
                        value: report.totalOvertimeCompensation.toSmartAmount(),
                        icon: Icons.timer_rounded,
                        color: AppColors.warning,
                        isDesktop: true,
                      ),
                      _buildMetricCard(
                        title: AppStrings.avgAttendanceRate.tr(),
                        value:
                            "${report.averageAttendanceRate.toSmartAmount()}%",
                        icon: Icons.done_all_rounded,
                        color: AppColors.success,
                        isDesktop: true,
                      ),
                      _buildMetricCard(
                        title: AppStrings.activeEmployees.tr(),
                        value: report.activeEmployees.toString(),
                        icon: Icons.person_add_alt_1_rounded,
                        color: AppColors.primaryColor,
                        isDesktop: true,
                      ),
                      _buildMetricCard(
                        title: AppStrings.totalEmployees.tr(),
                        value: report.totalEmployees.toString(),
                        icon: Icons.people_alt_rounded,
                        color: AppColors.blackLight,
                        isDesktop: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTotalSalaryPaidCard(report, false),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: AppStrings.totalOvertimeComp.tr(),
                  value: report.totalOvertimeCompensation.toSmartAmount(),
                  icon: Icons.timer_rounded,
                  color: AppColors.warning,
                  isDesktop: false,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildMetricCard(
                  title: AppStrings.avgAttendanceRate.tr(),
                  value: "${report.averageAttendanceRate.toSmartAmount()}%",
                  icon: Icons.done_all_rounded,
                  color: AppColors.success,
                  isDesktop: false,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: AppStrings.activeEmployees.tr(),
                  value: report.activeEmployees.toString(),
                  icon: Icons.person_add_alt_1_rounded,
                  color: AppColors.primaryColor,
                  isDesktop: false,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildMetricCard(
                  title: AppStrings.totalEmployees.tr(),
                  value: report.totalEmployees.toString(),
                  icon: Icons.people_alt_rounded,
                  color: AppColors.blackLight,
                  isDesktop: false,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          _buildGaugeBanner(report, false),
        ],
      ),
    );
  }

  Widget _buildTotalSalaryPaidCard(
    EmployeeReportsSuccess report,
    bool isDesktop,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 20 : 20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryColor, AppColors.sandText],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.totalPaidSalaries.tr(),
                style: TextStyles.customStyle(
                  fontSize: isDesktop ? 15 : 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const Icon(Icons.wallet_rounded, color: Colors.white, size: 24),
            ],
          ),
          SizedBox(height: isDesktop ? 12 : 12.h),
          Text(
            report.totalPaidSalaries.toSmartAmount(),
            style: TextStyles.customStyle(
              fontSize: isDesktop ? 32 : 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeBanner(EmployeeReportsSuccess report, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 16 : 16.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
        border: Border.all(color: AppColors.veryLightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.reportsSummaryTitle.tr(),
            style: TextStyles.customStyle(
              fontSize: isDesktop ? 14 : 14,
              fontWeight: FontWeight.bold,
              color: AppColors.blackReal,
            ),
          ),
          SizedBox(height: isDesktop ? 8 : 8.h),
          Text(
            AppStrings.reportsSummaryDesc.tr(),
            style: TextStyles.customStyle(
              fontSize: isDesktop ? 12 : 12,
              color: AppColors.blackLight,
            ),
          ),
          SizedBox(height: isDesktop ? 16 : 16.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(isDesktop ? 10 : 10.r),
            child: LinearProgressIndicator(
              value: report.averageAttendanceRate / 100,
              minHeight: 10,
              backgroundColor: AppColors.veryLightGrey,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDesktop,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 16.w,
        vertical: isDesktop ? 12 : 10.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
        border: Border.all(color: AppColors.veryLightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                radius: isDesktop ? 16 : 16.r,
                child: Icon(icon, color: color, size: isDesktop ? 18 : 16),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 8 : 8.h),
          Text(
            value,
            style: TextStyles.customStyle(
              fontSize: isDesktop ? 20 : 18,
              fontWeight: FontWeight.w900,
              color: AppColors.blackReal,
            ),
          ),
          SizedBox(height: isDesktop ? 4 : 4.h),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.customStyle(
              fontSize: isDesktop ? 12 : 11,
              color: AppColors.blackLight,
            ),
          ),
        ],
      ),
    );
  }
}
