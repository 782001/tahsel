import 'package:dartz/dartz.dart';
import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';
import 'package:intl/intl.dart';

class GetMonthlyExpensesUseCase {
  final ExpenseRepository repository;

  GetMonthlyExpensesUseCase({required this.repository});

  Future<Either<dynamic, List<MonthlyExpenseGroup>>> call(GetMonthlyExpensesParams params) async {
    // Generate the last 12 months keys
    final List<String> monthKeys = [];
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      var d = DateTime(now.year, now.month - i, 1);
      monthKeys.add(DateFormat('yyyy-MM').format(d));
    }
    
    return await repository.getMonthlyExpenses(params.uid, monthKeys);
  }
}

class GetMonthlyExpensesParams {
  final String uid;

  GetMonthlyExpensesParams({required this.uid});
}
