import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/operation_entity.dart';

class OperationModel extends OperationEntity {
  const OperationModel({
    super.id,
    required super.uid,
    required super.type,
    super.subType,
    super.customerName,
    super.phoneNumber,
    super.productName,
    required super.totalAmount,
    required super.paidAmount,
    required super.remainingDebt,
    super.timestamp,
    super.lastUpdatedAt,
    super.durationMinutes,
    super.turnCount,
    super.rate,
    super.ledgerNumber,
  });

  factory OperationModel.fromJson(Map<String, dynamic> json, String id) {
    return OperationModel(
      id: id,
      uid: json['uid'] ?? '',
      type: json['type'] ?? '',
      subType: json['subType'],
      customerName: json['customerName'],
      phoneNumber: json['phoneNumber'],
      productName: json['productName'],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      remainingDebt: (json['remainingDebt'] ?? 0).toDouble(),
      timestamp: (json['timestamp'] as Timestamp?)?.toDate(),
      lastUpdatedAt: (json['lastUpdatedAt'] as Timestamp?)?.toDate(),
      durationMinutes: json['durationMinutes'],
      turnCount: json['turnCount'],
      rate: json['rate']?.toDouble(),
      ledgerNumber: json['ledgerNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'type': type,
      'subType': subType,
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'productName': productName,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingDebt': remainingDebt,
      'timestamp': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : FieldValue.serverTimestamp(),
      'lastUpdatedAt': lastUpdatedAt != null
          ? Timestamp.fromDate(lastUpdatedAt!)
          : FieldValue.serverTimestamp(),
      'durationMinutes': durationMinutes,
      'turnCount': turnCount,
      'rate': rate,
      if (ledgerNumber != null) 'ledgerNumber': ledgerNumber,
    };
  }

  factory OperationModel.fromEntity(OperationEntity entity) {
    return OperationModel(
      id: entity.id,
      uid: entity.uid,
      type: entity.type,
      subType: entity.subType,
      customerName: entity.customerName,
      phoneNumber: entity.phoneNumber,
      productName: entity.productName,
      totalAmount: entity.totalAmount,
      paidAmount: entity.paidAmount,
      remainingDebt: entity.remainingDebt,
      timestamp: entity.timestamp,
      lastUpdatedAt: entity.lastUpdatedAt,
      durationMinutes: entity.durationMinutes,
      turnCount: entity.turnCount,
      rate: entity.rate,
      ledgerNumber: entity.ledgerNumber,
    );
  }
}
