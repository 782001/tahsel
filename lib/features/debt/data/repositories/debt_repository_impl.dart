import 'dart:convert';
import 'package:dartz/dartz.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/debt_repository.dart';
import '../datasources/debt_remote_data_source.dart';
import '../models/debt_model.dart';
import '../models/payment_model.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../../offline_sync/data/models/offline_record.dart';
import '../../../offline_sync/domain/repositories/offline_sync_repository.dart';
import '../../../../core/error/failures.dart';

class DebtRepositoryImpl implements DebtRepository {
  final DebtRemoteDataSource remoteDataSource;
  final InternetConnectionChecker connectionChecker;
  final OfflineSyncRepository offlineSyncRepository;

  DebtRepositoryImpl({
    required this.remoteDataSource,
    required this.connectionChecker,
    required this.offlineSyncRepository,
  });

  @override
  Future<Either<Failure, String>> addDebt(DebtEntity debt) async {
    try {
      final model = DebtModel.fromEntity(debt);
      final hasConnection = await connectionChecker.hasConnection;

      if (hasConnection) {
        final id = await remoteDataSource.addDebt(model);
        return Right(id);
      } else {
        // OFFLINE: Save to Hive for later sync
        final Map<String, dynamic> hivePayload = model.toJson();

        // Sanitize for JSON encoding (REMOVE Timestamps/FieldValues)
        hivePayload['timestamp'] =
            model.timestamp?.toIso8601String() ??
            DateTime.now().toIso8601String();
        hivePayload['lastUpdatedAt'] = DateTime.now().toIso8601String();

        final payloadJson = jsonEncode(hivePayload);

        final offlineRecord = OfflineRecord(
          id: debt.operationId, // Use the shared operationId
          amount: model.totalAmount,
          date: model.timestamp ?? DateTime.now(),
          customerName: model.customerName ?? '',
          type: 'debt_add',
          isSynced: false,
          payloadJson: payloadJson,
          collectionName: 'users/${model.uid}/debts',
        );

        final saveResult = await offlineSyncRepository.saveOfflineRecord(
          offlineRecord,
        );
        return saveResult.fold(
          (failure) => Left(failure),
          (_) => Right(debt.operationId),
        );
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DebtEntity>>> getDebts(
    String uid, {
    bool forceRefresh = false,
  }) async {
    try {
      final result = await remoteDataSource.getDebts(
        uid,
        forceRefresh: forceRefresh,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> payDebt(
    DebtEntity debt,
    PaymentEntity payment,
  ) async {
    try {
      final debtModel = DebtModel.fromEntity(debt);
      final paymentModel = PaymentModel.fromEntity(payment);
      await remoteDataSource.payDebt(debtModel, paymentModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> payTotalDebt(
    String uid,
    String customerName,
    double amount,
  ) async {
    try {
      await remoteDataSource.payTotalDebt(uid, customerName, amount);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markCustomerAsPaid(
    String uid,
    String customerName,
  ) async {
    try {
      await remoteDataSource.markCustomerAsPaid(uid, customerName);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomerDebts(
    String uid,
    String customerName,
  ) async {
    try {
      await remoteDataSource.deleteCustomerDebts(uid, customerName);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDebtItem(
    String uid,
    String debtId,
  ) async {
    try {
      await remoteDataSource.deleteDebtItem(uid, debtId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<PaymentEntity>> getDebtTransactions(String debtId) {
    return remoteDataSource.getDebtTransactions(debtId);
  }

  @override
  Future<Either<Failure, List<PaymentEntity>>> getDebtTransactionsFuture(
    String debtId, {
    bool forceRefresh = false,
  }) async {
    try {
      final result = await remoteDataSource.getDebtTransactionsFuture(
        debtId,
        forceRefresh: forceRefresh,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PaymentEntity>>> getCustomerAllPayments(
    String uid,
    String customerName,
  ) async {
    try {
      final result = await remoteDataSource.getCustomerAllPayments(
        uid,
        customerName,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<DebtEntity>> getDebtsStream(String uid) {
    return remoteDataSource.getDebtsStream(uid);
  }

  @override
  Future<Either<Failure, void>> updatePayment({
    required String uid,
    required String debtId,
    required String paymentId,
    required double newAmount,
    String? note,
  }) async {
    try {
      await remoteDataSource.updatePayment(
        uid: uid,
        debtId: debtId,
        paymentId: paymentId,
        newAmount: newAmount,
        note: note,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePayment({
    required String uid,
    required String debtId,
    required String paymentId,
  }) async {
    try {
      await remoteDataSource.deletePayment(
        uid: uid,
        debtId: debtId,
        paymentId: paymentId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DebtEntity?>> getDebtById(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  }) async {
    try {
      final result = await remoteDataSource.getDebtById(
        uid,
        debtId,
        forceRefresh: forceRefresh,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
