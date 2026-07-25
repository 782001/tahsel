import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/core/utils/date_formatter.dart';
import 'package:tahsel/features/expenses/domain/entities/expense_paginated_list.dart';
import 'package:tahsel/features/expenses/domain/entities/monthly_paginated_list.dart';

import '../../../offline_sync/data/models/offline_record.dart';
import '../../../offline_sync/domain/repositories/offline_sync_repository.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_data_source.dart';
import '../models/expense_model.dart';

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

      // 1. GENERATE OR USE EXPLICIT ID
      final timeKey = model.createdAt.millisecondsSinceEpoch ~/ 1000;
      final fingerprint =
          '${model.uid}_${model.amount}_${model.category}_${model.description}_$timeKey';
      final deterministicId = 'exp_${fingerprint.hashCode.toString()}';

      final localId = (expense.id != null && expense.id!.isNotEmpty)
          ? expense.id!
          : deterministicId;

      final modelWithId = ExpenseModel(
        id: localId,
        uid: model.uid,
        amount: model.amount,
        category: model.category,
        description: model.description,
        createdAt: model.createdAt,
        monthKey: model.monthKey,
      );

      // 2. ALWAYS handle as an offline record first for 100% data consistency.
      final Map<String, dynamic> hivePayload = {
        'id': localId,
        'uid': modelWithId.uid,
        'amount': modelWithId.amount,
        'category': modelWithId.category,
        'description': modelWithId.description,
        'createdAt': modelWithId.createdAt.toIso8601String(), // Safe for JSON/Hive
        'monthKey': modelWithId.monthKey,
      };

      final payloadJson = jsonEncode(hivePayload);

      final offlineRecord = OfflineRecord(
        id: localId,
        amount: modelWithId.amount,
        date: modelWithId.createdAt,
        customerName: modelWithId.category,
        type: 'expense',
        isSynced: false,
        payloadJson: payloadJson,
        collectionName: 'users/${modelWithId.uid}/expenses',
      );

      // Save to local cache first
      final saveResult = await offlineSyncRepository.saveOfflineRecord(
        offlineRecord,
      );

      return saveResult.fold((failure) => Left(failure), (_) async {
        // 2. CHECK CONNECTION: If online, trigger IMMEDIATE prioritized sync
        final hasConnection = await connectionChecker.hasConnection;
        if (hasConnection) {
          await offlineSyncRepository.syncSingleRecord(offlineRecord);
        }

        return Right(localId);
      });
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
  Future<Either<Failure, MonthlyPaginatedList>> getMonthlyExpenses(
    String uid, {
    int limit = 15,
    Object? lastDoc,
  }) async {
    try {
      final result = await remoteDataSource.getMonthlyAggregates(
        uid,
        limit: limit,
        lastDoc: lastDoc as DocumentSnapshot?,
      );

      // Format month names for the UI
      final formattedMonths = result.months.map((group) {
        try {
          final parts = group.monthKey.split('-');
          final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
          final localizedName = DateFormatter.formatArabicMonthYear(date);

          return MonthlyExpenseGroup(
            monthKey: group.monthKey,
            monthName: localizedName,
            totalAmount: group.totalAmount,
            transactionCount: group.transactionCount,
          );
        } catch (_) {
          return group;
        }
      }).toList();

      return Right(
        MonthlyPaginatedList(months: formattedMonths, lastDoc: result.lastDoc),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpensePaginatedList>> getExpensesByMonth(
    String uid,
    String monthKey, {
    int limit = 15,
    Object? lastDoc,
  }) async {
    try {
      final result = await remoteDataSource.getExpensesByMonth(
        uid,
        monthKey,
        limit: limit,
        lastDoc: lastDoc as DocumentSnapshot?,
      );
      return Right(
        ExpensePaginatedList(
          expenses: result.expenses,
          lastDoc: result.lastDoc,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(
    String uid,
    String expenseId,
  ) async {
    try {
      if (await connectionChecker.hasConnection) {
        await remoteDataSource.deleteExpense(uid, expenseId);
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMonthExpenses(
    String uid,
    String monthKey,
  ) async {
    try {
      await remoteDataSource.deleteMonthExpenses(uid, monthKey);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OfflineRecord>>> getPendingExpenses() async {
    final result = await offlineSyncRepository.getPendingRecords();
    return result.fold((failure) => Left(failure), (records) {
      // STRICT FILTER: Only return records with type 'expense'
      final expenseRecords = records.where((r) => r.type == 'expense').toList();
      return Right(expenseRecords);
    });
  }
}
