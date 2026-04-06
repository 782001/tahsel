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
  });

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
      ];
}
