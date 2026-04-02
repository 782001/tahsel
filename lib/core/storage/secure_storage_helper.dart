import 'package:vault_kit/vault_kit.dart';

class SecureStorageHelper {
  final VaultKit _storage;

  SecureStorageHelper(this._storage);

  /// Save a value securely
  Future<void> saveData({required String key, required String value}) async {
    await _storage.save(key: key, value: value);
  }

  /// Read a value securely
  Future<String?> getData({required String key}) async {
    return await _storage.fetch<String>(key: key);
  }

  /// Remove a value securely
  Future<void> deleteData({required String key}) async {
    await _storage.delete(key: key);
  }

  /// Clear all secure data
  Future<void> clearAll() async {
    await _storage.clearAll();
  }
}
