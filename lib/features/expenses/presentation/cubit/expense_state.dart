import 'package:equatable/equatable.dart';

import '../../../offline_sync/data/models/offline_record.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_stats.dart';

abstract class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

class ExpenseInitial extends ExpenseState {}

class ExpenseLoading extends ExpenseState {
  final ExpenseStats? previousStats;
  const ExpenseLoading({this.previousStats});

  @override
  List<Object?> get props => [previousStats];
}

class ExpenseFetchSuccess extends ExpenseState {
  final List<MonthlyExpenseGroup> months;
  final ExpenseStats stats;
  final List<OfflineRecord> pendingRecords;
  final Object? lastDoc;
  final bool hasReachedMax;

  const ExpenseFetchSuccess({
    required this.months,
    required this.stats,
    this.pendingRecords = const [],
    this.lastDoc,
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [
    months,
    stats,
    pendingRecords,
    lastDoc,
    hasReachedMax,
  ];
}

class ExpenseMonthDetailsSuccess extends ExpenseState {
  final List<DayExpenseGroup> expenses;
  final String monthKey;
  final String monthName;
  final Object? lastDoc;
  final bool hasReachedMax;
  final bool isPaginationLoading;
  final ExpenseStats? stats;

  const ExpenseMonthDetailsSuccess({
    required this.expenses,
    required this.monthKey,
    required this.monthName,
    this.lastDoc,
    this.hasReachedMax = false,
    this.isPaginationLoading = false,
    this.stats,
  });

  ExpenseMonthDetailsSuccess copyWith({
    List<DayExpenseGroup>? expenses,
    String? monthKey,
    String? monthName,
    Object? lastDoc,
    bool? hasReachedMax,
    bool? isPaginationLoading,
    ExpenseStats? stats,
  }) {
    return ExpenseMonthDetailsSuccess(
      expenses: expenses ?? this.expenses,
      monthKey: monthKey ?? this.monthKey,
      monthName: monthName ?? this.monthName,
      lastDoc: lastDoc ?? this.lastDoc,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isPaginationLoading: isPaginationLoading ?? this.isPaginationLoading,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [
    expenses,
    monthKey,
    monthName,
    lastDoc,
    hasReachedMax,
    isPaginationLoading,
    stats,
  ];
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
