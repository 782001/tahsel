import 'package:dartz/dartz.dart';
import '../entities/debt_entity.dart';
import '../entities/payment_entity.dart';
import '../repositories/debt_repository.dart';

class PayItemDebtParams {
  final DebtEntity debt;
  final double amountToPay;

  PayItemDebtParams({
    required this.debt,
    required this.amountToPay,
  });
}

class PayItemDebtUseCase {
  final DebtRepository repository;

  PayItemDebtUseCase({required this.repository});

  Future<Either<dynamic, void>> call(PayItemDebtParams params) {
    if (params.amountToPay <= 0) {
      return Future.value(const Left('Payment amount must be greater than zero'));
    }

    if (params.amountToPay > params.debt.remainingAmount) {
      return Future.value(const Left('Payment amount exceeds remaining debt'));
    }

    final newPaidAmount = params.debt.paidAmount + params.amountToPay;
    final newRemainingAmount = params.debt.totalAmount - newPaidAmount;
    final isPaid = newRemainingAmount <= 0;

    final updatedDebt = params.debt.copyWith(
      paidAmount: newPaidAmount,
      remainingAmount: newRemainingAmount,
      isPaid: isPaid,
    );

    final payment = PaymentEntity(
      debtId: params.debt.id!,
      amountPaid: params.amountToPay,
      remainingAfterPayment: newRemainingAmount,
      paymentDate: DateTime.now(),
    );

    return repository.payDebt(updatedDebt, payment);
  }
}
