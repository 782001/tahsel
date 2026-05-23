import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/payroll_entity.dart';

class PayrollModel extends PayrollEntity {
  const PayrollModel({
    super.id,
    required super.employeeId,
    required super.employeeName,
    required super.uid,
    required super.paymentDate,
    required super.amount,
    required super.bonus,
    required super.deduction,
    required super.overtimeCompensation,
    required super.netSalary,
    required super.monthKey,
    required super.notes,
    super.salaryType,
    super.periodStart,
    super.periodEnd,
    super.advancePaid,
    super.carriedForwardBalance,
  });

  factory PayrollModel.fromJson(Map<String, dynamic> json, String id) {
    final paymentDateData = json['paymentDate'];
    DateTime paymentDateVal;
    if (paymentDateData is Timestamp) {
      paymentDateVal = paymentDateData.toDate().toLocal();
    } else if (paymentDateData is String) {
      paymentDateVal = DateTime.parse(paymentDateData).toLocal();
    } else {
      paymentDateVal = DateTime.now();
    }

    final periodStartData = json['periodStart'];
    DateTime? periodStartVal;
    if (periodStartData is Timestamp) {
      periodStartVal = periodStartData.toDate().toLocal();
    } else if (periodStartData is String) {
      periodStartVal = DateTime.tryParse(periodStartData)?.toLocal();
    }

    final periodEndData = json['periodEnd'];
    DateTime? periodEndVal;
    if (periodEndData is Timestamp) {
      periodEndVal = periodEndData.toDate().toLocal();
    } else if (periodEndData is String) {
      periodEndVal = DateTime.tryParse(periodEndData)?.toLocal();
    }

    return PayrollModel(
      id: id,
      employeeId: json['employeeId'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      paymentDate: paymentDateVal,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      bonus: (json['bonus'] as num?)?.toDouble() ?? 0.0,
      deduction: (json['deduction'] as num?)?.toDouble() ?? 0.0,
      overtimeCompensation:
          (json['overtimeCompensation'] as num?)?.toDouble() ?? 0.0,
      netSalary: (json['netSalary'] as num?)?.toDouble() ?? 0.0,
      monthKey: json['monthKey'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      salaryType: json['salaryType'] as String?,
      periodStart: periodStartVal,
      periodEnd: periodEndVal,
      advancePaid: (json['advancePaid'] as num?)?.toDouble() ?? 0.0,
      carriedForwardBalance:
          (json['carriedForwardBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'uid': uid,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'amount': amount,
      'bonus': bonus,
      'deduction': deduction,
      'overtimeCompensation': overtimeCompensation,
      'netSalary': netSalary,
      'monthKey': monthKey,
      'notes': notes,
      'salaryType': salaryType,
      'periodStart': periodStart != null
          ? Timestamp.fromDate(periodStart!)
          : null,
      'periodEnd': periodEnd != null ? Timestamp.fromDate(periodEnd!) : null,
      'advancePaid': advancePaid ?? 0.0,
      'carriedForwardBalance': carriedForwardBalance ?? 0.0,
    };
  }

  factory PayrollModel.fromEntity(PayrollEntity entity) {
    return PayrollModel(
      id: entity.id,
      employeeId: entity.employeeId,
      employeeName: entity.employeeName,
      uid: entity.uid,
      paymentDate: entity.paymentDate,
      amount: entity.amount,
      bonus: entity.bonus,
      deduction: entity.deduction,
      overtimeCompensation: entity.overtimeCompensation,
      netSalary: entity.netSalary,
      monthKey: entity.monthKey,
      notes: entity.notes,
      salaryType: entity.salaryType,
      periodStart: entity.periodStart,
      periodEnd: entity.periodEnd,
      advancePaid: entity.advancePaid,
      carriedForwardBalance: entity.carriedForwardBalance,
    );
  }
}
