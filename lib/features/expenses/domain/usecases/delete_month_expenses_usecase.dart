import 'package:dartz/dartz.dart';
import '../repositories/expense_repository.dart';

class DeleteMonthExpensesUseCase {
  final ExpenseRepository repository;

  DeleteMonthExpensesUseCase(this.repository);

  Future<Either<dynamic, void>> call(String uid, String monthKey) {
    return repository.deleteMonthExpenses(uid, monthKey);
  }
}
