import 'package:flutter/foundation.dart';
import '../entities/debt_entity.dart';

class CalculateTotalDebtsUseCase {
  Future<TotalDebtsResult> call(List<DebtEntity> debts) async {
    return await compute(_calculate, debts);
  }

  static TotalDebtsResult _calculate(List<DebtEntity> debts) {
    double totalAmount = 0;
    Set<String> uniqueCustomers = {};

    for (var debt in debts) {
      if (debt.remainingAmount > 0) {
        totalAmount += debt.remainingAmount;
        if (debt.customerName != null) {
          uniqueCustomers.add(debt.customerName!);
        }
      }
    }

    return TotalDebtsResult(
      totalAmount: totalAmount,
      customerCount: uniqueCustomers.length,
    );
  }
}

class TotalDebtsResult {
  final double totalAmount;
  final int customerCount;

  TotalDebtsResult({required this.totalAmount, required this.customerCount});
}
