import 'package:equatable/equatable.dart';

class MyDebtPersonEntity extends Equatable {
  final String? id;
  final String name;
  final String? phoneNumber;
  final String notificationPreference;
  final DateTime lastUsedAt;
  final int totalTransactions;
  final String? ledgerNumber;
  final double totalDebtAmount;
  final double totalRemainingDebt;

  const MyDebtPersonEntity({
    this.id,
    required this.name,
    this.phoneNumber,
    this.notificationPreference = 'none',
    required this.lastUsedAt,
    this.totalTransactions = 1,
    this.ledgerNumber,
    this.totalDebtAmount = 0,
    this.totalRemainingDebt = 0,
  });

  MyDebtPersonEntity copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? notificationPreference,
    DateTime? lastUsedAt,
    int? totalTransactions,
    String? ledgerNumber,
    double? totalDebtAmount,
    double? totalRemainingDebt,
  }) {
    return MyDebtPersonEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      notificationPreference: notificationPreference ?? this.notificationPreference,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      ledgerNumber: ledgerNumber ?? this.ledgerNumber,
      totalDebtAmount: totalDebtAmount ?? this.totalDebtAmount,
      totalRemainingDebt: totalRemainingDebt ?? this.totalRemainingDebt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phoneNumber,
        notificationPreference,
        lastUsedAt,
        totalTransactions,
        ledgerNumber,
        totalDebtAmount,
        totalRemainingDebt,
      ];
}
