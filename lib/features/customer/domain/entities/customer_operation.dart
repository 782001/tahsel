import 'package:equatable/equatable.dart';

enum CustomerOperationType { purchase, payment, debt }

class CustomerOperation extends Equatable {
  final String id;
  final String activityName; // e.g., 'Tea', 'Mango', 'Session'
  final double amount;
  final CustomerOperationType type;
  final DateTime date;
  final String? details;

  const CustomerOperation({
    required this.id,
    required this.activityName,
    required this.amount,
    required this.type,
    required this.date,
    this.details,
  });

  @override
  List<Object?> get props => [id, activityName, amount, type, date, details];
}
