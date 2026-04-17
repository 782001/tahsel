import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class GetExpensesByMonthUseCase implements BaseUseCase<List<ExpenseEntity>, GetExpensesByMonthParams> {
  final ExpenseRepository repository;

  GetExpensesByMonthUseCase({required this.repository});

  @override
  Future<Either<Failure, List<ExpenseEntity>>> call(GetExpensesByMonthParams params) async {
    return await repository.getExpensesByMonth(params.uid, params.monthKey);
  }
}

class GetExpensesByMonthParams {
  final String uid;
  final String monthKey;

  GetExpensesByMonthParams({required this.uid, required this.monthKey});
}
