import 'package:equatable/equatable.dart';
import 'employee_entity.dart';
import 'attendance_entity.dart';
import 'payroll_entity.dart';
import 'advance_entity.dart';

class EmployeePaginatedList extends Equatable {
  final List<EmployeeEntity> employees;
  final Object? lastDoc;

  const EmployeePaginatedList({required this.employees, this.lastDoc});

  @override
  List<Object?> get props => [employees, lastDoc];
}

class AttendancePaginatedList extends Equatable {
  final List<AttendanceEntity> attendanceLogs;
  final Object? lastDoc;

  const AttendancePaginatedList({required this.attendanceLogs, this.lastDoc});

  @override
  List<Object?> get props => [attendanceLogs, lastDoc];
}

class PayrollPaginatedList extends Equatable {
  final List<PayrollEntity> payrollLogs;
  final Object? lastDoc;

  const PayrollPaginatedList({required this.payrollLogs, this.lastDoc});

  @override
  List<Object?> get props => [payrollLogs, lastDoc];
}

class AdvancePaginatedList extends Equatable {
  final List<AdvanceEntity> advanceLogs;
  final Object? lastDoc;

  const AdvancePaginatedList({required this.advanceLogs, this.lastDoc});

  @override
  List<Object?> get props => [advanceLogs, lastDoc];
}
