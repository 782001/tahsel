import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/advance_entity.dart';

class AdvanceModel extends AdvanceEntity {
  const AdvanceModel({
    super.id,
    required super.employeeId,
    required super.employeeName,
    required super.uid,
    required super.amount,
    required super.date,
    super.status = 'paid',
    super.payrollId,
    super.notes = '',
    super.createdAt,
  });

  factory AdvanceModel.fromJson(Map<String, dynamic> json, String id) {
    final dateData = json['date'];
    DateTime dateVal;
    if (dateData is Timestamp) {
      dateVal = dateData.toDate().toLocal();
    } else if (dateData is String) {
      dateVal = DateTime.tryParse(dateData)?.toLocal() ?? DateTime.now();
    } else {
      dateVal = DateTime.now();
    }

    final createdAtData = json['createdAt'];
    DateTime? createdAtVal;
    if (createdAtData is Timestamp) {
      createdAtVal = createdAtData.toDate().toLocal();
    } else if (createdAtData is String) {
      createdAtVal = DateTime.tryParse(createdAtData)?.toLocal();
    }

    return AdvanceModel(
      id: id,
      employeeId: json['employeeId'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: dateVal,
      status: json['status'] as String? ?? 'paid',
      payrollId: json['payrollId'] as String?,
      notes: json['notes'] as String? ?? '',
      createdAt: createdAtVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'uid': uid,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'status': status,
      'payrollId': payrollId,
      'notes': notes,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory AdvanceModel.fromEntity(AdvanceEntity entity) {
    return AdvanceModel(
      id: entity.id,
      employeeId: entity.employeeId,
      employeeName: entity.employeeName,
      uid: entity.uid,
      amount: entity.amount,
      date: entity.date,
      status: entity.status,
      payrollId: entity.payrollId,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }
}
