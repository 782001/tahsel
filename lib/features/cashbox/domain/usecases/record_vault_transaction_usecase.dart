import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/vault_transaction_entity.dart';
import '../repositories/vault_repository.dart';

class RecordVaultTransactionUseCase {
  final VaultRepository repository;

  RecordVaultTransactionUseCase(this.repository);

  Future<Either<Failure, void>> call(VaultTransactionEntity transaction) {
    return repository.recordTransaction(transaction: transaction);
  }
}
