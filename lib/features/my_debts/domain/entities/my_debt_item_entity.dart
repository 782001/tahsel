import 'package:equatable/equatable.dart';

class MyDebtItemEntity extends Equatable {
  final String? id;
  final String uid;
  final String operationId;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String? personName;
  final String? details;
  final String operationType;
  final DateTime? timestamp;
  final DateTime? lastUpdatedAt;
  final String? phoneNumber;
  final bool isPaid;
  final String? ledgerNumber;

  const MyDebtItemEntity({
    this.id,
    required this.uid,
    required this.operationId,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    this.personName,
    this.details,
    required this.operationType,
    this.timestamp,
    this.lastUpdatedAt,
    this.phoneNumber,
    this.isPaid = false,
    this.ledgerNumber,
  });

  MyDebtItemEntity copyWith({
    String? id,
    String? uid,
    String? operationId,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    String? personName,
    String? details,
    String? operationType,
    DateTime? timestamp,
    DateTime? lastUpdatedAt,
    String? phoneNumber,
    bool? isPaid,
    String? ledgerNumber,
  }) {
    return MyDebtItemEntity(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      operationId: operationId ?? this.operationId,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      personName: personName ?? this.personName,
      details: details ?? this.details,
      operationType: operationType ?? this.operationType,
      timestamp: timestamp ?? this.timestamp,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isPaid: isPaid ?? this.isPaid,
      ledgerNumber: ledgerNumber ?? this.ledgerNumber,
    );
  }

  @override
  List<Object?> get props => [
        id,
        uid,
        operationId,
        totalAmount,
        paidAmount,
        remainingAmount,
        personName,
        details,
        operationType,
        timestamp,
        lastUpdatedAt,
        phoneNumber,
        isPaid,
        ledgerNumber,
      ];
}
