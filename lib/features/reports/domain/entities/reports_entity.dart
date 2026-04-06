import 'package:equatable/equatable.dart';

enum ReportPeriod { daily, weekly, monthly }

class ReportsEntity extends Equatable {
  final double totalIncome;
  final double totalExpenses;
  final double totalDebts;
  final double paidDebts;
  final double unpaidDebts;
  final double netProfit;
  
  // New: Breakdowns for Cafe & PlayStation
  final double cafeIncome;
  final double playstationIncome;
  
  // Dashboard indicators (Now using Absolute Difference in EGP)
  final double incomeDiff;
  final double expenseDiff;
  final double profitDiff;
  final double cafeDiff;
  final double playstationDiff;
  
  final bool isIncomeIncrease;
  final bool isExpenseIncrease;
  final bool isProfitIncrease;
  final bool isCafeIncrease;
  final bool isPlaystationIncrease;

  // Raw data for previous period (required for UseCase calculations)
  final double prevIncome;
  final double prevExpenses;
  final double prevCafeIncome;
  final double prevPlaystationIncome;

  const ReportsEntity({
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalDebts,
    required this.paidDebts,
    required this.unpaidDebts,
    required this.netProfit,
    this.prevIncome = 0,
    this.prevExpenses = 0,
    this.prevCafeIncome = 0,
    this.prevPlaystationIncome = 0,
    this.cafeIncome = 0,
    this.playstationIncome = 0,
    this.incomeDiff = 0,
    this.expenseDiff = 0,
    this.profitDiff = 0,
    this.cafeDiff = 0,
    this.playstationDiff = 0,
    this.isIncomeIncrease = true,
    this.isExpenseIncrease = false,
    this.isProfitIncrease = true,
    this.isCafeIncrease = true,
    this.isPlaystationIncrease = true,
  });

  @override
  List<Object?> get props => [
        totalIncome,
        totalExpenses,
        totalDebts,
        paidDebts,
        unpaidDebts,
        netProfit,
        prevIncome,
        prevExpenses,
        prevCafeIncome,
        prevPlaystationIncome,
        cafeIncome,
        playstationIncome,
        incomeDiff,
        expenseDiff,
        profitDiff,
        cafeDiff,
        playstationDiff,
        isIncomeIncrease,
        isExpenseIncrease,
        isProfitIncrease,
        isCafeIncrease,
        isPlaystationIncrease,
      ];

  ReportsEntity copyWith({
    double? totalIncome,
    double? totalExpenses,
    double? totalDebts,
    double? paidDebts,
    double? unpaidDebts,
    double? netProfit,
    double? prevIncome,
    double? prevExpenses,
    double? prevCafeIncome,
    double? prevPlaystationIncome,
    double? cafeIncome,
    double? playstationIncome,
    double? incomeDiff,
    double? expenseDiff,
    double? profitDiff,
    double? cafeDiff,
    double? playstationDiff,
    bool? isIncomeIncrease,
    bool? isExpenseIncrease,
    bool? isProfitIncrease,
    bool? isCafeIncrease,
    bool? isPlaystationIncrease,
  }) {
    return ReportsEntity(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalDebts: totalDebts ?? this.totalDebts,
      paidDebts: paidDebts ?? this.paidDebts,
      unpaidDebts: unpaidDebts ?? this.unpaidDebts,
      netProfit: netProfit ?? this.netProfit,
      prevIncome: prevIncome ?? this.prevIncome,
      prevExpenses: prevExpenses ?? this.prevExpenses,
      prevCafeIncome: prevCafeIncome ?? this.prevCafeIncome,
      prevPlaystationIncome: prevPlaystationIncome ?? this.prevPlaystationIncome,
      cafeIncome: cafeIncome ?? this.cafeIncome,
      playstationIncome: playstationIncome ?? this.playstationIncome,
      incomeDiff: incomeDiff ?? this.incomeDiff,
      expenseDiff: expenseDiff ?? this.expenseDiff,
      profitDiff: profitDiff ?? this.profitDiff,
      cafeDiff: cafeDiff ?? this.cafeDiff,
      playstationDiff: playstationDiff ?? this.playstationDiff,
      isIncomeIncrease: isIncomeIncrease ?? this.isIncomeIncrease,
      isExpenseIncrease: isExpenseIncrease ?? this.isExpenseIncrease,
      isProfitIncrease: isProfitIncrease ?? this.isProfitIncrease,
      isCafeIncrease: isCafeIncrease ?? this.isCafeIncrease,
      isPlaystationIncrease: isPlaystationIncrease ?? this.isPlaystationIncrease,
    );
  }
}
