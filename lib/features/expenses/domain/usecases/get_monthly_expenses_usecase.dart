import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../entities/monthly_paginated_list.dart';
import '../repositories/expense_repository.dart';

class GetMonthlyExpensesUseCase
    implements BaseUseCase<MonthlyPaginatedList, GetMonthlyExpensesParams> {
  final ExpenseRepository repository;

  GetMonthlyExpensesUseCase({required this.repository});

  @override
  Future<Either<Failure, MonthlyPaginatedList>> call(
    GetMonthlyExpensesParams params,
  ) async {
    return await repository.getMonthlyExpenses(
      params.uid,
      limit: params.limit,
      lastDoc: params.lastDoc,
    );
  }
}

class GetMonthlyExpensesParams {
  final String uid;
  final int limit;
  final Object? lastDoc;

  GetMonthlyExpensesParams({required this.uid, this.limit = 15, this.lastDoc});
}
