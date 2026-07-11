import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/core/error/failures.dart';

import '../../../offline_sync/data/models/offline_record.dart';
import '../../../offline_sync/domain/repositories/offline_sync_repository.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../datasources/invoice_remote_data_source.dart';
import '../models/invoice_model.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/usecases/pagination_params.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDataSource remoteDataSource;
  final OfflineSyncRepository offlineSyncRepository;
  final InternetConnectionChecker connectionChecker;

  InvoiceRepositoryImpl({
    required this.remoteDataSource,
    required this.offlineSyncRepository,
    required this.connectionChecker,
  });

  @override
  Future<Either<Failure, String>> createInvoice(InvoiceEntity invoice) async {
    try {
      final model = InvoiceModel.fromEntity(invoice);

      // ─── 1. GENERATE DETERMINISTIC ID (Idempotency) ───────────────────────
      // Rounded to nearest second to prevent race conditions from double-clicks.
      final timeKey = model.createdAt.millisecondsSinceEpoch ~/ 1000;
      final fingerprint =
          '${model.uid}_${model.totalAmount}_${model.customerName ?? "anon"}_$timeKey';
      final invoiceId = 'inv_${fingerprint.hashCode.abs()}';

      final modelWithId =
          InvoiceModel.fromEntity(invoice.copyWith(id: invoiceId));

      // ─── 2. PERSIST LOCALLY FIRST (offline-first guarantee) ───────────────
      final payloadJson = modelWithId.toJson();

      final offlineRecord = OfflineRecord(
        id: invoiceId,
        amount: modelWithId.totalAmount,
        date: modelWithId.createdAt,
        customerName: modelWithId.customerName ?? '',
        type: 'invoice',
        isSynced: false,
        payloadJson: payloadJson,
        collectionName: 'users/${modelWithId.uid}/invoices',
      );

      final saveResult =
          await offlineSyncRepository.saveOfflineRecord(offlineRecord);

      return saveResult.fold(
        (failure) => Left(failure),
        (_) async {
          // ─── 3. IF ONLINE → SYNC IMMEDIATELY ──────────────────────────────
          final hasConnection = await connectionChecker.hasConnection;
          if (hasConnection) {
            await offlineSyncRepository.syncSingleRecord(offlineRecord);
          }
          return Right(invoiceId);
        },
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getInvoices(String uid) async {
    try {
      final result = await remoteDataSource.getInvoices(uid);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<InvoiceEntity>>> getInvoicesPaginated(
    String uid, {
    required int limit,
    DocumentSnapshot? lastDocument,
    bool forceRefresh = false,
  }) async {
    try {
      final hasConnection = await connectionChecker.hasConnection;
      if (!hasConnection) {
        return const Left(OfflineFailure("No internet connection"));
      }

      final result = await remoteDataSource.getInvoicesPaginated(
        uid,
        limit: limit,
        lastDocument: lastDocument,
        forceRefresh: forceRefresh,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getPendingInvoices() async {
    final result = await offlineSyncRepository.getPendingRecords();
    return result.fold(
      (failure) => Left(failure),
      (records) {
        final invoiceRecords =
            records.where((r) => r.type == 'invoice').toList();

        final invoices = invoiceRecords.map((record) {
          try {
            final map = jsonDecode(record.payloadJson) as Map<String, dynamic>;
            return InvoiceModel.fromMap(map);
          } catch (_) {
            return null;
          }
        }).whereType<InvoiceEntity>().toList();

        return Right(invoices);
      },
    );
  }

  @override
  Future<Either<Failure, InvoiceEntity>> getInvoiceById(
      String uid, String invoiceId) async {
    try {
      final result = await remoteDataSource.getInvoiceById(uid, invoiceId);
      if (result == null) {
        return const Left(ServerFailure('Invoice not found'));
      }
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> recordPayment(
      String uid, String invoiceId, InvoicePayment payment) async {
    try {
      final paymentModel = InvoicePaymentModel.fromEntity(payment);
      await remoteDataSource.recordPayment(uid, invoiceId, paymentModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> linkDebtToInvoice(
      String uid, String invoiceId, String debtId) async {
    try {
      await remoteDataSource.linkDebtToInvoice(uid, invoiceId, debtId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateInvoice(InvoiceEntity invoice) async {
    try {
      final model = InvoiceModel.fromEntity(invoice);
      await remoteDataSource.updateInvoice(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> voidInvoice(
      String uid, String invoiceId) async {
    try {
      await remoteDataSource.voidInvoice(uid, invoiceId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

}
