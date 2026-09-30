import 'dart:convert';

import '../storage/local_store.dart';

/// The local editor draft format. It is deliberately versioned so a future
/// schema change can ignore old/corrupt data instead of crashing the editor.
class RecipeDraft {
  const RecipeDraft({
    required this.recipeKey,
    required this.baselineVersionId,
    required this.payload,
    this.formatVersion = 1,
  });

  final int formatVersion;
  final String recipeKey;
  final String? baselineVersionId;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
    'format_version': formatVersion,
    'recipe_key': recipeKey,
    'baseline_version_id': baselineVersionId,
    'payload': payload,
  };

  static RecipeDraft? fromJson(Object? value) {
    if (value is! Map) return null;
    final format = value['format_version'];
    final key = value['recipe_key'];
    final payload = value['payload'];
    final baseline = value['baseline_version_id'];
    if (format != 1 || key is! String || key.isEmpty || payload is! Map) {
      return null;
    }
    if (baseline != null && baseline is! String) return null;
    return RecipeDraft(
      recipeKey: key,
      baselineVersionId: baseline as String?,
      payload: Map<String, dynamic>.from(payload),
    );
  }
}

class RecipeDraftStore {
  RecipeDraftStore(this._store);

  static const keyPrefix = 'recipe_draft:v1:';
  final LocalStore _store;

  String keyFor(String recipeKey) => '$keyPrefix$recipeKey';

  Future<void> save(RecipeDraft draft) async {
    await _store.setString(keyFor(draft.recipeKey), jsonEncode(draft.toJson()));
  }

  RecipeDraft? read({required String recipeKey, String? baselineVersionId}) {
    final raw = _store.getString(keyFor(recipeKey));
    if (raw == null) return null;
    try {
      final draft = RecipeDraft.fromJson(jsonDecode(raw));
      if (draft == null || draft.recipeKey != recipeKey) return null;
      if (draft.baselineVersionId != baselineVersionId) return null;
      return draft;
    } on FormatException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> discard(String recipeKey) => _store.remove(keyFor(recipeKey));
}
