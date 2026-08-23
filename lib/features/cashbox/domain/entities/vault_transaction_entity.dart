import 'package:equatable/equatable.dart';

enum VaultTransactionDirection { inFlow, outFlow }

enum VaultTransactionSource {
  all,
  customerDebt,
  myDebt,
  inventory,
  employee,
  expense,
  manualDeposit,
  manualWithdrawal,
}

class VaultTransactionEntity extends Equatable {
  final String id;
  final String uid;
  final double amount;
  final VaultTransactionDirection direction;
  final VaultTransactionSource source;
  final String type;
  final String description;
  final String? relatedEntityId;
  final String? relatedOperationId;
  final DateTime createdAt;
  final String? createdBy;

  const VaultTransactionEntity({
    required this.id,
    required this.uid,
    required this.amount,
    required this.direction,
    required this.source,
    required this.type,
    required this.description,
    this.relatedEntityId,
    this.relatedOperationId,
    required this.createdAt,
    this.createdBy,
  });

  @override
  List<Object?> get props => [
        id,
        uid,
        amount,
        direction,
        source,
        type,
        description,
        relatedEntityId,
        relatedOperationId,
        createdAt,
        createdBy,
      ];
}
