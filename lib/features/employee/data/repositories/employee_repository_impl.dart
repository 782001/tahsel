import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/core/error/failures.dart';

import '../../domain/entities/attendance_entity.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/entities/employee_paginated_lists.dart';
import '../../domain/entities/payroll_entity.dart';
import '../../domain/entities/advance_entity.dart';
import '../../domain/repositories/employee_repository.dart';
import '../datasources/employee_remote_data_source.dart';
import '../models/attendance_model.dart';
import '../models/employee_model.dart';
import '../models/payroll_model.dart';
import '../models/advance_model.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  final EmployeeRemoteDataSource remoteDataSource;
  final InternetConnectionChecker connectionChecker;

  EmployeeRepositoryImpl({
    required this.remoteDataSource,
    required this.connectionChecker,
  });

  @override
  Future<Either<Failure, String>> addEmployee(EmployeeEntity employee) async {
    try {
      final hasConnection = await connectionChecker.hasConnection;
      if (!hasConnection) {
        return const Left(ServerFailure("No internet connection."));
      }
      final model = EmployeeModel.fromEntity(employee);
      final id = await remoteDataSource.addEmployee(model);
      return Right(id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> editEmployee(EmployeeEntity employee) async {
    try {
      final hasConnection = await connectionChecker.hasConnection;
      if (!hasConnection) {
        return const Left(
          ServerFailure("No internet connection to edit employee details."),
        );
      }
      final model = EmployeeModel.fromEntity(employee);
      await remoteDataSource.editEmployee(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EmployeePaginatedList>> getEmployees(
    String uid, {
    int limit = 15,
    Object? lastDoc,
  }) async {
    try {
      final result = await remoteDataSource.getEmployees(
        uid,
        limit: limit,
        lastDoc: lastDoc as DocumentSnapshot?,
      );
      return Right(
        EmployeePaginatedList(
          employees: result.employees,
          lastDoc: result.lastDoc,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<EmployeeEntity>>> searchEmployees(
    String uid,
    String query,
  ) async {
    try {
      final result = await remoteDataSource.searchEmployees(uid, query);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> checkInEmployee(
    AttendanceEntity attendance,
  ) async {
    try {
      final hasConnection = await connectionChecker.hasConnection;
      if (!hasConnection) {
        return const Left(ServerFailure("No internet connection."));
      }
      final model = AttendanceModel.fromEntity(attendance);
      final id = await remoteDataSource.checkInEmployee(model);
      return Right(id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> checkOutEmployee({
    required String uid,
    required String attendanceId,
    required DateTime checkOut,
    required double overtimeHours,
    required double deductionHours,
    required int lateMinutes,
    required String status,
    required String notes,
  }) async {
    try {
      final hasConnection = await connectionChecker.hasConnection;
      if (!hasConnection) {
        return const Left(ServerFailure("No internet connection."));
      }
      await remoteDataSource.checkOutEmployee(
        uid: uid,
        attendanceId: attendanceId,
        checkOut: checkOut,
        overtimeHours: overtimeHours,
        deductionHours: deductionHours,
        lateMinutes: lateMinutes,
        status: status,
        notes: notes,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AttendancePaginatedList>> getAttendance(
    String uid,
    String employeeId, {
    int limit = 15,
    Object? lastDoc,
  }) async {
    try {
      final result = await remoteDataSource.getAttendance(
        uid,
        employeeId,
        limit: limit,
        lastDoc: lastDoc as DocumentSnapshot?,
      );
      return Right(
        AttendancePaginatedList(
          attendanceLogs: result.attendanceLogs,
          lastDoc: result.lastDoc,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> paySalary(
    PayrollEntity payroll, {
    List<String> attendanceIds = const [],
    List<String> advanceIds = const [],
  }) async {
    try {
      final hasConnection = await connectionChecker.hasConnection;
      if (!hasConnection) {
        return const Left(ServerFailure("No internet connection."));
      }
      final model = PayrollModel.fromEntity(payroll);
      final id = await remoteDataSource.paySalary(
        model,
        attendanceIds: attendanceIds,
        advanceIds: advanceIds,
      );
      return Right(id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PayrollPaginatedList>> getPayrollHistory(
    String uid,
    String employeeId, {
    int limit = 15,
    Object? lastDoc,
  }) async {
    try {
      final result = await remoteDataSource.getPayrollHistory(
        uid,
        employeeId,
        limit: limit,
        lastDoc: lastDoc as DocumentSnapshot?,
      );
      return Right(
        PayrollPaginatedList(
          payrollLogs: result.payrollLogs,
          lastDoc: result.lastDoc,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> requestAdvance(AdvanceEntity advance) async {
    try {
      final hasConnection = await connectionChecker.hasConnection;
      if (!hasConnection) {
        return const Left(ServerFailure("No internet connection."));
      }
      final model = AdvanceModel.fromEntity(advance);
      final id = await remoteDataSource.requestAdvance(model);
      return Right(id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AdvancePaginatedList>> getAdvanceHistory(
    String uid,
    String employeeId, {
    int limit = 15,
    Object? lastDoc,
  }) async {
    try {
      final result = await remoteDataSource.getAdvanceHistory(
        uid,
        employeeId,
        limit: limit,
        lastDoc: lastDoc as DocumentSnapshot?,
      );
      return Right(
        AdvancePaginatedList(
          advanceLogs: result.advanceLogs,
          lastDoc: result.lastDoc,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> settleAdvances({
    required String uid,
    required List<String> advanceIds,
    required String payrollId,
  }) async {
    try {
      final hasConnection = await connectionChecker.hasConnection;
      if (!hasConnection) {
        return const Left(ServerFailure("No internet connection."));
      }
      await remoteDataSource.settleAdvances(
        uid: uid,
        advanceIds: advanceIds,
        payrollId: payrollId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
