import 'package:equatable/equatable.dart';

class CustodyExpenseItem extends Equatable {
  final String id;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String? employeeName;
  final String? receiptUrl;

  const CustodyExpenseItem({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.employeeName,
    this.receiptUrl,
  });

  @override
  List<Object?> get props => [
        id,
        amount,
        category,
        description,
        date,
        employeeName,
        receiptUrl,
      ];
}
