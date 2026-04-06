import 'package:equatable/equatable.dart';

class ExpenseEntity extends Equatable {
  final String? id;
  final String uid;
  final double amount;
  final String category;
  final String description;
  final DateTime createdAt;
  final String monthKey;

  const ExpenseEntity({
    this.id,
    required this.uid,
    required this.amount,
    required this.category,
    required this.description,
    required this.createdAt,
    required this.monthKey,
  });

  @override
  List<Object?> get props => [id, uid, amount, category, description, createdAt, monthKey];
}

class MonthlyExpenseGroup extends Equatable {
  final String monthKey;
  final String monthName;
  final double totalAmount;
  final int transactionCount;

  const MonthlyExpenseGroup({
    required this.monthKey,
    required this.monthName,
    required this.totalAmount,
    required this.transactionCount,
  });

  @override
  List<Object?> get props => [monthKey, monthName, totalAmount, transactionCount];
}
