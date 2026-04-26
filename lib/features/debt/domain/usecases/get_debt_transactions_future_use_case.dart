import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/payment_entity.dart';
import '../repositories/debt_repository.dart';

class GetDebtTransactionsFutureUseCase {
  final DebtRepository repository;

  GetDebtTransactionsFutureUseCase(this.repository);

  Future<Either<Failure, List<PaymentEntity>>> call(String debtId) {
    return repository.getDebtTransactionsFuture(debtId);
  }
}
