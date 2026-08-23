import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/vault_summary_entity.dart';
import '../../domain/entities/vault_transaction_entity.dart';
import '../../domain/repositories/vault_repository.dart';
import '../datasources/vault_remote_data_source.dart';
import '../models/vault_transaction_model.dart';

class VaultRepositoryImpl implements VaultRepository {
  final VaultRemoteDataSource remoteDataSource;

  VaultRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, VaultSummaryEntity>> getSummary(String uid) async {
    try {
      final summary = await remoteDataSource.getSummary(uid);
      return Right(summary);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<VaultSummaryEntity> watchSummary(String uid) {
    return remoteDataSource.watchSummary(uid);
  }

  @override
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
  }) async {
    try {
      final result = await remoteDataSource.getTransactionsPaginated(
        uid: uid,
        sourceFilter: sourceFilter,
        limit: limit,
        lastDoc: lastDoc,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> depositManual({
    required String uid,
    required double amount,
    String? note,
  }) async {
    try {
      await remoteDataSource.depositManual(uid: uid, amount: amount, note: note);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> withdrawManual({
    required String uid,
    required double amount,
    String? note,
  }) async {
    try {
      await remoteDataSource.withdrawManual(uid: uid, amount: amount, note: note);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> recordTransaction({
    required VaultTransactionEntity transaction,
  }) async {
    try {
      final model = VaultTransactionModel.fromEntity(transaction);
      await remoteDataSource.recordTransaction(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> editManualTransaction({
    required String uid,
    required VaultTransactionEntity oldTransaction,
    required double newAmount,
    required String newDescription,
  }) async {
    try {
      final model = VaultTransactionModel.fromEntity(oldTransaction);
      await remoteDataSource.editManualTransaction(
        uid: uid,
        oldTransaction: model,
        newAmount: newAmount,
        newDescription: newDescription,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteManualTransaction({
    required String uid,
    required VaultTransactionEntity transaction,
  }) async {
    try {
      final model = VaultTransactionModel.fromEntity(transaction);
      await remoteDataSource.deleteManualTransaction(
        uid: uid,
        transaction: model,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
