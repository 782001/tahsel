import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/ps_session_entity.dart';

class PsSessionModel extends PsSessionEntity {
  const PsSessionModel({
    super.id,
    required super.uid,
    super.customerName,
    super.phoneNumber,
    super.deviceId,
    super.roomId,
    super.operatorName,
    required super.subType,
    required super.rate,
    required super.startTime,
    super.endTime,
    super.status = PsSessionStatus.active,
    super.totalAmount = 0.0,
    super.paidAmount = 0.0,
    super.remainingDebt = 0.0,
    super.turnCount,
    super.ledgerNumber,
    required super.createdAt,
  });

  factory PsSessionModel.fromJson(Map<String, dynamic> json, String id) {
    return PsSessionModel(
      id: id,
      uid: json['uid'] ?? '',
      customerName: json['customerName'],
      phoneNumber: json['phoneNumber'],
      deviceId: json['deviceId'],
      roomId: json['roomId'],
      operatorName: json['operatorName'],
      subType: json['subType'] ?? 'time',
      rate: (json['rate'] ?? 0).toDouble(),
      startTime: (json['startTime'] as Timestamp).toDate(),
      endTime: json['endTime'] != null
          ? (json['endTime'] as Timestamp).toDate()
          : null,
      status: json['status'] == 'completed'
          ? PsSessionStatus.completed
          : PsSessionStatus.active,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      remainingDebt: (json['remainingDebt'] ?? 0).toDouble(),
      turnCount: json['turnCount'],
      ledgerNumber: json['ledgerNumber'] as String?,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'deviceId': deviceId,
      'roomId': roomId,
      'operatorName': operatorName,
      'subType': subType,
      'rate': rate,
      'startTime': Timestamp.fromDate(startTime),
      if (endTime != null) 'endTime': Timestamp.fromDate(endTime!),
      'status': status == PsSessionStatus.completed ? 'completed' : 'active',
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingDebt': remainingDebt,
      'turnCount': turnCount,
      if (ledgerNumber != null) 'ledgerNumber': ledgerNumber,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PsSessionModel.fromEntity(PsSessionEntity entity) {
    return PsSessionModel(
      id: entity.id,
      uid: entity.uid,
      customerName: entity.customerName,
      phoneNumber: entity.phoneNumber,
      deviceId: entity.deviceId,
      roomId: entity.roomId,
      operatorName: entity.operatorName,
      subType: entity.subType,
      rate: entity.rate,
      startTime: entity.startTime,
      endTime: entity.endTime,
      status: entity.status,
      totalAmount: entity.totalAmount,
      paidAmount: entity.paidAmount,
      remainingDebt: entity.remainingDebt,
      turnCount: entity.turnCount,
      ledgerNumber: entity.ledgerNumber,
      createdAt: entity.createdAt,
    );
  }
}
