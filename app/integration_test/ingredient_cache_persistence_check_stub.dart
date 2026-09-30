import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/ingredients/ingredient_repository.dart';
import 'package:gram_tree/storage/local_store.dart';
import 'package:gramtree_api/gramtree_api.dart';

/// Web has no SQLite connection to close/reopen; exercise the web substitute's
/// serialized snapshot boundary with a fresh cache object instead.
Future<void> checkIngredientCacheSurvivesRestart() async {
  final store = MemoryLocalStore();
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

  await LocalStoreIngredientCache(store).write(snapshot);
  final restored = await LocalStoreIngredientCache(store).read();
  expect(restored?.version, 'v7');
  expect(restored?.ingredients[detail.id]?.standardName, '土豆');
  expect(restored?.ingredients[detail.id]?.attributes, detail.attributes);
}
