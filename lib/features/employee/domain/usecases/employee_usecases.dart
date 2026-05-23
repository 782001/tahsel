import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import '../entities/employee_entity.dart';
import '../entities/attendance_entity.dart';
import '../entities/payroll_entity.dart';
import '../entities/advance_entity.dart';
import '../entities/employee_paginated_lists.dart';
import '../repositories/employee_repository.dart';

class AddEmployeeUseCase {
  final EmployeeRepository repository;
  AddEmployeeUseCase({required this.repository});

  Future<Either<Failure, String>> call(EmployeeEntity employee) {
    return repository.addEmployee(employee);
  }
}

class EditEmployeeUseCase {
  final EmployeeRepository repository;
  EditEmployeeUseCase({required this.repository});

  Future<Either<Failure, void>> call(EmployeeEntity employee) {
    return repository.editEmployee(employee);
  }
}

class GetEmployeesParams {
  final String uid;
  final int limit;
  final Object? lastDoc;

  GetEmployeesParams({required this.uid, this.limit = 15, this.lastDoc});
}

class GetEmployeesUseCase {
  final EmployeeRepository repository;
  GetEmployeesUseCase({required this.repository});

  Future<Either<Failure, EmployeePaginatedList>> call(
    GetEmployeesParams params,
  ) {
    return repository.getEmployees(
      params.uid,
      limit: params.limit,
      lastDoc: params.lastDoc,
    );
  }
}

class SearchEmployeesParams {
  final String uid;
  final String query;

  SearchEmployeesParams({required this.uid, required this.query});
}

class SearchEmployeesUseCase {
  final EmployeeRepository repository;
  SearchEmployeesUseCase({required this.repository});

  Future<Either<Failure, List<EmployeeEntity>>> call(
    SearchEmployeesParams params,
  ) {
    return repository.searchEmployees(params.uid, params.query);
  }
}

class CheckInUseCase {
  final EmployeeRepository repository;
  CheckInUseCase({required this.repository});

  Future<Either<Failure, String>> call(AttendanceEntity attendance) {
    return repository.checkInEmployee(attendance);
  }
}

class CheckOutParams {
  final String uid;
  final String attendanceId;
  final DateTime checkOut;
  final double overtimeHours;
  final double deductionHours;
  final int lateMinutes;
  final String status;
  final String notes;

  CheckOutParams({
    required this.uid,
    required this.attendanceId,
    required this.checkOut,
    required this.overtimeHours,
    required this.deductionHours,
    required this.lateMinutes,
    required this.status,
    required this.notes,
  });
}

class CheckOutUseCase {
  final EmployeeRepository repository;
  CheckOutUseCase({required this.repository});

  Future<Either<Failure, void>> call(CheckOutParams params) {
    return repository.checkOutEmployee(
      uid: params.uid,
      attendanceId: params.attendanceId,
      checkOut: params.checkOut,
      overtimeHours: params.overtimeHours,
      deductionHours: params.deductionHours,
      lateMinutes: params.lateMinutes,
      status: params.status,
      notes: params.notes,
    );
  }
}

class GetAttendanceParams {
  final String uid;
  final String employeeId;
  final int limit;
  final Object? lastDoc;

  GetAttendanceParams({
    required this.uid,
    required this.employeeId,
    this.limit = 15,
    this.lastDoc,
  });
}

class GetAttendanceUseCase {
  final EmployeeRepository repository;
  GetAttendanceUseCase({required this.repository});

  Future<Either<Failure, AttendancePaginatedList>> call(
    GetAttendanceParams params,
  ) {
    return repository.getAttendance(
      params.uid,
      params.employeeId,
      limit: params.limit,
      lastDoc: params.lastDoc,
    );
  }
}

class PaySalaryUseCase {
  final EmployeeRepository repository;
  PaySalaryUseCase({required this.repository});

  Future<Either<Failure, String>> call(
    PayrollEntity payroll, {
    List<String> attendanceIds = const [],
    List<String> advanceIds = const [],
  }) {
    return repository.paySalary(
      payroll,
      attendanceIds: attendanceIds,
      advanceIds: advanceIds,
    );
  }
}

class GetPayrollParams {
  final String uid;
  final String employeeId;
  final int limit;
  final Object? lastDoc;

  GetPayrollParams({
    required this.uid,
    required this.employeeId,
    this.limit = 15,
    this.lastDoc,
  });
}

class GetPayrollUseCase {
  final EmployeeRepository repository;
  GetPayrollUseCase({required this.repository});

  Future<Either<Failure, PayrollPaginatedList>> call(GetPayrollParams params) {
    return repository.getPayrollHistory(
      params.uid,
      params.employeeId,
      limit: params.limit,
      lastDoc: params.lastDoc,
    );
  }
}

class RequestAdvanceUseCase {
  final EmployeeRepository repository;
  RequestAdvanceUseCase({required this.repository});

  Future<Either<Failure, String>> call(AdvanceEntity advance) {
    return repository.requestAdvance(advance);
  }
}

class SettleAdvancesParams {
  final String uid;
  final List<String> advanceIds;
  final String payrollId;

  SettleAdvancesParams({
    required this.uid,
    required this.advanceIds,
    required this.payrollId,
  });
}

class SettleAdvancesUseCase {
  final EmployeeRepository repository;
  SettleAdvancesUseCase({required this.repository});

  Future<Either<Failure, void>> call(SettleAdvancesParams params) {
    return repository.settleAdvances(
      uid: params.uid,
      advanceIds: params.advanceIds,
      payrollId: params.payrollId,
    );
  }
}
