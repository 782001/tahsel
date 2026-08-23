import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/vault_transaction_entity.dart';
import '../repositories/vault_repository.dart';

class GetVaultTransactionsPaginatedParams {
  final String uid;
  final VaultTransactionSource sourceFilter;
  final int limit;
  final dynamic lastDoc;

  GetVaultTransactionsPaginatedParams({
    required this.uid,
    this.sourceFilter = VaultTransactionSource.all,
    this.limit = 15,
    this.lastDoc,
  });
}

class GetVaultTransactionsPaginatedUseCase {
  final VaultRepository repository;

  GetVaultTransactionsPaginatedUseCase(this.repository);

  Future<
      Either<
          Failure,
          ({
            List<VaultTransactionEntity> transactions,
            dynamic lastDoc,
            bool hasMore
          })>> call(GetVaultTransactionsPaginatedParams params) {
    return repository.getTransactionsPaginated(
      uid: params.uid,
      sourceFilter: params.sourceFilter,
      limit: params.limit,
      lastDoc: params.lastDoc,
    );
  }
}
