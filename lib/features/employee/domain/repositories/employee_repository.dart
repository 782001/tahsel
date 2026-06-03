import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/advance_entity.dart';
import '../entities/attendance_entity.dart';
import '../entities/employee_entity.dart';
import '../entities/employee_paginated_lists.dart';
import '../entities/payroll_entity.dart';

abstract class EmployeeRepository {
  Future<Either<Failure, String>> addEmployee(EmployeeEntity employee);
  Future<Either<Failure, void>> editEmployee(EmployeeEntity employee);
  Future<Either<Failure, EmployeePaginatedList>> getEmployees(
    String uid, {
    int limit = 15,
    Object? lastDoc,
  });
  Future<Either<Failure, List<EmployeeEntity>>> searchEmployees(
    String uid,
    String query,
  );
  Future<Either<Failure, String>> checkInEmployee(AttendanceEntity attendance);
  Future<Either<Failure, void>> checkOutEmployee({
    required String uid,
    required String attendanceId,
    required DateTime checkOut,
    required double overtimeHours,
    required double deductionHours,
    required int lateMinutes,
    required String status,
    required String notes,
  });
  Future<Either<Failure, AttendancePaginatedList>> getAttendance(
    String uid,
    String employeeId, {
    int limit = 15,
    Object? lastDoc,
  });
  Future<Either<Failure, String>> paySalary(
    PayrollEntity payroll, {
    List<String> attendanceIds = const [],
    List<String> advanceIds = const [],
  });
  Future<Either<Failure, PayrollPaginatedList>> getPayrollHistory(
    String uid,
    String employeeId, {
    int limit = 15,
    Object? lastDoc,
  });
  Future<Either<Failure, String>> requestAdvance(AdvanceEntity advance);
  Future<Either<Failure, AdvancePaginatedList>> getAdvanceHistory(
    String uid,
    String employeeId, {
    int limit = 15,
    Object? lastDoc,
  });
  Future<Either<Failure, void>> settleAdvances({
    required String uid,
    required List<String> advanceIds,
    required String payrollId,
  });
  Future<Either<Failure, EmployeeEntity>> getEmployee(
    String uid,
    String employeeId,
  );
}
