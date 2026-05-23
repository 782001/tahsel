import 'package:equatable/equatable.dart';

class EmployeeEntity extends Equatable {
  final String? id;
  final String uid;
  final String name;
  final String phone;
  final String role;
  final String salaryType; // 'monthly', 'daily', 'hourly'
  final double salaryAmount;
  final String status; // 'active', 'inactive', 'suspended'
  final DateTime createdAt;
  final String notes;
  final double expectedDailyHours;
  final double overtimeMultiplier;
  final double? customOvertimeRate;
  final double? customDeductionRate;
  final int paymentWindowStart;
  final int paymentWindowEnd;
  final double outstandingBalance; // Negative carried forward balance/debt
  final int allowedPaidWeekendsPerMonth;
  final double dailyDeductionMultiplier;

  const EmployeeEntity({
    this.id,
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    required this.salaryType,
    required this.salaryAmount,
    required this.status,
    required this.createdAt,
    required this.notes,
    this.expectedDailyHours = 8.0,
    this.overtimeMultiplier = 1.5,
    this.customOvertimeRate,
    this.customDeductionRate,
    this.paymentWindowStart = 1,
    this.paymentWindowEnd = 31,
    this.outstandingBalance = 0.0,
    this.allowedPaidWeekendsPerMonth = 4,
    this.dailyDeductionMultiplier = 1.0,
  });

  @override
  List<Object?> get props => [
    id,
    uid,
    name,
    phone,
    role,
    salaryType,
    salaryAmount,
    status,
    createdAt,
    notes,
    expectedDailyHours,
    overtimeMultiplier,
    customOvertimeRate,
    customDeductionRate,
    paymentWindowStart,
    paymentWindowEnd,
    outstandingBalance,
    allowedPaidWeekendsPerMonth,
    dailyDeductionMultiplier,
  ];
}
