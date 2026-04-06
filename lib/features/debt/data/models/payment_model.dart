import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    super.id,
    required super.debtId,
    required super.amountPaid,
    required super.remainingAfterPayment,
    super.paymentDate,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json, String id) {
    return PaymentModel(
      id: id,
      debtId: json['debtId'] ?? '',
      amountPaid: (json['amountPaid'] ?? 0).toDouble(),
      remainingAfterPayment: (json['remainingAfterPayment'] ?? 0).toDouble(),
      paymentDate: json['paymentDate'] != null
          ? (json['paymentDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'debtId': debtId,
      'amountPaid': amountPaid,
      'remainingAfterPayment': remainingAfterPayment,
      'paymentDate': paymentDate ?? FieldValue.serverTimestamp(),
    };
  }

  factory PaymentModel.fromEntity(PaymentEntity entity) {
    return PaymentModel(
      id: entity.id,
      debtId: entity.debtId,
      amountPaid: entity.amountPaid,
      remainingAfterPayment: entity.remainingAfterPayment,
      paymentDate: entity.paymentDate,
    );
  }
}
