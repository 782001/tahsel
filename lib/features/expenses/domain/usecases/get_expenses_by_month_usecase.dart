import 'package:dartz/dartz.dart';

import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../entities/expense_paginated_list.dart';
import '../repositories/expense_repository.dart';

class GetExpensesByMonthUseCase
    implements BaseUseCase<ExpensePaginatedList, GetExpensesByMonthParams> {
  final ExpenseRepository repository;

  GetExpensesByMonthUseCase({required this.repository});

  @override
  Future<Either<Failure, ExpensePaginatedList>> call(
    GetExpensesByMonthParams params,
  ) async {
    return await repository.getExpensesByMonth(
      params.uid,
      params.monthKey,
      limit: params.limit,
      lastDoc: params.lastDoc,
    );
  }
}

class GetExpensesByMonthParams {
  final String uid;
  final String monthKey;
  final int limit;
  final Object? lastDoc;

  GetExpensesByMonthParams({
    required this.uid,
    required this.monthKey,
    this.limit = 15,
    this.lastDoc,
  });
}
