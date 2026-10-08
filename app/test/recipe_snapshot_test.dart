import 'package:flutter_test/flutter_test.dart';
import 'package:gramtree_api/gramtree_api.dart';
import 'package:gram_tree/recipes/recipe_snapshot.dart';
import 'package:gram_tree/storage/local_store.dart';

RecipeDetail recipeSnapshotFixture(
  String version, {
  String recipe = 'recipe',
}) => RecipeDetail(
  id: recipe,
  author: RecipeAuthor(id: 'alice', nickname: '作者'),
  dish: DishOut(id: 'dish', name: '汤', aliases: const []),
  createdAt: '2026-10-01T00:00:00Z',
  updatedAt: '2026-10-01T00:00:00Z',
  visibility: RecipeDetailVisibilityEnum.private,
  version: RecipeVersionOut(
    id: version,
    versionNumber: 1,
    aiAssisted: false,
    createdAt: '2026-10-01T00:00:00Z',
    changeNote: '原版',
    editOperations: const [],
    images: const [],
    derived: RecipeDerived(activeTimeSeconds: 0, totalTimeSeconds: 0),
    snapshot: RecipeSnapshot(
      formatVersion: RecipeSnapshotFormatVersionEnum.number1,
      servings: 2,
      ingredients: [
        RecipeIngredient(
          id: 'water',
          displayName: '水',
          quantity: 100,
          unit: 'g',
        ),
      ],
      steps: [RecipeStep(id: 'boil', instruction: '烧开')],
    ),
  ),
);

FrozenRecipeSnapshot frozenVersion(
  String version, {
  String recipe = 'recipe',
  int quantity = 200,
}) => FrozenRecipeSnapshot(
  detail: recipeSnapshotFixture(version, recipe: recipe),
  capturedAt: DateTime.utc(2026, 10, 1),
  inputs: {'target_servings': 4, 'target_mold': null, 'personal_measure': null},
  render: {'quantity': quantity},
  dependencies: {'serving_rules': 'v1'},
);

void main() {
  test('LRU evicts unused versions but retains menu execution and reports excess capacity', () async {
    final platform = MemoryLocalStore();
    final cache = RecipeSnapshotStore(
      platform,
      accountId: 'alice',
      maxBytes: 4000,
    );
    await cache.save(frozenVersion('v1'));
    await cache.save(frozenVersion('v2'));
    await cache.save(frozenVersion('v3'));
    await cache.read('recipe', versionId: 'v1');
    await cache.save(frozenVersion('v4'));
    await cache.save(frozenVersion('v5'));
    expect(await cache.read('recipe', versionId: 'v1'), isNotNull);
    expect(await cache.read('recipe', versionId: 'v2'), isNull);
    const menu = SnapshotProtection(SnapshotProtectionKind.menu, 'slot');
    await cache.protect('recipe', 'v1', menu);
    for (var i = 6; i < 15; i++) {
      await cache.save(frozenVersion('v$i'));
    }
    expect((await cache.readProtected(menu))!.versionId, 'v1');
    expect((await cache.read('recipe', versionId: 'v1'))!.versionId, 'v1');
    final tinyCache = RecipeSnapshotStore(
      platform,
      accountId: 'alice',
      maxBytes: 10,
    );
    expect((await tinyCache.save(frozenVersion('huge'))).accepted, isFalse);
    expect((await tinyCache.capacity()).overLimit, isTrue);
    await tinyCache.release(menu);
    expect((await tinyCache.capacity()).overLimit, isFalse);
    // A future execution can explicitly retain an oversized complete snapshot;
    // feedback exposes the excess, not an unsafe silent deletion.
    await tinyCache.prefetchAndProtect(
      menu,
      () async => frozenVersion('oversize'),
    );
    expect((await tinyCache.capacity()).overLimit, isTrue);
    expect((await tinyCache.readProtected(menu))!.versionId, 'oversize');
  });
  test('menu and cooking protections freeze execution while page refreshes and releases', () async {
    final platform = MemoryLocalStore();
    final cache = RecipeSnapshotStore(platform, accountId: 'alice');
    const menu = SnapshotProtection(SnapshotProtectionKind.menu, 'menu-slot-1');
    const cooking = SnapshotProtection(
      SnapshotProtectionKind.cooking,
      'session-1',
    );
    await cache.prefetchAndProtect(menu, () async => frozenVersion('v1'));
    await cache.protect('recipe', 'v1', cooking);
    await cache.save(frozenVersion('v1', quantity: 999));
    await cache.protect('recipe', 'v1', menu);
    expect(
      (await cache.read('recipe', versionId: 'v1'))!.render!['quantity'],
      999,
    );
    expect((await cache.readProtected(menu))!.render!['quantity'], 200);
    await cache.release(menu);
    expect(await cache.readProtected(menu), isNull);
    final reopened = RecipeSnapshotStore(platform, accountId: 'alice');
    expect((await reopened.readProtected(cooking))!.render!['quantity'], 200);
    await reopened.clear();
    expect(await reopened.readProtected(cooking), isNull);
    expect(
      await RecipeSnapshotStore(platform, accountId: 'alice').read('recipe'),
      isNull,
    );
  });
  test('reopened account cache returns immutable version and actual frozen amounts', () async {
    final platform = MemoryLocalStore();
    final cache = RecipeSnapshotStore(platform, accountId: 'alice');
    final original = FrozenRecipeSnapshot(
      detail: recipeSnapshotFixture('v1'),
      capturedAt: DateTime.utc(2026, 10, 1),
      inputs: {
        'target_servings': 4,
        'target_mold': null,
        'personal_measure': null,
      },
      render: {
        'water': {'quantity': 200, 'unit': 'g', 'source': 'scene_adjusted'},
      },
      dependencies: {'serving_rules': 'v1', 'ingredient_catalogue': null},
    );
    await cache.save(original);
    final reopened = RecipeSnapshotStore(platform, accountId: 'alice');
    final frozen = await reopened.read('recipe', versionId: 'v1');
    expect(frozen!.detail.version.id, 'v1');
    expect(frozen.detail.version.snapshot.steps!.single.instruction, '烧开');
    expect(frozen.render!['water']['quantity'], 200);
    expect(frozen.dependencies['ingredient_catalogue'], isNull);
    expect(await reopened.read('recipe', versionId: 'v2'), isNull);
    expect(
      await RecipeSnapshotStore(platform, accountId: 'bob').read('recipe'),
      isNull,
    );
  });
}
