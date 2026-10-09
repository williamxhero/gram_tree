import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gram_tree/app/router.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/features/create/create_page.dart';
import 'package:gram_tree/ui_protocol/intent_dispatcher.dart';
import 'package:gram_tree/network/online_features.dart';
import 'package:gram_tree/network/reachability.dart';
import 'package:gram_tree/ui_protocol/component_registry.dart';
import 'package:gram_tree/ui_protocol/components/text_block_component.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';

void main() {
  testWidgets(
    'connection lost after rendering blocks tap and keyboard submission before business request',
    (tester) async {
      final env = TestEnv.signedIn();
      await pumpApp(tester, env: env);
      await tapTab(tester, 2);
      await tester.tap(find.byKey(const ValueKey('one-line-recipe-entry')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('one-line-input')),
        '不辣的鸡丁',
      );
      env.reachability.reachable = false;
      await tester.tap(find.byKey(const ValueKey('one-line-search')));
      await tester.pumpAndSettle();
      expect(find.textContaining('需要联网'), findsWidgets);
      expect(find.text('不辣的鸡丁'), findsOneWidget);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(env.server.calls('POST', '/v1/ai/recipes/requests'), isEmpty);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('ai-manual-fallback')),
      );
      expect(find.byKey(const ValueKey('recipe-dish-name')), findsOneWidget);
    },
  );

  testWidgets('protocol card disables only online action, not local detail', (
    tester,
  ) async {
    var result = '尚未执行';
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => OnlineActionAvailability(
              status: ApiReachability.unavailable,
              child: Builder(
                builder: (context) => Column(
                  children: [
                    Text(result),
                    buildTextBlockComponent(
                      context,
                      ComponentDescriptor(
                        type: 'text_block',
                        id: 'mixed',
                        reason: ComponentReason(code: 'default', text: '默认组合'),
                        detail: ComponentDescriptorDetailEnum.detailed,
                        data: {
                          'conclusion': '已有缓存',
                          'action_label': '重新计算',
                          'detail_label': '查看本机',
                        },
                        actions: [
                          ActionDescriptor(
                            intent: 'call_operation',
                            params: {'operation': 'recalculate_plan'},
                          ),
                          ActionDescriptor(
                            intent: 'open_page',
                            params: {'page': 'my_recipes'},
                          ),
                        ],
                      ),
                      const ComponentEmptyState(title: '无内容'),
                      (action) => setState(
                        () => result = action.intent == 'open_page'
                            ? '打开本机内容'
                            : '不应重算',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('重新计算'));
    await tester.pump();
    expect(find.text('不应重算'), findsNothing);
    await tester.tap(find.text('查看本机'));
    await tester.pump();
    expect(find.text('打开本机内容'), findsOneWidget);
  });

  testWidgets(
    'online open-page intent cannot bypass offline entry enforcement',
    (tester) async {
      final env = TestEnv.signedIn(offline: true);
      await pumpApp(tester, env: env);
      await tapTab(tester, 2);
      final context = tester.element(find.byType(CreatePage));
      final container = ProviderScope.containerOf(context);
      await container
          .read(intentDispatcherProvider)
          .dispatch(
            context,
            compositionId: 'composition',
            componentId: 'entry',
            action: ActionDescriptor(
              intent: 'open_page',
              params: {'page': 'one_line_recipe'},
            ),
          );
      await tester.pumpAndSettle();
      expect(find.byType(CreatePage), findsOneWidget);
      expect(find.byKey(const ValueKey('one-line-input')), findsNothing);
      expect(find.textContaining('需要联网'), findsWidgets);
    },
  );

  testWidgets(
    'API loss disables online entry and a direct route, recovery restores them',
    (tester) async {
      final env = TestEnv.signedIn();
      await pumpApp(tester, env: env);
      await tapTab(tester, 2);
      env.reachability.reachable = false;
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
      expect(find.textContaining('需要联网'), findsWidgets);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CreatePage)),
      );
      container.read(routerProvider).push('/recipes/one-line');
      await tester.pumpAndSettle();
      expect(find.textContaining('需要联网'), findsWidgets);
      await tester.enterText(
        find.byKey(const ValueKey('one-line-input')),
        '保留我的原话',
      );
      await tester.tap(find.byKey(const ValueKey('one-line-search')));
      await tester.pumpAndSettle();
      expect(env.server.calls('POST', '/v1/ai/recipes/requests'), isEmpty);
      env.reachability.reachable = true;
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
      expect(find.text('保留我的原话'), findsOneWidget);
      expect(find.textContaining('需要联网'), findsNothing);
    },
  );

  testWidgets(
    'offline AI entry explains connectivity while manual creation remains usable',
    (tester) async {
      final env = TestEnv.signedIn(offline: true);
      await pumpApp(tester, env: env);
      await tapTab(tester, 2);
      expect(find.textContaining('需要联网'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('one-line-recipe-entry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('one-line-input')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('create-recipe-entry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('recipe-dish-name')), findsOneWidget);
      expect(env.server.calls('POST', '/v1/ai/recipes/requests'), isEmpty);
    },
  );
}
