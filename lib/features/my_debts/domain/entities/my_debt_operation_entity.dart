import 'package:equatable/equatable.dart';

enum MyDebtOperationType { debt, payment, purchase }

class MyDebtOperationEntity extends Equatable {
  final String id;
  final String activityName;
  final double amount;
  final MyDebtOperationType type;
  final DateTime date;
  final String? details;

  const MyDebtOperationEntity({
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
