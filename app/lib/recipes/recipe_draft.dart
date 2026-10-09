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
  RecipeDraftStore(this._store);

  static const keyPrefix = 'recipe_draft:v1:';
  final LocalStore _store;
  Future<void> _writeTail = Future<void>.value();

  String keyFor(
    String recipeKey, {
    String accountId = '',
    String? baselineVersionId,
  }) =>
      '$keyPrefix$accountId:$recipeKey${baselineVersionId == null ? '' : ':$baselineVersionId'}';

  RecipeDraft? readLatest({required String recipeKey, String accountId = ''}) {
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
    if (draft.baselineVersionId != null) {
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
    final result = _writeTail.then((_) => operation());
    _writeTail = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return result;
  }
}
