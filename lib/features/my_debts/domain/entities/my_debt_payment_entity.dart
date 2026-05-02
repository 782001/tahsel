import 'package:equatable/equatable.dart';

class MyDebtPaymentEntity extends Equatable {
  final String? id;
  final String debtId;
  final double amountPaid;
  final String type;
  final String? note;
  final String? relatedTo;
  final double remainingAmount;
  final DateTime createdAt;

  const MyDebtPaymentEntity({
    this.id,
    required this.debtId,
    required this.amountPaid,
    required this.type,
    this.note,
    this.relatedTo,
    required this.remainingAmount,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    debtId,
    amountPaid,
    type,
    note,
    relatedTo,
    remainingAmount,
    createdAt,
  ];
}
