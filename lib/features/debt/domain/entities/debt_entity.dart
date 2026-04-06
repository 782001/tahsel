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
  final bool isPaid;

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
    this.isPaid = false,
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
    bool? isPaid,
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
      isPaid: isPaid ?? this.isPaid,
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
        isPaid,
      ];
}
