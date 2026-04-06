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
    super.isPaid,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json, String id) {
    return DebtModel(
      id: id,
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
      isPaid: json['isPaid'] ?? false,
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
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
      'isPaid': isPaid,
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
      isPaid: entity.isPaid,
    );
  }
}
