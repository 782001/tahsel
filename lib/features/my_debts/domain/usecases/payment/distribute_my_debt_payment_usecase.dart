import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

class DistributeMyDebtPaymentUseCase {
  final MyDebtRepository repository;

  DistributeMyDebtPaymentUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String uid,
    required String personName,
    required double amount,
    String? note,
    DateTime? paymentDate,
  }) async {
    return await repository.distributeMyDebtPayment(
      uid: uid,
      personName: personName,
      amount: amount,
      note: note,
      paymentDate: paymentDate,
    );
  }
}
