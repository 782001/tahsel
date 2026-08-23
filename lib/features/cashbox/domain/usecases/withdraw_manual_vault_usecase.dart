import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/vault_repository.dart';

class WithdrawManualVaultUseCase {
  final VaultRepository repository;

  WithdrawManualVaultUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String uid,
    required double amount,
    String? note,
  }) {
    return repository.withdrawManual(
      uid: uid,
      amount: amount,
      note: note,
    );
  }
}
