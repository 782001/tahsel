import 'package:dartz/dartz.dart';
import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class GetExpensesByMonthUseCase {
  final ExpenseRepository repository;

  GetExpensesByMonthUseCase({required this.repository});

  Future<Either<dynamic, List<ExpenseEntity>>> call(GetExpensesByMonthParams params) async {
    return await repository.getExpensesByMonth(params.uid, params.monthKey);
  }
}

class GetExpensesByMonthParams {
  final String uid;
  final String monthKey;

  GetExpensesByMonthParams({required this.uid, required this.monthKey});
}
