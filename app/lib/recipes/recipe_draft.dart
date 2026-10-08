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
  });

  final int formatVersion;
  final String accountId;
  final String recipeKey;
  final String? baselineVersionId;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
    'format_version': formatVersion,
    'account_id': accountId,
    'recipe_key': recipeKey,
    'baseline_version_id': baselineVersionId,
    'payload': payload,
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
      );
    } catch (_) {
      return null;
    }
  }
}

class RecipeDraftStore {
  RecipeDraftStore(this._store);

  static const keyPrefix = 'recipe_draft:v1:';
  static const generatedResultKey = 'generation-result';
  final LocalStore _store;
  // Editor and modification surfaces share one platform store. A queue per
  // store also orders a disposal write before a successful-save removal.
  static final _writeTails = Expando<Future<void>>();

  String modificationKey(String recipeKey, String? baselineVersionId) =>
      'modification:$recipeKey:${baselineVersionId ?? 'generated'}';

  RecipeDraft? readModification({
    required String recipeKey,
    required String accountId,
    String? baselineVersionId,
  }) => read(
    recipeKey: modificationKey(recipeKey, baselineVersionId),
    accountId: accountId,
    baselineVersionId: baselineVersionId,
  );

  Future<void> saveModification({
    required String recipeKey,
    required String accountId,
    required Map<String, dynamic> payload,
    String? baselineVersionId,
  }) => save(
    RecipeDraft(
      accountId: accountId,
      recipeKey: modificationKey(recipeKey, baselineVersionId),
      baselineVersionId: baselineVersionId,
      payload: payload,
    ),
  );

  Future<void> discardModification({
    required String recipeKey,
    required String accountId,
    String? baselineVersionId,
  }) => discard(
    modificationKey(recipeKey, baselineVersionId),
    accountId: accountId,
  );

  String keyFor(String recipeKey, {String accountId = ''}) =>
      '$keyPrefix$accountId:$recipeKey';

  /// Writes are serialized so a delayed platform write cannot reorder a newer
  /// draft behind an older one.
  Future<void> save(RecipeDraft draft) => _enqueue(
    () => _store.setString(
      keyFor(draft.recipeKey, accountId: draft.accountId),
      jsonEncode(draft.toJson()),
    ),
  );

  RecipeDraft? read({
    required String recipeKey,
    String? baselineVersionId,
    String accountId = '',
  }) {
    final raw = _store.getString(keyFor(recipeKey, accountId: accountId));
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

  Future<void> discard(String recipeKey, {String accountId = ''}) =>
      _enqueue(() => _store.remove(keyFor(recipeKey, accountId: accountId)));

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = (_writeTails[_store] ?? Future<void>.value()).then(
      (_) => operation(),
    );
    _writeTails[_store] = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return result;
  }
}
