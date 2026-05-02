import 'package:dartz/dartz.dart';
import 'package:tahsel/core/base_usecase/base_usecase.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

class DeleteMyDebtPaymentParams {
  final String uid;
  final String debtId;
  final String paymentId;

  DeleteMyDebtPaymentParams({
    required this.uid,
    required this.debtId,
    required this.paymentId,
  });
}

class DeleteMyDebtPaymentUseCase
    implements BaseUseCase<void, DeleteMyDebtPaymentParams> {
  final MyDebtRepository repository;

  DeleteMyDebtPaymentUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(DeleteMyDebtPaymentParams params) {
    return repository.deleteMyDebtPayment(
      uid: params.uid,
      debtId: params.debtId,
      paymentId: params.paymentId,
    );
  }
}
