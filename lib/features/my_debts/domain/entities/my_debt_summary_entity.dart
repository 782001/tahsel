import 'package:equatable/equatable.dart';

class MyDebtSummaryEntity extends Equatable {
  final double totalRemainingDebt;
  final double totalDebtAmount;
  final int peopleCount;

  const MyDebtSummaryEntity({
    required this.totalRemainingDebt,
    required this.totalDebtAmount,
    required this.peopleCount,
  });

  double get totalPaid => totalDebtAmount - totalRemainingDebt;

  @override
  List<Object?> get props => [totalRemainingDebt, totalDebtAmount, peopleCount];
}
