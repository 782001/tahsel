import 'package:dartz/dartz.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_data_source.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource remoteDataSource;

  ExpenseRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<dynamic, String>> addExpense(ExpenseEntity expense) async {
    try {
      final model = ExpenseModel.fromEntity(expense);
      final id = await remoteDataSource.addExpense(model);
      return Right(id);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<dynamic, List<ExpenseEntity>>> getExpenses(String uid) async {
    try {
      final result = await remoteDataSource.getExpenses(uid);
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<dynamic, List<MonthlyExpenseGroup>>> getMonthlyExpenses(String uid, List<String> monthKeys) async {
    try {
      final result = await remoteDataSource.getMonthlyAggregates(uid, monthKeys);
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<dynamic, List<ExpenseEntity>>> getExpensesByMonth(String uid, String monthKey) async {
    try {
      final result = await remoteDataSource.getExpensesByMonth(uid, monthKey);
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<dynamic, void>> deleteExpense(String uid, String expenseId) async {
    try {
      await remoteDataSource.deleteExpense(uid, expenseId);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<dynamic, void>> deleteMonthExpenses(String uid, String monthKey) async {
    try {
      await remoteDataSource.deleteMonthExpenses(uid, monthKey);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
