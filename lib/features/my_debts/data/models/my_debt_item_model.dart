import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';

class MyDebtItemModel extends MyDebtItemEntity {
  const MyDebtItemModel({
    super.id,
    required super.uid,
    required super.operationId,
    required super.totalAmount,
    required super.paidAmount,
    required super.remainingAmount,
    super.personName,
    super.details,
    required super.operationType,
    super.timestamp,
    super.lastUpdatedAt,
    super.phoneNumber,
    super.isPaid,
    super.ledgerNumber,
  });

  factory MyDebtItemModel.fromJson(Map<String, dynamic> json, String id) {
    return MyDebtItemModel(
      id: id,
      uid: json['uid'] ?? '',
      operationId: json['operationId'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      remainingAmount: (json['remainingAmount'] ?? 0).toDouble(),
      personName: json['personName'],
      details: json['details'],
      operationType: json['operationType'] ?? 'shop',
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] as Timestamp).toDate()
          : null,
      lastUpdatedAt: json['lastUpdatedAt'] != null
          ? (json['lastUpdatedAt'] as Timestamp).toDate()
          : null,
      phoneNumber: json['phoneNumber'],
      isPaid: json['isPaid'] ?? false,
      ledgerNumber: json['ledgerNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'operationId': operationId,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'personName': personName,
      'details': details,
      'operationType': operationType,
      'timestamp': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : FieldValue.serverTimestamp(),
      'lastUpdatedAt': lastUpdatedAt != null
          ? Timestamp.fromDate(lastUpdatedAt!)
          : FieldValue.serverTimestamp(),
      'phoneNumber': phoneNumber,
      'isPaid': isPaid,
      'ledgerNumber': ledgerNumber,
    };
  }

  factory MyDebtItemModel.fromEntity(MyDebtItemEntity entity) {
    return MyDebtItemModel(
      id: entity.id,
      uid: entity.uid,
      operationId: entity.operationId,
      totalAmount: entity.totalAmount,
      paidAmount: entity.paidAmount,
      remainingAmount: entity.remainingAmount,
      personName: entity.personName,
      details: entity.details,
      operationType: entity.operationType,
      timestamp: entity.timestamp,
      lastUpdatedAt: entity.lastUpdatedAt,
      phoneNumber: entity.phoneNumber,
      isPaid: entity.isPaid,
      ledgerNumber: entity.ledgerNumber,
    );
  }
}
