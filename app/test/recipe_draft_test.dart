import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/recipes/recipe_draft.dart';
import 'package:gram_tree/storage/local_store.dart';

void main() {
  test(
    'draft round trips and is isolated by recipe key and baseline',
    () async {
      final store = MemoryLocalStore();
      final drafts = RecipeDraftStore(store);
      await drafts.save(
        const RecipeDraft(
          recipeKey: 'recipe-a',
          baselineVersionId: 'version-1',
          payload: {'dish_name': '宫保鸡丁'},
        ),
      );

      expect(
        drafts
            .read(recipeKey: 'recipe-a', baselineVersionId: 'version-1')!
            .payload,
        {'dish_name': '宫保鸡丁'},
      );
      expect(
        drafts.read(recipeKey: 'recipe-b', baselineVersionId: 'version-1'),
        isNull,
      );
      expect(
        drafts.read(recipeKey: 'recipe-a', baselineVersionId: 'version-2'),
        isNull,
      );
    },
  );

  test('corrupt or old drafts are ignored and discard is durable', () async {
    final store = MemoryLocalStore({
      '${RecipeDraftStore.keyPrefix}bad': jsonEncode({'format_version': 99}),
      '${RecipeDraftStore.keyPrefix}broken': '{not-json',
    });
    final drafts = RecipeDraftStore(store);
    expect(drafts.read(recipeKey: 'bad'), isNull);
    expect(drafts.read(recipeKey: 'broken'), isNull);

    await drafts.save(
      const RecipeDraft(
        recipeKey: 'saved',
        baselineVersionId: null,
        payload: {},
      ),
    );
    await drafts.discard('saved');
    expect(drafts.read(recipeKey: 'saved'), isNull);
  });
}
