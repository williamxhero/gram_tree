import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/ingredients/ingredient_repository.dart';
import 'package:gram_tree/storage/local_store.dart';
import 'package:gramtree_api/gramtree_api.dart';

const oldId = '00000000-0000-4000-8000-000000000001';
const carrotId = '00000000-0000-4000-8000-000000000002';
const newId = '00000000-0000-4000-8000-000000000004';

IngredientDetail ingredient({
  required String id,
  required String name,
  List<String> aliases = const [],
  String pinyin = '',
  String initials = '',
  String version = 'v1',
  String? requestedId,
}) => IngredientDetail(
  id: id,
  requestedId: requestedId,
  standardName: name,
  aliases: aliases,
  pinyin: pinyin,
  pinyinInitials: initials,
  category: '蔬菜',
  version: version,
  attributes: IngredientAttributes(),
);

class FakeIngredientSyncApi implements IngredientSyncApi {
  final List<IngredientChanges> changesResponses = [];
  final List<Object> changesErrors = [];
  bool failNextChanges = false;
  final List<List<IngredientDetail>> batchResponses = [];
  final List<Object> batchErrors = [];
  final List<String?> requestedVersions = [];
  final List<List<String>> requestedIds = [];

  @override
  Future<IngredientChanges> fetchChanges({String? sinceVersion}) async {
    requestedVersions.add(sinceVersion);
    if (failNextChanges) {
      failNextChanges = false;
      throw StateError('network down');
    }
    if (changesErrors.isNotEmpty) throw changesErrors.removeAt(0);
    return changesResponses.removeAt(0);
  }

  @override
  Future<List<IngredientDetail>> fetchBatch(Iterable<String> ids) async {
    final requested = ids.toList();
    requestedIds.add(requested);
    if (batchErrors.isNotEmpty) throw batchErrors.removeAt(0);
    return batchResponses.removeAt(0);
  }
}

class FailingIngredientCache implements IngredientCacheStore {
  IngredientCacheSnapshot? snapshot;
  bool failWrites = false;

  @override
  Future<IngredientCacheSnapshot?> read() async => snapshot;

  @override
  Future<void> write(IngredientCacheSnapshot next) async {
    if (failWrites) throw StateError('disk full');
    snapshot = next;
  }
}

IngredientChanges changes({
  required String version,
  List<IngredientDetail> added = const [],
  List<IngredientDetail> modified = const [],
  Map<String, String> merged = const {},
}) => IngredientChanges(
  currentVersion: version,
  added: added,
  modified: modified,
  merged: merged,
);

