import 'package:dartz/dartz.dart';
import '../entities/expense_entity.dart';

abstract class ExpenseRepository {
  Future<Either<dynamic, String>> addExpense(ExpenseEntity expense);
  Future<Either<dynamic, List<ExpenseEntity>>> getExpenses(String uid);
  Future<Either<dynamic, List<MonthlyExpenseGroup>>> getMonthlyExpenses(String uid, List<String> monthKeys);
  Future<Either<dynamic, List<ExpenseEntity>>> getExpensesByMonth(String uid, String monthKey);
  Future<Either<dynamic, void>> deleteExpense(String uid, String expenseId);
  Future<Either<dynamic, void>> deleteMonthExpenses(String uid, String monthKey);
}
