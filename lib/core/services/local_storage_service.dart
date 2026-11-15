import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorageService {
  Future<void> setString(String key, String value);

  Future<void> setBool(String key, bool value);

  String? getString(String key);

  bool? getBool(String key);

  Future<void> remove(String key);
}

class LocalStorageServiceImpl implements LocalStorageService {
  final SharedPreferences preferences;

  const LocalStorageServiceImpl(this.preferences);

  @override
  Future<void> setString(String key, String value) =>
      preferences.setString(key, value);

  @override
  Future<void> setBool(String key, bool value) =>
      preferences.setBool(key, value);

  @override
  String? getString(String key) => preferences.getString(key);

  @override
  bool? getBool(String key) => preferences.getBool(key);

  @override
  Future<void> remove(String key) => preferences.remove(key);
}
