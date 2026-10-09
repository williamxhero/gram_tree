import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/router.dart';
import 'package:gram_tree/api/api_client.dart';
import 'package:gram_tree/network/reachability.dart';
import 'package:gram_tree/recipes/recipe_snapshot.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';
import 'recipe_snapshot_test.dart' show recipeSnapshotFixture;

const recipeId = '11111111-1111-4111-8111-111111111111';
const versionId = '22222222-2222-4222-8222-222222222222';

RecipeDetail ownedRecipe() =>
    recipeSnapshotFixture(versionId, recipe: recipeId).copyWith(
      author: RecipeAuthor(id: testUser().id, nickname: '作者'),
    );

Future<void> cacheRecipe(TestEnv env) async {
  await RecipeSnapshotStore(env.local, accountId: env.server.user.id).save(
    FrozenRecipeSnapshot(
      detail: ownedRecipe(),
      capturedAt: DateTime.utc(2026, 10, 1),
      inputs: const {},
      render: null,
      dependencies: const {},
    ),
  );
}

void navigate(WidgetTester tester, String route) {
  ProviderScope.containerOf(tester.element(find.byType(Scaffold).first))
      .read(routerProvider)
      .go(route);
}

Future<void> editAndSave(WidgetTester tester, String instruction) async {
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('recipe-step-instruction-boil')),
    400,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('recipe-editor-content')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.enterText(
    find.byKey(const ValueKey('recipe-step-instruction-boil')),
    instruction,
  );
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('save-recipe-button')),
    -400,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('recipe-editor-content')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
  await tester.pumpAndSettle();
}

