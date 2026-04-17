import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../data/models/offline_record.dart';
import '../repositories/offline_sync_repository.dart';

class AddOfflineRecordUseCase implements BaseUseCase<void, OfflineRecord> {
  final OfflineSyncRepository repository;

  AddOfflineRecordUseCase(this.repository);

  @override
  Future<Either<dynamic, void>> call(OfflineRecord params) async {
    return repository.saveOfflineRecord(params);
  }
}

class SyncPendingOperationsUseCase implements BaseUseCase<void, void> {
  final OfflineSyncRepository repository;

  SyncPendingOperationsUseCase(this.repository);

  @override
  Future<Either<dynamic, void>> call(void params) async {
    return repository.syncAllPendingRecords();
  }
}

class GetPendingItemsUseCase implements BaseUseCase<List<OfflineRecord>, void> {
  final OfflineSyncRepository repository;

  GetPendingItemsUseCase(this.repository);

  @override
  Future<Either<dynamic, List<OfflineRecord>>> call(void params) async {
    return repository.getPendingRecords();
  }
}
