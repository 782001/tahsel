import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class GetExpensesParams {
  final String uid;
  GetExpensesParams({required this.uid});
}

class GetExpensesUseCase
    implements BaseUseCase<List<ExpenseEntity>, GetExpensesParams> {
  final ExpenseRepository repository;

  GetExpensesUseCase({required this.repository});

  @override
  Future<Either<Failure, List<ExpenseEntity>>> call(GetExpensesParams params) {
    return repository.getExpenses(params.uid);
  }
}
