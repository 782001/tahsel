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
      final hasConnection = await connectionChecker.hasConnection;

      if (hasConnection) {
        final id = await remoteDataSource.addExpense(model);
        return Right(id);
      } else {
        final localId = DateTime.now().millisecondsSinceEpoch.toString();
        final Map<String, dynamic> rawJson = model.toJson();
        rawJson['createdAt'] = null; // Replaced during sync
        
        final payloadJson = jsonEncode(rawJson);
        
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

        final result = await offlineSyncRepository.saveOfflineRecord(offlineRecord);
        return result.fold(
          (failure) => Left(failure),
          (_) => Right(localId),
        );
      }
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
}
