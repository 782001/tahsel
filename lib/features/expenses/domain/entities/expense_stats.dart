class ExpenseStats {
  final double totalAmount;
  final double previousMonthAmount;
  final double percentageChange;
  final bool isIncrease;

  const ExpenseStats({
    required this.totalAmount,
    this.previousMonthAmount = 0.0,
    required this.percentageChange,
    required this.isIncrease,
  });
}
