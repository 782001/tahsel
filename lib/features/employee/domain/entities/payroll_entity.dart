import 'package:equatable/equatable.dart';

class PayrollEntity extends Equatable {
  final String? id;
  final String employeeId;
  final String employeeName;
  final String uid;
  final DateTime paymentDate;
  final double amount;
  final double bonus;
  final double deduction;
  final double overtimeCompensation;
  final double netSalary;
  final String monthKey; // 'yyyy-MM'
  final String notes;
  final String? salaryType; // Added for expense creation
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final double? advancePaid;
  final double? carriedForwardBalance;

  const PayrollEntity({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.uid,
    required this.paymentDate,
    required this.amount,
    required this.bonus,
    required this.deduction,
    required this.overtimeCompensation,
    required this.netSalary,
    required this.monthKey,
    required this.notes,
    this.salaryType,
    this.periodStart,
    this.periodEnd,
    this.advancePaid,
    this.carriedForwardBalance,
  });

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeName,
    uid,
    paymentDate,
    amount,
    bonus,
    deduction,
    overtimeCompensation,
    netSalary,
    monthKey,
    notes,
    salaryType,
    periodStart,
    periodEnd,
    advancePaid,
    carriedForwardBalance,
  ];
}
