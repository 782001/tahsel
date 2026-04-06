import 'package:equatable/equatable.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_stats.dart';

abstract class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

class ExpenseInitial extends ExpenseState {}

class ExpenseLoading extends ExpenseState {}

class ExpenseFetchSuccess extends ExpenseState {
  final List<MonthlyExpenseGroup> months;
  final ExpenseStats stats;

  const ExpenseFetchSuccess({required this.months, required this.stats});

  @override
  List<Object?> get props => [months, stats];
}

class ExpenseMonthDetailsSuccess extends ExpenseState {
  final List<ExpenseEntity> expenses;
  final String monthKey;
  final String monthName;

  const ExpenseMonthDetailsSuccess({
    required this.expenses, 
    required this.monthKey,
    required this.monthName,
  });

  @override
  List<Object?> get props => [expenses, monthKey, monthName];
}

class ExpenseAddSuccess extends ExpenseState {
  final String expenseId;

  const ExpenseAddSuccess({required this.expenseId});

  @override
  List<Object?> get props => [expenseId];
}

class ExpenseDeleteSuccess extends ExpenseState {
  const ExpenseDeleteSuccess();
}

class ExpenseDeleteMonthSuccess extends ExpenseState {
  const ExpenseDeleteMonthSuccess();
}

class ExpenseFailure extends ExpenseState {
  final String message;

  const ExpenseFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
