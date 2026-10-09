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
      final writes = (await env.eventQueue.entries(ownerId: env.server.user.id))
          .where((entry) => entry.write.writeType == 'recipe_version.save')
          .toList();
      expect(writes, hasLength(1));
      final retained = writes.single;
      final localDetail = Map<String, dynamic>.from(
        retained.businessRecord!['detail'] as Map,
      );
      var uploads = 0;
      env.server.on('GET', '/v1/recipes/$recipeId', (_) => (200, localDetail));
      env.server.on(
        'GET',
        '/v1/recipes/$recipeId/versions/${retained.businessRecord!['candidate_version_id']}/display',
        (_) => (
          200,
          {
            'display': {
              'recipe_id': recipeId,
              'version_id': retained.businessRecord!['candidate_version_id'],
              'mode': 'base',
              'ingredients': [],
            },
          },
        ),
      );
      env.server.on('POST', '/v1/sync/writes', (request) {
        final batch = (request.body as Map)['writes'] as List;
        final results = <Map<String, dynamic>>[];
        for (final raw in batch) {
          final item = raw as Map;
          if (item['write_type'] == 'recipe_version.save') {
            uploads++;
            expectSync(item['write_id'], retained.write.id);
            expectSync(
              (item['payload'] as Map)['candidate_version_id'],
              retained.businessRecord!['candidate_version_id'],
            );
          }
          results.add({
            'write_id': item['write_id'],
            'status': 'confirmed',
            'confirmed_at': '2026-10-09T12:00:00Z',
            'result': item['write_type'] == 'recipe_version.save'
                ? {
                    'resource_type': 'recipe.version',
                    'resource_id':
                        retained.businessRecord!['candidate_version_id'],
                    'values': {'detail': localDetail},
                  }
                : {
                    'resource_type': 'experience.event',
                    'resource_id': item['write_id'],
                  },
          });
        }
        return (200, {'results': results});
      });
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
      expect(uploads, 1);
      expect(find.textContaining('待同步'), findsNothing);
      expect(
        (await env.eventQueue.entries(ownerId: env.server.user.id))
            .where((entry) => entry.write.writeType == 'recipe_version.save'),
        hasLength(1),
      );
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
