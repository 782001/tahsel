import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/date_formatter.dart';
import 'package:tahsel/features/offline_sync/data/models/offline_record.dart';

import '../../../../core/base_usecase/base_usecase.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_stats.dart';
import '../../domain/usecases/add_expense_usecase.dart';
import '../../domain/usecases/calculate_expense_stats_usecase.dart';
import '../../domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/delete_month_expenses_usecase.dart';
import '../../domain/usecases/get_expenses_by_month_usecase.dart';
import '../../domain/usecases/get_expenses_usecase.dart';
import '../../domain/usecases/get_monthly_expenses_usecase.dart';
import '../../domain/usecases/get_pending_expenses_usecase.dart';
import '../../domain/usecases/group_expenses_by_day_usecase.dart';
import 'expense_state.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  final AddExpenseUseCase addExpenseUseCase;
  final GetExpensesUseCase getExpensesUseCase;
  final GetMonthlyExpensesUseCase getMonthlyExpensesUseCase;
  final GetExpensesByMonthUseCase getExpensesByMonthUseCase;
  final CalculateExpenseStatsUseCase calculateStatsUseCase;
  final DeleteExpenseUseCase deleteExpenseUseCase;
  final DeleteMonthExpensesUseCase deleteMonthExpensesUseCase;
  final GetPendingExpensesUseCase getPendingExpensesUseCase;
  final GroupExpensesByDayUseCase groupExpensesByDayUseCase;

  ExpenseCubit({
    required this.addExpenseUseCase,
    required this.getExpensesUseCase,
    required this.getMonthlyExpensesUseCase,
    required this.getExpensesByMonthUseCase,
    required this.calculateStatsUseCase,
    required this.deleteExpenseUseCase,
    required this.deleteMonthExpensesUseCase,
    required this.getPendingExpensesUseCase,
    required this.groupExpensesByDayUseCase,
  }) : super(ExpenseInitial());

  Future<void> fetchMonths(String uid, {bool forceRefresh = false}) async {
    // REFRESH CONTROL: If already have data and not forcing refresh, return.
    // This saves Firestore reads when navigating back to this screen.
    if (!forceRefresh && state is ExpenseFetchSuccess) {
      return;
    }

    ExpenseStats? previousStats;
    if (state is ExpenseFetchSuccess) {
      previousStats = (state as ExpenseFetchSuccess).stats;
    }

    // Only show full loading if we don't have data already
    if (state is! ExpenseFetchSuccess && !forceRefresh) {
      emit(const ExpenseLoading());
    } else if (forceRefresh && state is ExpenseFetchSuccess) {
      // If refreshing, emit loading with previous stats to prevent UI flicker
      emit(ExpenseLoading(previousStats: (state as ExpenseFetchSuccess).stats));
    }

    // Always fetch pending records first (Offline-First)
    final pendingResult = await getPendingExpensesUseCase(const NoParams());
    final List<OfflineRecord> pendingRecords = pendingResult.fold(
      (_) => [],
      (records) => records,
    );

    // Initial load: 15 months only (Performance Optimization)
    final result = await getMonthlyExpensesUseCase(
      GetMonthlyExpensesParams(uid: uid, limit: 15),
    );

    result.fold(
      (failure) {
        if (pendingRecords.isNotEmpty) {
          emit(
            ExpenseFetchSuccess(
              months: const [],
              stats:
                  previousStats ??
                  const ExpenseStats(
                    totalAmount: 0,
                    percentageChange: 0,
                    isIncrease: false,
                  ),
              pendingRecords: pendingRecords,
              hasReachedMax: true,
            ),
          );
        } else {
          emit(ExpenseFailure(message: failure.message));
        }
      },
      (paginatedList) async {
        final List<MonthlyExpenseGroup> mergedMonths = _mergePendingWithMonths(
          paginatedList.months,
          pendingRecords,
        );

        final stats = _calculateStats(mergedMonths);

        emit(
          ExpenseFetchSuccess(
            months: mergedMonths,
            stats: stats,
            pendingRecords: pendingRecords,
            lastDoc: paginatedList.lastDoc,
            hasReachedMax: paginatedList.months.length < 15,
          ),
        );
      },
    );
  }

  Future<void> loadMoreMonths(String uid) async {
    final currentState = state;
    if (currentState is! ExpenseFetchSuccess || currentState.hasReachedMax) {
      return;
    }

    // We don't emit loading here to avoid screen flickering,
    // the UI can handle the pagination loading state if needed.

    final result = await getMonthlyExpensesUseCase(
      GetMonthlyExpensesParams(
        uid: uid,
        limit: 15,
        lastDoc: currentState.lastDoc,
      ),
    );

    result.fold(
      (_) => null, // Silently fail for load more
      (paginatedList) async {
        final combined = [...currentState.months, ...paginatedList.months];

        // Remove duplicates if any (though Firestore query should be clean)
        final uniqueMonths = <String, MonthlyExpenseGroup>{};
        for (var m in combined) {
          uniqueMonths[m.monthKey] = m;
        }

        final sortedMonths = uniqueMonths.values.toList()
          ..sort((a, b) => b.monthKey.compareTo(a.monthKey));

        emit(
          ExpenseFetchSuccess(
            months: sortedMonths,
            stats:
                currentState.stats, // Don't recalculate stats during load more
            pendingRecords: currentState.pendingRecords,
            lastDoc: paginatedList.lastDoc,
            hasReachedMax: paginatedList.months.length < 15,
          ),
        );
      },
    );
  }

  List<MonthlyExpenseGroup> _mergePendingWithMonths(
    List<MonthlyExpenseGroup> months,
    List<OfflineRecord> pendingRecords,
  ) {
    final List<MonthlyExpenseGroup> mergedMonths = List.from(months);

    for (final record in pendingRecords) {
      final recordMonthKey = DateFormatter.formatNumericMonth(record.date);
      final recordMonthName = DateFormatter.formatArabicMonthYear(record.date);

      final existingIndex = mergedMonths.indexWhere(
        (m) => m.monthKey == recordMonthKey,
      );

      if (existingIndex != -1) {
        final existing = mergedMonths[existingIndex];
        mergedMonths[existingIndex] = MonthlyExpenseGroup(
          monthKey: existing.monthKey,
          monthName: existing.monthName,
          totalAmount: existing.totalAmount + record.amount,
          transactionCount: existing.transactionCount + 1,
        );
      } else {
        mergedMonths.add(
          MonthlyExpenseGroup(
            monthKey: recordMonthKey,
            monthName: recordMonthName,
            totalAmount: record.amount,
            transactionCount: 1,
          ),
        );
      }
    }

    // Sort months by monthKey descending
    mergedMonths.sort((a, b) => b.monthKey.compareTo(a.monthKey));
    return mergedMonths;
  }

  ExpenseStats _calculateStats(List<MonthlyExpenseGroup> mergedMonths) {
    final now = DateTime.now();
    final thisMonthKeyStr = DateFormatter.formatNumericMonth(now);

    final lastMonth = now.month == 1
        ? DateTime(now.year - 1, 12)
        : DateTime(now.year, now.month - 1);
    final lastMonthKeyStr = DateFormatter.formatNumericMonth(lastMonth);

    double currentTotal = 0.0;
    double prevTotal = 0.0;

    try {
      final thisMonthGroup = mergedMonths.firstWhere(
        (m) => m.monthKey == thisMonthKeyStr,
      );
      currentTotal = thisMonthGroup.totalAmount;
    } catch (_) {}

    try {
      final prevMonthGroup = mergedMonths.firstWhere(
        (m) => m.monthKey == lastMonthKeyStr,
      );
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

    percentage = double.parse(percentage.toStringAsFixed(1));

    return ExpenseStats(
      totalAmount: currentTotal,
      percentageChange: percentage,
      isIncrease: isUp,
    );
  }

  Future<void> fetchMonthDetails(
    String uid,
    String monthKey,
    String monthName, {
    bool forceRefresh = false,
  }) async {
    // REFRESH CONTROL: If already have details for THIS month and not forcing refresh, return.
    if (!forceRefresh &&
        state is ExpenseMonthDetailsSuccess &&
        (state as ExpenseMonthDetailsSuccess).monthKey == monthKey) {
      return;
    }

    ExpenseStats? previousStats;
    if (state is ExpenseFetchSuccess) {
      previousStats = (state as ExpenseFetchSuccess).stats;
    } else if (state is ExpenseMonthDetailsSuccess) {
      previousStats = (state as ExpenseMonthDetailsSuccess).stats;
    }

    // Only emit loading if we don't have this month's data yet or forcing refresh
    if (state is! ExpenseMonthDetailsSuccess ||
        (state as ExpenseMonthDetailsSuccess).monthKey != monthKey ||
        forceRefresh) {
      emit(const ExpenseLoading(previousStats: null));
    }

    // 1. Fetch pending records to filter for this month
    final pendingResult = await getPendingExpensesUseCase(const NoParams());
    final pendingRecords = pendingResult.fold((_) => [], (records) => records);

    // Convert relevant pending records to ExpenseEntity objects
    final filteredPending = pendingRecords
        .where((record) {
          final recordMonthKey = DateFormatter.formatNumericMonth(record.date);
          return recordMonthKey == monthKey;
        })
        .map(
          (record) => ExpenseEntity(
            id: record.id,
            uid: uid,
            amount: record.amount,
            category: record.customerName, // We used customerName for category
            description: "Pending Sync", // Indicative description
            createdAt: record.date,
            monthKey: monthKey,
          ),
        )
        .toList();

    // 2. Fetch remote expenses (First Page)
    final result = await getExpensesByMonthUseCase(
      GetExpensesByMonthParams(uid: uid, monthKey: monthKey, limit: 15),
    );

    result.fold(
      (failure) async {
        // If it's a connection failure but we HAVE pending items for this month, show them!
        if (filteredPending.isNotEmpty) {
          final grouped = await groupExpensesByDayUseCase(filteredPending);
          emit(
            ExpenseMonthDetailsSuccess(
              expenses: grouped,
              monthKey: monthKey,
              monthName: monthName,
              hasReachedMax: true, // Only showing pending
              stats: previousStats,
            ),
          );
        } else {
          emit(ExpenseFailure(message: failure.message));
        }
      },
      (paginatedList) async {
        // Combine remote synced expenses + local pending expenses with ID de-duplication
        final Map<String, ExpenseEntity> uniqueExpenses = {};

        // Add local items first (they are more "fresh" in the user's mind)
        for (final item in filteredPending) {
          if (item.id != null) uniqueExpenses[item.id!] = item;
        }

        // Add remote items (overriding if ID matches, or adding new ones)
        for (final item in paginatedList.expenses) {
          if (item.id != null) uniqueExpenses[item.id!] = item;
        }

        final combined = uniqueExpenses.values.toList();
        final grouped = await groupExpensesByDayUseCase(combined);

        emit(
          ExpenseMonthDetailsSuccess(
            expenses: grouped,
            monthKey: monthKey,
            monthName: monthName,
            lastDoc: paginatedList.lastDoc,
            hasReachedMax: paginatedList.expenses.length < 20,
            stats: previousStats,
          ),
        );
      },
    );
  }

  Future<void> loadMoreExpenses(String uid) async {
    final currentState = state;
    if (currentState is! ExpenseMonthDetailsSuccess ||
        currentState.hasReachedMax ||
        currentState.isPaginationLoading) {
      return;
    }

    emit(currentState.copyWith(isPaginationLoading: true));

    final result = await getExpensesByMonthUseCase(
      GetExpensesByMonthParams(
        uid: uid,
        monthKey: currentState.monthKey,
        limit: 15,
        lastDoc: currentState.lastDoc,
      ),
    );

    result.fold(
      (failure) => emit(currentState.copyWith(isPaginationLoading: false)),
      (paginatedList) async {
        if (paginatedList.expenses.isEmpty) {
          emit(
            currentState.copyWith(
              hasReachedMax: true,
              isPaginationLoading: false,
            ),
          );
          return;
        }

        // Extract existing raw entities from groups
        final List<ExpenseEntity> existingExpenses = [];
        for (var group in currentState.expenses) {
          existingExpenses.addAll(group.expenses);
        }

        final combined = [...existingExpenses, ...paginatedList.expenses];

        // Remove duplicates (important when combining pending + remote)
        final uniqueExpenses = <String, ExpenseEntity>{};
        for (var e in combined) {
          if (e.id != null) uniqueExpenses[e.id!] = e;
        }

        final grouped = await groupExpensesByDayUseCase(
          uniqueExpenses.values.toList(),
        );
        emit(
          currentState.copyWith(
            expenses: grouped,
            lastDoc: paginatedList.lastDoc,
            hasReachedMax: paginatedList.expenses.length < 20,
            isPaginationLoading: false,
          ),
        );
      },
    );
  }

  Future<void> addExpense(ExpenseEntity expense) async {
    emit(const ExpenseLoading());
    final result = await addExpenseUseCase(AddExpenseParams(expense: expense));
    result.fold(
      (failure) {
        AppLogger.printMessage(failure);
        emit(ExpenseFailure(message: failure.message));
      },
      (id) async {
        emit(ExpenseAddSuccess(expenseId: id));
        // Auto-refresh after explicit user action to ensure UI consistency
        await fetchMonths(expense.uid, forceRefresh: true);
      },
    );
  }

  Future<void> deleteExpense(
    String uid,
    String expenseId, {
    String? monthKey,
    String? monthName,
  }) async {
    emit(const ExpenseLoading());
    final result = await deleteExpenseUseCase(
      DeleteExpenseParams(uid: uid, expenseId: expenseId),
    );
    result.fold((failure) => emit(ExpenseFailure(message: failure.message)), (
      _,
    ) async {
      emit(const ExpenseDeleteSuccess());
      // Refresh appropriately based on context
      if (monthKey != null && monthName != null) {
        await fetchMonthDetails(uid, monthKey, monthName, forceRefresh: true);
      } else {
        await fetchMonths(uid, forceRefresh: true);
      }
    });
  }

  Future<void> deleteMonth(String uid, String monthKey) async {
    emit(const ExpenseLoading());
    final result = await deleteMonthExpensesUseCase(
      DeleteMonthParams(uid: uid, monthKey: monthKey),
    );
    result.fold((failure) => emit(ExpenseFailure(message: failure.message)), (
      _,
    ) async {
      emit(const ExpenseDeleteMonthSuccess());
      await fetchMonths(uid, forceRefresh: true);
    });
  }

  void clearData() {
    emit(ExpenseInitial());
  }
}
