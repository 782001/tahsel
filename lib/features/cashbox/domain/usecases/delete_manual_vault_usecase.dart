import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/vault_transaction_entity.dart';
import '../repositories/vault_repository.dart';

class DeleteManualVaultUseCase {
  final VaultRepository repository;

  DeleteManualVaultUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String uid,
    required VaultTransactionEntity transaction,
  }) {
    return repository.deleteManualTransaction(
      uid: uid,
      transaction: transaction,
    );
  }
}
