import 'package:hive/hive.dart';
import '../models/offline_record.dart';

abstract class OfflineLocalDataSource {
  Future<void> saveRecord(OfflineRecord record);
  Future<List<OfflineRecord>> getPendingRecords();
  Future<void> markAsSynced(String id);
  Future<void> deleteRecord(String id);
}

class OfflineLocalDataSourceImpl implements OfflineLocalDataSource {
  static const boxName = 'offline_records_box';

  Future<Box<OfflineRecord>> get _box async =>
      await Hive.openBox<OfflineRecord>(boxName);

  @override
  Future<void> saveRecord(OfflineRecord record) async {
    final box = await _box;
    await box.put(record.id, record);
  }

  @override
  Future<List<OfflineRecord>> getPendingRecords() async {
    final box = await _box;
    return box.values.where((record) => !record.isSynced).toList();
  }

  @override
  Future<void> markAsSynced(String id) async {
    final box = await _box;
    final record = box.get(id);
    if (record != null) {
      record.isSynced = true;
      await record.save();
    }
  }

  @override
  Future<void> deleteRecord(String id) async {
    final box = await _box;
    await box.delete(id);
  }
}
