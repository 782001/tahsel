import 'package:equatable/equatable.dart';
import 'custody_expense_item.dart';

class CustodyEntity extends Equatable {
  final String id;
  final String ownerUid;
  final String recipientName;
  final String? recipientEmployeeId;
  final String recipientType; // 'employee' | 'owner' | 'other'
  final double initialAmount;
  final double spentAmount;
  final double remainingAmount;
  final String status; // 'active' | 'settled'
  final String? notes;
  final DateTime createdAt;
  final DateTime? settledAt;
  final String? settledBy;
  final double? actualSettledAmount;
  final double? varianceAmount;
  final String? settlementNotes;
  final List<CustodyExpenseItem> expenses;

  const CustodyEntity({
    required this.id,
    required this.ownerUid,
    required this.recipientName,
    this.recipientEmployeeId,
    required this.recipientType,
    required this.initialAmount,
    required this.spentAmount,
    required this.remainingAmount,
    required this.status,
    this.notes,
    required this.createdAt,
    this.settledAt,
    this.settledBy,
    this.actualSettledAmount,
    this.varianceAmount,
    this.settlementNotes,
    this.expenses = const [],
  });

  bool get isActive => status == 'active';
  bool get isSettled => status == 'settled';

  /// Whether the remaining balance is negative (employee paid out of their own pocket).
  bool get isDeficit => remainingAmount < 0;

  CustodyEntity copyWith({
    String? id,
    String? ownerUid,
    String? recipientName,
    String? recipientEmployeeId,
    String? recipientType,
    double? initialAmount,
    double? spentAmount,
    double? remainingAmount,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? settledAt,
    String? settledBy,
    double? actualSettledAmount,
    double? varianceAmount,
    String? settlementNotes,
    List<CustodyExpenseItem>? expenses,
  }) {
    return CustodyEntity(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      recipientName: recipientName ?? this.recipientName,
      recipientEmployeeId: recipientEmployeeId ?? this.recipientEmployeeId,
      recipientType: recipientType ?? this.recipientType,
      initialAmount: initialAmount ?? this.initialAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      settledAt: settledAt ?? this.settledAt,
      settledBy: settledBy ?? this.settledBy,
      actualSettledAmount: actualSettledAmount ?? this.actualSettledAmount,
      varianceAmount: varianceAmount ?? this.varianceAmount,
      settlementNotes: settlementNotes ?? this.settlementNotes,
      expenses: expenses ?? this.expenses,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerUid,
        recipientName,
        recipientEmployeeId,
        recipientType,
        initialAmount,
        spentAmount,
        remainingAmount,
        status,
        notes,
        createdAt,
        settledAt,
        settledBy,
        actualSettledAmount,
        varianceAmount,
        settlementNotes,
        expenses,
      ];
}
