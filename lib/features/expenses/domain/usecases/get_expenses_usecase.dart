import 'package:dartz/dartz.dart';
import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class GetExpensesParams {
  final String uid;
  GetExpensesParams({required this.uid});
}

class GetExpensesUseCase {
  final ExpenseRepository repository;

  GetExpensesUseCase({required this.repository});

  Future<Either<dynamic, List<ExpenseEntity>>> call(GetExpensesParams params) {
    return repository.getExpenses(params.uid);
  }
}
