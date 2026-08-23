import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/vault_transaction_entity.dart';
import '../repositories/vault_repository.dart';

class EditManualVaultUseCase {
  final VaultRepository repository;

  EditManualVaultUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String uid,
    required VaultTransactionEntity oldTransaction,
    required double newAmount,
    required String newDescription,
  }) {
    return repository.editManualTransaction(
      uid: uid,
      oldTransaction: oldTransaction,
      newAmount: newAmount,
      newDescription: newDescription,
    );
  }
}
