import 'package:equatable/equatable.dart';

enum PaymentType { partial, full, settlement, debtAdded }

class PaymentEntity extends Equatable {
  final String? id;
  final String debtId;
  final double amountPaid;
  final double remainingAmount;
  final DateTime? createdAt;
  final PaymentType type;
  final String? activityName;

  const PaymentEntity({
    this.id,
    required this.debtId,
    required this.amountPaid,
    required this.remainingAmount,
    this.createdAt,
    required this.type,
    this.activityName,
  });

  @override
  List<Object?> get props => [
        id,
        debtId,
        amountPaid,
        remainingAmount,
        createdAt,
        type,
        activityName,
      ];
}
