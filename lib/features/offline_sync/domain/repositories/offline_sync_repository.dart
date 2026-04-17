import 'package:dartz/dartz.dart';
import '../../data/models/offline_record.dart';

abstract class OfflineSyncRepository {
  Future<Either<dynamic, void>> saveOfflineRecord(OfflineRecord record);
  Future<Either<dynamic, List<OfflineRecord>>> getPendingRecords();
  Future<Either<dynamic, void>> syncAllPendingRecords();
}
