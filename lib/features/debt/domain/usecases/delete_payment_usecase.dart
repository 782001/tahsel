import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/debt_repository.dart';

class DeletePaymentParams {
  final String uid;
  final String debtId;
  final String paymentId;

  DeletePaymentParams({
    required this.uid,
    required this.debtId,
    required this.paymentId,
  });
}

class DeletePaymentUseCase implements BaseUseCase<void, DeletePaymentParams> {
  final DebtRepository repository;

  DeletePaymentUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(DeletePaymentParams params) {
    return repository.deletePayment(
      uid: params.uid,
      debtId: params.debtId,
      paymentId: params.paymentId,
    );
  }
}
