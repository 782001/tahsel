import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/employee_activity_entity.dart';

class EmployeeActivityModel extends EmployeeActivityEntity {
  const EmployeeActivityModel({
    required super.id,
    required super.ownerUid,
    required super.employeeUid,
    required super.employeeName,
    super.rolePreset,
    required super.actionCategory,
    required super.actionType,
    required super.actionTitle,
    required super.details,
    super.amount,
    super.extraData,
    required super.timestamp,
    super.isOfflineSync,
  });

  factory EmployeeActivityModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDate;
    final rawDate = map['timestamp'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate().toLocal();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate)?.toLocal() ?? DateTime.now();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate).toLocal();
    } else {
      parsedDate = DateTime.now();
    }

    double? parsedAmount;
    if (map['amount'] != null) {
      if (map['amount'] is num) {
        parsedAmount = (map['amount'] as num).toDouble();
      } else if (map['amount'] is String) {
        parsedAmount = double.tryParse(map['amount']);
      }
    }

    return EmployeeActivityModel(
      id: id,
      ownerUid: map['ownerUid'] as String? ?? '',
      employeeUid: map['employeeUid'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      rolePreset: map['rolePreset'] as String? ?? 'custom',
      actionCategory: map['actionCategory'] as String? ?? 'general',
      actionType: map['actionType'] as String? ?? 'general_action',
      actionTitle: map['actionTitle'] as String? ?? '',
      details: map['details'] as String? ?? '',
      amount: parsedAmount,
      extraData: map['extraData'] is Map
          ? Map<String, dynamic>.from(map['extraData'] as Map)
          : null,
      timestamp: parsedDate,
      isOfflineSync: (map['isOfflineSync'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerUid': ownerUid,
      'employeeUid': employeeUid,
      'employeeName': employeeName,
      'rolePreset': rolePreset,
      'actionCategory': actionCategory,
      'actionType': actionType,
      'actionTitle': actionTitle,
      'details': details,
      if (amount != null) 'amount': amount,
      if (extraData != null) 'extraData': extraData,
      'timestamp': Timestamp.fromDate(timestamp),
      'isOfflineSync': isOfflineSync,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
