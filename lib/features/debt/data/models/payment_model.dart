import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    super.id,
    required super.debtId,
    required super.amountPaid,
    required super.remainingAmount,
    super.createdAt,
    required super.type,
    super.activityName,
    super.relatedTo,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json, String id) {
    return PaymentModel(
      id: id,
      debtId: json['debtId'] ?? '',
      amountPaid: (json['amountPaid'] ?? 0).toDouble(),
      remainingAmount: (json['remainingAmount'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      type: PaymentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PaymentType.partial,
      ),
      activityName: json['activityName'],
      relatedTo: json['relatedTo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'debtId': debtId,
      'amountPaid': amountPaid,
      'remainingAmount': remainingAmount,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'type': type.name,
      'activityName': activityName,
      'relatedTo': relatedTo,
    };
  }

  factory PaymentModel.fromEntity(PaymentEntity entity) {
    return PaymentModel(
      id: entity.id,
      debtId: entity.debtId,
      amountPaid: entity.amountPaid,
      remainingAmount: entity.remainingAmount,
      createdAt: entity.createdAt,
      type: entity.type,
      activityName: entity.activityName,
      relatedTo: entity.relatedTo,
    );
  }
}
