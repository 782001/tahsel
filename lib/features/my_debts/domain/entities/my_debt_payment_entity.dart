import 'package:equatable/equatable.dart';

class MyDebtPaymentEntity extends Equatable {
  final String? id;
  final String debtId;
  final double amountPaid;
  final String type;
  final String? note;
  final DateTime createdAt;

  const MyDebtPaymentEntity({
    this.id,
    required this.debtId,
    required this.amountPaid,
    required this.type,
    this.note,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, debtId, amountPaid, type, note, createdAt];
}