void main() {
  for (final rejection in {
    'invalid_recipe': '同步失败：请检查食材和步骤后重新保存',
    'unexpected_reason_with_private_payload': '同步失败：修改已保留，请稍后重试',
  }.entries) {
    testWidgets(
      'recipe rejection shows a safe explanation and retains edits across restart: ${rejection.key}',
      (tester) async {
        final env = TestEnv.signedIn(offline: true);
        await cacheRecipe(env);
        await pumpApp(tester, env: env);
        navigate(tester, '/recipes/$recipeId/edit');
        await tester.pumpAndSettle();
        await editAndSave(tester, '被拒绝后仍保留的本机步骤');
        env.server.on(
          'POST',
          '/v1/sync/writes',
          (request) => (
            200,
            {
              'results': [
                for (final write in (request.body as Map)['writes'] as List)
                  {
                    'write_id': (write as Map)['write_id'],
                    'status': 'failed',
                    'reason_code': rejection.key,
                  },
              ],
            },
          ),
        );
        final container = ProviderScope.containerOf(
          tester.element(find.byType(Scaffold).first),
        );
        env.reachability.reachable = true;
        container.read(offlineSimulationProvider.notifier).set(false);
        await container.read(apiReachabilityProvider.notifier).check();
        await tester.pumpAndSettle();
        expect(find.text(rejection.value), findsOneWidget);
        expect(find.textContaining(rejection.key), findsNothing);
        expect(find.text('被拒绝后仍保留的本机步骤'), findsOneWidget);
        await restartApp(tester, env);
        navigate(tester, '/recipes');
        await tester.pumpAndSettle();
        expect(find.textContaining(rejection.value), findsOneWidget);
        expect(find.textContaining(rejection.key), findsNothing);
        await tester.tap(find.byKey(const ValueKey('recipe-card-$recipeId')));
        await tester.pumpAndSettle();
        expect(find.text(rejection.value), findsOneWidget);
        expect(find.text('被拒绝后仍保留的本机步骤'), findsOneWidget);
      },
    );
  }
  testWidgets(
    'recipe conflict keeps local content and list status across restart without choosing a winner',
    (tester) async {
      final env = TestEnv.signedIn(offline: true);
      await cacheRecipe(env);
      await pumpApp(tester, env: env);
      navigate(tester, '/recipes/$recipeId/edit');
      await tester.pumpAndSettle();
      await editAndSave(tester, '冲突中仍保留的本机步骤');
      env.server.on(
        'POST',
        '/v1/sync/writes',
        (request) => (
          200,
          {
            'results': [
              for (final write in (request.body as Map)['writes'] as List)
                {
                  'write_id': (write as Map)['write_id'],
                  'status': 'conflict',
                  'reason_code': 'conflict_choice_required',
                  'conflict': {
                    'local': (write['payload'] as Map)['candidate'],
                    'remote': ownedRecipe().toJson(),
                  },
                },
            ],
          },
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );
      env.reachability.reachable = true;
      container.read(offlineSimulationProvider.notifier).set(false);
      await container.read(apiReachabilityProvider.notifier).check();
      await tester.pumpAndSettle();
      expect(find.text('等待处理：两份修改均已保留'), findsOneWidget);
      expect(find.text('冲突中仍保留的本机步骤'), findsOneWidget);
      await restartApp(tester, env);
      navigate(tester, '/recipes');
      await tester.pumpAndSettle();
      expect(find.textContaining('等待处理：两份修改均已保留'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('recipe-card-$recipeId')));
      await tester.pumpAndSettle();
      expect(find.text('冲突中仍保留的本机步骤'), findsOneWidget);
      expect(find.text('等待处理：两份修改均已保留'), findsOneWidget);
      expect(find.text('用我这份'), findsNothing);
      expect(
        env.server.calls('POST', '/v1/recipes/$recipeId/versions'),
        isEmpty,
      );
    },
  );
  testWidgets(
    'cached offline manual save survives restart and confirms only one stable new version',
    (tester) async {
      final env = TestEnv.signedIn();
      await cacheRecipe(env);
      await pumpApp(tester, env: env);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );
      container.read(offlineSimulationProvider.notifier).set(true);
      env.reachability.reachable = false;
      navigate(tester, '/recipes/$recipeId/edit');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('recipe-step-instruction-boil')),
        400,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('recipe-editor-content')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(
        find.byKey(const ValueKey('recipe-step-instruction-boil')),
        '本机保存的小火步骤',
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('save-recipe-button')),
        -400,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('recipe-editor-content')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
      await tester.pumpAndSettle();
      expect(find.text('本机保存的小火步骤'), findsOneWidget);
      expect(find.text('待同步'), findsWidgets);
      expect(env.server.calls('POST', '/v1/recipes/safety-check'), isEmpty);
      expect(
        env.server.calls('POST', '/v1/recipes/$recipeId/versions'),
        isEmpty,
      );
      // Observe identities only on the public wire. The fake server commits the
      // first delivery but loses its response; retry after restart must replay
      // precisely that write and resource, not create another version.
      final deliveredWrites = <Map<String, dynamic>>[];
      Map<String, dynamic>? serverDetail;
      var confirmedUploads = 0;
      env.server.on('POST', '/v1/sync/writes', (request) {
        final batch = (request.body as Map)['writes'] as List;
        final results = <Map<String, dynamic>>[];
        for (final raw in batch) {
          final item = raw as Map;
          if (item['write_type'] == 'recipe_version.save') {
            deliveredWrites.add(Map<String, dynamic>.from(item));
            if (deliveredWrites.length == 1) {
              final payload = item['payload'] as Map;
              expectSync(payload['baseline_version_id'], versionId);
              expectSync(payload['recipe_id'], recipeId);
              expectSync(
                item['write_id'],
                isNot(payload['candidate_version_id']),
              );
              final uuidV4 = matches(
                RegExp(
                  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
                ),
              );
              expectSync(item['write_id'], uuidV4);
              expectSync(payload['candidate_version_id'], uuidV4);
              final detail = ownedRecipe().toJson();
              final version = Map<String, dynamic>.from(
                detail['version'] as Map,
              );
              version.addAll({
                'id': payload['candidate_version_id'],
                'previous_version_id': versionId,
                'version_number': 2,
                'snapshot': (payload['candidate'] as Map)['snapshot'],
              });
              detail['version'] = version;
              serverDetail = detail;
              final candidateId = payload['candidate_version_id'];
              env.server.on(
                'GET',
                '/v1/recipes/$recipeId',
                (_) => (200, detail),
              );
              env.server.on(
                'GET',
                '/v1/recipes/$recipeId/versions/$candidateId/display',
                (_) => (
                  200,
                  {
                    'display': {
                      'recipe_id': recipeId,
                      'version_id': candidateId,
                      'mode': 'base',
                      'ingredients': [],
                    },
                  },
                ),
              );
              // The mutation succeeded, but its response was lost. No client
              // confirmation may happen until the same envelope is redelivered.
              return (
                500,
                {
                  'error': {'code': 'response_lost'},
                },
              );
            }
            expectSync(item, deliveredWrites.first);
            confirmedUploads++;
          }
          results.add({
            'write_id': item['write_id'],
            'status': 'confirmed',
            'confirmed_at': '2026-10-09T12:00:00Z',
            'result': item['write_type'] == 'recipe_version.save'
                ? {
                    'resource_type': 'recipe.version',
                    'resource_id':
                        (item['payload'] as Map)['candidate_version_id'],
                    'values': {'detail': serverDetail},
                  }
                : {
                    'resource_type': 'experience.event',
                    'resource_id': item['write_id'],
                  },
          });
        }
        return (200, {'results': results});
      });
      env.reachability.reachable = true;
      container.read(offlineSimulationProvider.notifier).set(false);
      await container.read(apiReachabilityProvider.notifier).check();
      await tester.pumpAndSettle();
      expect(deliveredWrites, hasLength(1));
      expect(
        find.byKey(const ValueKey('offline-recipe-status')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('offline-recipe-status')))
            .data,
        '待同步',
      );
      expect(find.text('本机保存的小火步骤'), findsOneWidget);
      container.read(offlineSimulationProvider.notifier).set(true);
      env.reachability.reachable = false;
      final reopened = TestEnv(
        server: env.server,
        local: env.local,
        secure: env.secure,
        eventQueue: env.eventQueue,
        offline: true,
        probe: env.reachability,
      );
      await restartApp(tester, reopened);
      navigate(tester, '/recipes/$recipeId');
      await tester.pumpAndSettle();
      expect(find.text('本机保存的小火步骤'), findsOneWidget);
      // Resume the same queue after a process-style rebuild, not a recipe-specific retry.
      final resumed = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );
      env.reachability.reachable = true;
      resumed.read(offlineSimulationProvider.notifier).set(false);
      await resumed.read(apiReachabilityProvider.notifier).check();
      await tester.pumpAndSettle();
      navigate(tester, '/me/sync');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('sync-manual-retry')));
      await tester.pumpAndSettle();
      expect(confirmedUploads, 1);
      expect(deliveredWrites, hasLength(2));
      expect(deliveredWrites.last, deliveredWrites.first);
      expect(
        deliveredWrites.map((write) => write['write_id']).toSet(),
        hasLength(1),
      );
      expect(
        deliveredWrites
            .map((write) => (write['payload'] as Map)['candidate_version_id'])
            .toSet(),
        hasLength(1),
      );
      navigate(tester, '/recipes');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('recipe-card-$recipeId')),
        findsOneWidget,
      );
      expect(find.textContaining('第 2 版'), findsOneWidget);
      expect(find.textContaining('待同步'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('recipe-card-$recipeId')));
      await tester.pumpAndSettle();
      expect(find.textContaining('待同步'), findsNothing);
      await tester.scrollUntilVisible(
        find.textContaining('本机保存的小火步骤'),
        400,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('recipe-detail-content')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.textContaining('本机保存的小火步骤'), findsOneWidget);
      // Confirmation must retain the saved local version, not only clear its
      // pending marker. Reopen offline so HTTP cannot supply the visible copy.
      env.reachability.reachable = false;
      await restartApp(tester, reopened);
      navigate(tester, '/recipes/$recipeId');
      await tester.pumpAndSettle();
      expect(find.text('已同步'), findsOneWidget);
      expect(find.text('本机保存的小火步骤'), findsOneWidget);
      expect(deliveredWrites, hasLength(2));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'offline cached manual editor opens and recovers unsaved draft without HTTP baseline',
    (tester) async {
      final env = TestEnv.signedIn(offline: true);
      await cacheRecipe(env);
      await pumpApp(tester, env: env);
      navigate(tester, '/recipes/$recipeId/edit');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('recipe-editor-content')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('recipe-step-instruction-boil')),
        400,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('recipe-editor-content')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(
        find.byKey(const ValueKey('recipe-step-instruction-boil')),
        '离线改为小火烧开',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await restartApp(tester, env);
      navigate(tester, '/recipes/$recipeId/edit');
      await tester.pumpAndSettle();
      expect(find.text('恢复未保存修改？'), findsOneWidget);
      await tester.tap(find.text('恢复'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('recipe-step-instruction-boil')),
        400,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('recipe-editor-content')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('离线改为小火烧开'), findsOneWidget);
      expect(env.server.calls('GET', '/v1/recipes/$recipeId'), isEmpty);
    },
  );
}
