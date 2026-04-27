import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_person_entity.dart';

class MyDebtPersonModel extends MyDebtPersonEntity {
  const MyDebtPersonModel({
    super.id,
    required super.name,
    super.phoneNumber,
    super.notificationPreference = 'none',
    required super.lastUsedAt,
    super.totalTransactions = 1,
    super.ledgerNumber,
    super.totalDebtAmount = 0,
    super.totalRemainingDebt = 0,
  });

  factory MyDebtPersonModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return MyDebtPersonModel(
      id: id,
      name: (json['name'] as String?) ?? id ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      notificationPreference: json['notificationPreference'] as String? ?? 'none',
      lastUsedAt: (json['lastUsedAt'] as Timestamp).toDate(),
      totalTransactions: json['totalTransactions'] as int? ?? 1,
      ledgerNumber: json['ledgerNumber'] as String?,
      totalDebtAmount: (json['totalDebtAmount'] as num?)?.toDouble() ?? 0,
      totalRemainingDebt: (json['totalRemainingDebt'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'notificationPreference': notificationPreference,
      'lastUsedAt': Timestamp.fromDate(lastUsedAt),
      'totalTransactions': totalTransactions,
      'totalDebtAmount': totalDebtAmount,
      'totalRemainingDebt': totalRemainingDebt,
      if (ledgerNumber != null) 'ledgerNumber': ledgerNumber,
    };
  }

  factory MyDebtPersonModel.fromEntity(MyDebtPersonEntity entity) {
    return MyDebtPersonModel(
      id: entity.id,
      name: entity.name,
      phoneNumber: entity.phoneNumber,
      notificationPreference: entity.notificationPreference,
      lastUsedAt: entity.lastUsedAt,
      totalTransactions: entity.totalTransactions,
      ledgerNumber: entity.ledgerNumber,
      totalDebtAmount: entity.totalDebtAmount,
      totalRemainingDebt: entity.totalRemainingDebt,
    );
  }
}
