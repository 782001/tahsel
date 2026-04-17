import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class AddExpenseParams {
  final ExpenseEntity expense;
  AddExpenseParams({required this.expense});
}

class AddExpenseUseCase implements BaseUseCase<String, AddExpenseParams> {
  final ExpenseRepository repository;

  AddExpenseUseCase({required this.repository});

  @override
  Future<Either<Failure, String>> call(AddExpenseParams params) {
    return repository.addExpense(params.expense);
  }
}
