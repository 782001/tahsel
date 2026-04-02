import 'package:shared_preferences/shared_preferences.dart';

class CashHelper {
  final SharedPreferences sharedPreferences;

  CashHelper(this.sharedPreferences);

  dynamic getData({required String key}) {
    return sharedPreferences.get(key);
  }

  bool? getBoolData({required String key}) {
    return sharedPreferences.getBool(key);
  }

  Future<bool> removeData({required String key}) {
    return sharedPreferences.remove(key);
  }

  Future<bool> disposeData() {
    return sharedPreferences.clear();
  }

  Future<bool> saveData({required String key, required dynamic value}) async {
    if (value is String) {
      return await sharedPreferences.setString(key, value);
    }
    if (value is int) {
      return await sharedPreferences.setInt(key, value);
    }
    if (value is bool) {
      return await sharedPreferences.setBool(key, value);
    }
    if (value is double) {
      return await sharedPreferences.setDouble(key, value);
    }

    throw UnsupportedError('Type ${value.runtimeType} is not supported');
  }
}
