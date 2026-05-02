import 'package:equatable/equatable.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_stats.dart';
import '../../../offline_sync/data/models/offline_record.dart';

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
  final List<OfflineRecord> pendingRecords;

  const ExpenseFetchSuccess({
    required this.months,
    required this.stats,
    this.pendingRecords = const [],
  });

  @override
  List<Object?> get props => [months, stats, pendingRecords];
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
