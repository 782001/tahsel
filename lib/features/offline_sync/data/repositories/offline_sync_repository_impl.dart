import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import '../../domain/repositories/offline_sync_repository.dart';
import '../datasources/offline_local_data_source.dart';
import '../datasources/offline_remote_data_source.dart';
import '../models/offline_record.dart';
import '../../../../core/error/failures.dart';

class OfflineSyncRepositoryImpl implements OfflineSyncRepository {
  final OfflineLocalDataSource localDataSource;
  final OfflineRemoteDataSource remoteDataSource;
  final InternetConnectionChecker connectionChecker;

  OfflineSyncRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectionChecker,
  });

  @override
  Future<Either<Failure, void>> saveOfflineRecord(OfflineRecord record) async {
    try {
      await localDataSource.saveRecord(record);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OfflineRecord>>> getPendingRecords() async {
    try {
      final records = await localDataSource.getPendingRecords();
      return Right(records);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncAllPendingRecords() async {
    try {
      final pendingRecords = await localDataSource.getPendingRecords();
      final totalRecords = pendingRecords.length;

      if (totalRecords == 0) {
        return const Right(null);
      }

      AppLogger.printMessage(
        "[OfflineSync] Found $totalRecords pending records. Starting upload...",
      );

      int successCount = 0;
      int failureCount = 0;

      for (final record in pendingRecords) {
        try {
          AppLogger.printMessage(
            "[OfflineSync] Syncing record: ${record.id} (Type: ${record.type}, Collection: ${record.collectionName})",
          );
          await remoteDataSource.syncRecord(record);
          await localDataSource.deleteRecord(record.id);
          successCount++;
          AppLogger.printMessage(
            "[OfflineSync] Record ${record.id} synced successfully.",
          );
        } catch (e) {
          failureCount++;
          AppLogger.printMessage(
            "[OfflineSync] Failed to sync record: ${record.id} - Error: $e",
          );
        }
      }

      AppLogger.printMessage(
        "[OfflineSync] Sync finished. Success: $successCount, Failures: $failureCount",
      );

      if (failureCount > 0) {
        return Left(ServerFailure("Sync completed with $failureCount failures."));
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncSingleRecord(OfflineRecord record) async {
    try {
      // 1. Sync to remote
      await remoteDataSource.syncRecord(record);
      
      // 2. Mark as synced by deleting from local cache
      await localDataSource.deleteRecord(record.id);
      
      return const Right(null);
    } catch (e) {
      AppLogger.printMessage("[OfflineSync] Error in syncSingleRecord: $e");
      return Left(ServerFailure(e.toString()));
    }
  }
}
