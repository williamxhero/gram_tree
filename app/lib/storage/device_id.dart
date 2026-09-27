import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../util/ids.dart';
import 'local_store.dart';

const _key = 'device_id';

/// 安装时生成的设备 ID：随请求头发给服务端，用来按设备限流、区分登录设备，
/// 也写进同意记录。卸载重装会换一个。
final deviceIdProvider = Provider<String>((ref) {
  final store = ref.watch(localStoreProvider);
  final existing = store.getString(_key);
  if (existing != null) return existing;
  final id = newUuidV4();
  store.setString(_key, id);
  return id;
});
