import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../entities/debt_entity.dart';
import '../entities/payment_entity.dart';
import '../repositories/debt_repository.dart';

class PayItemDebtParams {
  final DebtEntity debt;
  final double amountToPay;
  final DateTime? paymentDate;

  PayItemDebtParams({
    required this.debt,
    required this.amountToPay,
    this.paymentDate,
  });
}

class PayItemDebtUseCase implements BaseUseCase<void, PayItemDebtParams> {
  final DebtRepository repository;

  PayItemDebtUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(PayItemDebtParams params) {
    if (params.amountToPay <= 0) {
      return Future.value(
        const Left(GeneralFailure('Payment amount must be greater than zero')),
      );
    }

    if (params.amountToPay > params.debt.remainingAmount) {
      return Future.value(
        const Left(GeneralFailure('Payment amount exceeds remaining debt')),
      );
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
      remainingAmount: newRemainingAmount,
      createdAt: params.paymentDate ?? DateTime.now(),
      type: isPaid ? PaymentType.full : PaymentType.partial,
    );

    return repository.payDebt(updatedDebt, payment);
  }
}
