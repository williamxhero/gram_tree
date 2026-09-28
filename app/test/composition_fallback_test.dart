import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/ui_protocol/embedded_assets.g.dart';
import 'package:gram_tree/ui_protocol/protocol_paths.dart';

import 'helpers.dart';

/// SPEC-009.1 票 3（#79）：出任何问题（协议大版本不认识、未登记组件/动作、数据不
/// 符合格式、缺必显组件、服务端报错、等待超时）都整页改用标准布局，并记录对应的
/// 兜底原因代码；同大版本更高小版本多出未知字段照常渲染；底部五入口不受影响。
///
/// 服务端那一半在 `server/tests/test_ui_protocol.py`；两边读同一批
/// `app/assets/contracts/ui_protocol/samples/invalid/` 文件，判定必须一致（见
/// `docs/adr/0005-界面描述协议共享契约.md`）。
void main() {
  Map<String, dynamic> loadSample(String category, String name) {
    final text = embeddedUiProtocolSamples[sampleAsset(category, name)];
    if (text == null) {
      fail('样例未内嵌，运行 tool/gen_ui_protocol_schemas.sh 重新生成：$category/$name');
    }
    return jsonDecode(text) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> composedEvents(TestEnv env) => env.server
      .calls('POST', '/v1/events/upload')
      .expand((r) => ((r.body as Map)['events'] as List).cast<Map>())
      .where((e) => e['event_type'] == 'ui.composition_shown')
      .map((e) => (e['content'] as Map).cast<String, dynamic>())
      .toList();

  Future<TestEnv> pumpWithSample(
    WidgetTester tester,
    Map<String, dynamic> sample, {
    Map<String, Set<String>>? requiredComponentTypes,
  }) async {
    final server = FakeServer();
    server.on('POST', '/v1/ui/compositions', (r) => (200, sample));
    final env = TestEnv.signedIn(
      server: server,
      requiredComponentTypes: requiredComponentTypes,
    );
    await pumpApp(tester, env: env);
    return env;
  }

  void expectStandardTodayLayout() {
    expect(find.text('今天还没有安排'), findsOneWidget);
    expect(find.text('添加第一道菜谱'), findsOneWidget);
  }

  void expectAllTabsPresent() {
    // 中间那个入口（"新建"）是一个 ＋ 图标按钮，不是文字（见 helpers.dart 的
    // tapTab），其它四个用文字断言。
    for (var i = 0; i < tabLabels.length; i++) {
      if (i == 2) {
        expect(
          find.byKey(const ValueKey('primary-create-button')),
          findsOneWidget,
        );
      } else {
        expect(find.text(tabLabels[i]), findsWidgets);
      }
    }
  }

  final expectedReasonByFile = {
    'unknown_component.json': 'unknown_component',
    'missing_field.json': 'invalid_data',
    'illegal_action.json': 'illegal_action',
    // SPEC-009.1 #81：意图是不是已登记、参数格式对不对，也在这一层被判定为
    // illegal_action（和服务端 server/tests/test_ui_protocol.py 的
    // INVALID_SAMPLE_REASONS 保持一致）。
    'unregistered_intent.json': 'illegal_action',
    'invalid_action_params.json': 'illegal_action',
    'arbitrary_url_action.json': 'illegal_action',
    'unknown_major.json': 'unknown_major',
  };

  for (final entry in expectedReasonByFile.entries) {
    testWidgets('共用样例 ${entry.key} 整页退回标准布局，记录原因 ${entry.value}', (
      tester,
    ) async {
      final sample = loadSample('invalid', entry.key);
      final env = await pumpWithSample(tester, sample);

      expectStandardTodayLayout();
      expectAllTabsPresent();

      final events = composedEvents(env);
      expect(events, hasLength(1));
      expect(events.single['is_fallback'], true);
      expect(events.single['fallback_reason'], entry.value);
      expect(events.single['components'], isEmpty);
    });
  }

  testWidgets('缺必显组件的共用样例：没有页面类型要求它时不算不合法，不走兜底', (tester) async {
    final sample = loadSample('invalid', 'missing_required_component.json');
    final env = await pumpWithSample(tester, sample);

    // 样例本身 components 是空数组，且 today 默认没有必显组件要求，所以这是一份
    // "合法但没有组件"的描述，不应该被当成兜底（不记 is_fallback 的组合展示事件）。
    final events = composedEvents(env);
    expect(events, hasLength(1));
    expect(events.single['is_fallback'], false);
  });

  testWidgets('缺必显组件的共用样例：临时给 today 注册必显组件后整页退回标准布局', (tester) async {
    final sample = loadSample('invalid', 'missing_required_component.json');
    final env = await pumpWithSample(
      tester,
      sample,
      requiredComponentTypes: {
        'today': {'hint_bar'},
      },
    );

    expectStandardTodayLayout();
    expectAllTabsPresent();

    final events = composedEvents(env);
    expect(events, hasLength(1));
    expect(events.single['is_fallback'], true);
    expect(events.single['fallback_reason'], 'missing_required');
  });

  testWidgets('服务端直接下发 fallback 非空的描述时也整页退回标准布局', (tester) async {
    final sample = {
      'protocol': '1.0',
      'page_type': 'today',
      'composition_id': '00000000-0000-4000-8000-0000000000f1',
      'generated_at': '2026-09-28T10:30:00Z',
      'cache': {'depends_on': <String, String>{}, 'ttl_s': 0},
      'experiment': null,
      'fallback': {'reason_code': 'server_error'},
      'components': <Object?>[],
    };
    final env = await pumpWithSample(tester, sample);

    expectStandardTodayLayout();
    final events = composedEvents(env);
    expect(events, hasLength(1));
    expect(events.single['is_fallback'], true);
    expect(events.single['fallback_reason'], 'server_error');
  });

  testWidgets('服务端接口 500 时整页退回标准布局，记录 server_error', (tester) async {
    final server = FakeServer();
    server.on(
      'POST',
      '/v1/ui/compositions',
      (r) => FakeServer.error(500, 'internal', '出错了'),
    );
    final env = TestEnv.signedIn(server: server);
    await pumpApp(tester, env: env);

    expectStandardTodayLayout();
    final events = composedEvents(env);
    expect(events, hasLength(1));
    expect(events.single['is_fallback'], true);
    expect(events.single['fallback_reason'], 'server_error');
  });

  testWidgets('等待超过配置的时限时整页退回标准布局，记录 timeout，不一直等', (tester) async {
    final server = FakeServer();
    server.on('POST', '/v1/ui/compositions', (r) async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return (
        200,
        {
          'protocol': '1.0',
          'page_type': 'today',
          'composition_id': '00000000-0000-4000-8000-0000000000f2',
          'generated_at': '2026-09-28T10:30:00Z',
          'cache': {
            'depends_on': {'plan': 'v0'},
            'ttl_s': 600,
          },
          'experiment': null,
          'components': [
            {
              'type': 'hint_bar',
              'id': 'c1',
              'detail': 'brief',
              'data': {'conclusion': '先添加一道你常做的菜'},
              'actions': <Object?>[],
              'reason': {'code': 'default', 'text': '默认组合'},
              'required': false,
            },
          ],
        },
      );
    });
    final env = TestEnv.signedIn(
      server: server,
      params: const {'ui.composition_timeout_ms': 50},
    );
    await pumpApp(tester, env: env);

    // 超时先显示标准布局，不会等那条延迟 300ms 才到的真实数据把它换掉。
    expectStandardTodayLayout();
    expect(find.text('先添加一道你常做的菜'), findsNothing);

    // pumpAndSettle 在 Provider 落定（在虚拟时间 50ms 时就已经因为超时完成）后就
    // 不再继续推进虚拟时钟，但 FakeServer 里那条延迟 300ms 的 Future/Timer 还挂着；
    // 显式再推进一段时间，让它正常触发完，避免测试结束时"还有定时器没触发"报错
    // （这条迟到的响应本身会被丢弃，不影响上面的断言）。
    await tester.pump(const Duration(milliseconds: 400));

    final events = composedEvents(env);
    expect(events, hasLength(1));
    expect(events.single['is_fallback'], true);
    expect(events.single['fallback_reason'], 'timeout');
  });

  testWidgets('等待时限来自服务端下发的配置项，调大之后能等到真实结果', (tester) async {
    final server = FakeServer();
    server.on('POST', '/v1/ui/compositions', (r) async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return (
        200,
        {
          'protocol': '1.0',
          'page_type': 'today',
          'composition_id': '00000000-0000-4000-8000-0000000000f3',
          'generated_at': '2026-09-28T10:30:00Z',
          'cache': {
            'depends_on': {'plan': 'v0'},
            'ttl_s': 600,
          },
          'experiment': null,
          'components': [
            {
              'type': 'hint_bar',
              'id': 'c1',
              'detail': 'brief',
              'data': {'conclusion': '先添加一道你常做的菜'},
              'actions': <Object?>[],
              'reason': {'code': 'default', 'text': '默认组合'},
              'required': false,
            },
          ],
        },
      );
    });
    final env = TestEnv.signedIn(
      server: server,
      params: const {'ui.composition_timeout_ms': 2000},
    );
    await pumpApp(tester, env: env);

    expect(find.text('先添加一道你常做的菜'), findsOneWidget);
    final events = composedEvents(env);
    expect(events, hasLength(1));
    expect(events.single['is_fallback'], false);
  });

  testWidgets('同大版本、更高小版本且多出未知字段的描述照常渲染', (tester) async {
    final valid = loadSample('valid', 'today_default.json');
    final forwardCompatible = {
      ...valid,
      'protocol': '1.7',
      'future_top_level_field': {'anything': true},
      'components': [
        for (final raw in valid['components'] as List)
          {...raw as Map<String, dynamic>, 'future_component_field': 'x'},
      ],
    };
    final env = await pumpWithSample(tester, forwardCompatible);

    expect(find.text('先添加一道你常做的菜'), findsOneWidget);
    expect(find.text('今天还没有安排'), findsOneWidget);
    final events = composedEvents(env);
    expect(events, hasLength(1));
    expect(events.single['is_fallback'], false);
  });

  testWidgets('任何描述（包括异常描述）下，底部五入口都不变', (tester) async {
    final sample = loadSample('invalid', 'unknown_major.json');
    await pumpWithSample(tester, sample);
    expectAllTabsPresent();
  });
}
