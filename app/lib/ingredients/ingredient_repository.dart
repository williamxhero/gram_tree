import 'dart:convert';

import 'package:gramtree_api/gramtree_api.dart';

import '../storage/local_store.dart';

/// The response needed by the cache is deliberately narrower than the generated
/// HTTP client. This keeps search and persistence testable without coupling them
/// to Dio or to the version of the OpenAPI generator in use.
class IngredientChanges {
  const IngredientChanges({
    required this.currentVersion,
    required this.added,
    required this.modified,
    required this.merged,
  });

  final String currentVersion;
  final List<IngredientDetail> added;
  final List<IngredientDetail> modified;
  final Map<String, String> merged;
}

/// Boundary used by [IngredientRepository] for the remote ingredient API.
abstract interface class IngredientSyncApi {
  Future<IngredientChanges> fetchChanges({String? sinceVersion});

  /// The server may omit unknown IDs from this response. A missing ID must not
  /// make the whole batch fail.
  Future<List<IngredientDetail>> fetchBatch(Iterable<String> ids);
}

class IngredientCacheSnapshot {
  const IngredientCacheSnapshot({
    required this.version,
    required this.ingredients,
    required this.merged,
  });

  final String version;
  final Map<String, IngredientDetail> ingredients;
  final Map<String, String> merged;

  factory IngredientCacheSnapshot.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'];
    final rawMerged = json['merged'];
    if (json['version'] is! String ||
        rawIngredients is! Map ||
        rawMerged is! Map) {
      throw const FormatException('invalid ingredient cache');
    }

    final ingredients = <String, IngredientDetail>{};
    for (final entry in rawIngredients.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw const FormatException('invalid ingredient cache item');
      }
      final id = entry.key as String;
      final detail = IngredientDetail.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
      if (detail.id != id) {
        throw const FormatException('ingredient cache key does not match ID');
      }
      ingredients[id] = detail;
    }

    final merged = <String, String>{};
    for (final entry in rawMerged.entries) {
      if (entry.key is! String || entry.value is! String) {
        throw const FormatException('invalid ingredient merge');
      }
      merged[entry.key as String] = entry.value as String;
    }

    return IngredientCacheSnapshot(
      version: json['version'] as String,
      ingredients: ingredients,
      merged: merged,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'ingredients': {
      for (final entry in ingredients.entries) entry.key: entry.value.toJson(),
    },
    'merged': merged,
  };
}

/// Persistence boundary for the complete cache snapshot.
abstract interface class IngredientCacheStore {
  Future<IngredientCacheSnapshot?> read();
  Future<void> write(IngredientCacheSnapshot snapshot);
}

abstract interface class CloseableIngredientCacheStore
    implements IngredientCacheStore {
  Future<void> close();
}

/// Web and test implementation backed by the existing key/value abstraction.
/// The whole snapshot is encoded and written in one [setString] call so a
/// failed sync cannot expose a half-written collection.
class LocalStoreIngredientCache implements IngredientCacheStore {
  LocalStoreIngredientCache(this._store, {this.key = _defaultKey});

  static const _defaultKey = 'ingredient_cache.snapshot';

  final LocalStore _store;
  final String key;

  @override
  Future<IngredientCacheSnapshot?> read() async {
    final encoded = _store.getString(key);
    if (encoded == null) return null;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return null;
      return IngredientCacheSnapshot.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> write(IngredientCacheSnapshot snapshot) =>
      _store.setString(key, jsonEncode(snapshot.toJson()));
}

/// UI-independent local ingredient catalogue.
class IngredientRepository {
  IngredientRepository({required this.api, required this.cache}) {
    _loaded = _load();
  }

  final IngredientSyncApi api;
  final IngredientCacheStore cache;

  late final Future<void> _loaded;
  IngredientCacheSnapshot? _snapshot;
  Future<void> _writeTail = Future<void>.value();

  /// The last successfully persisted version, or null before the first load.
  String? get version => _snapshot?.version;

  Future<void> _load() async {
    _snapshot = await cache.read();
  }

  Future<void> _ensureLoaded() => _loaded;

  Future<T> _withWriteLock<T>(Future<T> Function() action) {
    final result = _writeTail.then((_) => action());
    _writeTail = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return result;
  }

  /// Downloads either the complete catalogue or changes since [version].
  ///
  /// A network or persistence failure returns false and leaves both the in-memory
  /// and persisted snapshot untouched. The caller can continue serving offline
  /// reads and retry later.
  Future<bool> sync() async {
    return _withWriteLock(() async {
      await _ensureLoaded();
      final before = _snapshot;
      try {
        final changes = await api.fetchChanges(sinceVersion: before?.version);
        final ingredients = <String, IngredientDetail>{...?before?.ingredients};
        final merged = <String, String>{...?before?.merged};
        for (final detail in [...changes.added, ...changes.modified]) {
          ingredients[detail.id] = detail;
        }
        merged.addAll(changes.merged);
        final next = IngredientCacheSnapshot(
          version: changes.currentVersion,
          ingredients: ingredients,
          merged: merged,
        );
        await cache.write(next);
        _snapshot = next;
        return true;
      } catch (_) {
        _snapshot = before;
        return false;
      }
    });
  }

