import 'dart:convert';

import 'package:gramtree_api/gramtree_api.dart';

import '../storage/local_store.dart';

/// A frozen execution/view payload, not an editable recipe or a new API model.
/// Nullable dependencies mean unavailable/not applicable at capture time; they
/// must never be populated later from a newer catalogue, profile or rule set.
class FrozenRecipeSnapshot {
  FrozenRecipeSnapshot({
    required RecipeDetail detail,
    required DateTime capturedAt,
    required Map<String, dynamic> inputs,
    required Map<String, dynamic>? render,
    required Map<String, String?> dependencies,
  }) : _encoded = jsonEncode({
         'format_version': 1,
         'recipe_id': detail.id,
         'version_id': detail.version.id,
         'captured_at': capturedAt.toUtc().toIso8601String(),
         'detail': detail.toJson(),
         'inputs': inputs,
         'render': render,
         'dependencies': dependencies,
         // Reserved read-only integration boundaries for SPEC-005.1/005.2.
         'taste_profile': null,
         'taste_result': null,
         // Page descriptions remain owned by CompositionCache and its rules.
         'page_description': null,
       });

  FrozenRecipeSnapshot._(this._encoded);
  final String _encoded;
  Map<String, dynamic> toJson() => jsonDecode(_encoded) as Map<String, dynamic>;
  RecipeDetail get detail => RecipeDetail.fromJson(toJson()['detail']);
  String get recipeId => toJson()['recipe_id'] as String;
  String get versionId => toJson()['version_id'] as String;
  DateTime get capturedAt => DateTime.parse(toJson()['captured_at'] as String);
  Map<String, dynamic> get inputs =>
      Map<String, dynamic>.from(toJson()['inputs']);
  Map<String, dynamic>? get render => toJson()['render'] == null
      ? null
      : Map<String, dynamic>.from(toJson()['render']);
  Map<String, String?> get dependencies =>
      Map<String, String?>.from(toJson()['dependencies']);

  static FrozenRecipeSnapshot? fromJson(Object? value) {
    try {
      if (value is! Map || value['format_version'] != 1) return null;
      final frozen = FrozenRecipeSnapshot._(jsonEncode(value));
      if (frozen.recipeId != frozen.detail.id ||
          frozen.versionId != frozen.detail.version.id) {
        return null;
      }
      frozen.capturedAt;
      frozen.inputs;
      frozen.dependencies;
      return frozen;
    } catch (_) {
      return null;
    }
  }
}

/// Account-scoped persistent storage behind the existing platform LocalStore.
/// It deliberately owns no draft/queue keys: LRU cannot delete pending edits.
class RecipeSnapshotStore {
  RecipeSnapshotStore(
    this._store, {
    required this.accountId,
    this.maxBytes = 20 * 1024 * 1024,
  }) {
    if (maxBytes < 0) throw ArgumentError.value(maxBytes, 'maxBytes');
  }
  final LocalStore _store;
  final String accountId;
  final int maxBytes;
  String get _key => 'recipe_snapshots:v1:$accountId';
  Future<void> _tail = Future<void>.value();
  bool _cleared = false;

  Map<String, dynamic> _load() {
    if (!_cleared) {
      try {
        final raw = _store.getString(_key);
        if (raw != null) {
          final value = jsonDecode(raw);
          if (value is Map &&
              value['account_id'] == accountId &&
              value['format_version'] == 1 &&
              value['entries'] is Map &&
              value['protections'] is Map &&
              value['last_opened'] is Map) {
            return Map<String, dynamic>.from(value);
          }
        }
      } catch (_) {
        /* Unknown or corrupt caches are unavailable, never repaired with latest data. */
      }
    }
    return {
      'format_version': 1,
      'account_id': accountId,
      'clock': 0,
      'entries': <String, dynamic>{},
      'protections': <String, dynamic>{},
      'last_opened': <String, dynamic>{},
    };
  }

  String _id(String recipe, String version) => jsonEncode([recipe, version]);
  int _bytes(Map data) =>
      (data['entries'] as Map).isEmpty && (data['protections'] as Map).isEmpty
      ? 0
      : utf8.encode(jsonEncode(data)).length;
  int _tick(Map data) => data['clock'] = (data['clock'] as int? ?? 0) + 1;

  void _insert(Map data, FrozenRecipeSnapshot snapshot) {
    (data['entries'] as Map)[_id(snapshot.recipeId, snapshot.versionId)] = {
      'snapshot': snapshot.toJson(),
      'used': _tick(data),
    };
    (data['last_opened'] as Map)[snapshot.recipeId] = _id(
      snapshot.recipeId,
      snapshot.versionId,
    );
  }

  void _trim(Map data, {String? keep}) {
    final entries = data['entries'] as Map;
    final protected = <String>{
      for (final raw in (data['protections'] as Map).values)
        if (FrozenRecipeSnapshot.fromJson(raw) case final snapshot?)
          _id(snapshot.recipeId, snapshot.versionId),
    };
    final candidates =
        entries.keys
            .where((key) => key != keep && !protected.contains(key))
            .toList()
          ..sort(
            (a, b) => ((entries[a] as Map)['used'] as int).compareTo(
              (entries[b] as Map)['used'] as int,
            ),
          );
    for (final key in candidates) {
      if (_bytes(data) <= maxBytes) break;
      entries.remove(key);
      (data['last_opened'] as Map).removeWhere((_, value) => value == key);
    }
  }

