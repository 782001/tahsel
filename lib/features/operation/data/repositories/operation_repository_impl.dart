import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../domain/entities/operation_entity.dart';
import '../../domain/repositories/operation_repository.dart';
import '../datasources/operation_remote_data_source.dart';
import '../models/operation_model.dart';
import '../../../offline_sync/domain/repositories/offline_sync_repository.dart';
import '../../../offline_sync/data/models/offline_record.dart';

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
  Future<Either<dynamic, String>> addOperation(OperationEntity operation) async {
    try {
      final model = OperationModel.fromEntity(operation);
      final hasConnection = await connectionChecker.hasConnection;

      if (hasConnection) {
        final id = await remoteDataSource.addOperation(model);
        return Right(id);
      } else {
        final localId = DateTime.now().millisecondsSinceEpoch.toString();
        final Map<String, dynamic> rawJson = model.toJson();
        rawJson['timestamp'] = null; // Replaced during sync
        
        final payloadJson = jsonEncode(rawJson);
        
        final offlineRecord = OfflineRecord(
          id: localId,
          amount: model.totalAmount,
          date: model.timestamp ?? DateTime.now(),
          customerName: model.customerName ?? '',
          type: model.type, // 'cafe' or 'playstation'
          isSynced: false,
          payloadJson: payloadJson,
          collectionName: 'users/${model.uid}/operations',
        );

        final result = await offlineSyncRepository.saveOfflineRecord(offlineRecord);
        return result.fold(
          (failure) => Left(failure.toString()),
          (_) => Right(localId),
        );
      }
    } catch (e) {
      return Left(e.toString());
    }
  }
}
