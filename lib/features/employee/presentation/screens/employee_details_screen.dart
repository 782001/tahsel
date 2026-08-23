import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/utils/vault_balance_helper.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/employee/domain/entities/advance_entity.dart';
import 'package:tahsel/features/employee/domain/entities/attendance_entity.dart';
import 'package:tahsel/features/employee/domain/entities/employee_entity.dart';
import 'package:tahsel/features/employee/domain/entities/payroll_entity.dart';
import 'package:tahsel/features/employee/domain/services/employee_operation_guard.dart';
import 'package:tahsel/features/employee/domain/utils/monthly_payroll_calculator.dart';
import 'package:tahsel/features/employee/presentation/cubit/employee_cubit.dart';
import 'package:tahsel/features/employee/presentation/cubit/employee_state.dart';
import 'package:tahsel/features/employee/presentation/widgets/check_in_out_dialog.dart';
import 'package:tahsel/features/employee/presentation/widgets/employee_details_tab_selector.dart';
import 'package:tahsel/features/employee/presentation/widgets/pay_salary_dialog.dart';
import 'package:tahsel/features/employee/presentation/widgets/request_advance_dialog.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/no_internet_view.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  final EmployeeEntity employee;

  const EmployeeDetailsScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _attendanceScrollController = ScrollController();
  final ScrollController _payrollScrollController = ScrollController();
  final ScrollController _advanceScrollController = ScrollController();
  final EmployeeOperationGuard _guard = sl<EmployeeOperationGuard>();
  EmployeeDetailsFetchSuccess? _cachedDetails;

  /// Shows a SnackBar explaining why an action is blocked based on status.
  void _showStatusBlockedSnackBar(String status) {
    final guard = _guard;
    String message;
    if (guard.isSuspended(status)) {
      message = AppStrings.employeeSuspended.tr();
    } else if (guard.isInactive(status)) {
      message = AppStrings.operationNotAvailableForInactive.tr();
    } else {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _attendanceScrollController.addListener(() {
      if (_attendanceScrollController.position.pixels >=
          _attendanceScrollController.position.maxScrollExtent - 200) {
        context.read<EmployeeCubit>().loadMoreAttendance(
          AppStrings.userToken,
          widget.employee.id!,
        );
      }
    });

    _payrollScrollController.addListener(() {
      if (_payrollScrollController.position.pixels >=
          _payrollScrollController.position.maxScrollExtent - 200) {
        context.read<EmployeeCubit>().loadMorePayroll(
          AppStrings.userToken,
          widget.employee.id!,
        );
      }
    });

    _advanceScrollController.addListener(() {
      if (_advanceScrollController.position.pixels >=
          _advanceScrollController.position.maxScrollExtent - 200) {
        context.read<EmployeeCubit>().loadMoreAdvances(
          AppStrings.userToken,
          widget.employee.id!,
        );
      }
    });

    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _attendanceScrollController.dispose();
    _payrollScrollController.dispose();
    _advanceScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    context.read<EmployeeCubit>().fetchEmployeeDetails(
      AppStrings.userToken,
      widget.employee.id!,
      forceRefresh: true,
    );
  }

  Map<String, dynamic> _calculatePendingSalary(
    EmployeeEntity employee,
    List<AttendanceEntity> attendanceLogs,
    List<PayrollEntity> payrollLogs,
  ) {
    if (employee.salaryType == 'monthly') {
      final now = DateTime.now();
      final unpaidCompleted =
          MonthlyPayrollCalculator.getUnpaidCompletedPeriods(
            employee: employee,
            payrollLogs: payrollLogs,
            now: now,
          );

      if (unpaidCompleted.isNotEmpty) {
        final oldestPeriod = unpaidCompleted.first;
        final calcResult = MonthlyPayrollCalculator.calculate(
          employee: employee,
          attendanceLogs: attendanceLogs,
          referenceDate: oldestPeriod.end,
        );
        final status = MonthlyPayrollCalculator.getPeriodStatus(
          period: oldestPeriod,
          windowStart: employee.paymentWindowStart,
          windowEnd: employee.paymentWindowEnd,
          now: now,
        );
        return {
          ...calcResult,
          'status': status,
          'unpaidPeriods': unpaidCompleted,
          'targetPeriod': oldestPeriod,
        };
      } else {
        // No completed unpaid periods, fallback to active period (In Progress)
        final activePeriod = MonthlyPayrollCalculator.getPayrollPeriod(
          closingDay: employee.payrollClosingDay,
          referenceDate: now,
        );
        final calcResult = MonthlyPayrollCalculator.calculate(
          employee: employee,
          attendanceLogs: attendanceLogs,
          referenceDate: now,
        );
        return {
          ...calcResult,
          'status': 'in_progress',
          'unpaidPeriods': <({DateTime start, DateTime end})>[],
          'targetPeriod': activePeriod,
        };
      }
    } else {
      final calcResult = MonthlyPayrollCalculator.calculate(
        employee: employee,
        attendanceLogs: attendanceLogs,
      );
      return {
        ...calcResult,
        'status': 'ready',
        'unpaidPeriods': <({DateTime start, DateTime end})>[],
        'targetPeriod': null,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final localeCode = AppStrings.currentLang;
    final dateFormatter = DateFormat('yyyy-MM-dd hh:mm a', localeCode);

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
        title: BlocBuilder<EmployeeCubit, EmployeeState>(
          builder: (context, state) {
            final name = state is EmployeeDetailsFetchSuccess
                ? state.employee.name
                : widget.employee.name;
            return Text(
              name,
              style: TextStyles.customStyle(
                fontSize: isDesktop ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          },
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
          return BlocConsumer<EmployeeCubit, EmployeeState>(
            listener: (context, state) {
              if (state is EmployeeActionSuccess) {
                _loadInitialData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.actionMessage),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (state is EmployeeFailure) {
                if (state.message.contains(AppStrings.insufficientBalance) ||
                    state.message.contains('insufficient_balance')) {
                  VaultBalanceHelper.showInsufficientBalanceDialog(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            builder: (context, state) {
              if (state is EmployeeDetailsFetchSuccess) {
                _cachedDetails = state;
              }

              final detailsState = state is EmployeeDetailsFetchSuccess
                  ? state
                  : _cachedDetails;

              if (state is EmployeeLoading && detailsState == null) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                    strokeWidth: 3,
                  ),
                );
              }

              if (detailsState != null) {
                final employee = detailsState.employee;
                Color statusColor = AppColors.success;
                if (employee.status == 'suspended') {
                  statusColor = AppColors.error;
                } else if (employee.status == 'inactive') {
                  statusColor = AppColors.blackLight;
                }

                final attendanceLogs = detailsState.attendanceLogs;
                final payrollLogs = detailsState.payrollLogs;

                AttendanceEntity? activeCheckIn;
                for (final log in attendanceLogs) {
                  if ((log.status == 'present' || log.status == 'late') &&
                      log.checkOut == null) {
                    activeCheckIn = log;
                    break;
                  }
                }

                final pending = _calculatePendingSalary(
                  employee,
                  attendanceLogs,
                  payrollLogs,
                );
                final double netSalary = pending['netSalary'];
                final double baseSalary = pending['pendingBase'];
                final double overtimeComp = pending['pendingOvertimeComp'];
                final double deductions = pending['pendingDeductions'];
                final double overtimeHours = pending['unpaidOvertimeHours'];
                final double workedHours = pending['unpaidWorkedHours'];
                final int unpaidCount = pending['unpaidCount'];

                final paidAdvances = detailsState.advanceLogs
                    .where((adv) => adv.status == 'paid')
                    .toList();

                return SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 1100 : double.infinity,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 24 : 0,
                          vertical: isDesktop ? 16 : 0,
                        ),
                        child: isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Column(
                                        children: [
                                          _buildProfileHeader(
                                            true,
                                            statusColor,
                                            employee,
                                          ),
                                          const SizedBox(height: 16),
                                          _buildLiveCheckInCard(
                                            employee,
                                            dateFormatter,
                                            true,
                                            activeCheckIn,
                                            attendanceLogs,
                                          ),
                                          const SizedBox(height: 16),
                                          _buildPendingSalaryCard(
                                            employee,
                                            pending,
                                            netSalary,
                                            baseSalary,
                                            overtimeComp,
                                            deductions,
                                            overtimeHours,
                                            workedHours,
                                            unpaidCount,
                                            true,
                                            paidAdvances,
                                            attendanceLogs,
                                            payrollLogs,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 4,
                                    child: Card(
                                      elevation: 0,
                                      margin: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                        side: BorderSide(
                                          color: AppColors.veryLightGrey,
                                        ),
                                      ),
                                      color: AppColors.whiteColor,
                                      child: Column(
                                        children: [
                                          EmployeeDetailsTabSelector(
                                            selectedIndex: _tabController.index,
                                            onTabChanged: (index) {
                                              _tabController.animateTo(index);
                                            },
                                          ),
                                          Expanded(
                                            child: TabBarView(
                                              controller: _tabController,
                                              children: [
                                                _buildAttendanceList(
                                                  dateFormatter,
                                                  true,
                                                  attendanceLogs,
                                                  detailsState
                                                      .isPaginationLoadingAttendance,
                                                  detailsState
                                                      .hasReachedMaxAttendance,
                                                ),
                                                CustomScrollView(
                                                  controller:
                                                      _payrollScrollController,
                                                  slivers: [
                                                    _buildPayrollList(
                                                      true,
                                                      payrollLogs,
                                                      detailsState
                                                          .isPaginationLoadingPayroll,
                                                      detailsState
                                                          .hasReachedMaxPayroll,
                                                    ),
                                                  ],
                                                ),
                                                _buildAdvancesTab(
                                                  employee,
                                                  true,
                                                  detailsState.advanceLogs,
                                                  detailsState
                                                      .isPaginationLoadingAdvance,
                                                  detailsState
                                                      .hasReachedMaxAdvance,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildProfileHeader(
                                    false,
                                    statusColor,
                                    employee,
                                  ),
                                  Container(
                                    color: AppColors.whiteColor,
                                    child: EmployeeDetailsTabSelector(
                                      selectedIndex: _tabController.index,
                                      onTabChanged: (index) {
                                        _tabController.animateTo(index);
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: TabBarView(
                                      controller: _tabController,
                                      children: [
                                        _buildAttendanceTab(
                                          employee,
                                          false,
                                          dateFormatter,
                                          attendanceLogs,
                                          detailsState
                                              .isPaginationLoadingAttendance,
                                          detailsState.hasReachedMaxAttendance,
                                          activeCheckIn,
                                        ),
                                        _buildPayrollTab(
                                          employee,
                                          false,
                                          pending,
                                          payrollLogs,
                                          detailsState
                                              .isPaginationLoadingPayroll,
                                          detailsState.hasReachedMaxPayroll,
                                          netSalary,
                                          baseSalary,
                                          overtimeComp,
                                          deductions,
                                          overtimeHours,
                                          workedHours,
                                          unpaidCount,
                                          paidAdvances,
                                          attendanceLogs,
                                        ),
                                        _buildAdvancesTab(
                                          employee,
                                          false,
                                          detailsState.advanceLogs,
                                          detailsState
                                              .isPaginationLoadingAdvance,
                                          detailsState.hasReachedMaxAdvance,
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

              if (state is EmployeeFailure) {
                AppLogger.printMessage(state.message);
                return Center(
                  child: Text(
                    AppStrings.noData.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      color: AppColors.error,
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(
    bool isDesktop,
    Color statusColor,
    EmployeeEntity employee,
  ) {
    return Container(
      width: double.infinity,
      decoration: isDesktop
          ? BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.veryLightGrey),
            )
          : BoxDecoration(color: AppColors.whiteColor),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20 : 16.w,
        vertical: isDesktop ? 20 : 16.h,
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(width: isDesktop ? 16 : 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            employee.name,
                            style: TextStyles.customStyle(
                              fontSize: isDesktop ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blackReal,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: isDesktop ? 8 : 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 10 : 10.w,
                            vertical: isDesktop ? 2 : 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            employee.status.tr(),
                            style: TextStyles.customStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isDesktop ? 4 : 4.h),
                    Text(
                      employee.role,
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 14 : 14,
                        color: AppColors.sandText,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 4 : 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_iphone_rounded,
                          size: 14,
                          color: AppColors.blackLight,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            employee.phone,
                            style: TextStyles.customStyle(
                              fontSize: isDesktop ? 13 : 13,
                              color: AppColors.blackLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.baseSalary.tr(),
                                style: TextStyles.customStyle(
                                  fontSize: 11,
                                  color: AppColors.blackLight,
                                ),
                              ),
                              Text(
                                "${employee.salaryAmount.toSmartAmount()} / ${employee.salaryType.tr()}",
                                style: TextStyles.customStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.blackReal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (employee.notes.isNotEmpty) ...[
            SizedBox(height: isDesktop ? 12 : 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isDesktop ? 10 : 10.w),
              decoration: BoxDecoration(
                color: AppColors.veryLightGrey,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                employee.notes,
                style: TextStyles.customStyle(
                  fontSize: 12,
                  color: AppColors.blackLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceTab(
    EmployeeEntity employee,
    bool isDesktop,
    DateFormat dateFormatter,
    List<AttendanceEntity> attendanceLogs,
    bool isLoadingMore,
    bool hasReachedMax,
    AttendanceEntity? activeCheckIn,
  ) {
    return Column(
      children: [
        _buildLiveCheckInCard(
          employee,
          dateFormatter,
          isDesktop,
          activeCheckIn,
          attendanceLogs,
        ),
        Expanded(
          child: _buildAttendanceList(
            dateFormatter,
            isDesktop,
            attendanceLogs,
            isLoadingMore,
            hasReachedMax,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveCheckInCard(
    EmployeeEntity employee,
    DateFormat dateFormatter,
    bool isDesktop,
    AttendanceEntity? activeCheckIn,
    List<AttendanceEntity> attendanceLogs,
  ) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(isDesktop ? 0 : 16.w),
      padding: EdgeInsets.all(isDesktop ? 16 : 16.w),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeCheckIn != null
                          ? AppStrings.currentlyWorking.tr()
                          : AppStrings.notCheckedIn.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackReal,
                      ),
                    ),
                    if (activeCheckIn != null) ...[
                      SizedBox(height: isDesktop ? 4 : 4.h),
                      Text(
                        "${AppStrings.checkedInAt.tr()}: ${activeCheckIn.checkIn != null ? dateFormatter.format(activeCheckIn.checkIn!) : ''}",
                        style: TextStyles.customStyle(
                          fontSize: 12,
                          color: AppColors.sandText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (activeCheckIn != null) ...[
                SizedBox(width: isDesktop ? 12 : 12.w),
                ElevatedButton.icon(
                  onPressed: _guard.canCheckOut(employee.status)
                      ? () => _showCheckInOutDialog(
                          employee,
                          activeCheckIn,
                          attendanceLogs,
                        )
                      : () => _showStatusBlockedSnackBar(employee.status),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    AppStrings.confirmCheckout.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 16 : 16.w,
                      vertical: isDesktop ? 10 : 10.h,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (activeCheckIn == null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _guard.canCheckIn(employee.status)
                      ? () => _showCheckInOutDialog(
                          employee,
                          activeCheckIn,
                          attendanceLogs,
                        )
                      : () => _showStatusBlockedSnackBar(employee.status),
                  icon: const Icon(
                    Icons.login_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    AppStrings.checkIn.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 16 : 16.w,
                      vertical: isDesktop ? 10 : 10.h,
                    ),
                  ),
                ),
                if (employee.salaryType == "monthly") ...[
                  OutlinedButton.icon(
                    onPressed: _guard.canModifyAttendance(employee.status)
                        ? () => _showMarkExceptionDialog(
                            context,
                            employee,
                            'absent',
                          )
                        : () => _showStatusBlockedSnackBar(employee.status),
                    icon: Icon(
                      Icons.cancel_outlined,
                      color: AppColors.error,
                      size: 18,
                    ),
                    label: Text(
                      AppStrings.markAbsent.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 16 : 16.w,
                        vertical: isDesktop ? 10 : 10.h,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _guard.canModifyAttendance(employee.status)
                        ? () => _showMarkExceptionDialog(
                            context,
                            employee,
                            'excused',
                          )
                        : () => _showStatusBlockedSnackBar(employee.status),
                    icon: Icon(
                      Icons.event_busy_rounded,
                      color: AppColors.blackLight,
                      size: 18,
                    ),
                    label: Text(
                      AppStrings.markExcused.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackLight,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.blackLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 16 : 16.w,
                        vertical: isDesktop ? 10 : 10.h,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showMarkExceptionDialog(
    BuildContext context,
    EmployeeEntity employee,
    String status,
  ) {
    final formKey = GlobalKey<FormState>();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final employeeCubit = context.read<EmployeeCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              backgroundColor: AppColors.scafoldBackGround,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 400 : double.infinity,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 20.w,
                    vertical: isDesktop ? 24 : 20.h,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              (status == 'absent'
                                      ? AppStrings.markAbsent
                                      : AppStrings.markExcused)
                                  .tr(),
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: status == 'absent'
                                    ? AppColors.error
                                    : AppColors.blackLight,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close),
                              color: AppColors.blackLight,
                            ),
                          ],
                        ),
                        const Divider(),
                        SizedBox(height: 12.h),
                        Text(
                          AppStrings.dateLabel.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        InkWell(
                          borderRadius: BorderRadius.circular(10.r),
                          onTap: () async {
                            final DateTime? date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: AppColors.isDark
                                        ? ColorScheme.dark(
                                            primary: AppColors.primaryColor,
                                          )
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
                            if (date != null) {
                              setState(() {
                                selectedDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.surfaceContainerHigh,
                              ),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('yyyy-MM-dd').format(selectedDate),
                                  style: TextStyles.customStyle(
                                    fontSize: 14,
                                    color: AppColors.blackReal,
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today_rounded,
                                  color: AppColors.primaryColor,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          AppStrings.notes.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        TextFormField(
                          cursorColor: AppColors.primaryColor,
                          controller: notesController,
                          decoration: InputDecoration(
                            hintText: AppStrings.addNotesPlaceholder.tr(),
                            hintStyle: TextStyles.customStyle(
                              fontSize: 13,
                              color: AppColors.blackLight.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: BorderSide(
                                color: AppColors.surfaceContainerHigh,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: BorderSide(
                                color: AppColors.surfaceContainerHigh,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: BorderSide(
                                color: AppColors.primaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                          style: TextStyles.customStyle(
                            fontSize: 14,
                            color: AppColors.blackReal,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                                child: Text(
                                  AppStrings.cancel.tr(),
                                  style: TextStyles.customStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blackLight,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    final targetDateStr = DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(selectedDate);
                                    employeeCubit.markAbsentOrExcused(
                                      uid: AppStrings.userToken,
                                      employeeId: employee.id!,
                                      employeeName: employee.name,
                                      date: targetDateStr,
                                      status: status,
                                      notes: notesController.text.trim(),
                                    );
                                    Navigator.pop(dialogContext);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: status == 'absent'
                                      ? AppColors.error
                                      : AppColors.blackLight,
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  AppStrings.confirm.tr(),
                                  style: TextStyles.customStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAttendanceList(
    DateFormat dateFormatter,
    bool isDesktop,
    List<AttendanceEntity> attendanceLogs,
    bool isLoadingMore,
    bool hasReachedMax,
  ) {
    if (attendanceLogs.isEmpty) {
      return Center(
        child: Text(
          AppStrings.noAttendanceLogs.tr(),
          style: TextStyles.customStyle(
            fontSize: 14,
            color: AppColors.blackLight,
          ),
        ),
      );
    }

    final showLoader = isLoadingMore && !hasReachedMax;

    return ListView.builder(
      controller: _attendanceScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 16.w,
        vertical: isDesktop ? 12 : 12.h,
      ),
      itemCount: attendanceLogs.length + (showLoader ? 1 : 0),
      itemBuilder: (context, idx) {
        if (idx == attendanceLogs.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          );
        }

        final log = attendanceLogs[idx];
        final dateStr = log.checkIn != null
            ? DateFormat('yyyy-MM-dd').format(log.checkIn!)
            : log.date;
        final checkInStr = log.checkIn != null
            ? DateFormat('hh:mm a', AppStrings.currentLang).format(log.checkIn!)
            : '--:--';
        final checkOutStr = log.checkOut != null
            ? DateFormat(
                'hh:mm a',
                AppStrings.currentLang,
              ).format(log.checkOut!)
            : '--:--';

        Color statusBgColor = AppColors.success;
        if (log.status == 'late') {
          statusBgColor = AppColors.warning;
        } else if (log.status == 'absent' || log.status == 'suspended') {
          statusBgColor = AppColors.error;
        } else if (log.status == 'excused') {
          statusBgColor = AppColors.blackLight;
        }

        return Card(
          elevation: 0,
          margin: EdgeInsets.only(bottom: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(color: AppColors.dividerColor),
          ),
          color: AppColors.whiteColor,
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 12 : 12.w),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: AppColors.sandText,
                          ),
                          SizedBox(width: isDesktop ? 6 : 6.w),
                          Expanded(
                            child: Text(
                              dateStr,
                              style: TextStyles.customStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blackReal,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 8 : 8.w,
                        vertical: isDesktop ? 2 : 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        log.status.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusBgColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.workingHours.tr(),
                            style: TextStyles.customStyle(
                              fontSize: 11,
                              color: AppColors.blackLight,
                            ),
                          ),
                          Text(
                            "${(log.checkOut != null && log.checkIn != null ? log.checkOut!.difference(log.checkIn!).inMinutes / 60.0 : 0.0).toStringAsFixed(1)} ${AppStrings.hours.tr()}",
                            style: TextStyles.customStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blackReal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            AppStrings.checkIn.tr(),
                            style: TextStyles.customStyle(
                              fontSize: 11,
                              color: AppColors.blackLight,
                            ),
                          ),
                          Text(
                            checkInStr,
                            style: TextStyles.customStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppStrings.checkOut.tr(),
                            style: TextStyles.customStyle(
                              fontSize: 11,
                              color: AppColors.blackLight,
                            ),
                          ),
                          Text(
                            checkOutStr,
                            style: TextStyles.customStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: log.checkOut != null
                                  ? AppColors.warning
                                  : AppColors.blackLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (log.overtimeHours > 0 || log.lateMinutes > 0) ...[
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (log.overtimeHours > 0)
                        Text(
                          "+${log.overtimeHours} ${AppStrings.overtimeHours.tr()}",
                          style: TextStyles.customStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      if (log.lateMinutes > 0)
                        Text(
                          "${log.lateMinutes} ${AppStrings.lateArrivalMins.tr()}",
                          style: TextStyles.customStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                    ],
                  ),
                ],
                if (log.notes.isNotEmpty) ...[
                  const Divider(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "${AppStrings.notes.tr()}: ${log.notes}",
                      style: TextStyles.customStyle(
                        fontSize: 11,
                        color: AppColors.blackLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPayrollTab(
    EmployeeEntity employee,
    bool isDesktop,
    Map<String, dynamic> pending,
    List<PayrollEntity> payrollLogs,
    bool isLoadingMore,
    bool hasReachedMax,
    double netSalary,
    double baseSalary,
    double overtimeComp,
    double deductions,
    double overtimeHours,
    double workedHours,
    int unpaidCount,
    List<AdvanceEntity> paidAdvances,
    List<AttendanceEntity> attendanceLogs,
  ) {
    return CustomScrollView(
      controller: _payrollScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: _buildPendingSalaryCard(
              employee,
              pending,
              netSalary,
              baseSalary,
              overtimeComp,
              deductions,
              overtimeHours,
              workedHours,
              unpaidCount,
              isDesktop,
              paidAdvances,
              attendanceLogs,
              payrollLogs,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              top: 12.h,
              bottom: 8.h,
            ),
            child: Text(
              AppStrings.payrollHistoryTitle.tr(),
              style: TextStyles.customStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.blackReal,
              ),
            ),
          ),
        ),
        _buildPayrollList(isDesktop, payrollLogs, isLoadingMore, hasReachedMax),
      ],
    );
  }

  Widget _buildPendingSalaryCard(
    EmployeeEntity employee,
    Map<String, dynamic> pending,
    double netSalary,
    double baseSalary,
    double overtimeComp,
    double deductions,
    double overtimeHours,
    double workedHours,
    int unpaidCount,
    bool isDesktop,
    List<AdvanceEntity> paidAdvances,
    List<AttendanceEntity> attendanceLogs,
    List<PayrollEntity> payrollLogs,
  ) {
    // final today = DateTime.now().day;
    final start = employee.paymentWindowStart;
    final end = employee.paymentWindowEnd;

    final String status = pending['status'] ?? 'ready';
    final bool isWithinWindow = employee.salaryType == 'monthly'
        ? (status == 'ready' || status == 'overdue')
        : true;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: [
            AppColors.blue100,
            AppColors.primaryColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 16 : 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.estimatedNetSalary.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 4 : 4.h),
                      Text(
                        "${netSalary.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
                        style: TextStyles.customStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (employee.salaryType == 'monthly') ...[
                  _buildPayrollStatusBadge(status),
                ],
              ],
            ),
            const SizedBox(height: 10),
            if (employee.salaryType == 'monthly' &&
                pending['periodStart'] != null &&
                pending['periodEnd'] != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 10 : 10.w,
                  vertical: isDesktop ? 6 : 6.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.date_range_rounded,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "${AppStrings.payrollPeriod.tr()}: ${DateFormat('yyyy-MM-dd').format(pending['periodStart'])} ${AppStrings.currentLang == "en" ? "→→" : "←←"} ${DateFormat('yyyy-MM-dd').format(pending['periodEnd'])}",
                        style: TextStyles.customStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (employee.salaryType == 'monthly' &&
                (status == 'in_progress' || status == 'waiting_window')) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(isDesktop ? 10 : 10.w),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.white38),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        status == 'in_progress'
                            ? AppStrings.payrollInProgressWarning.tr()
                            : AppStrings.payrollWaitingWindowWarning.tr(
                                namedArgs: {
                                  'start': start.toString(),
                                  'end': end.toString(),
                                },
                              ),
                        style: TextStyles.customStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (employee.outstandingBalance > 0) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(isDesktop ? 10 : 10.w),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.white38),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${AppStrings.outstandingBalance.tr()}: ${employee.outstandingBalance.toSmartAmount()} ${AppStrings.currencyEgp.tr()}\n${AppStrings.carriedForwardAutomatically.tr()}",
                        style: TextStyles.customStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ElevatedButton.icon(
              onPressed: !isWithinWindow
                  ? null
                  : !_guard.canPaySalary(employee.status)
                  ? () => _showStatusBlockedSnackBar(employee.status)
                  : () {
                      if (context.read<ConnectivityCubit>().state
                          is ConnectivityDisconnected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.noInternetConnection.tr()),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      if (unpaidCount == 0
                      //  && employee.outstandingBalance <= 0
                      ) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.noPendingRecords.tr()),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      showDialog(
                        context: context,
                        builder: (ctx) => PaySalaryDialog(
                          employee: employee,
                          initialBaseSalary: baseSalary,
                          initialOvertimeHours: overtimeHours,
                          initialOvertimeRate: pending['overtimeRate'],
                          initialDeductions: deductions,
                          paidAdvances: paidAdvances,
                          paidMonthKeys: payrollLogs
                              .map((log) => log.monthKey)
                              .toList(),
                          payrollLogs: payrollLogs,
                          pendingMap: pending,
                          periodStart: pending['targetPeriod'] != null
                              ? (pending['targetPeriod'] as dynamic).start
                              : null,
                          periodEnd: pending['targetPeriod'] != null
                              ? (pending['targetPeriod'] as dynamic).end
                              : null,
                          onPay: (payroll, paidAdvanceIds) {
                            // Collect IDs of unpaid, completed attendance records within active payroll period
                            final unpaidAttendanceIds = attendanceLogs
                                .where((log) {
                                  if (log.isPaid ||
                                      log.checkOut == null ||
                                      log.id == null) {
                                    return false;
                                  }
                                  if (employee.salaryType == 'monthly') {
                                    final periodStart =
                                        pending['periodStart'] as DateTime?;
                                    final periodEnd =
                                        pending['periodEnd'] as DateTime?;
                                    if (periodStart != null &&
                                        periodEnd != null) {
                                      final logDate = DateTime.tryParse(
                                        log.date,
                                      );
                                      if (logDate == null) return false;
                                      return (logDate.isAtSameMomentAs(
                                                periodStart,
                                              ) ||
                                              logDate.isAfter(periodStart)) &&
                                          (logDate.isAtSameMomentAs(
                                                periodEnd,
                                              ) ||
                                              logDate.isBefore(periodEnd));
                                    }
                                  }
                                  return true;
                                })
                                .map((log) => log.id!)
                                .toList();
                            context
                                .read<EmployeeCubit>()
                                .payPayroll(
                                  payroll,
                                  advanceIdsToDeduct: paidAdvanceIds,
                                  attendanceIds: unpaidAttendanceIds,
                                );
                          },
                        ),
                      );
                    },
              icon: Icon(
                Icons.payment_rounded,
                size: 16,
                color: AppColors.black,
              ),
              label: Text(
                AppStrings.paySalary.tr(),
                style: TextStyles.customStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorContainer,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white24,
                disabledForegroundColor: Colors.white54,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 12 : 14.w,
                  vertical: isDesktop ? 8 : 8.h,
                ),
              ),
            ),
            const Divider(color: Colors.white24, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildPendingMetricItem(
                    AppStrings.pendingBaseSalary.tr(),
                    "${baseSalary.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
                  ),
                ),
                if (employee.salaryType != 'hourly') ...[
                  Expanded(
                    child: _buildPendingMetricItem(
                      AppStrings.pendingOvertimeComp.tr(),
                      "${overtimeComp.toSmartAmount()} ${AppStrings.currencyEgp.tr()}\n (${overtimeHours.toSmartAmount()} ${AppStrings.hours.tr()})",
                    ),
                  ),
                  Expanded(
                    child: _buildPendingMetricItem(
                      AppStrings.pendingDeductionsEst.tr(),
                      "-${deductions.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
                      isDeduction: true,
                    ),
                  ),
                ],
              ],
            ),
            if (employee.salaryType == 'monthly') ...[
              SizedBox(height: isDesktop ? 8 : 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isDesktop ? 10 : 10.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.attendanceStatus.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildPendingMetricItem(
                            AppStrings.totalPeriodDays.tr(),
                            "${pending['totalDaysInPeriod'] ?? 30}",
                          ),
                        ),
                        Expanded(
                          child: _buildPendingMetricItem(
                            AppStrings.workedDays.tr(),
                            "${pending['workedDays'] ?? 0}",
                          ),
                        ),
                        Expanded(
                          child: _buildPendingMetricItem(
                            AppStrings.missingDays.tr(),
                            "${pending['missingDays'] ?? 0}",
                          ),
                        ),
                        Expanded(
                          child: _buildPendingMetricItem(
                            AppStrings.allowedOffDays.tr(),
                            "${pending['allowedOffDays'] ?? 0}",
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildPendingMetricItem(
                            AppStrings.bonusDays.tr(),
                            "${pending['bonusDays'] ?? 0}",
                          ),
                        ),
                        Expanded(
                          child: _buildPendingMetricItem(
                            AppStrings.deductionDays.tr(),
                            "${pending['deductionDays'] ?? 0}",
                          ),
                        ),
                        Expanded(
                          child: _buildPendingMetricItem(
                            AppStrings.bonusHours.tr(),
                            "${(pending['bonusHours'] as num?)?.toStringAsFixed(1) ?? '0.0'} ${AppStrings.hours.tr()}",
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 12,
                    color: Colors.white70,
                  ),
                  SizedBox(width: isDesktop ? 4 : 4.w),
                  Text(
                    employee.salaryType == 'hourly'
                        ? "$unpaidCount ${AppStrings.attendance.tr()} ($workedHours ${AppStrings.hours.tr()})"
                        : "$unpaidCount ${AppStrings.attendance.tr()} (${pending['unpaidDaysCount']} ${AppStrings.unpaidDays.tr()})",
                    style: TextStyles.customStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPayrollList(
    bool isDesktop,
    List<PayrollEntity> payrollLogs,
    bool isLoadingMore,
    bool hasReachedMax,
  ) {
    if (payrollLogs.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 24 : 24.w),
            child: Text(
              AppStrings.noPreviousPayments.tr(),
              style: TextStyles.customStyle(
                fontSize: 13,
                color: AppColors.blackLight,
              ),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 16.w,
        vertical: isDesktop ? 8 : 8.h,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, idx) {
            if (idx == payrollLogs.length) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              );
            }

            final log = payrollLogs[idx];
            final dateStr = DateFormat('yyyy-MM-dd').format(log.paymentDate);

            return Card(
              elevation: 0,
              margin: EdgeInsets.only(bottom: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(color: AppColors.veryLightGrey),
              ),
              color: AppColors.whiteColor,
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? 14 : 14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.payment_rounded,
                                size: 16,
                                color: AppColors.primaryColor,
                              ),
                              SizedBox(width: isDesktop ? 8 : 8.w),
                              Text(
                                dateStr,
                                style: TextStyles.customStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.blackReal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          log.netSalary.toStringAsFixed(2),
                          style: TextStyles.customStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildAmountItem(
                            AppStrings.baseSalary.tr(),
                            log.amount,
                          ),
                        ),
                        Expanded(
                          child: _buildAmountItem(
                            AppStrings.allowance.tr(),
                            log.bonus,
                          ),
                        ),
                        Expanded(
                          child: _buildAmountItem(
                            AppStrings.deduction.tr(),
                            -log.deduction,
                          ),
                        ),
                      ],
                    ),
                    if (log.overtimeCompensation > 0) ...[
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              AppStrings.totalOvertimeComp.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 12,
                                color: AppColors.sandText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "+${log.overtimeCompensation.toStringAsFixed(2)}",
                            style: TextStyles.customStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (log.notes.isNotEmpty) ...[
                      const Divider(height: 16),
                      Text(
                        "${AppStrings.notes.tr()}: ${log.notes}",
                        style: TextStyles.customStyle(
                          fontSize: 11,
                          color: AppColors.blackLight,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
          childCount:
              payrollLogs.length + ((isLoadingMore && !hasReachedMax) ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildPendingMetricItem(
    String label,
    String value, {
    bool isDeduction = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.customStyle(fontSize: 10, color: Colors.white70),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyles.customStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDeduction ? AppColors.error : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountItem(String title, double amount) {
    Color amtColor = AppColors.blackReal;
    if (amount < 0) {
      amtColor = AppColors.error;
    } else if (amount > 0 && title == AppStrings.allowance.tr()) {
      amtColor = AppColors.success;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyles.customStyle(
            fontSize: 11,
            color: AppColors.blackLight,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          amount.toSmartAmount(),
          style: TextStyles.customStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: amtColor,
          ),
        ),
      ],
    );
  }

  void _showCheckInOutDialog(
    EmployeeEntity employee,
    AttendanceEntity? activeCheckIn,
    List<AttendanceEntity> attendanceLogs,
  ) {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.noInternetConnection.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    double previousWorkedHoursToday = 0.0;
    double previousOvertimeToday = 0.0;
    double previousDeductionToday = 0.0;

    // Determine the target date for same-day records
    final targetDateStr = activeCheckIn != null
        ? DateFormat('yyyy-MM-dd').format(activeCheckIn.checkIn!)
        : DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Collect all completed attendance records for the same day
    final sameDayCompletedRecords = <AttendanceEntity>[];

    for (final log in attendanceLogs) {
      if (log.checkOut == null) continue;
      final logDateStr = DateFormat('yyyy-MM-dd').format(log.checkIn!);
      if (logDateStr == targetDateStr) {
        sameDayCompletedRecords.add(log);
        // Also accumulate previous hours (exclude current active check-in)
        if (activeCheckIn != null && log.id != activeCheckIn.id) {
          final diff = log.checkOut!.difference(log.checkIn!).inMinutes / 60.0;
          previousWorkedHoursToday += diff;
          previousOvertimeToday += log.overtimeHours;
          previousDeductionToday += log.deductionHours;
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return CheckInOutDialog(
          employee: employee,
          activeAttendance: activeCheckIn,
          previousWorkedHoursToday: previousWorkedHoursToday,
          previousOvertimeToday: previousOvertimeToday,
          previousDeductionToday: previousDeductionToday,
          attendanceLogs: attendanceLogs,
          onCheckIn: (attendance) {
            context.read<EmployeeCubit>().checkIn(attendance);
          },
          onCheckOut:
              ({
                required String attendanceId,
                required DateTime checkOutTime,
                required double overtimeHours,
                required double deductionHours,
                required int lateMinutes,
                required String status,
                required String notes,
              }) {
                context.read<EmployeeCubit>().checkOut(
                  uid: AppStrings.userToken,
                  employeeId: employee.id ?? "",
                  attendanceId: attendanceId,
                  checkOutTime: checkOutTime,
                  overtimeHours: overtimeHours,
                  deductionHours: deductionHours,
                  lateMinutes: lateMinutes,
                  status: status,
                  notes: notes,
                );
              },
        );
      },
    );
  }

  void _showRequestAdvanceDialog(EmployeeEntity employee) {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.noInternetConnection.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final employeeCubit = context.read<EmployeeCubit>();
    showDialog(
      context: context,
      builder: (ctx) {
        return BlocProvider.value(
          value: employeeCubit,
          child: RequestAdvanceDialog(employee: employee),
        );
      },
    );
  }

  Widget _buildAdvancesTab(
    EmployeeEntity employee,
    bool isDesktop,
    List<AdvanceEntity> advanceLogs,
    bool isLoadingMore,
    bool hasReachedMax,
  ) {
    return Column(
      children: [
        _buildAdvanceHeaderCard(isDesktop, employee),
        Expanded(
          child: CustomScrollView(
            controller: _advanceScrollController,
            slivers: [
              _buildAdvancesList(
                isDesktop,
                advanceLogs,
                isLoadingMore,
                hasReachedMax,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvanceHeaderCard(bool isDesktop, EmployeeEntity employee) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(isDesktop ? 16 : 16.w),
      padding: EdgeInsets.all(isDesktop ? 16 : 16.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
        border: Border.all(color: AppColors.veryLightGrey),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              AppStrings.advanceHistory.tr(),
              style: TextStyles.customStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.blackReal,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _guard.canRequestAdvance(employee.status)
                ? () {
                    _showRequestAdvanceDialog(employee);
                  }
                : () => _showStatusBlockedSnackBar(employee.status),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 16 : 16.w,
                vertical: isDesktop ? 10 : 8.h,
              ),
            ),
            icon: Icon(
              Icons.add_rounded,
              size: isDesktop ? 18 : 16.r,
              color: Colors.white,
            ),
            label: Text(
              AppStrings.requestAdvance.tr(),
              style: TextStyles.customStyle(
                fontSize: isDesktop ? 12 : 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancesList(
    bool isDesktop,
    List<AdvanceEntity> advanceLogs,
    bool isLoadingMore,
    bool hasReachedMax,
  ) {
    if (advanceLogs.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            AppStrings.noAdvanceLogs.tr(),
            style: TextStyles.customStyle(
              fontSize: 14,
              color: AppColors.blackLight,
            ),
          ),
        ),
      );
    }

    final localeCode = AppStrings.currentLang;
    final dateFormatter = DateFormat('yyyy-MM-dd', localeCode);

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 16.w,
        vertical: isDesktop ? 16 : 8.h,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= advanceLogs.length) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            final log = advanceLogs[index];
            final dateStr = dateFormatter.format(log.date);

            Color statusColor = AppColors.warning;
            String statusText = AppStrings.payment.tr();
            if (log.status == 'deducted') {
              statusColor = AppColors.success;
              statusText = AppStrings.deduction.tr();
            }

            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(isDesktop ? 12 : 12.w),
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.veryLightGrey),
              ),
              child: Row(
                children: [
                  Container(
                    width: isDesktop ? 40 : 40.w,
                    height: isDesktop ? 40 : 40.h,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.primaryColor,
                      size: isDesktop ? 20 : 20.r,
                    ),
                  ),
                  SizedBox(width: isDesktop ? 12 : 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: TextStyles.customStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blackReal,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        if (log.notes.isNotEmpty)
                          Text(
                            log.notes,
                            style: TextStyles.customStyle(
                              fontSize: 11,
                              color: AppColors.blackLight,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        log.amount.toSmartAmount(),
                        style: TextStyles.customStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blackReal,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyles.customStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          childCount:
              advanceLogs.length + ((isLoadingMore && !hasReachedMax) ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildPayrollStatusBadge(String status) {
    Color badgeColor;
    Color textColor;
    String labelKey;

    switch (status) {
      case 'in_progress':
        badgeColor = Colors.blue.shade100.withValues(alpha: 0.2);
        textColor = Colors.blue.shade200;
        labelKey = AppStrings.payrollStatusInProgress;
        break;
      case 'waiting_window':
        badgeColor = Colors.orange.shade100.withValues(alpha: 0.2);
        textColor = Colors.orange.shade200;
        labelKey = AppStrings.payrollStatusWaitingWindow;
        break;
      case 'overdue':
        badgeColor = Colors.red.shade100.withValues(alpha: 0.2);
        textColor = Colors.red.shade300;
        labelKey = AppStrings.payrollStatusOverdue;
        break;
      case 'ready':
      default:
        badgeColor = Colors.green.shade100.withValues(alpha: 0.2);
        textColor = Colors.green.shade300;
        labelKey = AppStrings.payrollStatusReady;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        labelKey.tr(),
        style: TextStyles.customStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
