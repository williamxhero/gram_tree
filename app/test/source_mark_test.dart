import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/l10n/app_localizations.dart';
import 'package:gram_tree/ui_protocol/source_mark.dart';

import 'helpers.dart';

/// SPEC-009.1 #82：来源标记与"为什么"面板——统一标记样式、原值与依据、"这次不用"和
/// "以后别这样"。用 `source_demo`（仅测试用的示例组件，见
/// `contracts/ui_protocol/schema/1.0/components/source_demo.schema.json`）驱动整条
/// "标记 -> 点开 -> 面板 -> 反馈" 链路，不依赖任何真实换算内容（本子 SPEC 还没有）。
void main() {
  Map<String, dynamic> sourceDemoComponent({
    required String id,
    required String conclusion,
    required String sourceType,
    String value = '3 g',
    String? originalValue = '5 g',
    String basisText = '你最近几次做菜都调低了盐量',
    String? citation = '口味档案更新于 2026-09-20',
    bool required = false,
  }) => {
    'type': 'source_demo',
    'id': id,
    'detail': 'standard',
    'data': {
      'conclusion': conclusion,
      'source': {
        'source_type': sourceType,
        'value': value,
        'original_value': ?originalValue,
        'basis': {
          'reason_code': 'demo',
          'text': basisText,
          'citation': ?citation,
        },
      },
    },
    'actions': <Object?>[],
    'reason': {'code': 'source_demo', 'text': '仅用于测试来源标记链路的示例组件'},
    'required': required,
  };

  Map<String, dynamic> composition(List<Map<String, dynamic>> components) => {
    'protocol': '1.0',
    'page_type': 'today',
    'composition_id': '11111111-1111-4111-8111-111111111111',
    'generated_at': '2026-09-28T10:30:00Z',
    'cache': {'depends_on': <String, String>{}, 'ttl_s': 600},
    'experiment': null,
    'components': components,
  };

  List<Map<String, dynamic>> uploadedEvents(TestEnv env, String eventType) =>
      env.server
          .calls('POST', '/v1/events/upload')
          .expand((r) => ((r.body as Map)['events'] as List).cast<Map>())
          .where((e) => e['event_type'] == eventType)
          .cast<Map<String, dynamic>>()
          .toList();

  testWidgets('作者填写不显示来源标记，其它来源类型都显示同一套标记', (tester) async {
    final server = FakeServer();
    server.on(
      'POST',
      '/v1/ui/compositions',
      (r) => (
        200,
        composition([
          sourceDemoComponent(
            id: 'c1',
            conclusion: '作者写的用量',
            sourceType: 'author_filled',
            originalValue: null,
          ),
          sourceDemoComponent(
            id: 'c2',
            conclusion: '换算过的用量',
            sourceType: 'taste_adjusted',
          ),
          sourceDemoComponent(
            id: 'c3',
            conclusion: '已验证的用量',
            sourceType: 'verified',
          ),
          sourceDemoComponent(
            id: 'c4',
            conclusion: 'AI 估算的用量',
            sourceType: 'ai_estimated',
          ),
        ]),
      ),
    );
    await pumpApp(tester, env: TestEnv.signedIn(server: server));

    // 作者填写：结论显示，但没有来源标记（没有对应的标记文案）。
    expect(find.text('作者写的用量'), findsOneWidget);
    expect(find.text('作者填写'), findsNothing);

    // 其它三种都显示各自的标记文案，同一套渲染方式（SourceMark）。
    expect(find.text('按你的口味换算'), findsOneWidget);
    expect(find.text('已验证'), findsOneWidget);
    expect(find.text('AI 估算'), findsOneWidget);

    final theme = buildTheme(Brightness.light);
    final colors = theme.extension<GramTreeColors>()!;
    final tasteAdjustedStyle = tester.widget<Text>(find.text('按你的口味换算')).style!;
    expect(tasteAdjustedStyle.color, colors.accent, reason: '按你的口味换算用酱红');
    final verifiedStyle = tester.widget<Text>(find.text('已验证')).style!;
    expect(verifiedStyle.color, colors.verified, reason: '已验证用绿');
    final aiEstimatedStyle = tester.widget<Text>(find.text('AI 估算')).style!;
    expect(
      aiEstimatedStyle.color,
      theme.colorScheme.onSurfaceVariant,
      reason: 'AI 估算用中性色',
    );
  });

  testWidgets('点任何来源标记都打开同一个为什么面板，显示原值、依据、来源引用和两个反馈动作，并记录打开事件', (tester) async {
    final server = FakeServer();
    server.on(
      'POST',
      '/v1/ui/compositions',
      (r) => (
        200,
        composition([
          sourceDemoComponent(
            id: 'c3',
            conclusion: '建议用盐 3 g',
            sourceType: 'taste_adjusted',
          ),
        ]),
      ),
    );
    final env = await pumpApp(tester, env: TestEnv.signedIn(server: server));

    await tester.tap(find.text('按你的口味换算'));
    await tester.pumpAndSettle();

    expect(find.text('原来：5 g'), findsOneWidget);
    expect(find.text('现在：3 g'), findsOneWidget);
    expect(find.text('你最近几次做菜都调低了盐量'), findsOneWidget);
    expect(find.text('口味档案更新于 2026-09-20'), findsOneWidget);
    expect(find.text('这次不用'), findsOneWidget);
    expect(find.text('以后别这样'), findsOneWidget);

    final opened = uploadedEvents(env, 'ui.why_panel_opened');
    expect(opened, hasLength(1));
    expect(opened.single['type_version'], 1);
    expect(
      (opened.single['correlation'] as Map)['ui_composition_id'],
      '11111111-1111-4111-8111-111111111111',
    );
    expect(opened.single['content'], {
      'component_id': 'c3',
      'source_type': 'taste_adjusted',
    });
  });

  testWidgets('来源依据为空时仍显示本地化的可用说明', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: WhyPanel(
            sourceType: 'verified',
            value: '6 克',
            basisText: '',
            required: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('暂无可显示的依据'), findsOneWidget);
  });

  testWidgets('必显内容上的面板没有这次不用/以后别这样，只说明这是必显内容', (tester) async {
    final server = FakeServer();
    server.on(
      'POST',
      '/v1/ui/compositions',
      (r) => (
        200,
        composition([
          sourceDemoComponent(
            id: 'c9',
            conclusion: '过敏提示：含花生',
            sourceType: 'ai_estimated',
            required: true,
          ),
        ]),
      ),
    );
    await pumpApp(tester, env: TestEnv.signedIn(server: server));

    await tester.tap(find.text('AI 估算'));
    await tester.pumpAndSettle();

    expect(find.text('这是必显内容，不能关掉'), findsOneWidget);
    expect(find.text('这次不用'), findsNothing);
    expect(find.text('以后别这样'), findsNothing);
  });

  testWidgets('"这次不用"：走票 5 的意图派发，记来源反馈事件，调用服务端接口拿到去掉调整后的结果并更新显示', (
    tester,
  ) async {
    final server = FakeServer();
    server.on(
      'POST',
      '/v1/ui/compositions',
      (r) => (
        200,
        composition([
          sourceDemoComponent(
            id: 'c3',
            conclusion: '建议用盐 3 g',
            sourceType: 'taste_adjusted',
          ),
        ]),
      ),
    );
    server.on('POST', '/v1/ui/compositions/skip-adjustment', (r) {
      expect((r.body as Map)['component_id'], 'c3');
      return (
        200,
        {
          'component_id': 'c3',
          'source': {
            'source_type': 'author_filled',
            'value': '5 g',
            'basis': {
              'reason_code': 'skip_adjustment',
              'text': '已去掉按你的口味换算的调整，显示菜谱原文用量',
            },
          },
        },
      );
    });
    final env = await pumpApp(tester, env: TestEnv.signedIn(server: server));

    await tester.tap(find.text('按你的口味换算'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('这次不用'));
    await tester.pumpAndSettle();

    // 面板关闭，标记按服务端退回的结果变成"作者填写"（不再显示标记）。
    expect(find.text('这次不用'), findsNothing);
    expect(find.text('按你的口味换算'), findsNothing);

    expect(
      server.calls('POST', '/v1/ui/compositions/skip-adjustment'),
      hasLength(1),
    );

    final actions = uploadedEvents(env, 'ui.component_action');
    expect(actions, hasLength(1));
    expect(actions.single['content'], {
      'component_id': 'c3',
      'intent': 'skip_this_time',
    });

    final feedback = uploadedEvents(env, 'ui.source_feedback');
    expect(feedback, hasLength(1));
    expect(feedback.single['content'], {
      'component_id': 'c3',
      'source_type': 'taste_adjusted',
      'feedback': 'skip_once',
    });
    expect(
      (feedback.single['correlation'] as Map)['ui_composition_id'],
      '11111111-1111-4111-8111-111111111111',
    );
  });

  testWidgets('"以后别这样"：走票 5 的意图派发，只记来源反馈事件，不调用服务端接口、不改变显示', (tester) async {
    final server = FakeServer();
    server.on(
      'POST',
      '/v1/ui/compositions',
      (r) => (
        200,
        composition([
          sourceDemoComponent(
            id: 'c3',
            conclusion: '建议用盐 3 g',
            sourceType: 'taste_adjusted',
          ),
        ]),
      ),
    );
    final env = await pumpApp(tester, env: TestEnv.signedIn(server: server));

    await tester.tap(find.text('按你的口味换算'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('以后别这样'));
    await tester.pumpAndSettle();

    // 标记显示不变——"以后别这样"不重算这次查看的内容。
    expect(find.text('按你的口味换算'), findsOneWidget);
    expect(
      server.calls('POST', '/v1/ui/compositions/skip-adjustment'),
      isEmpty,
    );

    final actions = uploadedEvents(env, 'ui.component_action');
    expect(actions, hasLength(1));
    expect(actions.single['content'], {
      'component_id': 'c3',
      'intent': 'dont_do_again',
    });

    final feedback = uploadedEvents(env, 'ui.source_feedback');
    expect(feedback, hasLength(1));
    expect(feedback.single['content'], {
      'component_id': 'c3',
      'source_type': 'taste_adjusted',
      'feedback': 'never_again',
    });
  });
}
