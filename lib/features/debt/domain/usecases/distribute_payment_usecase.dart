import '../entities/debt_entity.dart';

class DistributedPaymentResult {
  final DebtEntity updatedDebt;
  final double amountToPay;
  final double remainingAfter;
  final bool isFullPayment;

  DistributedPaymentResult({
    required this.updatedDebt,
    required this.amountToPay,
    required this.remainingAfter,
    required this.isFullPayment,
  });
}

class DistributePaymentUseCase {
  List<DistributedPaymentResult> call(List<DebtEntity> debts, double paymentAmount) {
    // Sort debts by timestamp to ensure FIFO (oldest first)
    final sortedDebts = List<DebtEntity>.from(debts)
      ..sort((a, b) => (a.timestamp ?? DateTime.now()).compareTo(b.timestamp ?? DateTime.now()));

    List<DistributedPaymentResult> results = [];
    double remainingToDistribute = paymentAmount;

    for (var debt in sortedDebts) {
      if (remainingToDistribute <= 0) break;

      double paymentForThisItem = 0;
      if (remainingToDistribute >= debt.remainingAmount) {
        paymentForThisItem = debt.remainingAmount;
        remainingToDistribute -= debt.remainingAmount;
      } else {
        paymentForThisItem = remainingToDistribute;
        remainingToDistribute = 0;
      }

      final newPaidAmount = debt.paidAmount + paymentForThisItem;
      final newRemainingAmount = debt.totalAmount - newPaidAmount;
      final isPaid = newRemainingAmount <= 1e-9; // Use small epsilon for double precision

      final updatedDebt = debt.copyWith(
        paidAmount: newPaidAmount,
        remainingAmount: newRemainingAmount,
        isPaid: isPaid,
      );

      results.add(DistributedPaymentResult(
        updatedDebt: updatedDebt,
        amountToPay: paymentForThisItem,
        remainingAfter: newRemainingAmount,
        isFullPayment: isPaid,
      ));
    }

    return results;
  }
}
