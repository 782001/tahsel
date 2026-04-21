import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/core/error/failures.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_data_source.dart';
import '../models/expense_model.dart';
import '../../../offline_sync/domain/repositories/offline_sync_repository.dart';
import '../../../offline_sync/data/models/offline_record.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource remoteDataSource;
  final OfflineSyncRepository offlineSyncRepository;
  final InternetConnectionChecker connectionChecker;

  ExpenseRepositoryImpl({
    required this.remoteDataSource,
    required this.offlineSyncRepository,
    required this.connectionChecker,
  });

  @override
  Future<Either<Failure, String>> addExpense(ExpenseEntity expense) async {
    try {
      final model = ExpenseModel.fromEntity(expense);
      
      // 1. ALWAYS handle as an offline record first for 100% data consistency.
      final localId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // We manually construct the Hive payload to avoid jsonEncode failing on Firestore Timestamps.
      final Map<String, dynamic> hivePayload = {
        'uid': model.uid,
        'amount': model.amount,
        'category': model.category,
        'description': model.description,
        'createdAt': model.createdAt.toIso8601String(), // Safe for JSON/Hive
        'monthKey': model.monthKey,
      };
      
      final payloadJson = jsonEncode(hivePayload);
      
      final offlineRecord = OfflineRecord(
        id: localId,
        amount: model.amount,
        date: model.createdAt,
        customerName: model.category,
        type: 'expense',
        isSynced: false,
        payloadJson: payloadJson,
        collectionName: 'users/${model.uid}/expenses',
      );

      // Save to local cache first
      final saveResult = await offlineSyncRepository.saveOfflineRecord(offlineRecord);
      
      return saveResult.fold(
        (failure) => Left(failure),
        (_) async {
          // 2. CHECK CONNECTION: If online, trigger IMMEDIATE prioritized sync
          final hasConnection = await connectionChecker.hasConnection;
          if (hasConnection) {
            // This sync call converts 'createdAt' String back to Timestamp and adds 'syncedAt'
            await offlineSyncRepository.syncSingleRecord(offlineRecord);
          }
          
          return Right(localId);
        },
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ExpenseEntity>>> getExpenses(String uid) async {
    try {
      final result = await remoteDataSource.getExpenses(uid);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MonthlyExpenseGroup>>> getMonthlyExpenses(String uid, List<String> monthKeys) async {
    try {
      final result = await remoteDataSource.getMonthlyAggregates(uid, monthKeys);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ExpenseEntity>>> getExpensesByMonth(String uid, String monthKey) async {
    try {
      final result = await remoteDataSource.getExpensesByMonth(uid, monthKey);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(String uid, String expenseId) async {
    try {
      await remoteDataSource.deleteExpense(uid, expenseId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMonthExpenses(String uid, String monthKey) async {
    try {
      await remoteDataSource.deleteMonthExpenses(uid, monthKey);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OfflineRecord>>> getPendingExpenses() async {
    return await offlineSyncRepository.getPendingRecords();
  }
}
