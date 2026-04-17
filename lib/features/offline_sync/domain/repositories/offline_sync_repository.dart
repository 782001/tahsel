import 'package:dartz/dartz.dart';
import '../../data/models/offline_record.dart';
import '../../../../core/error/failures.dart';

abstract class OfflineSyncRepository {
  Future<Either<Failure, void>> saveOfflineRecord(OfflineRecord record);
  Future<Either<Failure, List<OfflineRecord>>> getPendingRecords();
  Future<Either<Failure, void>> syncAllPendingRecords();
}
