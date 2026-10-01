import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// SPEC-009.1 #77：“今天”页由服务端默认组合渲染，出问题时先退回和之前一样的
/// 静态空态（完整的兜底原因记录在 #79）。
///
/// SPEC-009.1 票 2（#78）：显示成功后记一条带组合 ID 的“组合展示”事件。
void main() {
  testWidgets('今天页由服务端默认组合渲染，显示提示条和标准空态', (tester) async {
    final env = await pumpApp(tester);
    expect(find.text('先添加一道你常做的菜'), findsOneWidget);
    expect(find.text('今天还没有安排'), findsOneWidget);
    expect(find.text('这里会显示今天要做的菜'), findsOneWidget);
    expect(find.text('添加第一道菜谱'), findsOneWidget);

    final calls = env.server.calls('POST', '/v1/ui/compositions').toList();
    expect(calls, hasLength(1));
    final body = calls.single.body as Map;
    expect(body['page_type'], 'today');
    expect(body['protocol_version'], '1.0');
    // SPEC-009.1 #80 把通用组件库补齐到五个，#82 又加了仅测试用的 source_demo，
    // App 声明支持的组件类型清单也跟着变。
    expect((body['supported_components'] as List).toSet(), {
      'hint_bar',
      'section_title',
      'text_block',
      'list',
      'empty_state',
      'recipe_header',
      'recipe_ingredients',
      'recipe_steps',
      'recipe_card',
      'source_demo',
    });
  });

  testWidgets('今天页显示后记录一条带组合 ID 的组合展示事件', (tester) async {
    // 已登录联网时记事件后会立刻在后台传上去（event_recorder_test.dart），
    // 到 pumpAndSettle 结束时这条事件多半已经从本机队列（FakeEventQueue）挪走、
    // 传给了 /v1/events/upload，所以断言看服务端收到了什么，而不是本机队列里
    // 还剩什么。
    final env = await pumpApp(tester);

    final uploaded = env.server
        .calls('POST', '/v1/events/upload')
        .expand((r) => ((r.body as Map)['events'] as List).cast<Map>())
        .where((e) => e['event_type'] == 'ui.composition_shown')
        .toList();
    expect(uploaded, hasLength(1));
    final event = uploaded.single;
    expect(event['type_version'], 1);
    expect(
      (event['correlation'] as Map)['ui_composition_id'],
      '7c9e6679-7425-40de-944b-e07fc1f90ae7',
    );
    expect(event['content'], {
      'page_type': 'today',
      'components': [
        {
          'type': 'hint_bar',
          'detail': 'brief',
          'reason_code': 'default',
          'reason_text': '默认组合',
        },
        {
          'type': 'empty_state',
          'detail': 'standard',
          'reason_code': 'default',
          'reason_text': '默认组合',
        },
      ],
      'is_fallback': false,
    });
  });

  testWidgets('点提示条跳到新建页', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('先添加一道你常做的菜'));
    await tester.pumpAndSettle();
    expect(find.text('想做点什么？'), findsOneWidget);
  });

  testWidgets('服务端下发未登记的组件类型时，整页退回标准布局', (tester) async {
    final server = FakeServer();
    server.on('POST', '/v1/ui/compositions', (r) {
      return (
        200,
        {
          'protocol': '1.0',
          'page_type': 'today',
          'composition_id': '00000000-0000-4000-8000-000000000000',
          'generated_at': '2026-09-28T10:30:00Z',
          'cache': {'depends_on': <String, String>{}, 'ttl_s': 600},
          'experiment': null,
          'components': [
            {
              'type': 'mystery_widget',
              'id': 'x1',
              'detail': 'brief',
              'data': <String, Object?>{},
              'actions': <Object?>[],
              'reason': {'code': 'default', 'text': '默认组合'},
              'required': false,
            },
          ],
        },
      );
    });
    await pumpApp(tester, env: TestEnv.signedIn(server: server));

    expect(find.text('先添加一道你常做的菜'), findsNothing);
    expect(find.text('今天还没有安排'), findsOneWidget);
    expect(find.text('添加第一道菜谱'), findsOneWidget);
  });

  testWidgets('组件数据不符合 Schema 时，整页退回标准布局', (tester) async {
    final server = FakeServer();
    server.on('POST', '/v1/ui/compositions', (r) {
      return (
        200,
        {
          'protocol': '1.0',
          'page_type': 'today',
          'composition_id': '00000000-0000-4000-8000-000000000000',
          'generated_at': '2026-09-28T10:30:00Z',
          'cache': {'depends_on': <String, String>{}, 'ttl_s': 600},
          'experiment': null,
          'components': [
            {
              // hint_bar 的 Schema 要求 conclusion 是必填字段
              'type': 'hint_bar',
              'id': 'c1',
              'detail': 'brief',
              'data': <String, Object?>{},
              'actions': <Object?>[],
              'reason': {'code': 'default', 'text': '默认组合'},
              'required': false,
            },
          ],
        },
      );
    });
    await pumpApp(tester, env: TestEnv.signedIn(server: server));

    expect(find.text('今天还没有安排'), findsOneWidget);
    expect(find.text('添加第一道菜谱'), findsOneWidget);
  });

  testWidgets('服务端接口出错时，整页退回标准布局', (tester) async {
    final server = FakeServer();
    server.on(
      'POST',
      '/v1/ui/compositions',
      (r) => FakeServer.error(500, 'internal', '出错了'),
    );
    await pumpApp(tester, env: TestEnv.signedIn(server: server));

    expect(find.text('今天还没有安排'), findsOneWidget);
    expect(find.text('添加第一道菜谱'), findsOneWidget);
  });
}
