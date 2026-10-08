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
      final inputs = frozen.inputs;
      if (inputs['target_servings'] != null &&
          inputs['target_servings'] is! int) {
        return null;
      }
      if (inputs['target_mold'] != null) {
        MoldSpec.fromJson(inputs['target_mold']);
      }
      if (inputs['personal_measure'] != null) {
        PersonalMeasureOut.fromJson(inputs['personal_measure']);
      }
      if (inputs['scale_mode'] != null &&
          !{'servings', 'mold'}.contains(inputs['scale_mode'])) {
        return null;
      }
      if (inputs['display_mode'] != null &&
          !{'base', 'standard', 'home'}.contains(inputs['display_mode'])) {
        return null;
      }
      frozen.dependencies;
      return frozen;
    } catch (_) {
      return null;
    }
  }
}

/// Owner-scoped access to a device-wide cache behind the existing LocalStore.
/// A single persisted owner index makes cross-account LRU atomic. Public reads
/// never cross owner boundaries; eviction only removes disposable snapshots,
/// never drafts/queue keys or protected execution content from any account.
class RecipeSnapshotStore {
  RecipeSnapshotStore(
    this._store, {
    required this.accountId,
    this.maxBytes = 20 * 1024 * 1024,
  }) {
    if (maxBytes < 0) throw ArgumentError.value(maxBytes, 'maxBytes');
    _coordinator = _coordinators[_store] ??= _SnapshotCoordinator();
    _epoch = _coordinator.epochs[accountId] ?? 0;
  }
  static const _deviceKey = 'recipe_snapshots:device:v1';
  static final _coordinators = Expando<_SnapshotCoordinator>();
  final LocalStore _store;
  final String accountId;
  final int maxBytes;
  late final _SnapshotCoordinator _coordinator;
  late final int _epoch;
  bool get _cleared => _epoch != (_coordinator.epochs[accountId] ?? 0);

