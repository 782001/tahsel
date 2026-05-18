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
    );
  }
}
