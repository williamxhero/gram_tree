import 'dart:convert';

import '../storage/local_store.dart';

/// Versioned local editor snapshot. A draft is scoped to one account, recipe,
/// and immutable baseline version so it can never silently cross those seams.
class RecipeDraft {
  const RecipeDraft({
    required this.recipeKey,
    required this.baselineVersionId,
    required this.payload,
    this.accountId = '',
    this.formatVersion = 1,
    this.baselineDetail,
  });

  final int formatVersion;
  final String accountId;
  final String recipeKey;
  final String? baselineVersionId;
  final Map<String, dynamic> payload;
  final Map<String, dynamic>? baselineDetail;

  Map<String, dynamic> toJson() => {
    'format_version': formatVersion,
    'account_id': accountId,
    'recipe_key': recipeKey,
    'baseline_version_id': baselineVersionId,
    'payload': payload,
    if (baselineDetail != null) 'baseline_detail': baselineDetail,
  };

  static RecipeDraft? fromJson(Object? value) {
    if (value is! Map) return null;
    try {
      final format = value['format_version'];
      final account = value['account_id'];
      final key = value['recipe_key'];
      final payload = value['payload'];
      final baseline = value['baseline_version_id'];
      if (format != 1 || key is! String || key.isEmpty || payload is! Map) {
        return null;
      }
      if (account != null && account is! String) return null;
      if (baseline != null && baseline is! String) return null;
      return RecipeDraft(
        accountId: account as String? ?? '',
        recipeKey: key,
        baselineVersionId: baseline as String?,
        payload: Map<String, dynamic>.from(payload),
        baselineDetail: value['baseline_detail'] is Map
            ? Map<String, dynamic>.from(value['baseline_detail'] as Map)
            : null,
      );
    } catch (_) {
      return null;
    }
  }
}

class RecipeDraftStore {
  RecipeDraftStore(this._store) {
    _coordinator = _coordinators[_store] ??= _DraftCoordinator();
    _epochs = Map.of(_coordinator.epochs);
  }

  static const keyPrefix = 'recipe_draft:v1:';
  static final _coordinators = Expando<_DraftCoordinator>();
  final LocalStore _store;
  late final _DraftCoordinator _coordinator;
  late final Map<String, int> _epochs;

  bool _canUseAccount(String owner) =>
      (_epochs[owner] ?? 0) == (_coordinator.epochs[owner] ?? 0);

  /// Successful account deletion only. Fence every old editor handle before
  /// waiting for admitted platform writes, then erase pointers and all baselines.
  Future<void> clearAccount(String owner) {
    _coordinator.epochs[owner] = (_coordinator.epochs[owner] ?? 0) + 1;
    return _enqueue(() async {
      for (final key in _store.keys.where(
        (key) => key.startsWith('$keyPrefix$owner:'),
      )) {
        await _store.remove(key);
      }
    });
  }

  String keyFor(
    String recipeKey, {
    String accountId = '',
    String? baselineVersionId,
  }) =>
      '$keyPrefix$accountId:$recipeKey${baselineVersionId == null ? '' : ':$baselineVersionId'}';

  RecipeDraft? readLatest({required String recipeKey, String accountId = ''}) {
    if (!_canUseAccount(accountId)) return null;
    final raw = _store.getString(keyFor(recipeKey, accountId: accountId));
    if (raw == null) return null;
    try {
      final draft = RecipeDraft.fromJson(jsonDecode(raw));
      return draft?.recipeKey == recipeKey && draft?.accountId == accountId
          ? draft
          : null;
    } catch (_) {
      return null;
    }
  }

  /// Writes are serialized so a delayed platform write cannot reorder a newer
  /// draft behind an older one.
  Future<void> save(RecipeDraft draft) => _enqueue(() async {
    if (!_canUseAccount(draft.accountId)) return;
    final encoded = jsonEncode(draft.toJson());
    await _store.setString(
      keyFor(
        draft.recipeKey,
        accountId: draft.accountId,
        baselineVersionId: draft.baselineVersionId,
      ),
      encoded,
    );
    // The recipe pointer permits local-first recovery without a remote lookup;
    // baseline-specific copies remain separate when a newer version is edited.
    if (draft.baselineVersionId != null && _canUseAccount(draft.accountId)) {
      await _store.setString(
        keyFor(draft.recipeKey, accountId: draft.accountId),
        encoded,
      );
    }
  });

  RecipeDraft? read({
    required String recipeKey,
    String? baselineVersionId,
    String accountId = '',
  }) {
    if (!_canUseAccount(accountId)) return null;
    final raw =
        _store.getString(
          keyFor(
            recipeKey,
            accountId: accountId,
            baselineVersionId: baselineVersionId,
          ),
        ) ??
        _store.getString(keyFor(recipeKey, accountId: accountId));
    if (raw == null) return null;
    try {
      final draft = RecipeDraft.fromJson(jsonDecode(raw));
      if (draft == null ||
          draft.recipeKey != recipeKey ||
          draft.accountId != accountId ||
          draft.baselineVersionId != baselineVersionId) {
        return null;
      }
      return draft;
    } catch (_) {
      return null;
    }
  }

  Future<void> discard(
    String recipeKey, {
    String accountId = '',
    String? baselineVersionId,
  }) => _enqueue(() async {
    if (!_canUseAccount(accountId)) return;
    final latest = readLatest(recipeKey: recipeKey, accountId: accountId);
    final baseline = baselineVersionId ?? latest?.baselineVersionId;
    await _store.remove(
      keyFor(recipeKey, accountId: accountId, baselineVersionId: baseline),
    );
    if (latest?.baselineVersionId == baseline) {
      await _store.remove(keyFor(recipeKey, accountId: accountId));
    }
  });

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _coordinator.tail.then((_) => operation());
    _coordinator.tail = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return result;
  }
}

class _DraftCoordinator {
  Future<void> tail = Future<void>.value();
  final Map<String, int> epochs = {};
}
