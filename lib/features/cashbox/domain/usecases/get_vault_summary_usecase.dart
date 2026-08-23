import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/vault_summary_entity.dart';
import '../repositories/vault_repository.dart';

class GetVaultSummaryUseCase {
  final VaultRepository repository;

  GetVaultSummaryUseCase(this.repository);

  Future<Either<Failure, VaultSummaryEntity>> call(String uid) {
    return repository.getSummary(uid);
  }

  Stream<VaultSummaryEntity> watch(String uid) {
    return repository.watchSummary(uid);
  }
}
