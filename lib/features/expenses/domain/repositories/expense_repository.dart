import 'package:dartz/dartz.dart';
import '../entities/expense_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../offline_sync/data/models/offline_record.dart';

abstract class ExpenseRepository {
  Future<Either<Failure, String>> addExpense(ExpenseEntity expense);
  Future<Either<Failure, List<ExpenseEntity>>> getExpenses(String uid);
  Future<Either<Failure, List<MonthlyExpenseGroup>>> getMonthlyExpenses(String uid, List<String> monthKeys);
  Future<Either<Failure, List<ExpenseEntity>>> getExpensesByMonth(String uid, String monthKey);
  Future<Either<Failure, void>> deleteExpense(String uid, String expenseId);
  Future<Either<Failure, void>> deleteMonthExpenses(String uid, String monthKey);
  Future<Either<Failure, List<OfflineRecord>>> getPendingExpenses();
}
