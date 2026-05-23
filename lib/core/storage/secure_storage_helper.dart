import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vault_kit/vault_kit.dart';

class SecureStorageHelper {
  final VaultKit _vault;
  final SharedPreferences _prefs;

  SecureStorageHelper(this._vault, this._prefs);

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Save a value securely
  Future<void> saveData({required String key, required String value}) async {
    if (_isMobile) {
      await _vault.save(key: key, value: value);
    } else {
      await _prefs.setString('secure_$key', value);
    }
  }

  /// Read a value securely
  Future<String?> getData({required String key}) async {
    if (_isMobile) {
      try {
        return await _vault.fetch<String>(key: key);
      } catch (e) {
        return null;
      }
    } else {
      return _prefs.getString('secure_$key');
    }
  }

  /// Remove a value securely
  Future<void> deleteData({required String key}) async {
    if (_isMobile) {
      await _vault.delete(key: key);
    } else {
      await _prefs.remove('secure_$key');
    }
  }

  /// Clear all secure data
  Future<void> clearAll() async {
    if (_isMobile) {
      await _vault.clearAll();
    } else {
      final keys = _prefs
          .getKeys()
          .where((k) => k.startsWith('secure_'))
          .toList();
      for (var key in keys) {
        await _prefs.remove(key);
      }
    }
  }
}
