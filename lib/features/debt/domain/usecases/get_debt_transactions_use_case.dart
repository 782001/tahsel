import '../entities/payment_entity.dart';
import '../repositories/debt_repository.dart';

class GetDebtTransactionsUseCase {
  final DebtRepository repository;

  GetDebtTransactionsUseCase(this.repository);

  Stream<List<PaymentEntity>> call(String debtId) {
    return repository.getDebtTransactions(debtId);
  }
}
