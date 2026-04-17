import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/expense_repository.dart';

class DeleteMonthExpensesUseCase implements BaseUseCase<void, DeleteMonthParams> {
  final ExpenseRepository repository;

  DeleteMonthExpensesUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteMonthParams params) {
    return repository.deleteMonthExpenses(params.uid, params.monthKey);
  }
}

class DeleteMonthParams {
  final String uid;
  final String monthKey;

  DeleteMonthParams({required this.uid, required this.monthKey});
}
