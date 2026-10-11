import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 本机的普通键值存储（同意记录、设备 ID 等不敏感的数据）。读是同步的。
abstract class LocalStore {
  Set<String> get keys;
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

class PrefsLocalStore implements LocalStore {
  PrefsLocalStore(this._prefs);

  static Future<PrefsLocalStore> open() async =>
      PrefsLocalStore(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  @override
  Set<String> get keys => _prefs.getKeys();

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// 测试和网页替身用：存在内存里。
class MemoryLocalStore implements LocalStore {
  MemoryLocalStore([Map<String, String>? values]) : values = values ?? {};

  final Map<String, String> values;

  @override
  Set<String> get keys => values.keys.toSet();

  @override
  String? getString(String key) => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

/// 启动时在 main() 里打开后注入（见 bootstrap.dart）。
final localStoreProvider = Provider<LocalStore>(
  (ref) => throw UnimplementedError('localStoreProvider 需要在启动时注入'),
);
