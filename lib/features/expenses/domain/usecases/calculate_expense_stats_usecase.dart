import 'dart:async';
import 'package:flutter/foundation.dart';
import '../entities/expense_entity.dart';
import '../entities/expense_stats.dart';

class CalculateExpenseStatsUseCase {
  Future<ExpenseStats> call(List<ExpenseEntity> expenses) async {
    return await compute(_calculateStats, expenses);
  }

  static ExpenseStats _calculateStats(List<ExpenseEntity> expenses) {
    if (expenses.isEmpty) {
      return const ExpenseStats(
        totalAmount: 0.0,
        percentageChange: 0.0,
        isIncrease: false,
      );
    }

    double totalAmount = 0.0;
    for (final e in expenses) {
      totalAmount += e.amount;
    }

    // Percentage Calculation (Monthly)
    final now = DateTime.now();
    final firstDayCurrentMonth = DateTime(now.year, now.month, 1);
    final firstDayPrevMonth = DateTime(now.year, now.month - 1, 1);
    final lastDayPrevMonth = firstDayCurrentMonth.subtract(const Duration(milliseconds: 1));

    double currentMonthTotal = 0.0;
    double prevMonthTotal = 0.0;

    for (final e in expenses) {
      if (e.createdAt.isAfter(firstDayCurrentMonth) || e.createdAt.isAtSameMomentAs(firstDayCurrentMonth)) {
        currentMonthTotal += e.amount;
      } else if (e.createdAt.isAfter(firstDayPrevMonth) && e.createdAt.isBefore(lastDayPrevMonth)) {
        prevMonthTotal += e.amount;
      }
    }

    double percentageChange = 0.0;
    bool isIncrease = false;

    if (prevMonthTotal > 0) {
      percentageChange = ((currentMonthTotal - prevMonthTotal) / prevMonthTotal) * 100;
      if (percentageChange > 0) {
        isIncrease = true;
      } else {
        isIncrease = false;
        percentageChange = percentageChange.abs();
      }
    } else if (currentMonthTotal > 0) {
      // If there was no previous month and we have a current one
      percentageChange = 100.0;
      isIncrease = true;
    }

    return ExpenseStats(
      totalAmount: totalAmount,
      percentageChange: percentageChange,
      isIncrease: isIncrease,
    );
  }
}
