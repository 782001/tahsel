import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../entities/debt_entity.dart';
import '../entities/payment_entity.dart';
import '../repositories/debt_repository.dart';

class MarkItemAsPaidUseCase implements BaseUseCase<void, DebtEntity> {
  final DebtRepository repository;

  MarkItemAsPaidUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(DebtEntity debt) {
    final amountPaid = debt.remainingAmount;
    final newPaidAmount = debt.totalAmount;
    const newRemainingAmount = 0.0;
    const isPaid = true;

    final updatedDebt = debt.copyWith(
      paidAmount: newPaidAmount,
      remainingAmount: newRemainingAmount,
      isPaid: isPaid,
    );

    final payment = PaymentEntity(
      debtId: debt.id!,
      amountPaid: amountPaid,
      remainingAfterPayment: newRemainingAmount,
      paymentDate: DateTime.now(),
    );

    return repository.payDebt(updatedDebt, payment);
  }
}
