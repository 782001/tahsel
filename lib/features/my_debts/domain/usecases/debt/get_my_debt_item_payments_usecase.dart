import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

class GetMyDebtItemPaymentsUseCase {
  final MyDebtRepository repository;

  GetMyDebtItemPaymentsUseCase(this.repository);

  Future<Either<Failure, List<PaymentEntity>>> call(String uid, String debtId) {
    return repository.getMyDebtItemPayments(uid, debtId);
  }
}
