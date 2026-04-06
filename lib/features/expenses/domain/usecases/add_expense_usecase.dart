import 'package:dartz/dartz.dart';
import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class AddExpenseParams {
  final ExpenseEntity expense;
  AddExpenseParams({required this.expense});
}

class AddExpenseUseCase {
  final ExpenseRepository repository;

  AddExpenseUseCase({required this.repository});

  Future<Either<dynamic, String>> call(AddExpenseParams params) {
    return repository.addExpense(params.expense);
  }
}