void main() {
  test('首次同步保存完整详情和版本，之后可以离线搜索和读取', () async {
    final api = FakeIngredientSyncApi()
      ..changesResponses.add(
        changes(
          version: 'v1',
          added: [
            ingredient(
              id: oldId,
              name: '胡萝卜',
              aliases: ['红萝卜'],
              pinyin: 'huluobo',
              initials: 'hlb',
            ),
            ingredient(
              id: carrotId,
              name: '白萝卜',
              aliases: ['萝卜', '大根'],
              pinyin: 'bailuobo',
              initials: 'blb',
            ),
            ingredient(id: newId, name: '萝卜苗', pinyin: 'luobomiao'),
          ],
        ),
      );
    final repository = IngredientRepository(
      api: api,
      cache: LocalStoreIngredientCache(MemoryLocalStore()),
    );

    expect(await repository.sync(), isTrue);
    expect(api.requestedVersions, [null]);
    expect(repository.version, 'v1');
    expect((await repository.search('  胡  ')).map((item) => item.id), [oldId]);
    expect((await repository.search('红')).single.id, oldId);
    expect((await repository.search('HL')).single.id, oldId);
    expect((await repository.search('bai')).single.id, carrotId);
    expect((await repository.search('萝')).map((item) => item.id), [
      newId,
      carrotId,
    ]);
    expect((await repository.get(oldId))!.standardName, '胡萝卜');
    expect(await repository.get('missing'), isNull);
  });

  test('离线搜索按服务端的精确、别名、前缀和拼音优先级排序', () async {
    final api = FakeIngredientSyncApi()
      ..changesResponses.add(
        changes(
          version: 'v1',
          added: [
            ingredient(id: '00000000-0000-4000-8000-000000000011', name: '番茄酱'),
            ingredient(id: '00000000-0000-4000-8000-000000000012', name: '番茄'),
            ingredient(id: '00000000-0000-4000-8000-000000000013', name: '番茄汁'),
          ],
        ),
      );
    final repository = IngredientRepository(
      api: api,
      cache: LocalStoreIngredientCache(MemoryLocalStore()),
    );

    expect(await repository.sync(), isTrue);
    expect((await repository.search('番茄')).map((item) => item.standardName), [
      '番茄',
      '番茄汁',
      '番茄酱',
    ]);
  });

  test('增量同步合并新增、修改和旧 ID 映射，并使用新版本', () async {
    final api = FakeIngredientSyncApi()
      ..changesResponses.add(
        changes(
          version: 'v1',
          added: [
            ingredient(id: oldId, name: '胡萝卜', aliases: ['红萝卜']),
          ],
        ),
      )
      ..changesResponses.add(
        changes(
          version: 'v2',
          added: [
            ingredient(id: newId, name: '青萝卜', aliases: ['水萝卜']),
          ],
          modified: [
            ingredient(
              id: oldId,
              name: '胡萝卜（橙色）',
              aliases: ['红萝卜'],
              version: 'v2',
            ),
          ],
          merged: {oldId: newId},
        ),
      );
    final repository = IngredientRepository(
      api: api,
      cache: LocalStoreIngredientCache(MemoryLocalStore()),
    );

    expect(await repository.sync(), isTrue);
    expect(await repository.sync(), isTrue);
    expect(api.requestedVersions, [null, 'v1']);
    expect(repository.version, 'v2');
    expect((await repository.get(oldId))!.id, newId);
    expect((await repository.search('水')).single.id, newId);
    expect((await repository.search('红')).single.id, newId);
  });

  test('同步失败时保留旧缓存、版本和离线查询结果', () async {
    final api = FakeIngredientSyncApi()
      ..changesResponses.add(
        changes(
          version: 'v1',
          added: [ingredient(id: oldId, name: '胡萝卜')],
        ),
      );
    final repository = IngredientRepository(
      api: api,
      cache: LocalStoreIngredientCache(MemoryLocalStore()),
    );

    expect(await repository.sync(), isTrue);
    api.failNextChanges = true;
    expect(await repository.sync(), isFalse);
    expect(repository.version, 'v1');
    expect((await repository.get(oldId))!.standardName, '胡萝卜');
  });

  test('本机写入失败时也保留旧缓存和版本', () async {
    final api = FakeIngredientSyncApi()
      ..changesResponses.add(
        changes(
          version: 'v1',
          added: [ingredient(id: oldId, name: '胡萝卜')],
        ),
      )
      ..changesResponses.add(
        changes(
          version: 'v2',
          modified: [ingredient(id: oldId, name: '橙胡萝卜')],
        ),
      );
    final cache = FailingIngredientCache();
    final repository = IngredientRepository(api: api, cache: cache);

    expect(await repository.sync(), isTrue);
    cache.failWrites = true;
    expect(await repository.sync(), isFalse);
    expect(repository.version, 'v1');
    expect((await repository.get(oldId))!.standardName, '胡萝卜');
    expect(cache.snapshot?.version, 'v1');
  });

  test('批量读取的合并 provenance 会成为后续离线旧 ID 映射', () async {
    final api = FakeIngredientSyncApi()
      ..changesResponses.add(changes(version: 'v1'))
      ..batchResponses.add([
        ingredient(id: newId, name: '青萝卜', requestedId: oldId),
      ]);
    final local = MemoryLocalStore();
    final repository = IngredientRepository(
      api: api,
      cache: LocalStoreIngredientCache(local),
    );

    await repository.sync();
    final result = await repository.getMany([oldId, 'missing']);

    expect(result.map((item) => item.id), [newId]);
    expect((await repository.get(oldId))!.id, newId);

    final reopened = IngredientRepository(
      api: api,
      cache: LocalStoreIngredientCache(local),
    );
    expect((await reopened.get(oldId))!.id, newId);
  });

  test('批量读取只返回已有或接口找到的食材，不因缺失 ID 失败', () async {
    final api = FakeIngredientSyncApi()
      ..changesResponses.add(
        changes(
          version: 'v1',
          added: [ingredient(id: oldId, name: '胡萝卜')],
        ),
      )
      ..batchResponses.add([ingredient(id: newId, name: '青萝卜')]);
    final repository = IngredientRepository(
      api: api,
      cache: LocalStoreIngredientCache(MemoryLocalStore()),
    );

    await repository.sync();
    final result = await repository.getMany([oldId, newId, 'missing']);

    expect(api.requestedIds, [
      [newId, 'missing'],
    ]);
    expect(result.map((item) => item.id), [oldId, newId]);
    expect((await repository.get(newId))!.standardName, '青萝卜');
  });
}
