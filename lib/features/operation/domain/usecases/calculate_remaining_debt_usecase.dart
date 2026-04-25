import 'package:flutter/foundation.dart';

class CalculateRemainingDebtUseCase {
  Future<double> call(CalculateRemainingDebtParams params) async {
    return await compute(_calculate, params);
  }

  static double _calculate(CalculateRemainingDebtParams params) {
    if (params.totalAmount < params.paidAmount) {
      return 0.0; // Or handle error? Validation should happen in UI
    }
    return params.totalAmount - params.paidAmount;
  }
}

class CalculateRemainingDebtParams {
  final double totalAmount;
  final double paidAmount;

  CalculateRemainingDebtParams({
    required this.totalAmount,
    required this.paidAmount,
  });
}
