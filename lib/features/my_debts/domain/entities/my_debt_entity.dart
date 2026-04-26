import 'package:equatable/equatable.dart';

class MyDebtEntity extends Equatable {
  final String id;
  final String? personId; // Links multiple entries to the same person
  final String personName;
  final double totalAmount;
  final double paidAmount;
  final double remainingDebt;
  final String? phoneNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime lastTransactionDate;

  final String notificationPreference;

  const MyDebtEntity({
    required this.id,
    this.personId,
    required this.personName,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingDebt,
    this.phoneNumber,
    this.notes,
    required this.createdAt,
    required this.lastTransactionDate,
    this.notificationPreference = 'none',
  });

  MyDebtEntity copyWith({
    String? id,
    String? personId,
    String? personName,
    double? totalAmount,
    double? paidAmount,
    double? remainingDebt,
    String? phoneNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? lastTransactionDate,
    String? notificationPreference,
  }) {
    return MyDebtEntity(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingDebt: remainingDebt ?? this.remainingDebt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      notificationPreference: notificationPreference ?? this.notificationPreference,
    );
  }

  @override
  List<Object?> get props => [
        id,
        personId,
        personName,
        totalAmount,
        paidAmount,
        remainingDebt,
        phoneNumber,
        notes,
        createdAt,
        lastTransactionDate,
        notificationPreference,
      ];
}

class MyDebtTransactionEntity extends Equatable {
  final String id;
  final String debtId;
  final double amount;
  final String type; // 'debt' or 'payment'
  final String? note;
  final DateTime date;

  const MyDebtTransactionEntity({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.type,
    this.note,
    required this.date,
  });

  @override
  List<Object?> get props => [id, debtId, amount, type, note, date];
}
