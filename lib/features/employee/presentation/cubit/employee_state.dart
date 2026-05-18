import 'package:equatable/equatable.dart';
import '../../../offline_sync/data/models/offline_record.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../domain/entities/payroll_entity.dart';

abstract class EmployeeState extends Equatable {
  const EmployeeState();

  @override
  List<Object?> get props => [];
}

class EmployeeInitial extends EmployeeState {}

class EmployeeLoading extends EmployeeState {}

class EmployeeFetchSuccess extends EmployeeState {
  final List<EmployeeEntity> employees;
  final List<OfflineRecord> pendingRecords;
  final Object? lastDoc;
  final bool hasReachedMax;

  const EmployeeFetchSuccess({
    required this.employees,
    this.pendingRecords = const [],
    this.lastDoc,
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [
    employees,
    pendingRecords,
    lastDoc,
    hasReachedMax,
  ];
}

class EmployeeActionSuccess extends EmployeeState {
  final String actionMessage;
  const EmployeeActionSuccess(this.actionMessage);

  @override
  List<Object?> get props => [actionMessage];
}

class EmployeeFailure extends EmployeeState {
  final String message;
  const EmployeeFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class EmployeeDetailsFetchSuccess extends EmployeeState {
  final List<AttendanceEntity> attendanceLogs;
  final List<PayrollEntity> payrollLogs;
  final Object? lastAttendanceDoc;
  final Object? lastPayrollDoc;
  final bool hasReachedMaxAttendance;
  final bool hasReachedMaxPayroll;
  final bool isPaginationLoadingAttendance;
  final bool isPaginationLoadingPayroll;

  const EmployeeDetailsFetchSuccess({
    required this.attendanceLogs,
    required this.payrollLogs,
    this.lastAttendanceDoc,
    this.lastPayrollDoc,
    this.hasReachedMaxAttendance = false,
    this.hasReachedMaxPayroll = false,
    this.isPaginationLoadingAttendance = false,
    this.isPaginationLoadingPayroll = false,
  });

  EmployeeDetailsFetchSuccess copyWith({
    List<AttendanceEntity>? attendanceLogs,
    List<PayrollEntity>? payrollLogs,
    Object? lastAttendanceDoc,
    Object? lastPayrollDoc,
    bool? hasReachedMaxAttendance,
    bool? hasReachedMaxPayroll,
    bool? isPaginationLoadingAttendance,
    bool? isPaginationLoadingPayroll,
  }) {
    return EmployeeDetailsFetchSuccess(
      attendanceLogs: attendanceLogs ?? this.attendanceLogs,
      payrollLogs: payrollLogs ?? this.payrollLogs,
      lastAttendanceDoc: lastAttendanceDoc ?? this.lastAttendanceDoc,
      lastPayrollDoc: lastPayrollDoc ?? this.lastPayrollDoc,
      hasReachedMaxAttendance: hasReachedMaxAttendance ?? this.hasReachedMaxAttendance,
      hasReachedMaxPayroll: hasReachedMaxPayroll ?? this.hasReachedMaxPayroll,
      isPaginationLoadingAttendance: isPaginationLoadingAttendance ?? this.isPaginationLoadingAttendance,
      isPaginationLoadingPayroll: isPaginationLoadingPayroll ?? this.isPaginationLoadingPayroll,
    );
  }

  @override
  List<Object?> get props => [
    attendanceLogs,
    payrollLogs,
    lastAttendanceDoc,
    lastPayrollDoc,
    hasReachedMaxAttendance,
    hasReachedMaxPayroll,
    isPaginationLoadingAttendance,
    isPaginationLoadingPayroll,
  ];
}

class EmployeeReportsSuccess extends EmployeeState {
  final double totalPaidSalaries;
  final double totalOvertimeCompensation;
  final int totalEmployees;
  final int activeEmployees;
  final double averageAttendanceRate;

  const EmployeeReportsSuccess({
    required this.totalPaidSalaries,
    required this.totalOvertimeCompensation,
    required this.totalEmployees,
    required this.activeEmployees,
    required this.averageAttendanceRate,
  });

  @override
  List<Object?> get props => [
    totalPaidSalaries,
    totalOvertimeCompensation,
    totalEmployees,
    activeEmployees,
    averageAttendanceRate,
  ];
}
