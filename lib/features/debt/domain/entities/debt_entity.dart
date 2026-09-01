import 'package:equatable/equatable.dart';

class DebtEntity extends Equatable {
  final String? id;
  final String uid;
  final String operationId;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String? customerName;
  final String? productOrSessionDetails;
  final String operationType;
  final DateTime? timestamp;
  final DateTime? lastUpdatedAt;
  final String? phoneNumber;
  final bool isPaid;
  final String? ledgerNumber;
  final DateTime? dueDate;
  final DateTime? lastReminderSentAt;

  const DebtEntity({
    this.id,
    required this.uid,
    required this.operationId,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    this.customerName,
    this.productOrSessionDetails,
    required this.operationType,
    this.timestamp,
    this.lastUpdatedAt,
    this.phoneNumber,
    this.isPaid = false,
    this.ledgerNumber,
    this.dueDate,
    this.lastReminderSentAt,
  });

  DebtEntity copyWith({
    String? id,
    String? uid,
    String? operationId,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    String? customerName,
    String? productOrSessionDetails,
    String? operationType,
    DateTime? timestamp,
    DateTime? lastUpdatedAt,
    String? phoneNumber,
    bool? isPaid,
    String? ledgerNumber,
    DateTime? dueDate,
    DateTime? lastReminderSentAt,
  }) {
    return DebtEntity(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      operationId: operationId ?? this.operationId,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      customerName: customerName ?? this.customerName,
      productOrSessionDetails:
          productOrSessionDetails ?? this.productOrSessionDetails,
      operationType: operationType ?? this.operationType,
      timestamp: timestamp ?? this.timestamp,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isPaid: isPaid ?? this.isPaid,
      ledgerNumber: ledgerNumber ?? this.ledgerNumber,
      dueDate: dueDate ?? this.dueDate,
      lastReminderSentAt: lastReminderSentAt ?? this.lastReminderSentAt,
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
    customerName,
    productOrSessionDetails,
    operationType,
    timestamp,
    lastUpdatedAt,
    phoneNumber,
    isPaid,
    ledgerNumber,
    dueDate,
    lastReminderSentAt,
  ];
}

class TotalDebtsResult {
  final double totalAmount;
  final int customerCount;

  TotalDebtsResult({required this.totalAmount, required this.customerCount});
}
