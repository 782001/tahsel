import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/vault_summary_entity.dart';
import '../entities/vault_transaction_entity.dart';

abstract class VaultRepository {
  Future<Either<Failure, VaultSummaryEntity>> getSummary(String uid);

  Stream<VaultSummaryEntity> watchSummary(String uid);

  Future<
      Either<
          Failure,
          ({
            List<VaultTransactionEntity> transactions,
            dynamic lastDoc,
            bool hasMore
          })>> getTransactionsPaginated({
    required String uid,
    VaultTransactionSource sourceFilter = VaultTransactionSource.all,
    int limit = 15,
    dynamic lastDoc,
  });

  Future<Either<Failure, void>> depositManual({
    required String uid,
    required double amount,
    String? note,
  });

  Future<Either<Failure, void>> withdrawManual({
    required String uid,
    required double amount,
    String? note,
  });

  Future<Either<Failure, void>> recordTransaction({
    required VaultTransactionEntity transaction,
  });

  Future<Either<Failure, void>> editManualTransaction({
    required String uid,
    required VaultTransactionEntity oldTransaction,
    required double newAmount,
    required String newDescription,
  });

  Future<Either<Failure, void>> deleteManualTransaction({
    required String uid,
    required VaultTransactionEntity transaction,
  });
}
