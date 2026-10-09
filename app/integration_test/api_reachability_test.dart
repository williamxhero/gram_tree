import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/router.dart';
import 'package:gram_tree/features/create/create_page.dart';
import 'package:gram_tree/network/reachability.dart';
import 'package:gram_tree/ui_protocol/intent_dispatcher.dart';
import 'package:gramtree_api/gramtree_api.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers.dart';

/// Actual browser HTTP transport (not offlineSimulationProvider). Business
/// fixtures remain generated-contract fakes; no model call or user upload.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment(
    'REACHABILITY_TEST_URL',
    defaultValue: 'http://127.0.0.1:8766',
  );

  testWidgets(
    'production probe respects consent, API failures disable entries, local editing and recovery work',
    (tester) async {
      tester.testTextInput.register();
      addTearDown(tester.testTextInput.unregister);
      final control = Dio(BaseOptions(baseUrl: url));
      addTearDown(() => control.close(force: true));
      await control.post('/test/state', data: {'mode': 'ok', 'reset': true});
      final probe = HttpApiReachabilityProbe(url);
      addTearDown(probe.dispose);
      final signedIn = TestEnv.signedIn();
      final env = TestEnv(secure: signedIn.secure, probe: probe);
      await pumpApp(tester, env: env);
      expect(find.byKey(const ValueKey('consent-agree')), findsOneWidget);
      expect((await control.get<List<dynamic>>('/test/probes')).data, isEmpty);
      await tapVisible(tester, find.byKey(const ValueKey('consent-agree')));
      await tapTab(tester, 2);

      Future<void> waitForConnection(bool online) async {
        for (var i = 0; i < 220; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          final texts = tester
              .widgetList<Text>(find.byType(Text))
              .map((t) => t.data ?? '')
              .join();
          if (online ? !texts.contains('需要联网') : texts.contains('暂时连接不到服务')) {
            return;
          }
        }
        fail('Connection UI did not reach expected online=$online');
      }

      await waitForConnection(true);
      for (final mode in ['unhealthy', 'portal', 'disconnect']) {
        await control.post('/test/state', data: {'mode': mode});
        // The app's production periodic monitor detects API loss without a test
        // offline switch or a manual controller state mutation.
        await waitForConnection(false);
        await tester.tap(find.byKey(const ValueKey('one-line-recipe-entry')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('one-line-input')), findsNothing);
        await control.post('/test/state', data: {'mode': 'ok'});
        await waitForConnection(true);
      }

      // Lose connectivity after the button rendered: the execution preflight
      // prevents sending even the one-line text, while preserving that text.
      await tester.tap(find.byKey(const ValueKey('one-line-recipe-entry')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('one-line-input')),
        '保留这句话',
      );
      await control.post('/test/state', data: {'mode': 'unhealthy'});
      await tester.tap(find.byKey(const ValueKey('one-line-search')));
      await waitForConnection(false);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(env.server.calls('POST', '/v1/ai/recipes/requests'), isEmpty);
      expect(find.text('保留这句话'), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('ai-manual-fallback')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('recipe-dish-name')),
        '离线手工菜谱',
      );
      expect(find.text('离线手工菜谱'), findsOneWidget);

      final context = tester.element(
        find.byKey(const ValueKey('recipe-dish-name')),
      );
      final container = ProviderScope.containerOf(context);
      container.read(routerProvider).go('/create');
      await tester.pumpAndSettle();
      final createContext = tester.element(find.byType(CreatePage));
      await container
          .read(intentDispatcherProvider)
          .dispatch(
            createContext,
            compositionId: 'test',
            componentId: 'online-entry',
            action: ActionDescriptor(
              intent: 'open_page',
              params: {'page': 'one_line_recipe'},
            ),
          );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('one-line-input')), findsNothing);
      container.read(routerProvider).go('/recipes/one-line');
      await tester.pumpAndSettle();
      expect(find.textContaining('需要联网'), findsWidgets);
      expect(env.server.calls('POST', '/v1/ai/recipes/requests'), isEmpty);
      await control.post('/test/state', data: {'mode': 'ok'});
      await waitForConnection(true);

      final probes = (await control.get<List<dynamic>>('/test/probes')).data!;
      expect(probes, isNotEmpty);
      for (final request in probes.cast<Map<String, dynamic>>()) {
        expect(request, {
          'method': 'GET',
          'path': '/v1/health',
          'has_authorization': false,
          'has_device_id': false,
          'body_size': 0,
        });
      }
      await tester.pumpWidget(const SizedBox());
    },
    skip: !kIsWeb,
  ); // Browser fixture; physical network changes require a device.
}
