import '../entities/expense_entity.dart';

class MonthlyPaginatedList {
  final List<MonthlyExpenseGroup> months;
  final Object? lastDoc;

  MonthlyPaginatedList({
    required this.months,
    this.lastDoc,
  });
}
