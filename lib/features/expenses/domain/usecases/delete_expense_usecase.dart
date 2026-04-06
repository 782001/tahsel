import 'package:dartz/dartz.dart';
import '../repositories/expense_repository.dart';

class DeleteExpenseUseCase {
  final ExpenseRepository repository;

  DeleteExpenseUseCase(this.repository);

  Future<Either<dynamic, void>> call(String uid, String expenseId) {
    return repository.deleteExpense(uid, expenseId);
  }
}