  SnapshotCapacity _capacity(Map data, {bool accepted = true}) =>
      SnapshotCapacity(
        accepted: accepted,
        bytes: _bytes(data),
        maxBytes: maxBytes,
      );
  Future<SnapshotCapacity> capacity() =>
      _enqueue(() async => _capacity(_load()));

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<SnapshotCapacity> save(FrozenRecipeSnapshot snapshot) => _enqueue(
    () async {
      if (_cleared) {
        return SnapshotCapacity(accepted: false, bytes: 0, maxBytes: maxBytes);
      }
      final data = _load();
      final original = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
      final id = _id(snapshot.recipeId, snapshot.versionId);
      _insert(data, snapshot);
      _trim(data, keep: id);
      if (_bytes(data) > maxBytes) {
        // Reject the new page cache without deleting any existing user content.
        // Explicit protection/prefetch can retain oversized execution payloads.
        return _capacity(original, accepted: false);
      }
      await _store.setString(_key, jsonEncode(data));
      return _capacity(data);
    },
  );

  Future<FrozenRecipeSnapshot?> read(String recipeId, {String? versionId}) =>
      _enqueue(() async {
        final data = _load();
        final entries = data['entries'] as Map;
        final id = versionId == null
            ? (data['last_opened'] as Map)[recipeId]
            : _id(recipeId, versionId);
        final entry = entries[id];
        if (entry is! Map) return null;
        final snapshot = FrozenRecipeSnapshot.fromJson(entry['snapshot']);
        if (snapshot == null) return null;
        entry['used'] = _tick(data);
        if (!_cleared) await _store.setString(_key, jsonEncode(data));
        return snapshot;
      });

  Future<void> removeRecipe(String recipeId) => _enqueue(() async {
    final data = _load();
    (data['entries'] as Map).removeWhere(
      (_, raw) =>
          FrozenRecipeSnapshot.fromJson((raw as Map)['snapshot'])?.recipeId ==
          recipeId,
    );
    (data['protections'] as Map).removeWhere(
      (_, raw) => FrozenRecipeSnapshot.fromJson(raw)?.recipeId == recipeId,
    );
    (data['last_opened'] as Map).remove(recipeId);
    if (!_cleared) await _store.setString(_key, jsonEncode(data));
  });

  /// Idempotent registration: refreshing a menu or starting an already known
  /// cooking session cannot change the execution payload held by that token.
  Future<FrozenRecipeSnapshot> protect(
    String recipeId,
    String versionId,
    SnapshotProtection protection,
  ) => _enqueue(() async {
    if (_cleared) throw StateError('账号缓存已清理');
    final data = _load();
    final protections = data['protections'] as Map;
    final existing = FrozenRecipeSnapshot.fromJson(protections[protection.key]);
    if (existing != null) return existing;
    final raw = (data['entries'] as Map)[_id(recipeId, versionId)];
    final snapshot = raw is Map
        ? FrozenRecipeSnapshot.fromJson(raw['snapshot'])
        : null;
    if (snapshot == null || snapshot.render == null) {
      throw StateError('需要联网备好完整快照与换算结果');
    }
    protections[protection.key] = snapshot.toJson();
    _trim(data);
    await _store.setString(_key, jsonEncode(data));
    return snapshot;
  });

  Future<FrozenRecipeSnapshot?> readProtected(SnapshotProtection protection) =>
      _enqueue(() async {
        return FrozenRecipeSnapshot.fromJson(
          (_load()['protections'] as Map)[protection.key],
        );
      });

  /// Loader must fetch the specific version and its complete displayed result,
  /// never the latest version. Registration and persistence are atomic, so an
  /// oversized protected item is retained with capacity().overLimit feedback.
  Future<FrozenRecipeSnapshot> prefetchAndProtect(
    SnapshotProtection protection,
    Future<FrozenRecipeSnapshot> Function() load,
  ) async {
    final existing = await readProtected(protection);
    if (existing != null) return existing;
    final snapshot = await load();
    if (snapshot.render == null) throw StateError('需要联网备好完整快照与换算结果');
    return _enqueue(() async {
      if (_cleared) throw StateError('账号缓存已清理');
      final data = _load();
      final protections = data['protections'] as Map;
      final existing = FrozenRecipeSnapshot.fromJson(
        protections[protection.key],
      );
      if (existing != null) return existing;
      _insert(data, snapshot);
      protections[protection.key] = snapshot.toJson();
      _trim(data);
      await _store.setString(_key, jsonEncode(data));
      return snapshot;
    });
  }

  Future<void> release(SnapshotProtection protection) => _enqueue(() async {
    final data = _load();
    (data['protections'] as Map).remove(protection.key);
    _trim(data);
    if (!_cleared) await _store.setString(_key, jsonEncode(data));
  });

  /// Privacy deletion overrides protections and prevents late in-flight page
  /// writes from resurrecting this store instance after withdrawal/deletion.
  Future<void> clear() {
    _cleared = true;
    return _enqueue(() => _store.remove(_key));
  }
}

class SnapshotCapacity {
  const SnapshotCapacity({
    required this.accepted,
    required this.bytes,
    required this.maxBytes,
  });
  final bool accepted;
  final int bytes;
  final int maxBytes;
  bool get overLimit => bytes > maxBytes;
  String? get message => !accepted
      ? '本机缓存空间不足，此版本未离线保存；菜单和正在做的内容已保留。'
      : overLimit
      ? '受保护的菜谱超出缓存容量，内容已保留；请释放不再需要的保护。'
      : null;
}

enum SnapshotProtectionKind { menu, cooking, pendingWrite }

class SnapshotProtection {
  const SnapshotProtection(this.kind, this.ownerId);
  final SnapshotProtectionKind kind;
  final String ownerId;
  String get key => jsonEncode([kind.name, ownerId]);
}
