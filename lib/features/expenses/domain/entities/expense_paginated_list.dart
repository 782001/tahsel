import '../entities/expense_entity.dart';

class ExpensePaginatedList {
  final List<ExpenseEntity> expenses;
  final Object? lastDoc; // Opaque cursor for Firestore

  ExpensePaginatedList({required this.expenses, this.lastDoc});
}
