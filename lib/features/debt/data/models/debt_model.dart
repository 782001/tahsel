import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/debt_entity.dart';

class DebtModel extends DebtEntity {
  const DebtModel({
    super.id,
    required super.uid,
    required super.operationId,
    required super.totalAmount,
    required super.paidAmount,
    required super.remainingAmount,
    super.customerName,
    super.productOrSessionDetails,
    required super.operationType,
    super.timestamp,
    super.lastUpdatedAt,
    super.phoneNumber,
    super.isPaid,
    super.ledgerNumber,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json, String id) {
    // If ID is empty or null, fallback to operationId as it's our authoritative local key
    final effectiveId = id.isNotEmpty ? id : (json['operationId'] ?? '');
    return DebtModel(
      id: effectiveId,
      uid: json['uid'] ?? '',
      operationId: json['operationId'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      remainingAmount: (json['remainingAmount'] ?? 0).toDouble(),
      customerName: json['customerName'],
      productOrSessionDetails: json['productOrSessionDetails'],
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
      'customerName': customerName,
      'productOrSessionDetails': productOrSessionDetails,
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

  factory DebtModel.fromEntity(DebtEntity entity) {
    return DebtModel(
      id: entity.id,
      uid: entity.uid,
      operationId: entity.operationId,
      totalAmount: entity.totalAmount,
      paidAmount: entity.paidAmount,
      remainingAmount: entity.remainingAmount,
      customerName: entity.customerName,
      productOrSessionDetails: entity.productOrSessionDetails,
      operationType: entity.operationType,
      timestamp: entity.timestamp,
      lastUpdatedAt: entity.lastUpdatedAt,
      phoneNumber: entity.phoneNumber,
      isPaid: entity.isPaid,
      ledgerNumber: entity.ledgerNumber,
    );
  }
}
