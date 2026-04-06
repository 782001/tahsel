import 'package:equatable/equatable.dart';

class PaymentEntity extends Equatable {
  final String? id;
  final String debtId;
  final double amountPaid;
  final double remainingAfterPayment;
  final DateTime? paymentDate;

  const PaymentEntity({
    this.id,
    required this.debtId,
    required this.amountPaid,
    required this.remainingAfterPayment,
    this.paymentDate,
  });

  @override
  List<Object?> get props => [
        id,
        debtId,
        amountPaid,
        remainingAfterPayment,
        paymentDate,
      ];
}
