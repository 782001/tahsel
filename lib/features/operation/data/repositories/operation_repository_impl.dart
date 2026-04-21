import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../domain/entities/operation_entity.dart';
import '../../domain/repositories/operation_repository.dart';
import '../datasources/operation_remote_data_source.dart';
import '../models/operation_model.dart';
import '../../../offline_sync/domain/repositories/offline_sync_repository.dart';
import '../../../offline_sync/data/models/offline_record.dart';
import '../../../../core/error/failures.dart';

class OperationRepositoryImpl implements OperationRepository {
  final OperationRemoteDataSource remoteDataSource;
  final OfflineSyncRepository offlineSyncRepository;
  final InternetConnectionChecker connectionChecker;

  OperationRepositoryImpl({
    required this.remoteDataSource,
    required this.offlineSyncRepository,
    required this.connectionChecker,
  });

  @override
  Future<Either<Failure, String>> addOperation(
      OperationEntity operation) async {
    try {
      final model = OperationModel.fromEntity(operation);

      // 1. ALWAYS handle as an offline record first for consistency ('syncedAt' and type safety)
      final localId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // We don't use model.toJson() directly for the local payload because it contains 
      // FieldValue.serverTimestamp() which cannot be jsonEncoded for Hive.
      final transactionDate = model.timestamp ?? DateTime.now();
      
      final Map<String, dynamic> hivePayload = {
        'uid': model.uid,
        'type': model.type,
        'subType': model.subType,
        'customerName': model.customerName,
        'productName': model.productName,
        'totalAmount': model.totalAmount,
        'paidAmount': model.paidAmount,
        'remainingDebt': model.remainingDebt,
        'timestamp': transactionDate.toIso8601String(), // Safe for JSON
        'durationMinutes': model.durationMinutes,
        'turnCount': model.turnCount,
        'rate': model.rate,
      };

      final payloadJson = jsonEncode(hivePayload);

      final offlineRecord = OfflineRecord(
        id: localId,
        amount: model.totalAmount,
        date: transactionDate,
        customerName: model.customerName ?? '',
        type: model.type, // 'cafe' or 'playstation'
        isSynced: false,
        payloadJson: payloadJson,
        collectionName: 'users/${model.uid}/operations',
      );

      // Save to local cache first
      final saveResult =
          await offlineSyncRepository.saveOfflineRecord(offlineRecord);

      return saveResult.fold(
        (failure) => Left(failure),
        (_) async {
          // 2. Immediate prioritized sync if online
          final hasConnection = await connectionChecker.hasConnection;
          if (hasConnection) {
            // This sync logic (in OfflineRemoteDataSourceImpl) will convert 
            // the 'timestamp' String back into a proper Firestore Timestamp.
            await offlineSyncRepository.syncSingleRecord(offlineRecord);
          }
          return Right(localId);
        },
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
