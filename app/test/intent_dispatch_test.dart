import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/app.dart';
import 'package:gram_tree/ui_protocol/intent_dispatcher.dart';
import 'package:gram_tree/ui_protocol/intent_registry.dart';

import 'helpers.dart';

/// SPEC-009.1 #81：动作即意图——App 内置意图登记表、统一的意图派发入口、组件动作
/// 事件、来源组合 ID 传递。非法动作（未登记意图、参数格式错、任意网址）两端都判定
/// 为不合法这条验收标准，在 `composition_fallback_test.dart` 里和其它 SPEC-009.1
/// #79 的样例一起测（同一套 `expectedReasonByFile` 循环）。
void main() {
  group('意图登记表', () {
    test('打开页面类意图只能打开已登记页面，其余一律拒绝（含未登记页面名和任意网址）', () {
      expect(
        defaultIntentRegistry.isValidAction('open_page', {'page': 'create'}),
        isTrue,
      );
      expect(
        defaultIntentRegistry.isValidAction('open_page', {'page': 'history'}),
        isFalse,
        reason: '"history" 不是已登记的页面名',
      );
      expect(
        defaultIntentRegistry.isValidAction('open_page', {
          'page': 'https://evil.example.com/steal',
        }),
        isFalse,
        reason: '任意网址不是已登记的页面名，天然被拒绝',
      );
      expect(
        defaultIntentRegistry.isValidAction('open_page', const {}),
        isFalse,
        reason: '缺 page 参数',
      );
    });

    test('未登记的意图名一律不合法', () {
      expect(defaultIntentRegistry.isRegistered('delete_everything'), isFalse);
      expect(
        defaultIntentRegistry.isValidAction('delete_everything', const {}),
        isFalse,
      );
    });

    test('start_cooking/open_record_card/call_operation 的参数格式校验', () {
      expect(
        defaultIntentRegistry.isValidAction('start_cooking', {
          'recipe_version_id': 'rv-1',
        }),
        isTrue,
      );
      expect(
        defaultIntentRegistry.isValidAction('start_cooking', const {}),
        isFalse,
      );
      expect(
        defaultIntentRegistry.isValidAction('open_record_card', {
          'cooking_record_id': 'cr-1',
        }),
        isTrue,
      );
      expect(
        defaultIntentRegistry.isValidAction('open_record_card', const {}),
        isFalse,
      );
      expect(
        defaultIntentRegistry.isValidAction('call_operation', {
          'operation': 'op-1',
        }),
        isTrue,
      );
      expect(
        defaultIntentRegistry.isValidAction('call_operation', const {}),
        isFalse,
      );
    });

    test('存进口味/应用改动/这次不用/以后别这样先只登记名字和参数格式，处理器留给以后', () {
      for (final intent in [
        'save_to_taste',
        'apply_change',
        'skip_this_time',
        'dont_do_again',
      ]) {
        expect(
          defaultIntentRegistry.isRegistered(intent),
          isTrue,
          reason: intent,
        );
        expect(
          defaultIntentRegistry.isValidAction(intent, {'anything': 1}),
          isTrue,
          reason: intent,
        );
        expect(
          defaultIntentRegistry[intent]!.handler,
          isNull,
          reason: '$intent 的处理器留给以后的子 SPEC 补',
        );
      }
    });

    test('意图默认文案按登记表给，未登记的意图退回通用文案', () {
      expect(intentDefaultLabel('open_page'), '去看看');
      expect(intentDefaultLabel('start_cooking'), '开始做');
      expect(intentDefaultLabel('open_record_card'), '打开记录卡');
      expect(intentDefaultLabel('no_such_intent'), '去操作');
    });
  });

  group('统一意图派发入口', () {
    testWidgets('同一个意图从"整条可点"和"按钮"两个不同入口触发，调用同一个处理器，结果一致', (tester) async {
      // "今天"页的默认组合（helpers.dart 的 FakeServer）：hint_bar 是整条可点
      // （没有单独按钮），empty_state 有一个显式按钮——两个不同的组件、两种不同的
      // 触发方式，触发的是同一个意图 open_page/page=create。
      final env = await pumpApp(tester);

      await tester.tap(find.text('先添加一道你常做的菜'));
      await tester.pumpAndSettle();
      expect(find.text('想做点什么？'), findsOneWidget);

      await tapTab(tester, 0);
      await tester.tap(find.text('添加第一道菜谱'));
      await tester.pumpAndSettle();
      expect(find.text('想做点什么？'), findsOneWidget);

      final events = env.server
          .calls('POST', '/v1/events/upload')
          .expand((r) => ((r.body as Map)['events'] as List).cast<Map>())
          .where((e) => e['event_type'] == 'ui.component_action')
          .toList();
      expect(events, hasLength(2));
      for (final event in events) {
        expect(event['type_version'], 1);
        expect(
          (event['correlation'] as Map)['ui_composition_id'],
          '7c9e6679-7425-40de-944b-e07fc1f90ae7',
        );
        expect(event['content'], {
          'component_id': isA<String>(),
          'intent': 'open_page',
        });
      }
      // 两次触发分别来自 hint_bar（c1）和 empty_state（c2）——不同的组件实例，
      // 同一个意图、同一个处理器，最终结果一致（都跳到新建页）。
      expect(
        events.map((e) => (e['content'] as Map)['component_id']),
        containsAll(['c1', 'c2']),
      );
    });
  });

  group('来源组合 ID 传递', () {
    testWidgets('从组合页面跳转到下一页时，来源组合 ID 被带上，别处能读到', (tester) async {
      await pumpApp(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GramTreeApp)),
      );
      expect(
        container.read(sourceCompositionIdProvider),
        isNull,
        reason: '还没有触发任何组件动作',
      );

      await tester.tap(find.text('先添加一道你常做的菜'));
      await tester.pumpAndSettle();

      expect(
        container.read(sourceCompositionIdProvider),
        '7c9e6679-7425-40de-944b-e07fc1f90ae7',
        reason: '这条组合展示（helpers.dart 默认组合）的 composition_id',
      );
    });
  });
}
