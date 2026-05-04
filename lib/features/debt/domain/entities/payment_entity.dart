import 'package:equatable/equatable.dart';

enum PaymentType { partial, full, settlement, debtAdded, adjustment, reversal }

class PaymentEntity extends Equatable {
  final String? id;
  final String? uid;
  final String debtId;
  final double amountPaid;
  final double remainingAmount;
  final DateTime? createdAt;
  final PaymentType type;
  final String? activityName;
  final String? relatedTo;

  const PaymentEntity({
    this.id,
    this.uid,
    required this.debtId,
    required this.amountPaid,
    required this.remainingAmount,
    this.createdAt,
    required this.type,
    this.activityName,
    this.relatedTo,
  });

  @override
  List<Object?> get props => [
    id,
    uid,
    debtId,
    amountPaid,
    remainingAmount,
    createdAt,
    type,
    activityName,
    relatedTo,
  ];
}
