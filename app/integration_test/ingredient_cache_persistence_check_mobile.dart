import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/ingredients/ingredient_cache_mobile.dart';
import 'package:gram_tree/ingredients/ingredient_repository.dart';
import 'package:gramtree_api/gramtree_api.dart';

Future<void> checkIngredientCacheSurvivesRestart() async {
  const databaseName = 'ingredient_cache_persistence_check';
  IngredientCacheDatabase open() =>
      IngredientCacheDatabase.withExecutor(driftDatabase(name: databaseName));

  final detail = IngredientDetail(
    id: '00000000-0000-4000-8000-000000000010',
    standardName: '土豆',
    aliases: ['马铃薯'],
    pinyin: 'tudou',
    pinyinInitials: 'td',
    category: '蔬菜',
    version: 'v7',
    attributes: IngredientAttributes(),
  );
  final snapshot = IngredientCacheSnapshot(
    version: 'v7',
    ingredients: {detail.id: detail},
    merged: const {},
  );

  final cleanup = open();
  await cleanup.delete(cleanup.ingredientCacheDetails).go();
  await cleanup.delete(cleanup.ingredientCacheVersions).go();
  await cleanup.close();

  final first = DriftIngredientCache(open());
  await first.write(snapshot);
  await first.close();

  final reopened = DriftIngredientCache(open());
  final restored = await reopened.read();
  expect(restored?.version, 'v7');
  expect(restored?.ingredients[detail.id]?.standardName, '土豆');
  expect(restored?.ingredients[detail.id]?.attributes, detail.attributes);
  await reopened.close();
}
