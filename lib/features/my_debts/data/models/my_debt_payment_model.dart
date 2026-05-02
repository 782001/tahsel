import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_payment_entity.dart';

class MyDebtPaymentModel extends MyDebtPaymentEntity {
  const MyDebtPaymentModel({
    super.id,
    required super.debtId,
    required super.amountPaid,
    required super.type,
    super.note,
    super.relatedTo,
    required super.remainingAmount,
    required super.createdAt,
  });

  factory MyDebtPaymentModel.fromJson(Map<String, dynamic> json, String id) {
    return MyDebtPaymentModel(
      id: id,
      debtId: json['debtId'] ?? '',
      amountPaid: (json['amountPaid'] ?? 0).toDouble(),
      type: json['type'] ?? '',
      note: json['note'],
      relatedTo: json['relatedTo'],
      remainingAmount: (json['remainingAmount'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'debtId': debtId,
      'amountPaid': amountPaid,
      'type': type,
      'note': note,
      'relatedTo': relatedTo,
      'remainingAmount': remainingAmount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MyDebtPaymentModel.fromEntity(MyDebtPaymentEntity entity) {
    return MyDebtPaymentModel(
      id: entity.id,
      debtId: entity.debtId,
      amountPaid: entity.amountPaid,
      type: entity.type,
      note: entity.note,
      relatedTo: entity.relatedTo,
      remainingAmount: entity.remainingAmount,
      createdAt: entity.createdAt,
    );
  }
}
