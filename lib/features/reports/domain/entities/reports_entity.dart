import 'package:equatable/equatable.dart';

enum ReportPeriod { daily, weekly, monthly, allTime }

class ReportsEntity extends Equatable {
  final double totalIncome;
  final double totalExpenses;
  final double totalDebts;
  final double paidDebts;
  final double unpaidDebts;
  final double netProfit;

  // Breakdowns for counts
  final int totalCount;
  final int cafeCount;
  final int playstationCount;

  // New: Breakdowns for Cafe & PlayStation
  final double cafeIncome;
  final double playstationIncome;

  // New: Breakdowns for Invoices
  final int invoiceCount;
  final double invoiceValue;
  final double invoiceCollected;
  final double invoiceRemaining;
  final int invoicePaidCount;
  final int invoicePartialCount;
  final int invoiceUnpaidCount;

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
    this.totalCount = 0,
    this.cafeCount = 0,
    this.playstationCount = 0,
    this.prevIncome = 0,
    this.prevExpenses = 0,
    this.prevCafeIncome = 0,
    this.prevPlaystationIncome = 0,
    this.cafeIncome = 0,
    this.playstationIncome = 0,
    this.invoiceCount = 0,
    this.invoiceValue = 0,
    this.invoiceCollected = 0,
    this.invoiceRemaining = 0,
    this.invoicePaidCount = 0,
    this.invoicePartialCount = 0,
    this.invoiceUnpaidCount = 0,
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
    totalCount,
    cafeCount,
    playstationCount,
    prevIncome,
    prevExpenses,
    prevCafeIncome,
    prevPlaystationIncome,
    cafeIncome,
    playstationIncome,
    invoiceCount,
    invoiceValue,
    invoiceCollected,
    invoiceRemaining,
    invoicePaidCount,
    invoicePartialCount,
    invoiceUnpaidCount,
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
    int? invoiceCount,
    double? invoiceValue,
    double? invoiceCollected,
    double? invoiceRemaining,
    int? invoicePaidCount,
    int? invoicePartialCount,
    int? invoiceUnpaidCount,
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
      prevPlaystationIncome:
          prevPlaystationIncome ?? this.prevPlaystationIncome,
      cafeIncome: cafeIncome ?? this.cafeIncome,
      playstationIncome: playstationIncome ?? this.playstationIncome,
      invoiceCount: invoiceCount ?? this.invoiceCount,
      invoiceValue: invoiceValue ?? this.invoiceValue,
      invoiceCollected: invoiceCollected ?? this.invoiceCollected,
      invoiceRemaining: invoiceRemaining ?? this.invoiceRemaining,
      invoicePaidCount: invoicePaidCount ?? this.invoicePaidCount,
      invoicePartialCount: invoicePartialCount ?? this.invoicePartialCount,
      invoiceUnpaidCount: invoiceUnpaidCount ?? this.invoiceUnpaidCount,
      incomeDiff: incomeDiff ?? this.incomeDiff,
      expenseDiff: expenseDiff ?? this.expenseDiff,
      profitDiff: profitDiff ?? this.profitDiff,
      cafeDiff: cafeDiff ?? this.cafeDiff,
      playstationDiff: playstationDiff ?? this.playstationDiff,
      isIncomeIncrease: isIncomeIncrease ?? this.isIncomeIncrease,
      isExpenseIncrease: isExpenseIncrease ?? this.isExpenseIncrease,
      isProfitIncrease: isProfitIncrease ?? this.isProfitIncrease,
      isCafeIncrease: isCafeIncrease ?? this.isCafeIncrease,
      isPlaystationIncrease:
          isPlaystationIncrease ?? this.isPlaystationIncrease,
    );
  }
}