  /// Searches only the local snapshot. Matching follows the server's field
  /// priority: standard name, alias, pinyin initials, then full pinyin.
  Future<List<IngredientDetail>> search(String query) async {
    await _ensureLoaded();
    final snapshot = _snapshot;
    if (snapshot == null) return [];
    final q = query.trim();
    if (q.isEmpty) return [];
    final lower = q.toLowerCase();
    final ranked = <String, ({int priority, IngredientDetail detail})>{};

    for (final detail in snapshot.ingredients.values) {
      // The online search excludes rows that have been merged. Reads by an
      // explicit old ID still follow [snapshot.merged] in [get].
      if (snapshot.merged.containsKey(detail.id)) continue;
      final resolved = _resolve(snapshot, detail.id);
      final target = snapshot.ingredients[resolved];
      if (target == null) continue;
      final priority = _matchPriority(detail, q, lower);
      if (priority == null) continue;
      final existing = ranked[target.id];
      if (existing == null || priority < existing.priority) {
        ranked[target.id] = (priority: priority, detail: target);
      }
    }

    final results = ranked.values.toList()
      ..sort((a, b) {
        final priority = a.priority.compareTo(b.priority);
        if (priority != 0) return priority;
        final name = a.detail.standardName.compareTo(b.detail.standardName);
        if (name != 0) return name;
        return a.detail.id.compareTo(b.detail.id);
      });
    return results.take(20).map((item) => item.detail).toList(growable: false);
  }

  Future<IngredientDetail?> get(String id) async {
    await _ensureLoaded();
    final snapshot = _snapshot;
    if (snapshot == null) return null;
    final resolved = _resolve(snapshot, id);
    return snapshot.ingredients[resolved];
  }

  /// Reads all locally available IDs and asks the remote boundary only for the
  /// missing ones. Unknown IDs are omitted from the result, matching the batch
  /// endpoint contract rather than failing the complete request.
  Future<List<IngredientDetail>> getMany(Iterable<String> ids) async {
    await _ensureLoaded();
    final requested = ids.toList(growable: false);
    final snapshot = _snapshot;
    if (snapshot == null) {
      return _fetchMissing(requested);
    }

    final result = <String, IngredientDetail>{};
    final missing = <String>[];
    for (final id in requested) {
      final resolved = _resolve(snapshot, id);
      final detail = snapshot.ingredients[resolved];
      if (detail == null) {
        if (!missing.contains(id)) missing.add(id);
      } else {
        result[id] = detail;
      }
    }
    if (missing.isNotEmpty) {
      final fetched = await _fetchMissing(missing);
      for (final detail in fetched) {
        result[detail.requestedId ?? detail.id] = detail;
        result[detail.id] = detail;
      }
    }

    final ordered = <IngredientDetail>[];
    final seen = <String>{};
    for (final id in requested) {
      final detail = result[id] ?? result[_resolve(snapshot, id)];
      if (detail != null && seen.add(detail.id)) ordered.add(detail);
    }
    return ordered;
  }

  Future<List<IngredientDetail>> _fetchMissing(List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final fetched = await api.fetchBatch(ids);
      if (fetched.isEmpty) return [];
      return await _withWriteLock(() async {
        final before = _snapshot;
        final ingredients = <String, IngredientDetail>{
          ...?before?.ingredients,
          for (final detail in fetched) detail.id: detail,
        };
        if (before != null) {
          final merged = <String, String>{...?before.merged};
          for (final detail in fetched) {
            final requestedId = detail.requestedId;
            if (requestedId != null && requestedId != detail.id) {
              merged[requestedId] = detail.id;
            }
          }
          final next = IngredientCacheSnapshot(
            version: before.version,
            ingredients: ingredients,
            merged: merged,
          );
          try {
            await cache.write(next);
            _snapshot = next;
          } catch (_) {
            // A batch read is still useful to its caller even if persisting the
            // newly fetched details fails; the prior snapshot remains intact.
          }
        }
        return fetched;
      });
    } catch (_) {
      return [];
    }
  }

  int? _matchPriority(IngredientDetail detail, String query, String lower) {
    if (detail.standardName.startsWith(query)) return 0;
    if (detail.aliases.any((alias) => alias.startsWith(query))) return 1;
    if (detail.pinyinInitials.toLowerCase().startsWith(lower)) return 2;
    if (detail.pinyin.toLowerCase().startsWith(lower)) return 3;
    return null;
  }

  String _resolve(IngredientCacheSnapshot snapshot, String id) {
    var current = id;
    final seen = <String>{};
    while (true) {
      if (!seen.add(current)) return id;
      final next = snapshot.merged[current];
      if (next == null) return current;
      current = next;
    }
  }
}
