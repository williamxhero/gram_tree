import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/storage/local_store.dart';
import 'package:gram_tree/ui_protocol/composition_cache.dart';
import 'package:gramtree_api/gramtree_api.dart' show PageDescription;
import 'package:intl/intl.dart' as intl;

import 'helpers.dart';

/// 和 `composition_view.dart` 里 `_LastUpdatedBanner` 用的格式完全一样——测试不
/// 假设本机时区（跑测试的机器/CI 大概率是 UTC，不是 Asia/Shanghai），按同样的
/// 格式化逻辑现算期望值，而不是写死一个具体的时刻字符串。
String _expectedUpdatedAtText(DateTime savedAt) =>
    intl.DateFormat.Hm().format(savedAt.toLocal());

/// SPEC-009.1 票 7（#83）：组合缓存——App 端把最近一次成功的页面描述存在本机，
/// 离线/超时时依赖版本一致才用它，并显示"上次更新时间"；不一致就退回标准布局。
/// 服务端那一半在 `server/tests/test_ui_composition_cache.py`。
void main() {
  Map<String, dynamic> sampleJson({
    required String compositionId,
    required Map<String, String> dependsOn,
  }) => {
    'protocol': '1.0',
    'page_type': 'today',
    'composition_id': compositionId,
    'generated_at': '2026-09-28T10:30:00Z',
    'cache': {'depends_on': dependsOn, 'ttl_s': 600},
    'experiment': null,
    'components': [
      {
        'type': 'hint_bar',
        'id': 'c1',
        'detail': 'brief',
        'data': {'conclusion': '先添加一道你常做的菜'},
        'actions': [
          {
            'intent': 'open_page',
            'params': {'page': 'create'},
          },
        ],
        'reason': {'code': 'default', 'text': '默认组合'},
        'required': false,
      },
    ],
  };

  /// 预先在本机存好一份缓存（不经过真实的组合请求），测试离线/超时路径时用——
  /// 直接摆好"本机已经有什么"这个前提，不依赖"先联网成功一次"的时序。
  Future<MemoryLocalStore> seededLocalStore({
    required Map<String, String> cachedDependsOn,
    required DateTime savedAt,
    String compositionId = '00000000-0000-4000-8000-0000000000c1',
  }) async {
    final local = MemoryLocalStore(consentedStore());
    final description = PageDescription.fromJson(
      sampleJson(compositionId: compositionId, dependsOn: cachedDependsOn),
    );
    await CompositionCacheStore(local).save('today', description, savedAt);
    return local;
  }

  void expectStandardTodayLayout() {
    expect(find.text('今天还没有安排'), findsOneWidget);
    expect(find.text('添加第一道菜谱'), findsOneWidget);
  }

  testWidgets('离线且内容版本一致时用本机缓存，并显示上次更新时间', (tester) async {
    final savedAt = DateTime.utc(2026, 9, 28, 1, 5);
    final local = await seededLocalStore(
      cachedDependsOn: {'plan': 'v0'},
      savedAt: savedAt,
    );
    final env = TestEnv.signedIn(
      local: local,
      localDependencyVersions: const {'plan': 'v0'},
      offline: true,
    );
    await pumpApp(tester, env: env);

    // 缓存里的组件内容照常渲染，不是标准布局。
    expect(find.text('先添加一道你常做的菜'), findsOneWidget);
    expect(
      find.text('上次更新于 ${_expectedUpdatedAtText(savedAt)}'),
      findsOneWidget,
    );
  });

  testWidgets('离线且内容版本不一致时改用标准布局', (tester) async {
    final local = await seededLocalStore(
      cachedDependsOn: {'plan': 'v0'},
      savedAt: DateTime.utc(2026, 9, 28, 1, 5),
    );
    final env = TestEnv.signedIn(
      local: local,
      // 本机现在知道的依赖版本和缓存里存的不一样（模拟依赖数据已经变了）。
      localDependencyVersions: const {'plan': 'v9'},
      offline: true,
    );
    await pumpApp(tester, env: env);

    expectStandardTodayLayout();
    expect(find.text('先添加一道你常做的菜'), findsNothing);
    expect(find.textContaining('上次更新于'), findsNothing);
  });

  testWidgets('离线且本机完全没有缓存时改用标准布局', (tester) async {
    final env = TestEnv.signedIn(
      localDependencyVersions: const {'plan': 'v0'},
      offline: true,
    );
    await pumpApp(tester, env: env);

    expectStandardTodayLayout();
    expect(find.textContaining('上次更新于'), findsNothing);
  });

  testWidgets('等待超过时限时，如果有依赖版本一致的缓存，先显示缓存而不是标准布局', (tester) async {
    final savedAt = DateTime.utc(2026, 9, 28, 1, 5);
    final local = await seededLocalStore(
      cachedDependsOn: {'plan': 'v0'},
      savedAt: savedAt,
    );
    final server = FakeServer();
    server.on('POST', '/v1/ui/compositions', (r) async {
      // 比下面配的等待时限长得多，确保先触发超时。
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return (
        200,
        sampleJson(compositionId: 'late-response', dependsOn: {'plan': 'v0'}),
      );
    });
    final env = TestEnv.signedIn(
      server: server,
      local: local,
      localDependencyVersions: const {'plan': 'v0'},
      params: const {'ui.composition_timeout_ms': 50},
    );
    await pumpApp(tester, env: env);

    // 用的是缓存里的内容，不是标准布局，也不是那份延迟到达的新响应。
    expect(find.text('先添加一道你常做的菜'), findsOneWidget);
    expect(find.textContaining('上次更新于'), findsOneWidget);
    expect(find.text('今天还没有安排'), findsNothing);

    // 让那条延迟的响应正常触发完，避免测试结束时"还有定时器没触发"报错。
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('等待超过时限但本机没有可用缓存时，仍然退回标准布局（回归 #79）', (tester) async {
    final server = FakeServer();
    server.on('POST', '/v1/ui/compositions', (r) async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return (
        200,
        sampleJson(compositionId: 'late-response', dependsOn: {'plan': 'v0'}),
      );
    });
    final env = TestEnv.signedIn(
      server: server,
      params: const {'ui.composition_timeout_ms': 50},
    );
    await pumpApp(tester, env: env);

    expectStandardTodayLayout();
    expect(find.textContaining('上次更新于'), findsNothing);

    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('服务端接口出错（4xx/5xx）时不使用本机缓存，直接退回标准布局', (tester) async {
    // 这不是"离线"（请求确实到达了服务端、服务端确实回应了），SPEC-009.1 票 7
    // （#83）明确把它和网络层失败区分开：不能拿一份可能已经过期的本机内容去掩盖
    // 服务端本身的问题。
    final savedAt = DateTime.utc(2026, 9, 28, 1, 5);
    final local = await seededLocalStore(
      cachedDependsOn: {'plan': 'v0'},
      savedAt: savedAt,
    );
    final server = FakeServer();
    server.on(
      'POST',
      '/v1/ui/compositions',
      (r) => FakeServer.error(500, 'internal', '出错了'),
    );
    final env = TestEnv.signedIn(
      server: server,
      local: local,
      localDependencyVersions: const {'plan': 'v0'},
    );
    await pumpApp(tester, env: env);

    expectStandardTodayLayout();
    expect(find.textContaining('上次更新于'), findsNothing);
  });

  testWidgets('组合成功后，把这份描述连同依赖版本存进本机缓存', (tester) async {
    final env = TestEnv.signedIn();
    await pumpApp(tester, env: env);
    expect(find.text('先添加一道你常做的菜'), findsOneWidget);

    final cached = CompositionCacheStore(env.local).read('today');
    expect(cached, isNotNull);
    expect(
      cached!.description.compositionId,
      '7c9e6679-7425-40de-944b-e07fc1f90ae7',
    );
    expect(cached.description.cache.dependsOn, {'plan': 'v0'});
  });

  testWidgets('网页版（本质是同一份 LocalStore 接口）离线用缓存也能工作', (tester) async {
    // 这个测试本身不区分平台——LocalStore/MemoryLocalStore 不触碰任何非 web-safe
    // 的 API（没有 dart:io、没有 drift），`flutter test --platform chrome`
    // 跑这个文件时这条测试原样通过，用来确认这一点。
    final savedAt = DateTime.utc(2026, 9, 28, 1, 5);
    final local = await seededLocalStore(
      cachedDependsOn: {'scenario_test': 'v1'},
      savedAt: savedAt,
    );
    final env = TestEnv.signedIn(
      local: local,
      localDependencyVersions: const {'scenario_test': 'v1'},
      offline: true,
    );
    await pumpApp(tester, env: env);

    expect(find.text('先添加一道你常做的菜'), findsOneWidget);
    expect(find.textContaining('上次更新于'), findsOneWidget);
  });

  test('dependsOnMatches 逐字段比较，长度和键值都要一致', () {
    expect(dependsOnMatches({'a': '1'}, {'a': '1'}), isTrue);
    expect(dependsOnMatches({'a': '1'}, {'a': '2'}), isFalse);
    expect(dependsOnMatches({'a': '1'}, {'a': '1', 'b': '2'}), isFalse);
    expect(dependsOnMatches({}, {}), isTrue);
  });
}
