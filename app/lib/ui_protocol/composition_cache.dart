import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart' show PageDescription;

import '../storage/local_store.dart';

/// 本机保存的一份"最近一次页面描述"：内容本身、它依赖的内容版本
/// （[PageDescription.cache.dependsOn]）、存下来的时间（用来算"上次更新时间"）
/// （SPEC-009.1 票 7，#83）。
///
/// **为什么存进 [LocalStore] 而不是 drift**：这里只是"每类页面存最近一次的描述"，
/// 简单的 key-value，`LocalStore` 的 getString/setString 足够；drift 是给事件队列
/// 那种要结构化查询、且只有移动端需要的场景用的
/// （`app/lib/events/event_queue_mobile.dart`），这里用不上，也不想只为网页版多开
/// 一套替身实现——`LocalStore` 本来就有 `PrefsLocalStore`（`shared_preferences`，
/// 网页版天然支持）和测试用的 `MemoryLocalStore`。
class CachedComposition {
  const CachedComposition({required this.description, required this.savedAt});

  final PageDescription description;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
    'description': description.toJson(),
    'saved_at': savedAt.toUtc().toIso8601String(),
  };

  static CachedComposition? tryParse(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final description = PageDescription.fromJson(
        json['description'] as Map<String, dynamic>,
      );
      final savedAt = DateTime.parse(json['saved_at'] as String);
      return CachedComposition(description: description, savedAt: savedAt);
    } catch (_) {
      // 本机存的内容读不出来（协议改了、数据损坏……）：当成"没有缓存"处理，不能让
      // 一条坏掉的本机记录卡住页面渲染。
      return null;
    }
  }
}

String _cacheKey(String pageType) => 'ui_composition_cache:$pageType';

/// 读写"页面描述本机缓存"的小工具，包一层 [LocalStore]。
class CompositionCacheStore {
  const CompositionCacheStore(this._store);

  final LocalStore _store;

  CachedComposition? read(String pageType) {
    final raw = _store.getString(_cacheKey(pageType));
    if (raw == null) return null;
    return CachedComposition.tryParse(raw);
  }

  Future<void> save(
    String pageType,
    PageDescription description,
    DateTime savedAt,
  ) => _store.setString(
    _cacheKey(pageType),
    jsonEncode(
      CachedComposition(description: description, savedAt: savedAt).toJson(),
    ),
  );
}

final compositionCacheStoreProvider = Provider<CompositionCacheStore>(
  (ref) => CompositionCacheStore(ref.watch(localStoreProvider)),
);

/// App 现在认为"当下"的依赖版本——离线/超时时，缓存能不能用，比较的就是这个和
/// 缓存自带的 [PageDescription.cache.dependsOn] 是否完全一致。
///
/// #83 阶段还没有真实业务依赖（菜谱版本、口味档案这些要后续子 SPEC 才接上真实数据，
/// 服务端那一半见 `gramtree.ui_protocol.service.dependency_versions()` 的说明），
/// 这里先返回空 Map——App 不"知道"任何依赖版本；离线时缓存的 `depends_on` 只要
/// 非空（现在恒非空，至少带着服务端的 `plan` 占位版本），就一定判定为"不一致"，
/// 安全地退回标准布局，不会显示可能已经过期的内容。等真实依赖接上后，在这里返回
/// 本机实际已知的最新版本即可，不用改这条机制本身。
///
/// 测试用 override 注入假的依赖版本（一个 `Map<String, String>`，键名字任意，
/// 例如 `{'scenario_test': 'v1'}`），验证"版本一致就用缓存、不一致就退标准布局"
/// 这条机制本身，不需要等真实依赖接上（见 `app/test/composition_cache_test.dart`）。
final localDependencyVersionsProvider = Provider<Map<String, String>>(
  (ref) => const <String, String>{},
);

/// 两份依赖版本是否完全一致——键值对逐一比较，键的个数也要相等（不是子集/超集
/// 就算一致），这是本机没存真实依赖时唯一站得住脚的"完全相等"判断。
bool dependsOnMatches(Map<String, String> cached, Map<String, String> current) {
  if (cached.length != current.length) return false;
  for (final entry in cached.entries) {
    if (current[entry.key] != entry.value) return false;
  }
  return true;
}
