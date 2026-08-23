import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/vault_transaction_entity.dart';

class VaultTransactionModel extends VaultTransactionEntity {
  const VaultTransactionModel({
    required super.id,
    required super.uid,
    required super.amount,
    required super.direction,
    required super.source,
    required super.type,
    required super.description,
    super.relatedEntityId,
    super.relatedOperationId,
    required super.createdAt,
    super.createdBy,
  });

  factory VaultTransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDate;
    final rawDate = map['createdAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return VaultTransactionModel(
      id: docId,
      uid: map['uid'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      direction: (map['direction'] as String?) == 'in'
          ? VaultTransactionDirection.inFlow
          : VaultTransactionDirection.outFlow,
      source: _parseSource(map['source'] as String?),
      type: map['type'] as String? ?? '',
      description: map['description'] as String? ?? '',
      relatedEntityId: map['relatedEntityId'] as String?,
      relatedOperationId: map['relatedOperationId'] as String?,
      createdAt: parsedDate,
      createdBy: map['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'amount': amount,
      'direction': direction == VaultTransactionDirection.inFlow ? 'in' : 'out',
      'source': source.name,
      'type': type,
      'description': description,
      'relatedEntityId': relatedEntityId,
      'relatedOperationId': relatedOperationId,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  factory VaultTransactionModel.fromEntity(VaultTransactionEntity entity) {
    return VaultTransactionModel(
      id: entity.id,
      uid: entity.uid,
      amount: entity.amount,
      direction: entity.direction,
      source: entity.source,
      type: entity.type,
      description: entity.description,
      relatedEntityId: entity.relatedEntityId,
      relatedOperationId: entity.relatedOperationId,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
    );
  }

  static VaultTransactionSource _parseSource(String? raw) {
    if (raw == null) return VaultTransactionSource.all;
    switch (raw) {
      case 'customerDebt':
      case 'customer_debt':
        return VaultTransactionSource.customerDebt;
      case 'myDebt':
      case 'my_debt':
        return VaultTransactionSource.myDebt;
      case 'inventory':
      case 'inventory_purchase':
        return VaultTransactionSource.inventory;
      case 'employee':
        return VaultTransactionSource.employee;
      case 'expense':
        return VaultTransactionSource.expense;
      case 'manualDeposit':
      case 'manual_deposit':
      case 'manual_add':
        return VaultTransactionSource.manualDeposit;
      case 'manualWithdrawal':
      case 'manual_withdrawal':
      case 'manual_withdraw':
        return VaultTransactionSource.manualWithdrawal;
      default:
        return VaultTransactionSource.all;
    }
  }
}
