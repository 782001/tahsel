import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';

import '../entities/advance_entity.dart';
import '../entities/attendance_entity.dart';
import '../entities/employee_entity.dart';
import '../entities/employee_paginated_lists.dart';
import '../entities/payroll_entity.dart';
import '../repositories/employee_repository.dart';
import '../services/employee_operation_guard.dart';
import 'package:tahsel/core/utils/app_strings.dart';

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
  final EmployeeOperationGuard guard;
  CheckInUseCase({required this.repository, required this.guard});

  Future<Either<Failure, String>> call(AttendanceEntity attendance) async {
    final empResult = await repository.getEmployee(attendance.uid, attendance.employeeId);
    return empResult.fold(
      (failure) => Left(failure),
      (employee) async {
        if (guard.isSuspended(employee.status ?? '')) {
          return const Left(StatusViolationFailure(AppStrings.employeeSuspended));
        }
        if (guard.isInactive(employee.status ?? '')) {
          return const Left(StatusViolationFailure(AppStrings.operationNotAvailableForInactive));
        }
        return repository.checkInEmployee(attendance);
      },
    );
  }
}

class CheckOutParams {
  final String uid;
  final String employeeId;
  final String attendanceId;
  final DateTime checkOut;
  final double overtimeHours;
  final double deductionHours;
  final int lateMinutes;
  final String status;
  final String notes;

  CheckOutParams({
    required this.uid,
    required this.employeeId,
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
  final EmployeeOperationGuard guard;
  CheckOutUseCase({required this.repository, required this.guard});

  Future<Either<Failure, void>> call(CheckOutParams params) async {
    final empResult = await repository.getEmployee(params.uid, params.employeeId);
    return empResult.fold(
      (failure) => Left(failure),
      (employee) async {
        if (guard.isSuspended(employee.status ?? '')) {
          return const Left(StatusViolationFailure(AppStrings.employeeSuspended));
        }
        if (guard.isInactive(employee.status ?? '')) {
          return const Left(StatusViolationFailure(AppStrings.operationNotAvailableForInactive));
        }
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
      },
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
  final EmployeeOperationGuard guard;
  PaySalaryUseCase({required this.repository, required this.guard});

  Future<Either<Failure, String>> call(
    PayrollEntity payroll, {
    List<String> attendanceIds = const [],
    List<String> advanceIds = const [],
  }) async {
    final empResult = await repository.getEmployee(payroll.uid, payroll.employeeId);
    return empResult.fold(
      (failure) => Left(failure),
      (employee) async {
        if (guard.isSuspended(employee.status ?? '')) {
          return const Left(StatusViolationFailure(AppStrings.employeeSuspended));
        }
        if (guard.isInactive(employee.status ?? '')) {
          return const Left(StatusViolationFailure(AppStrings.operationNotAvailableForInactive));
        }
        return repository.paySalary(
          payroll,
          attendanceIds: attendanceIds,
          advanceIds: advanceIds,
        );
      },
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
  final EmployeeOperationGuard guard;
  RequestAdvanceUseCase({required this.repository, required this.guard});

  Future<Either<Failure, String>> call(AdvanceEntity advance) async {
    final empResult = await repository.getEmployee(advance.uid, advance.employeeId);
    return empResult.fold(
      (failure) => Left(failure),
      (employee) async {
        if (guard.isSuspended(employee.status ?? '')) {
          return const Left(StatusViolationFailure(AppStrings.employeeSuspended));
        }
        if (guard.isInactive(employee.status ?? '')) {
          return const Left(StatusViolationFailure(AppStrings.operationNotAvailableForInactive));
        }
        return repository.requestAdvance(advance);
      },
    );
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

class GetEmployeeParams {
  final String uid;
  final String employeeId;

  GetEmployeeParams({required this.uid, required this.employeeId});
}

class GetEmployeeUseCase {
  final EmployeeRepository repository;
  GetEmployeeUseCase({required this.repository});

  Future<Either<Failure, EmployeeEntity>> call(GetEmployeeParams params) {
    return repository.getEmployee(params.uid, params.employeeId);
  }
}
