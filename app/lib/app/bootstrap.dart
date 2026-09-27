import 'package:flutter_riverpod/misc.dart' show Override;

import '../storage/local_store.dart';

/// 启动前要准备好的东西（只读本机，不联网）。测试里用内存版本代替。
Future<List<Override>> bootstrapOverrides() async {
  final local = await PrefsLocalStore.open();
  return [localStoreProvider.overrideWithValue(local)];
}