  Map<String, dynamic> _loadDevice() {
    try {
      final raw = _store.getString(_deviceKey);
      if (raw != null) {
        final data = jsonDecode(raw);
        if (data is Map &&
            data['format_version'] == 1 &&
            data['owners'] is Map &&
            data['clock'] is int) {
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (_) {
      /* Corrupt/unknown cache is unavailable, never repaired using newer data. */
    }
    return {'format_version': 1, 'clock': 0, 'owners': <String, dynamic>{}};
  }

  Map _owner(Map device) {
    final owners = device['owners'] as Map;
    final data = owners[accountId];
    if (data is Map &&
        data['account_id'] == accountId &&
        data['entries'] is Map &&
        data['protections'] is Map &&
        data['last_opened'] is Map) {
      return data;
    }
    return owners[accountId] = {
      'account_id': accountId,
      'entries': <String, dynamic>{},
      'protections': <String, dynamic>{},
      'last_opened': <String, dynamic>{},
    };
  }

  String _id(String recipe, String version) => jsonEncode([recipe, version]);
  int _bytes(Map device) => (device['owners'] as Map).isEmpty
      ? 0
      : utf8.encode(jsonEncode(device)).length;
  int _tick(Map device) => device['clock'] = (device['clock'] as int) + 1;

  void _insert(Map device, FrozenRecipeSnapshot snapshot) {
    final data = _owner(device);
    (data['entries'] as Map)[_id(snapshot.recipeId, snapshot.versionId)] = {
      'snapshot': snapshot.toJson(),
      'used': _tick(device),
    };
    (data['last_opened'] as Map)[snapshot.recipeId] = _id(
      snapshot.recipeId,
      snapshot.versionId,
    );
  }

  void _pruneOwners(Map device) {
    (device['owners'] as Map).removeWhere(
      (_, data) =>
          (data['entries'] as Map).isEmpty &&
          (data['protections'] as Map).isEmpty,
    );
  }

  void _trim(Map device, {String? keep}) {
    final owners = device['owners'] as Map;
    final candidates = <({String owner, String id, int used})>[];
    for (final e in owners.entries) {
      final data = e.value as Map;
      final protected = <String>{
        for (final raw in (data['protections'] as Map).values)
          if (FrozenRecipeSnapshot.fromJson(raw) case final snapshot?)
            _id(snapshot.recipeId, snapshot.versionId),
      };
      for (final entry in (data['entries'] as Map).entries) {
        if (!protected.contains(entry.key) &&
            !(e.key == accountId && entry.key == keep)) {
          candidates.add((
            owner: e.key as String,
            id: entry.key as String,
            used: (entry.value as Map)['used'] as int,
          ));
        }
      }
    }
    candidates.sort((a, b) => a.used.compareTo(b.used));
    for (final item in candidates) {
      if (_bytes(device) <= maxBytes) break;
      final data = owners[item.owner] as Map;
      (data['entries'] as Map).remove(item.id);
      (data['last_opened'] as Map).removeWhere((_, value) => value == item.id);
      _pruneOwners(device);
    }
  }

  Future<void> _persist(Map device) {
    _pruneOwners(device);
    return (device['owners'] as Map).isEmpty
        ? _store.remove(_deviceKey)
        : _store.setString(_deviceKey, jsonEncode(device));
  }

  SnapshotCapacity _capacity(Map device, {bool accepted = true}) =>
      SnapshotCapacity(
        accepted: accepted,
        bytes: _bytes(device),
        maxBytes: maxBytes,
      );
  Future<SnapshotCapacity> capacity() =>
      _enqueue(() async => _capacity(_loadDevice()));

  // Shared serialization is essential: one account's late write cannot replace
  // another account's protection registration or privacy deletion.
  Future<T> _enqueue<T>(Future<T> Function() action) {
    final result = _coordinator.tail.then((_) => action());
    _coordinator.tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<SnapshotCapacity> save(
    FrozenRecipeSnapshot snapshot,
  ) => _enqueue(() async {
    final device = _loadDevice();
    if (_cleared) return _capacity(device, accepted: false);
    final original = jsonDecode(jsonEncode(device)) as Map<String, dynamic>;
    _insert(device, snapshot);
    _trim(device, keep: _id(snapshot.recipeId, snapshot.versionId));
    if (_bytes(device) > maxBytes) {
      // Explicit prefetch/protection can keep oversized execution payloads;
      // an ordinary page cache instead reports refusal and preserves old data.
      return _capacity(original, accepted: false);
    }
    await _persist(device);
    return _capacity(device);
  });

  Future<FrozenRecipeSnapshot?> read(String recipeId, {String? versionId}) =>
      _enqueue(() async {
        if (_cleared) return null;
        final device = _loadDevice();
        final data = _owner(device);
        final id = versionId == null
            ? (data['last_opened'] as Map)[recipeId]
            : _id(recipeId, versionId);
        final entry = (data['entries'] as Map)[id];
        if (entry is! Map) return null;
        final snapshot = FrozenRecipeSnapshot.fromJson(entry['snapshot']);
        if (snapshot == null) return null;
        entry['used'] = _tick(device);
        _trim(device, keep: id as String);
        await _persist(device);
        return snapshot;
      });

  Future<void> removeRecipe(String recipeId) => _enqueue(() async {
    if (_cleared) return;
    final device = _loadDevice();
    final data = _owner(device);
    (data['entries'] as Map).removeWhere(
      (_, raw) =>
          FrozenRecipeSnapshot.fromJson((raw as Map)['snapshot'])?.recipeId ==
          recipeId,
    );
    (data['protections'] as Map).removeWhere(
      (_, raw) => FrozenRecipeSnapshot.fromJson(raw)?.recipeId == recipeId,
    );
    (data['last_opened'] as Map).remove(recipeId);
    await _persist(device);
  });

  /// Idempotent registration: menu refresh or restarting a known cooking token
  /// cannot replace that token's immutable execution payload.
  Future<FrozenRecipeSnapshot> protect(
    String recipeId,
    String versionId,
    SnapshotProtection protection,
  ) => _enqueue(() async {
    if (_cleared) throw StateError('账号缓存已清理');
    final device = _loadDevice();
    final data = _owner(device);
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
    _trim(device);
    await _persist(device);
    return snapshot;
  });

  Future<FrozenRecipeSnapshot?> readProtected(SnapshotProtection protection) =>
      _enqueue(() async {
        if (_cleared) return null;
        return FrozenRecipeSnapshot.fromJson(
          (_owner(_loadDevice())['protections'] as Map)[protection.key],
        );
      });

  /// Loader must capture the requested specific version and full displayed
  /// result, not latest data. Atomic persistence permits protected excess with
  /// capacity().overLimit feedback rather than deleting another user's content.
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
      final device = _loadDevice();
      final protections = _owner(device)['protections'] as Map;
      final existing = FrozenRecipeSnapshot.fromJson(
        protections[protection.key],
      );
      if (existing != null) return existing;
      _insert(device, snapshot);
      protections[protection.key] = snapshot.toJson();
      _trim(device);
      await _persist(device);
      return snapshot;
    });
  }

  Future<void> release(SnapshotProtection protection) => _enqueue(() async {
    if (_cleared) return;
    final device = _loadDevice();
    (_owner(device)['protections'] as Map).remove(protection.key);
    _trim(device);
    await _persist(device);
  });

  /// Privacy deletion overrides this owner's protections and invalidates all
  /// already-created handles so late work cannot resurrect deleted snapshots.
  /// Other owners' protected content and all business drafts/queues are untouched.
  Future<void> clear() {
    _coordinator.epochs[accountId] = (_coordinator.epochs[accountId] ?? 0) + 1;
    return _enqueue(() async {
      final device = _loadDevice();
      (device['owners'] as Map).remove(accountId);
      await _persist(device);
    });
  }
}

class _SnapshotCoordinator {
  Future<void> tail = Future<void>.value();
  final Map<String, int> epochs = {};
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
