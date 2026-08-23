import 'package:equatable/equatable.dart';

class VaultSummaryEntity extends Equatable {
  final double currentBalance;
  final double totalIn;
  final double totalOut;
  final int transactionCount;
  final DateTime? lastUpdatedAt;

  const VaultSummaryEntity({
    required this.currentBalance,
    this.totalIn = 0.0,
    this.totalOut = 0.0,
    this.transactionCount = 0,
    this.lastUpdatedAt,
  });

  @override
  List<Object?> get props => [
        currentBalance,
        totalIn,
        totalOut,
        transactionCount,
        lastUpdatedAt,
      ];
}
