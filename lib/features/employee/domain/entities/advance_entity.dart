import 'package:equatable/equatable.dart';

class AdvanceEntity extends Equatable {
  final String? id;
  final String employeeId;
  final String employeeName;
  final String uid;
  final double amount;
  final DateTime date;
  final String status;
  final String? payrollId;
  final String notes;
  final DateTime? createdAt;

  const AdvanceEntity({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.uid,
    required this.amount,
    required this.date,
    this.status = 'paid',
    this.payrollId,
    this.notes = '',
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeName,
    uid,
    amount,
    date,
    status,
    payrollId,
    notes,
    createdAt,
  ];
}
