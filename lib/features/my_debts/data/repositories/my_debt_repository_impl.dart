import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/core/usecases/pagination_params.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_person_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_operation_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_summary_entity.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';
import 'package:tahsel/features/my_debts/data/datasources/my_debt_person_remote_data_source.dart';
import 'package:tahsel/features/my_debts/data/datasources/my_debt_item_remote_data_source.dart';
import 'package:tahsel/features/my_debts/data/models/my_debt_person_model.dart';
import 'package:tahsel/features/my_debts/data/models/my_debt_item_model.dart';
import 'package:tahsel/features/offline_sync/data/models/offline_record.dart';
import 'package:tahsel/features/offline_sync/domain/repositories/offline_sync_repository.dart';

class MyDebtRepositoryImpl implements MyDebtRepository {
  final MyDebtPersonRemoteDataSource personRemoteDataSource;
  final MyDebtItemRemoteDataSource itemRemoteDataSource;
  final OfflineSyncRepository offlineSyncRepository;
  final InternetConnectionChecker connectionChecker;

  MyDebtRepositoryImpl({
    required this.personRemoteDataSource,
    required this.itemRemoteDataSource,
    required this.offlineSyncRepository,
    required this.connectionChecker,
  });

  @override
  Future<Either<Failure, MyDebtSummaryEntity>> getMyDebtSummary(
    String uid,
  ) async {
    try {
      final hasConnection = await connectionChecker.hasConnection;
      if (!hasConnection) {
        return const Left(OfflineFailure("No internet connection"));
      }
      final summary = await personRemoteDataSource.getMyDebtSummary(uid);
      return Right(summary);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MyDebtPersonEntity>>> getMyDebtPersons(
    String uid, {
    bool forceRefresh = false,
  }) async {
    try {
      final hasConnection = await connectionChecker.hasConnection;
      if (!hasConnection) {
        return const Left(OfflineFailure("No internet connection"));
      }

      // TRIGGER SYNC when online before fetching
      await offlineSyncRepository.syncAllPendingRecords();

      final persons = await personRemoteDataSource.getPersons(
        uid,
        forceRefresh: forceRefresh,
      );
      return Right(persons);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<MyDebtPersonEntity>>>
  getMyDebtPersonsPaginated(
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

      // TRIGGER SYNC when online before fetching
      await offlineSyncRepository.syncAllPendingRecords();

      final paginatedResult = await personRemoteDataSource.getPersonsPaginated(
        uid,
        limit: limit,
        lastDocument: lastDocument,
        forceRefresh: forceRefresh,
      );

      return Right(
        PaginatedResult(
          items: paginatedResult.items,
          lastDocument: paginatedResult.lastDocument,
          hasMore: paginatedResult.hasMore,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveMyDebtPerson(
    String uid,
    MyDebtPersonEntity person,
  ) async {
    try {
      await personRemoteDataSource.savePerson(
        uid,
        MyDebtPersonModel.fromEntity(person),
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMyDebtPersonPhone(
    String uid,
    String name,
    String phoneNumber,
  ) async {
    try {
      await personRemoteDataSource.updatePersonPhone(uid, name, phoneNumber);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMyDebtPersonPreference(
    String uid,
    String name,
    String preference,
  ) async {
    try {
      await personRemoteDataSource.updatePersonPreference(
        uid,
        name,
        preference,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> addMyDebtItem(MyDebtItemEntity debt) async {
    try {
      final model = MyDebtItemModel.fromEntity(debt);
      final hasConnection = await connectionChecker.hasConnection;

      if (hasConnection) {
        // ONLINE: Add directly to Firebase
        final id = await itemRemoteDataSource.addDebtItem(model);
        return Right(id);
      } else {
        // OFFLINE: Save to Hive for later sync
        final localId = DateTime.now().millisecondsSinceEpoch.toString();

        // Construct payload for Hive/Firestore
        final Map<String, dynamic> hivePayload = model.toJson();

        // CRITICAL: Sanitize payload for jsonEncode (REMOVE all Timestamp/FieldValue objects)
        // Hive storage requires plain JSON types
        hivePayload['timestamp'] =
            model.timestamp?.toIso8601String() ??
            DateTime.now().toIso8601String();
        hivePayload['lastUpdatedAt'] =
            model.lastUpdatedAt?.toIso8601String() ??
            DateTime.now().toIso8601String();

        final payloadJson = jsonEncode(hivePayload);

        final offlineRecord = OfflineRecord(
          id: localId,
          amount: model.remainingAmount,
          date: model.timestamp ?? DateTime.now(),
          customerName: model.personName ?? 'Unknown',
          type: 'my_debt_add',
          isSynced: false,
          payloadJson: payloadJson,
          collectionName: 'users/${model.uid}',
        );

        final saveResult = await offlineSyncRepository.saveOfflineRecord(
          offlineRecord,
        );
        return saveResult.fold(
          (failure) => Left(failure),
          (_) => Right(localId),
        );
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MyDebtItemEntity>>> getMyDebtItems(
    String uid,
    String personName, {
    bool forceRefresh = false,
  }) async {
    try {
      final hasConnection = await connectionChecker.hasConnection;
      if (!hasConnection) {
        return const Left(OfflineFailure("No internet connection"));
      }

      // TRIGGER SYNC when online
      await offlineSyncRepository.syncAllPendingRecords();

      final items = await itemRemoteDataSource.getDebtItems(
        uid,
        personName,
        forceRefresh: forceRefresh,
      );
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMyDebtItem(
    String uid,
    String debtId,
  ) async {
    try {
      await itemRemoteDataSource.deleteDebtItem(uid, debtId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markMyDebtItemAsPaid(
    String uid,
    String debtId,
  ) async {
    try {
      final items = await itemRemoteDataSource.getDebtsStream(uid).first;
      final item = items.firstWhere((e) => e.id == debtId);
      await itemRemoteDataSource.payItem(
        uid: uid,
        debtId: debtId,
        amount: item.remainingAmount,
        note: 'Full settlement',
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> payMyDebtItem({
    required String uid,
    required String debtId,
    required double amount,
    String? note,
    DateTime? paymentDate,
  }) async {
    try {
      await itemRemoteDataSource.payItem(
        uid: uid,
        debtId: debtId,
        amount: amount,
        note: note,
        paymentDate: paymentDate,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> settleSupplierCredit({
    required String uid,
    required String debtId,
    required double creditAmount,
    String? note,
  }) async {
    try {
      await itemRemoteDataSource.settleSupplierCredit(
        uid: uid,
        debtId: debtId,
        creditAmount: creditAmount,
        note: note,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> distributeMyDebtPayment({
    required String uid,
    required String personName,
    required double amount,
    String? note,
    DateTime? paymentDate,
  }) async {
    try {
      await itemRemoteDataSource.distributePayment(
        uid,
        personName,
        amount,
        note: note,
        paymentDate: paymentDate,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMyDebtPayment({
    required String uid,
    required String debtId,
    required String paymentId,
    required double newAmount,
    String? note,
  }) async {
    try {
      await itemRemoteDataSource.updateMyDebtPayment(
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
  Future<Either<Failure, void>> deleteMyDebtPayment({
    required String uid,
    required String debtId,
    required String paymentId,
  }) async {
    try {
      await itemRemoteDataSource.deleteMyDebtPayment(
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
  Future<Either<Failure, List<MyDebtOperationEntity>>>
  getMyDebtPersonOperations(
    String uid,
    String personName, {
    bool forceRefresh = false,
  }) async {
    try {
      final hasConnection = await connectionChecker.hasConnection;
      if (!hasConnection) {
        return const Left(OfflineFailure("No internet connection"));
      }
      final ops = await personRemoteDataSource.getPersonOperations(
        uid,
        personName,
        forceRefresh: forceRefresh,
      );
      return Right(ops);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PaymentEntity>>> getMyDebtItemPayments(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  }) async {
    try {
      final payments = await itemRemoteDataSource.getDebtItemPayments(
        uid,
        debtId,
        forceRefresh: forceRefresh,
      );
      // Map MyDebtPaymentModel to PaymentEntity since Customer Debts UI expects PaymentEntity
      final entities = payments
          .map(
            (p) => PaymentEntity(
              id: p.id,
              debtId: p.debtId,
              amountPaid: p.amountPaid,
              remainingAmount: 0.0,
              createdAt: p.createdAt,
              type: _mapType(p.type),
              activityName: p.note,
              relatedTo: p.relatedTo,
            ),
          )
          .toList();
      return Right(entities);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<PaymentEntity>>>
  getMyDebtItemPaymentsPaginated(
    String uid,
    String debtId, {
    required int limit,
    DocumentSnapshot? lastDocument,
    bool forceRefresh = false,
  }) async {
    try {
      final paginatedResult = await itemRemoteDataSource
          .getDebtItemPaymentsPaginated(
            uid,
            debtId,
            limit: limit,
            lastDocument: lastDocument,
            forceRefresh: forceRefresh,
          );

      final entities = paginatedResult.items
          .map(
            (p) => PaymentEntity(
              id: p.id,
              debtId: p.debtId,
              amountPaid: p.amountPaid,
              remainingAmount: 0.0,
              createdAt: p.createdAt,
              type: _mapType(p.type),
              activityName: p.note,
              relatedTo: p.relatedTo,
            ),
          )
          .toList();

      return Right(
        PaginatedResult(
          items: entities,
          lastDocument: paginatedResult.lastDocument,
          hasMore: paginatedResult.hasMore,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OfflineRecord>>> getPendingMyDebts() async {
    final result = await offlineSyncRepository.getPendingRecords();
    return result.fold((failure) => Left(failure), (records) {
      // Filter my_debt type records (including 'my_debt_add')
      final myDebtRecords = records
          .where((r) => r.type.startsWith('my_debt'))
          .toList();
      return Right(myDebtRecords);
    });
  }

  PaymentType _mapType(String type) {
    switch (type) {
      case 'full':
        return PaymentType.full;
      case 'partial':
        return PaymentType.partial;
      case 'settlement':
        return PaymentType.settlement;
      case 'debtAdded':
        return PaymentType.debtAdded;
      case 'adjustment':
        return PaymentType.adjustment;
      case 'reversal':
        return PaymentType.reversal;
      default:
        return PaymentType.partial;
    }
  }

  @override
  Future<Either<Failure, MyDebtItemEntity?>> getMyDebtItemById(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  }) async {
    try {
      final result = await itemRemoteDataSource.getMyDebtItemById(
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
