import 'package:flutter/foundation.dart';
import '../entities/expense_entity.dart';

class GroupExpensesByDayUseCase {
  Future<List<DayExpenseGroup>> call(List<ExpenseEntity> expenses) async {
    if (expenses.isEmpty) return [];

    // Use compute (Isolate) for heavy grouping logic
    return await compute(_groupExpenses, expenses);
  }

  static List<DayExpenseGroup> _groupExpenses(List<ExpenseEntity> expenses) {
    // 1. Group by date (ignoring time)
    final Map<String, List<ExpenseEntity>> groupedMap = {};

    for (final expense in expenses) {
      // Create a key using only YYYY-MM-DD
      final dateKey =
          "${expense.createdAt.year}-${expense.createdAt.month}-${expense.createdAt.day}";

      if (!groupedMap.containsKey(dateKey)) {
        groupedMap[dateKey] = [];
      }
      groupedMap[dateKey]!.add(expense);
    }

    // 2. Convert to DayExpenseGroup list
    final List<DayExpenseGroup> groups = groupedMap.entries.map((entry) {
      return DayExpenseGroup(
        date: entry.value.first.createdAt,
        expenses: entry.value,
      );
    }).toList();

    // 3. Sort by date descending (latest first)
    groups.sort((a, b) => b.date.compareTo(a.date));

    // 4. Sort expenses within each group by time descending (latest first)
    for (final group in groups) {
      group.expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return groups;
  }
}
