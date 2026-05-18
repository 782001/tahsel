import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/core/error/failures.dart';

import '../../../offline_sync/data/models/offline_record.dart';
import '../../../offline_sync/domain/repositories/offline_sync_repository.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/entities/employee_paginated_lists.dart';
import '../../domain/entities/payroll_entity.dart';
import '../../domain/repositories/employee_repository.dart';
import '../datasources/employee_remote_data_source.dart';
import '../models/attendance_model.dart';
import '../models/employee_model.dart';
import '../models/payroll_model.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  final EmployeeRemoteDataSource remoteDataSource;
  final OfflineSyncRepository offlineSyncRepository;
  final InternetConnectionChecker connectionChecker;

  EmployeeRepositoryImpl({
    required this.remoteDataSource,
    required this.offlineSyncRepository,
    required this.connectionChecker,
  });

  @override
  Future<Either<Failure, String>> addEmployee(EmployeeEntity employee) async {
    try {
      final model = EmployeeModel.fromEntity(employee);

      // Deterministic ID for Idempotency
      final fingerprint =
          '${model.uid}_${model.name}_${model.createdAt.millisecondsSinceEpoch ~/ 1000}';
      final deterministicId = 'emp_${fingerprint.hashCode.toString()}';

      final Map<String, dynamic> hivePayload = {
        'uid': model.uid,
        'name': model.name,
        'phone': model.phone,
        'role': model.role,
        'salaryType': model.salaryType,
        'salaryAmount': model.salaryAmount,
        'status': model.status,
        'createdAt': model.createdAt.toIso8601String(),
        'notes': model.notes,
      };

      final offlineRecord = OfflineRecord(
        id: deterministicId,
        amount: model.salaryAmount,
        date: model.createdAt,
        customerName: model.name,
        type: 'employee',
        isSynced: false,
        payloadJson: jsonEncode(hivePayload),
        collectionName: 'users/${model.uid}/employees',
      );

      final saveResult = await offlineSyncRepository.saveOfflineRecord(
        offlineRecord,
      );

      return saveResult.fold((failure) => Left(failure), (_) async {
        final hasConnection = await connectionChecker.hasConnection;
        if (hasConnection) {
          await offlineSyncRepository.syncSingleRecord(offlineRecord);
        }
        return Right(deterministicId);
      });
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> editEmployee(EmployeeEntity employee) async {
    try {
      final hasConnection = await connectionChecker.hasConnection;
      if (hasConnection) {
        final model = EmployeeModel.fromEntity(employee);
        await remoteDataSource.editEmployee(model);
        return const Right(null);
      } else {
        return const Left(
          ServerFailure("No internet connection to edit employee details."),
        );
      }
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
      final model = AttendanceModel.fromEntity(attendance);

      // Deterministic ID for Idempotency
      final fingerprint =
          '${model.uid}_${model.employeeId}_${model.checkIn.millisecondsSinceEpoch ~/ 1000}';
      final deterministicId = 'att_${fingerprint.hashCode.toString()}';

      final Map<String, dynamic> hivePayload = {
        'employeeId': model.employeeId,
        'employeeName': model.employeeName,
        'uid': model.uid,
        'checkIn': model.checkIn.toIso8601String(),
        'date': model.date,
        'status': model.status,
        'expectedWorkingHours': model.expectedWorkingHours,
        'deductionHours': model.deductionHours,
        'overtimeHours': model.overtimeHours,
        'lateMinutes': model.lateMinutes,
        'notes': model.notes,
      };

      final offlineRecord = OfflineRecord(
        id: deterministicId,
        amount: 0,
        date: model.checkIn,
        customerName: model.employeeName,
        type: 'attendance_checkin',
        isSynced: false,
        payloadJson: jsonEncode(hivePayload),
        collectionName: 'users/${model.uid}/attendances',
      );

      final saveResult = await offlineSyncRepository.saveOfflineRecord(
        offlineRecord,
      );

      return saveResult.fold((failure) => Left(failure), (_) async {
        final hasConnection = await connectionChecker.hasConnection;
        if (hasConnection) {
          await offlineSyncRepository.syncSingleRecord(offlineRecord);
        }
        return Right(deterministicId);
      });
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
      final Map<String, dynamic> hivePayload = {
        'uid': uid,
        'attendanceId': attendanceId,
        'checkOut': checkOut.toIso8601String(),
        'overtimeHours': overtimeHours,
        'deductionHours': deductionHours,
        'lateMinutes': lateMinutes,
        'status': status,
        'notes': notes,
      };

      final deterministicId = 'chk_$attendanceId';

      final offlineRecord = OfflineRecord(
        id: deterministicId,
        amount: overtimeHours,
        date: checkOut,
        customerName: 'Checkout',
        type: 'checkout_update',
        isSynced: false,
        payloadJson: jsonEncode(hivePayload),
        collectionName: 'users/$uid/attendances',
      );

      final saveResult = await offlineSyncRepository.saveOfflineRecord(
        offlineRecord,
      );

      return saveResult.fold((failure) => Left(failure), (_) async {
        final hasConnection = await connectionChecker.hasConnection;
        if (hasConnection) {
          await offlineSyncRepository.syncSingleRecord(offlineRecord);
        }
        return const Right(null);
      });
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
  Future<Either<Failure, String>> paySalary(PayrollEntity payroll) async {
    try {
      final model = PayrollModel.fromEntity(payroll);

      // Deterministic ID for Idempotency
      final fingerprint =
          '${model.uid}_${model.employeeId}_${model.paymentDate.millisecondsSinceEpoch ~/ 1000}';
      final deterministicId = 'pay_${fingerprint.hashCode.toString()}';

      final Map<String, dynamic> hivePayload = {
        'employeeId': model.employeeId,
        'employeeName': model.employeeName,
        'uid': model.uid,
        'paymentDate': model.paymentDate.toIso8601String(),
        'amount': model.amount,
        'bonus': model.bonus,
        'deduction': model.deduction,
        'overtimeCompensation': model.overtimeCompensation,
        'netSalary': model.netSalary,
        'monthKey': model.monthKey,
        'notes': model.notes,
      };

      final offlineRecord = OfflineRecord(
        id: deterministicId,
        amount: model.netSalary,
        date: model.paymentDate,
        customerName: model.employeeName,
        type: 'payroll',
        isSynced: false,
        payloadJson: jsonEncode(hivePayload),
        collectionName: 'users/${model.uid}/payrolls',
      );

      final saveResult = await offlineSyncRepository.saveOfflineRecord(
        offlineRecord,
      );

      return saveResult.fold((failure) => Left(failure), (_) async {
        final hasConnection = await connectionChecker.hasConnection;
        if (hasConnection) {
          await offlineSyncRepository.syncSingleRecord(offlineRecord);
        }
        return Right(deterministicId);
      });
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
  Future<Either<Failure, List<OfflineRecord>>>
  getPendingEmployeeRecords() async {
    final result = await offlineSyncRepository.getPendingRecords();
    return result.fold((failure) => Left(failure), (records) {
      final filtered = records
          .where(
            (r) =>
                r.type == 'employee' ||
                r.type == 'attendance_checkin' ||
                r.type == 'checkout_update' ||
                r.type == 'payroll',
          )
          .toList();
      return Right(filtered);
    });
  }
}
