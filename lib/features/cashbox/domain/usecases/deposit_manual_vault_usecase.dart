import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/vault_repository.dart';

class DepositManualVaultUseCase {
  final VaultRepository repository;

  DepositManualVaultUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String uid,
    required double amount,
    String? note,
  }) {
    return repository.depositManual(
      uid: uid,
      amount: amount,
      note: note,
    );
  }
}
