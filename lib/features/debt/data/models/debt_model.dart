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
    super.dueDate,
    super.lastReminderSentAt,
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
          ? (json['timestamp'] is Timestamp
              ? (json['timestamp'] as Timestamp).toDate()
              : DateTime.tryParse(json['timestamp'].toString()))
          : null,
      lastUpdatedAt: json['lastUpdatedAt'] != null
          ? (json['lastUpdatedAt'] is Timestamp
              ? (json['lastUpdatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(json['lastUpdatedAt'].toString()))
          : null,
      phoneNumber: json['phoneNumber'],
      isPaid: json['isPaid'] ?? false,
      ledgerNumber: json['ledgerNumber'],
      dueDate: json['dueDate'] != null
          ? (json['dueDate'] is Timestamp
              ? (json['dueDate'] as Timestamp).toDate()
              : DateTime.tryParse(json['dueDate'].toString()))
          : null,
      lastReminderSentAt: json['lastReminderSentAt'] != null
          ? (json['lastReminderSentAt'] is Timestamp
              ? (json['lastReminderSentAt'] as Timestamp).toDate()
              : DateTime.tryParse(json['lastReminderSentAt'].toString()))
          : null,
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
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
      if (lastReminderSentAt != null)
        'lastReminderSentAt': Timestamp.fromDate(lastReminderSentAt!),
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
      dueDate: entity.dueDate,
      lastReminderSentAt: entity.lastReminderSentAt,
    );
  }
}
