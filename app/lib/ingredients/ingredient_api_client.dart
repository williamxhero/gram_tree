import 'package:gramtree_api/gramtree_api.dart';

import 'ingredient_repository.dart';

/// Adapter from the generated OpenAPI client to the cache's narrow API seam.
/// It contains no cache policy; [IngredientRepository] owns persistence and
/// failure handling.
class GeneratedIngredientSyncApi implements IngredientSyncApi {
  GeneratedIngredientSyncApi(this.api);

  final IngredientsApi api;

  @override
  Future<IngredientChanges> fetchChanges({String? sinceVersion}) async {
    final response = await api.getIngredientChanges(sinceVersion: sinceVersion);
    final data = response.data;
    if (data == null) throw StateError('食材变化接口返回空响应');
    return IngredientChanges(
      currentVersion: data.currentVersion,
      added: data.added,
      // Retired identities are carried by merge relations rather than the
      // server's active-only modified array. Keep them in the cache's detail
      // collection so old names, aliases and pinyin remain searchable.
      modified: [
        ...data.modified,
        for (final relation in data.merged) ?relation.identity,
      ],
      merged: {
        for (final relation in data.merged) relation.fromId: relation.toId,
      },
    );
  }

  @override
  Future<List<IngredientDetail>> fetchBatch(Iterable<String> ids) async {
    final requested = ids.toList(growable: false);
    if (requested.isEmpty) return [];
    final response = await api.batchGetIngredients(
      batchRequest: BatchRequest(ids: requested),
    );
    return response.data?.items ?? const [];
  }
}
