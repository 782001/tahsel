import 'package:equatable/equatable.dart';

class ReportsEntity extends Equatable {
  final double totalIncome;
  final double totalExpenses;
  final double totalDebts;
  final double paidDebts;
  final double unpaidDebts;
  final double netProfit;
  
  // Dashboard indicators
  final double incomePercentage;
  final double expensePercentage;
  final double profitPercentage;
  final bool isIncomeIncrease;
  final bool isExpenseIncrease;
  final bool isProfitIncrease;

  const ReportsEntity({
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalDebts,
    required this.paidDebts,
    required this.unpaidDebts,
    required this.netProfit,
    this.incomePercentage = 0,
    this.expensePercentage = 0,
    this.profitPercentage = 0,
    this.isIncomeIncrease = true,
    this.isExpenseIncrease = false,
    this.isProfitIncrease = true,
  });

  @override
  List<Object?> get props => [
        totalIncome,
        totalExpenses,
        totalDebts,
        paidDebts,
        unpaidDebts,
        netProfit,
        incomePercentage,
        expensePercentage,
        profitPercentage,
        isIncomeIncrease,
        isExpenseIncrease,
        isProfitIncrease,
      ];

  ReportsEntity copyWith({
    double? totalIncome,
    double? totalExpenses,
    double? totalDebts,
    double? paidDebts,
    double? unpaidDebts,
    double? netProfit,
    double? incomePercentage,
    double? expensePercentage,
    double? profitPercentage,
    bool? isIncomeIncrease,
    bool? isExpenseIncrease,
    bool? isProfitIncrease,
  }) {
    return ReportsEntity(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalDebts: totalDebts ?? this.totalDebts,
      paidDebts: paidDebts ?? this.paidDebts,
      unpaidDebts: unpaidDebts ?? this.unpaidDebts,
      netProfit: netProfit ?? this.netProfit,
      incomePercentage: incomePercentage ?? this.incomePercentage,
      expensePercentage: expensePercentage ?? this.expensePercentage,
      profitPercentage: profitPercentage ?? this.profitPercentage,
      isIncomeIncrease: isIncomeIncrease ?? this.isIncomeIncrease,
      isExpenseIncrease: isExpenseIncrease ?? this.isExpenseIncrease,
      isProfitIncrease: isProfitIncrease ?? this.isProfitIncrease,
    );
  }
}
