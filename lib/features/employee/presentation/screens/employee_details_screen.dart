import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/employee/domain/entities/attendance_entity.dart';
import 'package:tahsel/features/employee/domain/entities/employee_entity.dart';
import 'package:tahsel/features/employee/domain/entities/payroll_entity.dart';
import 'package:tahsel/features/employee/presentation/cubit/employee_cubit.dart';
import 'package:tahsel/features/employee/presentation/cubit/employee_state.dart';
import 'package:tahsel/features/employee/presentation/widgets/check_in_out_dialog.dart';
import 'package:tahsel/features/employee/presentation/widgets/employee_details_tab_selector.dart';
import 'package:tahsel/features/employee/presentation/widgets/pay_salary_dialog.dart';
import 'package:tahsel/features/expenses/domain/entities/expense_entity.dart';
import 'package:tahsel/features/expenses/presentation/cubit/expense_cubit.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

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
      List<AttendanceEntity> attendanceLogs, List<PayrollEntity> payrollLogs) {
    double pendingBase = 0.0;
    double pendingOvertimeComp = 0.0;
    double unpaidOvertimeHours = 0.0;
    double unpaidWorkedHours = 0.0;
    double pendingDeductions = 0.0;
    int unpaidDaysCount = 0;
    int unpaidAttendanceCount = 0;

    DateTime latestPaymentDate = DateTime(2000);
    for (final p in payrollLogs) {
      if (p.paymentDate.isAfter(latestPaymentDate)) {
        latestPaymentDate = p.paymentDate;
      }
    }

    final unpaidAttendance = attendanceLogs
        .where((log) => log.checkIn.isAfter(latestPaymentDate))
        .toList();

    final salaryType = widget.employee.salaryType;
    final baseAmount = widget.employee.salaryAmount;

    double overtimeHourlyRate = 10.0;
    if (salaryType == 'monthly') {
      overtimeHourlyRate = baseAmount / (26 * 8) * 1.5;
    } else if (salaryType == 'daily') {
      overtimeHourlyRate = baseAmount / 8 * 1.5;
    } else {
      overtimeHourlyRate = baseAmount * 1.5;
    }

    if (salaryType == 'hourly') {
      for (final log in unpaidAttendance) {
        if (log.checkOut != null) {
          final workedHrs =
              log.checkOut!.difference(log.checkIn).inMinutes / 60.0;
          unpaidWorkedHours += workedHrs;
          pendingBase += workedHrs * baseAmount;
          unpaidAttendanceCount++;
        }
        unpaidOvertimeHours += log.overtimeHours;
        pendingOvertimeComp += log.overtimeHours * overtimeHourlyRate;
        pendingDeductions += log.deductionHours * baseAmount;
      }
    } else if (salaryType == 'daily') {
      for (final log in unpaidAttendance) {
        unpaidDaysCount++;
        unpaidAttendanceCount++;
        if (log.status == 'present' || log.status == 'late') {
          pendingBase += baseAmount;
        } else if (log.status == 'half_day') {
          pendingBase += baseAmount * 0.5;
        }
        unpaidOvertimeHours += log.overtimeHours;
        pendingOvertimeComp += log.overtimeHours * overtimeHourlyRate;

        double hourlyRate = baseAmount / 8;
        pendingDeductions += log.deductionHours * hourlyRate;
      }
    } else {
      pendingBase = baseAmount;
      for (final log in unpaidAttendance) {
        unpaidDaysCount++;
        unpaidAttendanceCount++;
        if (log.status == 'absent') {
          pendingDeductions += baseAmount / 26;
        }
        unpaidOvertimeHours += log.overtimeHours;
        pendingOvertimeComp += log.overtimeHours * overtimeHourlyRate;

        double hourlyRate = baseAmount / (26 * 8);
        pendingDeductions += log.deductionHours * hourlyRate;
      }
    }

    final double netSalary =
        pendingBase + pendingOvertimeComp - pendingDeductions;

    return {
      'pendingBase': pendingBase,
      'pendingOvertimeComp': pendingOvertimeComp,
      'unpaidOvertimeHours': unpaidOvertimeHours,
      'unpaidWorkedHours': unpaidWorkedHours,
      'pendingDeductions': pendingDeductions,
      'unpaidDaysCount': unpaidDaysCount,
      'unpaidCount': unpaidAttendanceCount,
      'netSalary': netSalary < 0 ? 0.0 : netSalary,
      'overtimeRate': overtimeHourlyRate,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final localeCode = AppStrings.currentLang;
    final dateFormatter = DateFormat('yyyy-MM-dd hh:mm a', localeCode);

    Color statusColor = AppColors.success;
    if (widget.employee.status == 'suspended') {
      statusColor = AppColors.error;
    } else if (widget.employee.status == 'inactive') {
      statusColor = AppColors.blackLight;
    }

    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.employee.name,
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
      body: BlocConsumer<EmployeeCubit, EmployeeState>(
        listener: (context, state) {
          if (state is EmployeeActionSuccess) {
            _loadInitialData();
          }
        },
        builder: (context, state) {
          if (state is EmployeeLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
                strokeWidth: 3,
              ),
            );
          }

          if (state is EmployeeDetailsFetchSuccess) {
            final attendanceLogs = state.attendanceLogs;
            final payrollLogs = state.payrollLogs;

            AttendanceEntity? activeCheckIn;
            for (final log in attendanceLogs) {
              if (log.checkOut == null) {
                activeCheckIn = log;
                break;
              }
            }

            final pending = _calculatePendingSalary(attendanceLogs, payrollLogs);
            final double netSalary = pending['netSalary'];
            final double baseSalary = pending['pendingBase'];
            final double overtimeComp = pending['pendingOvertimeComp'];
            final double deductions = pending['pendingDeductions'];
            final double overtimeHours = pending['unpaidOvertimeHours'];
            final double workedHours = pending['unpaidWorkedHours'];
            final int unpaidCount = pending['unpaidCount'];

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
                                      _buildProfileHeader(true, statusColor),
                                      const SizedBox(height: 16),
                                      _buildLiveCheckInCard(
                                          dateFormatter, true, activeCheckIn),
                                      const SizedBox(height: 16),
                                      _buildPendingSalaryCard(
                                        pending,
                                        netSalary,
                                        baseSalary,
                                        overtimeComp,
                                        deductions,
                                        overtimeHours,
                                        workedHours,
                                        unpaidCount,
                                        true,
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
                                    borderRadius: BorderRadius.circular(16.r),
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
                                              state.isPaginationLoadingAttendance,
                                              state.hasReachedMaxAttendance,
                                            ),
                                            CustomScrollView(
                                              controller: _payrollScrollController,
                                              slivers: [
                                                _buildPayrollList(
                                                  true,
                                                  payrollLogs,
                                                  state.isPaginationLoadingPayroll,
                                                  state.hasReachedMaxPayroll,
                                                )
                                              ],
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
                              _buildProfileHeader(false, statusColor),
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
                                      false,
                                      dateFormatter,
                                      attendanceLogs,
                                      state.isPaginationLoadingAttendance,
                                      state.hasReachedMaxAttendance,
                                      activeCheckIn,
                                    ),
                                    _buildPayrollTab(
                                      false,
                                      pending,
                                      payrollLogs,
                                      state.isPaginationLoadingPayroll,
                                      state.hasReachedMaxPayroll,
                                      netSalary,
                                      baseSalary,
                                      overtimeComp,
                                      deductions,
                                      overtimeHours,
                                      workedHours,
                                      unpaidCount,
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
            return Center(
              child: Text(
                state.message,
                style: TextStyles.customStyle(
                  fontSize: 14,
                  color: AppColors.error,
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProfileHeader(bool isDesktop, Color statusColor) {
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
                            widget.employee.name,
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
                            widget.employee.status.tr(),
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
                      widget.employee.role,
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
                            widget.employee.phone,
                            style: TextStyles.customStyle(
                              fontSize: isDesktop ? 13 : 13,
                              color: AppColors.blackLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.employee.notes.isNotEmpty) ...[
            SizedBox(height: isDesktop ? 12 : 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isDesktop ? 10 : 10.w),
              decoration: BoxDecoration(
                color: AppColors.veryLightGrey,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                widget.employee.notes,
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
      bool isDesktop,
      DateFormat dateFormatter,
      List<AttendanceEntity> attendanceLogs,
      bool isLoadingMore,
      bool hasReachedMax,
      AttendanceEntity? activeCheckIn) {
    return Column(
      children: [
        _buildLiveCheckInCard(dateFormatter, isDesktop, activeCheckIn),
        Expanded(
            child: _buildAttendanceList(
                dateFormatter, isDesktop, attendanceLogs, isLoadingMore, hasReachedMax)),
      ],
    );
  }

  Widget _buildLiveCheckInCard(
      DateFormat dateFormatter, bool isDesktop, AttendanceEntity? activeCheckIn) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(isDesktop ? 0 : 16.w),
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
                    "${AppStrings.checkedInAt.tr()}: ${dateFormatter.format(activeCheckIn.checkIn)}",
                    style: TextStyles.customStyle(
                      fontSize: 12,
                      color: AppColors.sandText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: isDesktop ? 12 : 12.w),
          Flexible(
            child: ElevatedButton.icon(
              onPressed: () => _showCheckInOutDialog(widget.employee, activeCheckIn),
              icon: Icon(
                activeCheckIn != null
                    ? Icons.logout_rounded
                    : Icons.login_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                (activeCheckIn != null
                        ? AppStrings.confirmCheckout
                        : AppStrings.checkIn)
                    .tr(),
                style: TextStyles.customStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: activeCheckIn != null
                    ? AppColors.warning
                    : AppColors.success,
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
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(DateFormat dateFormatter, bool isDesktop,
      List<AttendanceEntity> attendanceLogs, bool isLoadingMore, bool hasReachedMax) {
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
        final dateStr = DateFormat('yyyy-MM-dd').format(log.checkIn);
        final checkInStr = DateFormat(
          'hh:mm a',
          AppStrings.currentLang,
        ).format(log.checkIn);
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
            side: BorderSide(color: AppColors.veryLightGrey),
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
                            "${(log.checkOut != null ? log.checkOut!.difference(log.checkIn).inMinutes / 60.0 : 0.0).toStringAsFixed(1)} ${AppStrings.hours.tr()}",
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
  ) {
    return CustomScrollView(
      controller: _payrollScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: _buildPendingSalaryCard(
              pending,
              netSalary,
              baseSalary,
              overtimeComp,
              deductions,
              overtimeHours,
              workedHours,
              unpaidCount,
              isDesktop,
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
    Map<String, dynamic> pending,
    double netSalary,
    double baseSalary,
    double overtimeComp,
    double deductions,
    double overtimeHours,
    double workedHours,
    int unpaidCount,
    bool isDesktop,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
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
                        "${netSalary.toSmartAmount()} ${AppStrings.egp.tr()}",
                        style: TextStyles.customStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => PaySalaryDialog(
                    employee: widget.employee,
                    initialBaseSalary: baseSalary > 0
                        ? baseSalary
                        : widget.employee.salaryAmount,
                    initialOvertimeHours: overtimeHours,
                    initialOvertimeRate: pending['overtimeRate'],
                    initialDeductions: deductions,
                    onPay: (payroll) {
                      context.read<EmployeeCubit>().payPayroll(payroll).then((
                        _,
                      ) {
                        String salaryTypeLabel;
                        switch (payroll.salaryType) {
                          case 'monthly':
                            salaryTypeLabel = AppStrings.monthly.tr();
                            break;
                          case 'daily':
                            salaryTypeLabel = AppStrings.daily.tr();
                            break;
                          case 'hourly':
                            salaryTypeLabel = AppStrings.hourly.tr();
                            break;
                          default:
                            salaryTypeLabel = AppStrings.monthly.tr();
                        }

                        final categoryName = AppStrings.salaryExpenseFor.tr(
                          namedArgs: {
                            'type': salaryTypeLabel,
                            'name': payroll.employeeName,
                          },
                        );

                        final expense = ExpenseEntity(
                          uid: AppStrings.userToken,
                          amount: payroll.netSalary,
                          category: categoryName,
                          description: payroll.notes,
                          createdAt: payroll.paymentDate,
                          monthKey: payroll.monthKey,
                        );
                        if (!mounted) return;
                        context.read<ExpenseCubit>().addExpense(expense);
                      });
                    },
                  ),
                );
              },
              icon: const Icon(
                Icons.payment_rounded,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                AppStrings.paySalary.tr(),
                style: TextStyles.customStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorContainer,
                foregroundColor: Colors.white,
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
                    "${baseSalary.toStringAsFixed(2)} ${AppStrings.egp.tr()}",
                  ),
                ),
                Expanded(
                  child: _buildPendingMetricItem(
                    AppStrings.pendingOvertimeComp.tr(),
                    "${overtimeComp.toStringAsFixed(2)} ${AppStrings.egp.tr()} ($overtimeHours h)",
                  ),
                ),
                Expanded(
                  child: _buildPendingMetricItem(
                    AppStrings.pendingDeductionsEst.tr(),
                    "-${deductions.toStringAsFixed(2)} ${AppStrings.egp.tr()}",
                    isDeduction: true,
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 8 : 8.h),
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 12,
                  color: Colors.white70,
                ),
                SizedBox(width: isDesktop ? 4 : 4.w),
                Text(
                  widget.employee.salaryType == 'hourly'
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
        ),
      ),
    );
  }

  Widget _buildPayrollList(
      bool isDesktop, List<PayrollEntity> payrollLogs, bool isLoadingMore, bool hasReachedMax) {
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
        delegate: SliverChildBuilderDelegate((context, idx) {
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
        }, childCount: payrollLogs.length + ((isLoadingMore && !hasReachedMax) ? 1 : 0)),
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
            color: isDeduction ? const Color(0xFFFFBABA) : Colors.white,
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
      EmployeeEntity employee, AttendanceEntity? activeCheckIn) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return CheckInOutDialog(
          employee: employee,
          activeAttendance: activeCheckIn,
          onCheckIn: (attendance) {
            context.read<EmployeeCubit>().checkIn(attendance);
          },
          onCheckOut: ({
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
}
