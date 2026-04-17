import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/expense_repository.dart';

class DeleteExpenseUseCase implements BaseUseCase<void, DeleteExpenseParams> {
  final ExpenseRepository repository;

  DeleteExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteExpenseParams params) {
    return repository.deleteExpense(params.uid, params.expenseId);
  }
}

class DeleteExpenseParams {
  final String uid;
  final String expenseId;

  DeleteExpenseParams({required this.uid, required this.expenseId});
}
