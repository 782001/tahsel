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

  ExpenseCubit({
    required this.addExpenseUseCase,
    required this.getExpensesUseCase,
    required this.getMonthlyExpensesUseCase,
    required this.getExpensesByMonthUseCase,
    required this.calculateStatsUseCase,
    required this.deleteExpenseUseCase,
    required this.deleteMonthExpensesUseCase,
    required this.getPendingExpensesUseCase,
  }) : super(ExpenseInitial());

  Future<void> fetchMonths(String uid) async {
    emit(ExpenseLoading());

    // Always fetch pending records first
    final pendingResult = await getPendingExpensesUseCase(const NoParams());
    final List<OfflineRecord> pendingRecords = pendingResult.fold(
      (_) => [],
      (records) => records,
    );

    final result = await getMonthlyExpensesUseCase(
      GetMonthlyExpensesParams(uid: uid),
    );

    result.fold(
      (failure) {
        // If it's a failure (like no internet), we still want to show pending records
        if (pendingRecords.isNotEmpty) {
          emit(
            ExpenseFetchSuccess(
              months: const [],
              stats: const ExpenseStats(
                totalAmount: 0,
                percentageChange: 0,
                isIncrease: false,
              ),
              pendingRecords: pendingRecords,
            ),
          );
        } else {
          emit(ExpenseFailure(message: failure.message));
        }
      },
      (months) async {
        // Merge pending records into the months list
        final List<MonthlyExpenseGroup> mergedMonths = List.from(months);

        for (final record in pendingRecords) {
          final recordMonthKey = DateFormatter.formatNumericMonth(record.date);
          final recordMonthName = DateFormatter.formatArabicMonthYear(
            record.date,
          );

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

        // Sort months by monthKey descending (newest first)
        mergedMonths.sort((a, b) => b.monthKey.compareTo(a.monthKey));

        // Calculate stats using the merged data
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

        final stats = ExpenseStats(
          totalAmount: currentTotal,
          percentageChange: percentage,
          isIncrease: isUp,
        );

        emit(
          ExpenseFetchSuccess(
            months: mergedMonths,
            stats: stats,
            pendingRecords: pendingRecords,
          ),
        );
      },
    );
  }

  Future<void> fetchMonthDetails(
    String uid,
    String monthKey,
    String monthName,
  ) async {
    emit(ExpenseLoading());

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

    // 2. Fetch remote expenses
    final result = await getExpensesByMonthUseCase(
      GetExpensesByMonthParams(uid: uid, monthKey: monthKey),
    );

    result.fold(
      (failure) {
        // If it's a connection failure but we HAVE pending items for this month, show them!
        if (filteredPending.isNotEmpty) {
          emit(
            ExpenseMonthDetailsSuccess(
              expenses: filteredPending,
              monthKey: monthKey,
              monthName: monthName,
            ),
          );
        } else {
          emit(ExpenseFailure(message: failure.message));
        }
      },
      (remoteExpenses) {
        // Combine remote synced expenses + local pending expenses
        final combined = [...filteredPending, ...remoteExpenses];
        emit(
          ExpenseMonthDetailsSuccess(
            expenses: combined,
            monthKey: monthKey,
            monthName: monthName,
          ),
        );
      },
    );
  }

  Future<void> addExpense(ExpenseEntity expense) async {
    emit(ExpenseLoading());
    final result = await addExpenseUseCase(AddExpenseParams(expense: expense));
    result.fold(
      (failure) {
        AppLogger.printMessage(failure);
        emit(ExpenseFailure(message: failure.message));
      },
      (id) async {
        emit(ExpenseAddSuccess(expenseId: id));
        await fetchMonths(expense.uid);
      },
    );
  }

  Future<void> deleteExpense(
    String uid,
    String expenseId, {
    String? monthKey,
    String? monthName,
  }) async {
    emit(ExpenseLoading());
    final result = await deleteExpenseUseCase(
      DeleteExpenseParams(uid: uid, expenseId: expenseId),
    );
    result.fold((failure) => emit(ExpenseFailure(message: failure.message)), (
      _,
    ) async {
      emit(const ExpenseDeleteSuccess());
      if (monthKey != null && monthName != null) {
        await fetchMonthDetails(uid, monthKey, monthName);
      } else {
        await fetchMonths(uid);
      }
    });
  }

  Future<void> deleteMonth(String uid, String monthKey) async {
    emit(ExpenseLoading());
    final result = await deleteMonthExpensesUseCase(
      DeleteMonthParams(uid: uid, monthKey: monthKey),
    );
    result.fold((failure) => emit(ExpenseFailure(message: failure.message)), (
      _,
    ) async {
      emit(const ExpenseDeleteMonthSuccess());
      await fetchMonths(uid);
    });
  }
}
