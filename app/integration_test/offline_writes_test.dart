// Profile Chromium journey against the real backend. The webpage queue is an
// in-memory substitute: disk durability is asserted ONLY by the Android harness.
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/api/api_client.dart';
import 'package:gram_tree/app/app.dart';
import 'package:gram_tree/app/bootstrap.dart';
import 'package:gram_tree/config/app_config.dart';
import 'package:gram_tree/network/reachability.dart';
import 'package:integration_test/integration_test.dart';

import 'event_pipeline_support.dart' as support;
import 'offline_writes_support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'offline saves replay once, measures reconcile, logout retains A/B/A',
    (tester) async {
      if (!kIsWeb) {
        return; // Native acceptance uses actual adb force-stop/relaunch.
      }
      final previousReporter = reportTestException;
      reportTestException = (details, description) {
        binding.reportData = {
          ...?binding.reportData,
          'framework_error': details.exceptionAsString(),
          'framework_stack': details.stack?.toString(),
          'framework_context': description,
        };
        previousReporter(details, description);
      };
      addTearDown(() => reportTestException = previousReporter);
      try {
        acceptanceStep('bootstrap and consent');
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        tester.testTextInput.register();
        addTearDown(tester.testTextInput.unregister);
        await support.resetLocalAppState();
        final container = ProviderContainer(
          overrides: [
            ...await bootstrapOverrides(),
            apiReachabilityProbeProvider.overrideWith((ref) {
              final probe = AcceptanceOutageProbe(
                () => ref.read(offlineSimulationProvider),
                HttpApiReachabilityProbe(
                  AppConfig.fromEnvironment().apiBaseUrl,
                ),
              );
              ref.onDispose(probe.dispose);
              return probe;
            }),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const GramTreeApp(),
          ),
        );
        await support.waitFor(
          tester,
          find.byKey(const ValueKey('consent-agree')),
        );
        await revealAcceptance(
          tester,
          find.byKey(const ValueKey('consent-agree')),
        );
        await tester.tap(find.byKey(const ValueKey('consent-agree')));
        final email =
            'offline-writes-${DateTime.now().microsecondsSinceEpoch}@example.com';
        await loginAcceptance(tester, email);
        final recipe = await seedAcceptanceRecipe(
          support.devServer,
          support.accessTokenOf(container),
        );
        final manifest = await seedOfflineBusinessWrites(
          tester,
          container,
          support.devServer,
          recipeId: recipe['id'] as String,
          versionId: (recipe['version'] as Map)['id'] as String,
          stepId: 'step-1',
          email: email,
        );
        await showRestoredOfflineBusiness(tester, container, manifest);
        await retryAndSwitchAccounts(tester, container, manifest);
        await replayAndVerifyBusiness(
          tester,
          container,
          support.devServer,
          manifest,
        );
        await goAcceptance(tester, container, '/me/sync');
        await support.waitUntil(
          tester,
          () => find.text('未完成 0 条').evaluate().isNotEmpty,
        );
        expect(find.byKey(const ValueKey('sync-last-success')), findsOneWidget);
        expect(find.textContaining('上次服务端确认'), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('sync-manual-retry')),
              )
              .onPressed,
          isNull,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      } catch (error, stack) {
        binding.reportData = {
          ...?binding.reportData,
          'e2e_error': error is DioException
              ? 'DioException ${error.type.name} status=${error.response?.statusCode}'
              : error.toString(),
          'e2e_stack': stack.toString(),
          'visible_text': [
            for (final text in tester.widgetList<Text>(find.byType(Text)))
              if (text.data != null) text.data,
          ],
        };
        rethrow;
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
