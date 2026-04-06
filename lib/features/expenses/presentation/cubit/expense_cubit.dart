import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/date_formatter.dart';

import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_stats.dart';
import '../../domain/usecases/add_expense_usecase.dart';
import '../../domain/usecases/get_expenses_usecase.dart';
import '../../domain/usecases/get_monthly_expenses_usecase.dart';
import '../../domain/usecases/get_expenses_by_month_usecase.dart';
import '../../domain/usecases/calculate_expense_stats_usecase.dart';
import '../../domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/delete_month_expenses_usecase.dart';
import 'expense_state.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  final AddExpenseUseCase addExpenseUseCase;
  final GetExpensesUseCase getExpensesUseCase;
  final GetMonthlyExpensesUseCase getMonthlyExpensesUseCase;
  final GetExpensesByMonthUseCase getExpensesByMonthUseCase;
  final CalculateExpenseStatsUseCase calculateStatsUseCase;
  final DeleteExpenseUseCase deleteExpenseUseCase;
  final DeleteMonthExpensesUseCase deleteMonthExpensesUseCase;

  ExpenseCubit({
    required this.addExpenseUseCase,
    required this.getExpensesUseCase,
    required this.getMonthlyExpensesUseCase,
    required this.getExpensesByMonthUseCase,
    required this.calculateStatsUseCase,
    required this.deleteExpenseUseCase,
    required this.deleteMonthExpensesUseCase,
  }) : super(ExpenseInitial());

  Future<void> fetchMonths(String uid) async {
    emit(ExpenseLoading());
    final result = await getMonthlyExpensesUseCase(GetMonthlyExpensesParams(uid: uid));
    result.fold(
      (failure) => emit(ExpenseFailure(message: failure.toString())),
      (months) async {
        // Calculate comparing current actual month vs previous actual month
        // Calculate comparing current actual month vs previous actual month
        final now = DateTime.now();
        final thisMonthKeyStr = DateFormatter.formatNumericMonth(now);
        
        final lastMonth = now.month == 1 
            ? DateTime(now.year - 1, 12) 
            : DateTime(now.year, now.month - 1);
        final lastMonthKeyStr = DateFormatter.formatNumericMonth(lastMonth);
        
        double currentTotal = 0.0;
        double prevTotal = 0.0;
        
        try {
          final thisMonthGroup = months.firstWhere((m) => m.monthKey == thisMonthKeyStr);
          currentTotal = thisMonthGroup.totalAmount;
        } catch (_) {}
        
        try {
          final prevMonthGroup = months.firstWhere((m) => m.monthKey == lastMonthKeyStr);
          prevTotal = prevMonthGroup.totalAmount;
        } catch (_) {}
        
        double percentage = 0.0;
        bool isUp = false;
        if (prevTotal > 0) {
          percentage = ((currentTotal - prevTotal) / prevTotal) * 100;
          isUp = percentage > 0;
          if (!isUp) percentage = percentage.abs();
        } else if (currentTotal > 0) {
          percentage = 100.0;
          isUp = true;
        }
        
        // Round to 1 decimal place
        percentage = double.parse(percentage.toStringAsFixed(1));
        
        final stats = ExpenseStats(
          totalAmount: currentTotal,
          percentageChange: percentage,
          isIncrease: isUp,
        );

        emit(ExpenseFetchSuccess(months: months, stats: stats));
      },
    );
  }

  Future<void> fetchMonthDetails(String uid, String monthKey, String monthName) async {
    emit(ExpenseLoading());
    final result = await getExpensesByMonthUseCase(GetExpensesByMonthParams(uid: uid, monthKey: monthKey));
    result.fold(
      (failure) => emit(ExpenseFailure(message: failure.toString())),
      (expenses) => emit(ExpenseMonthDetailsSuccess(
        expenses: expenses, 
        monthKey: monthKey, 
        monthName: monthName
      )),
    );
  }

  Future<void> addExpense(ExpenseEntity expense) async {
    emit(ExpenseLoading());
    final result = await addExpenseUseCase(AddExpenseParams(expense: expense));
    result.fold(
      (failure) {
        AppLogger.printMessage(failure);
        emit(ExpenseFailure(message: failure.toString()));
      },
      (id) async {
        emit(ExpenseAddSuccess(expenseId: id));
        await fetchMonths(expense.uid);
      },
    );
  }

  Future<void> deleteExpense(String uid, String expenseId, {String? monthKey, String? monthName}) async {
    emit(ExpenseLoading());
    final result = await deleteExpenseUseCase(uid, expenseId);
    result.fold(
      (failure) => emit(ExpenseFailure(message: failure.toString())),
      (_) async {
        emit(const ExpenseDeleteSuccess());
        if (monthKey != null && monthName != null) {
          await fetchMonthDetails(uid, monthKey, monthName);
        } else {
          await fetchMonths(uid);
        }
      },
    );
  }

  Future<void> deleteMonth(String uid, String monthKey) async {
    emit(ExpenseLoading());
    final result = await deleteMonthExpensesUseCase(uid, monthKey);
    result.fold(
      (failure) => emit(ExpenseFailure(message: failure.toString())),
      (_) async {
        emit(const ExpenseDeleteMonthSuccess());
        await fetchMonths(uid);
      },
    );
  }
}
