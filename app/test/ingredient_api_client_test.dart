import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/ingredients/ingredient_api_client.dart';
import 'package:gramtree_api/gramtree_api.dart';

IngredientDetail detail({
  required String id,
  String? requestedId,
  required String name,
}) => IngredientDetail(
  id: id,
  requestedId: requestedId,
  standardName: name,
  aliases: const [],
  pinyin: 'pingyin',
  pinyinInitials: 'py',
  category: '蔬菜',
  version: 'v2',
  attributes: IngredientAttributes(),
);

void main() {
  test(
    'generated changes and batch responses are adapted at the transport seam',
    () async {
      final calls = <RequestOptions>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              calls.add(options);
              if (options.path == '/v1/ingredients/changes') {
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: ChangesResponse(
                      currentVersion: 'v2',
                      added: [detail(id: 'new', name: '青萝卜')],
                      modified: const [],
                      merged: [
                        MergeRelation(
                          fromId: 'old',
                          toId: 'new',
                          identity: detail(id: 'old', name: '旧食材'),
                        ),
                      ],
                      releases: [
                        ReleaseNote(version: 'v2', changelog: '补充青萝卜'),
                      ],
                    ).toJson(),
                  ),
                );
              } else {
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: BatchResponse(
                      items: [
                        detail(id: 'new', requestedId: 'old', name: '青萝卜'),
                      ],
                      missingIds: const ['missing'],
                    ).toJson(),
                  ),
                );
              }
            },
          ),
        );
      final adapter = GeneratedIngredientSyncApi(IngredientsApi(dio));

      final changes = await adapter.fetchChanges();
      final batch = await adapter.fetchBatch(['old', 'missing']);

      expect(changes.currentVersion, 'v2');
      expect(changes.added.single.id, 'new');
      expect(changes.modified.single.id, 'old');
      expect(changes.modified.single.standardName, '旧食材');
      expect(changes.merged, {'old': 'new'});
      expect(batch.single.requestedId, 'old');
      expect(calls.map((call) => call.path), [
        '/v1/ingredients/changes',
        '/v1/ingredients/batch',
      ]);
      expect(calls.last.data, '{"ids":["old","missing"]}');
    },
  );
}
