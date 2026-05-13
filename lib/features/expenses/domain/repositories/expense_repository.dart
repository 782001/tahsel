import 'package:dartz/dartz.dart';
import 'package:tahsel/features/expenses/domain/entities/monthly_paginated_list.dart';
import '../entities/expense_entity.dart';
import '../entities/expense_paginated_list.dart';
import '../../../../core/error/failures.dart';
import '../../../offline_sync/data/models/offline_record.dart';

abstract class ExpenseRepository {
  Future<Either<Failure, String>> addExpense(ExpenseEntity expense);
  Future<Either<Failure, List<ExpenseEntity>>> getExpenses(String uid);
  Future<Either<Failure, MonthlyPaginatedList>> getMonthlyExpenses(
    String uid, {
    int limit = 15,
    Object? lastDoc,
  });
  Future<Either<Failure, ExpensePaginatedList>> getExpensesByMonth(
    String uid,
    String monthKey, {
    int limit = 20,
    Object? lastDoc,
  });
  Future<Either<Failure, void>> deleteExpense(String uid, String expenseId);
  Future<Either<Failure, void>> deleteMonthExpenses(
    String uid,
    String monthKey,
  );
  Future<Either<Failure, List<OfflineRecord>>> getPendingExpenses();
}
