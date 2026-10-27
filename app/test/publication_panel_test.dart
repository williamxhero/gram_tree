import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gram_tree/auth/auth_controller.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/events/event_uploader.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:gram_tree/events/fake_event_queue.dart';
import 'package:gram_tree/features/records/records_page.dart';
import 'package:gram_tree/l10n/app_localizations.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/features/recipes/publication_panel.dart';
import 'package:gram_tree/features/recipes/recipe_pages.dart';
import 'package:gram_tree/ui_protocol/source_attribution.dart';
import 'package:gram_tree/ui_protocol/composition_provider.dart';
import 'package:gram_tree/ui_protocol/recipe_safety_protocol.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';

const recipeId = '11111111-1111-4111-8111-111111111111';
const versionId = '22222222-2222-4222-8222-222222222222';

RecipeDetail publicationRecipeFixture() => RecipeDetail.fromJson({
  'id': recipeId,
  'author': {'id': testUser().id, 'nickname': '真正的作者'},
  'dish': {
    'id': '33333333-3333-4333-8333-333333333333',
    'name': '番茄汤',
    'aliases': <String>[],
  },
  'visibility': 'private',
  'ever_public': false,
  'withdrawn': false,
  'source_version_id': null,
  'root_recipe_id': null,
  'created_at': '2026-10-01T00:00:00Z',
  'updated_at': '2026-10-01T00:00:00Z',
  'version': {
    'id': versionId,
    'version_number': 1,
    'ai_assisted': false,
    'change_note': '',
    'images': <Object>[],
    'edit_operations': <Object>[],
    'previous_version_id': null,
    'created_at': '2026-10-01T00:00:00Z',
    'publication_state': 'draft',
    'derived': {
      'active_time_seconds': 0,
      'total_time_seconds': 0,
      'allergens_incomplete': false,
    },
    'snapshot': {
      'format_version': 1,
      'servings': 2,
      'ingredients': [
        {
          'id': 'ingredient-1',
          'display_name': '盐',
          'quantity': 100,
          'unit': 'g',
          'base_quantity': 100,
          'base_unit': 'g',
          'functional': false,
        },
      ],
      'steps': [
        {
          'id': 'step-1',
          'instruction': '搅匀',
          'action': '拌',
          'duration_seconds': 0,
          'unattended': false,
        },
      ],
    },
  },
});

Map<String, Object?> panelFixture({
  String state = 'draft',
  bool public = false,
  List<Object> missing = const [],
}) => {
  'state': state,
  'ever_public': public,
  'automatically_publishes': true,
  'missing': missing,
  'baseline_version_id': null,
  'cumulative_conclusion': null,
  'rules_version': null,
  'high_risk': true,
  'review_level': 'high',
};

Future<void> mount(
  WidgetTester tester,
  TestEnv env,
  Widget Function(WidgetRef) build,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: env.overrides,
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              final auth = ref.watch(authProvider);
              if (auth.isLoading) return const SizedBox.shrink();
              final child = build(ref);
              return child is RecipeEditorPage
                  ? child
                  : SingleChildScrollView(child: child);
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> improvementPreviewFixture({bool convertible = true}) => {
  'snapshot': publicationRecipeFixture().version.snapshot.toJson(),
  'microadjust_prompt': '这个改动更像个人口味',
  'taste_proposal': {
    'convertible': convertible,
    'reason': convertible ? null : '非用量微调不能转换',
    'profile_version': 2,
    'coefficients': {'salty': 0.98},
  },
  'comparison': {
    'scope': 'full',
    'conclusion': 'minor_only',
    'rules_version': 'rules-1',
    'basis': ['用量变化小于 5%'],
    'normalized_servings': 2,
    for (final key in ['from_version', 'to_version'])
      key: {
        'recipe_id': recipeId,
        'version_id': versionId,
        'version_number': 1,
        'author': '作者',
        'dish_name': '番茄汤',
        'servings': 2,
      },
    'ingredients': <Object>[],
    'steps': <Object>[],
    'snapshot_fields': <Object>[],
    'method_changes': <Object>[],
  },
};

Future<void> mountImprovement(WidgetTester tester, TestEnv env) async {
  await pumpApp(tester, env: env);
  unawaited(
    Navigator.of(tester.element(find.byType(Scaffold).first)).push(
      MaterialPageRoute<void>(
        builder: (_) => RecipeEditorPage(
          improvementDraft: ImprovementDraftOut(
            id: '44444444-4444-4444-8444-444444444444',
            sourceRecipeId: recipeId,
            sourceVersionId: versionId,
            snapshot: publicationRecipeFixture().version.snapshot,
            dishName: '番茄汤',
            aiAssisted: false,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> saveEditor(WidgetTester tester) async {
  final save = find.byKey(const ValueKey('save-recipe-button'));
  await tester.scrollUntilVisible(
    save,
    400,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('recipe-editor-content')),
          matching: find.byType(Scrollable),
        )
        .first,
    maxScrolls: 40,
  );
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
  await tester.pumpAndSettle();
}

class _BacklogGateQueue extends FakeEventQueue {
  int? readsUntilGate;
  final blocked = Completer<void>();
  final release = Completer<void>();

  @override
  Future<List<QueueEntry>> entries({String? ownerId}) async {
    final snapshot = await super.entries(ownerId: ownerId);
    final remaining = readsUntilGate;
    if (remaining != null) {
      readsUntilGate = remaining - 1;
      if (remaining == 1) {
        readsUntilGate = null;
        blocked.complete();
        await release.future;
      }
    }
    return snapshot;
  }
}

class _DiscoveryGateQueue extends FakeEventQueue {
  bool held = false;
  final release = Completer<void>();

  @override
  Future<List<QueueEntry>> entries({String? ownerId}) async {
    final snapshot = await super.entries(ownerId: ownerId);
    if (held) await release.future;
    return snapshot;
  }
}

const _savedRecordId = '66666666-6666-4666-8666-666666666666';

void _recordRoutes(
  TestEnv env, {
  required bool own,
  String serverId = _savedRecordId,
}) {
  final detail = publicationRecipeFixture().toJson();
  if (!own) {
    (detail['author'] as Map)['id'] = '77777777-7777-4777-8777-777777777777';
  }
  final record = CookingRecordOut.fromJson({
    'id': serverId,
    'client_id': _savedRecordId,
    'recipe_id': recipeId,
    'recipe_version_id': versionId,
    'dish_name': '番茄汤',
    'source': 'cooking_session',
    'verification': 'unverified',
    'occurred_at': '2026-10-01T00:00:00Z',
    'created_at': '2026-10-01T00:00:00Z',
    'counts_as_cooked': true,
    'meal': null,
    'co_diner_ids': <String>[],
    'snapshot': {'detail': detail},
    'adjustments': [
      {'ingredient_id': 'ingredient-1', 'quantity': 98},
    ],
    'source_context': <String, Object>{},
    'taste_summary': <String, Object>{},
  });
  env.server.on(
    'GET',
    '/v1/records',
    (_) => (200, CookingRecordListOut(items: [record]).toJson()),
  );
}

Iterable<Map> _recordWrites(TestEnv env) => env.server
    .calls('POST', '/v1/sync/writes')
    .expand((request) => ((request.body as Map)['writes'] as List).cast<Map>())
    .where((write) => write['write_type'] == 'record_improvement.save');

(int, Object?) _recordConfirmation(Recorded request, {bool preview = false}) =>
    (
      200,
      {
        'results': [
          for (final write
              in ((request.body as Map)['writes'] as List).cast<Map>())
            {
              'write_id': write['write_id'],
              'status': 'confirmed',
              'confirmed_at': '2026-10-01T00:00:00Z',
              'result': write['write_type'] == 'record_improvement.save'
                  ? {
                      'resource_type': 'record.improvement',
                      'resource_id': _savedRecordId,
                      'values':
                          preview &&
                              (write['payload'] as Map)['microadjust_choice'] ==
                                  null
                          ? {'preview': improvementPreviewFixture()}
                          : {
                              'response': {
                                'outcome':
                                    (write['payload']
                                            as Map)['microadjust_choice'] ==
                                        'taste'
                                    ? 'taste'
                                    : 'branch',
                                'recipe':
                                    (write['payload']
                                            as Map)['microadjust_choice'] ==
                                        'taste'
                                    ? null
                                    : publicationRecipeFixture().toJson(),
                              },
                            },
                    }
                  : write['write_type'] == 'cooking_record.create'
                  ? {
                      'resource_type': 'cooking.record',
                      'resource_id': '99999999-9999-4999-8999-999999999999',
                    }
                  : {
                      'resource_type': 'experience.event',
                      'resource_id': write['write_id'],
                    },
            },
        ],
      },
    );

void main() {
  for (final own in [false, true]) {
    testWidgets(
      'record snapshot stays viewable after withdrawal and saves ${own ? "linear version" : "improvement"}',
      (tester) async {
        const recordId = '66666666-6666-4666-8666-666666666666';
        final env = TestEnv.signedIn();
        final detail = publicationRecipeFixture().toJson();
        detail['withdrawn'] = true;
        if (!own) {
          (detail['author'] as Map)['id'] =
              '77777777-7777-4777-8777-777777777777';
        }
        final record = CookingRecordOut.fromJson({
          'id': recordId,
          'client_id': recordId,
          'recipe_id': recipeId,
          'recipe_version_id': versionId,
          'dish_name': '番茄汤',
          'source': 'cooking_session',
          'verification': 'unverified',
          'occurred_at': '2026-10-01T00:00:00Z',
          'created_at': '2026-10-01T00:00:00Z',
          'counts_as_cooked': true,
          'co_diner_ids': <String>[],
          'meal': null,
          'snapshot': {'detail': detail},
          'adjustments': [
            {
              'kind': 'ingredient_quantity',
              'ingredient_id': 'ingredient-1',
              'quantity': 98,
            },
          ],
          'source_context': <String, Object>{},
          'taste_summary': <String, Object>{},
        });
        env.server.on(
          'GET',
          '/v1/records',
          (_) => (200, CookingRecordListOut(items: [record]).toJson()),
        );
        env.server.on(
          'GET',
          '/v1/recipes/$recipeId',
          (_) => FakeServer.error(404, 'not_found', '来源已下架'),
        );
        final preview = improvementPreviewFixture()
          ..['microadjust_prompt'] = null;
        env.server.on(
          'POST',
          '/v1/recipes/$recipeId/improvements/preview',
          (_) => (200, preview),
        );
        final saveResponse = {
          'outcome': 'branch',
          'recipe': publicationRecipeFixture().toJson(),
          'profile_version': null,
        };
        env.server.on('POST', '/v1/sync/writes', (request) {
          final body = request.body as Map;
          return (
            200,
            {
              'results': [
                for (final write in (body['writes'] as List).cast<Map>())
                  {
                    'write_id': write['write_id'],
                    'status': 'confirmed',
                    'confirmed_at': '2026-10-01T00:00:00Z',
                    'result': write['write_type'] == 'record_improvement.save'
                        ? {
                            'resource_type': 'record.improvement',
                            'resource_id': recordId,
                            'values': {'response': saveResponse},
                          }
                        : {
                            'resource_type': 'experience.event',
                            'resource_id': write['write_id'],
                          },
                  },
              ],
            },
          );
        });
        await pumpApp(tester, env: env);
        await tester.tap(find.text('记录'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('record-$recordId')));
        await tester.pumpAndSettle();
        expect(find.text('搅匀'), findsOneWidget);
        expect(find.textContaining('来源下架后仍可回看'), findsOneWidget);
        await tester.tap(find.text('关闭'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(own ? '存为我的新一版' : '存成改良版'));
        await tester.pumpAndSettle();
        final write = env.server
            .calls('POST', '/v1/sync/writes')
            .expand(
              (request) =>
                  ((request.body as Map)['writes'] as List).cast<Map>(),
            )
            .where((write) => write['write_type'] == 'record_improvement.save')
            .single;
        expect(
          write['write_id'],
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            ),
          ),
        );
        expect(write['payload'], isA<Map>());
        final payload = write['payload'] as Map;
        expect(
          payload.containsKey('snapshot'),
          isFalse,
          reason: 'server must derive executed record snapshot',
        );
        expect(
          env.server.calls('POST', '/v1/records/$recordId/save-version'),
          isEmpty,
        );
        expect(
          env.server.calls('POST', '/v1/recipes/$recipeId/improvements'),
          isEmpty,
        );
        expect(payload['change_note'], '记录临时调整');
        expect(payload['record_id'], recordId);
        expect(payload['recipe_id'], recipeId);
        expect(payload['source_version_id'], versionId);
        expect(env.server.calls('GET', '/v1/recipes/$recipeId'), isEmpty);
        expect(
          find.textContaining(own ? '已存为我的新一版' : '已存成改良版'),
          findsOneWidget,
        );
      },
    );
  }
  testWidgets('foreground record save joins a drain paused in backlog read', (
    tester,
  ) async {
    final base = TestEnv.signedIn();
    final queue = _BacklogGateQueue();
    final env = TestEnv(
      server: base.server,
      local: base.local,
      secure: base.secure,
      eventQueue: queue,
    );
    _recordRoutes(env, own: true);
    env.server.on('POST', '/v1/sync/writes', _recordConfirmation);
    await pumpApp(tester, env: env);
    await tester.tap(find.text('记录'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.text('存为我的新一版')),
    );
    queue.readsUntilGate = 2;
    unawaited(container.read(eventUploaderProvider).triggerUpload());
    for (var frame = 0; frame < 10 && !queue.blocked.isCompleted; frame++) {
      await tester.pump();
    }
    expect(queue.blocked.isCompleted, isTrue);
    await tester.tap(find.text('存为我的新一版'));
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump();
    }
    expect(find.textContaining('已存为我的新一版'), findsNothing);
    queue.release.complete();
    await tester.pumpAndSettle();
    expect(_recordWrites(env), hasLength(1));
    expect(find.textContaining('已存为我的新一版'), findsOneWidget);
  });

  testWidgets('simultaneous record cards retain one immutable save ID', (
    tester,
  ) async {
    final base = TestEnv.signedIn();
    final queue = _DiscoveryGateQueue();
    final env = TestEnv(
      server: base.server,
      local: base.local,
      secure: base.secure,
      eventQueue: queue,
    );
    _recordRoutes(env, own: true);
    env.server.on(
      'POST',
      '/v1/sync/writes',
      (_) => FakeServer.error(503, 'unavailable', '暂不可用'),
    );
    await mount(
      tester,
      env,
      (_) => const SizedBox(
        height: 500,
        child: Row(
          children: [
            Expanded(child: RecordsPage()),
            Expanded(child: RecordsPage()),
          ],
        ),
      ),
    );
    final buttons = find.text('存为我的新一版');
    expect(buttons, findsNWidgets(2));
    queue.held = true;
    await tester.tap(buttons.at(0));
    await tester.tap(buttons.at(1));
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump();
    }
    queue.held = false;
    queue.release.complete();
    await tester.pumpAndSettle();
    await restartApp(tester, env);
    await tester.tap(find.text('记录'));
    await tester.pumpAndSettle();
    env.server.on('POST', '/v1/sync/writes', _recordConfirmation);
    final container = ProviderScope.containerOf(tester.element(buttons.first));
    unawaited(container.read(eventUploaderProvider).networkRestored());
    await tester.pumpAndSettle();
    await tester.tap(buttons.first);
    await tester.pumpAndSettle();
    expect(find.textContaining('已存为我的新一版'), findsOneWidget);
    expect(
      _recordWrites(env).map((write) => write['write_id']).toSet(),
      hasLength(1),
    );
  });

  for (final own in [false, true]) {
    testWidgets(
      'offline record save survives reopen with stable retry ID ${own ? "own" : "foreign"}',
      (tester) async {
        final env = TestEnv.signedIn();
        _recordRoutes(env, own: own);
        env.server.on(
          'POST',
          '/v1/sync/writes',
          (_) => FakeServer.error(503, 'unavailable', '暂不可用'),
        );
        await pumpApp(tester, env: env);
        await tester.tap(find.text('记录'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(own ? '存为我的新一版' : '存成改良版'));
        await tester.pumpAndSettle();
        expect(find.textContaining(own ? '已存为我的新一版' : '已存成改良版'), findsNothing);
        final sent = _recordWrites(env).first;
        final id = sent['write_id'];
        final payload = sent['payload'] as Map;
        await restartApp(tester, env);
        env.server.on('POST', '/v1/sync/writes', _recordConfirmation);
        await tester.tap(find.text('记录'));
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(
          tester.element(find.text(own ? '存为我的新一版' : '存成改良版')),
        );
        unawaited(container.read(eventUploaderProvider).networkRestored());
        await tester.pumpAndSettle();
        await tester.tap(find.text(own ? '存为我的新一版' : '存成改良版'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining(own ? '已存为我的新一版' : '已存成改良版'),
          findsOneWidget,
        );
        expect(_recordWrites(env).map((write) => write['write_id']).toSet(), {
          id,
        });
        expect(
          _recordWrites(env)
              .every((write) => mapEquals(write['payload'] as Map, payload)),
          isTrue,
        );
        expect(
          env.server.calls(
            'POST',
            '/v1/recipes/$recipeId/improvements/preview',
          ),
          isEmpty,
        );
        await tester.tap(find.text(own ? '存为我的新一版' : '存成改良版'));
        await tester.pumpAndSettle();
        expect(_recordWrites(env).map((write) => write['write_id']).toSet(), {
          id,
        });
      },
    );
  }

  for (final choice in ['cancel', 'taste', 'branch']) {
    testWidgets('record microadjust keeps explicit $choice across reopen', (
      tester,
    ) async {
      final env = TestEnv.signedIn();
      _recordRoutes(env, own: false);
      env.server.on(
        'POST',
        '/v1/sync/writes',
        (request) => _recordConfirmation(request, preview: true),
      );
      await pumpApp(tester, env: env);
      await tester.tap(find.text('记录'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('存成改良版'));
      await tester.pumpAndSettle();
      expect(find.text('这个改动更像个人口味'), findsOneWidget);
      expect(_recordWrites(env), hasLength(1));
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(_recordWrites(env), hasLength(1));
      await restartApp(tester, env);
      await tester.tap(find.text('记录'));
      await tester.pumpAndSettle();
      expect(find.text('这个改动更像个人口味'), findsNothing);
      expect(
        _recordWrites(env),
        hasLength(1),
        reason: 'reopen is not a save or choice',
      );
      await tester.tap(find.text('存成改良版'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(
          choice == 'cancel'
              ? '取消'
              : choice == 'taste'
              ? '存进我的口味'
              : '仍然保存',
        ),
      );
      await tester.pumpAndSettle();
      final writes = _recordWrites(env).toList();
      expect(writes, hasLength(choice == 'cancel' ? 1 : 2));
      if (choice != 'cancel') {
        expect((writes.last['payload'] as Map)['microadjust_choice'], choice);
        expect(writes.last['write_id'], isNot(writes.first['write_id']));
        final id = writes.last['write_id'];
        await restartApp(tester, env);
        await tester.tap(find.text('记录'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('存成改良版'));
        await tester.pumpAndSettle();
        expect(find.text('这个改动更像个人口味'), findsNothing);
        expect(_recordWrites(env).last['write_id'], id);
        expect(_recordWrites(env), hasLength(2));
        expect(
          find.textContaining(choice == 'taste' ? '已存进我的口味' : '已存成改良版'),
          findsOneWidget,
        );
      }
    });
  }

  for (final lost in [false, true]) {
    testWidgets(
      'direct record save identity survives late producer mapping ${lost ? "lost response" : "confirmed"}',
      (tester) async {
        final env = TestEnv.signedIn();
        _recordRoutes(
          env,
          own: false,
          serverId: '99999999-9999-4999-8999-999999999999',
        );
        var available = !lost;
        env.server.on(
          'POST',
          '/v1/sync/writes',
          (request) => available
              ? _recordConfirmation(request)
              : FakeServer.error(503, 'lost_response', '暂不可用'),
        );
        await pumpApp(tester, env: env);
        await tester.tap(find.text('记录'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('存成改良版'));
        await tester.pumpAndSettle();
        final first = _recordWrites(env).first;
        expect(
          (first['payload'] as Map)['record_id'],
          '99999999-9999-4999-8999-999999999999',
        );
        final detail = publicationRecipeFixture().toJson();
        (detail['author'] as Map)['id'] =
            '77777777-7777-4777-8777-777777777777';
        await env.eventQueue.enqueue(
          QueuedEvent.write(
            id: '88888888-8888-4888-8888-888888888888',
            ownerId: testUser().id,
            deviceTime: DateTime.utc(2026, 10, 1),
            writeType: 'cooking_record.create',
            payload: {
              'record': {
                'client_id': _savedRecordId,
                'recipe_id': recipeId,
                'recipe_version_id': versionId,
                'dish_name': '番茄汤',
                'source': 'cooking_session',
                'verification': 'unverified',
                'occurred_at': '2026-10-01T00:00:00Z',
                'snapshot': {'detail': detail},
                'adjustments': <Object>[],
                'co_diner_ids': <String>[],
                'source_context': <String, Object>{},
              },
            },
          ),
        );
        available = true;
        final container = ProviderScope.containerOf(
          tester.element(find.text('存成改良版')),
        );
        unawaited(container.read(eventUploaderProvider).networkRestored());
        await tester.pumpAndSettle();
        await restartApp(tester, env);
        await tester.tap(find.text('记录'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('存成改良版'));
        await tester.pumpAndSettle();
        expect(find.textContaining('已存成改良版'), findsOneWidget);
        expect(_recordWrites(env).map((write) => write['write_id']).toSet(), {
          first['write_id'],
        });
        for (final write in _recordWrites(env)) {
          expect(
            write['payload'],
            first['payload'],
            reason: 'reference spelling cannot change an existing envelope',
          );
          expect(write['dependencies'], first['dependencies']);
        }
      },
    );
  }

  for (final own in [false, true]) {
    testWidgets(
      'offline-created record exposes durable dependent save ${own ? "own" : "foreign"}',
      (tester) async {
        final env = TestEnv.signedIn();
        final detail = publicationRecipeFixture().toJson();
        if (!own) {
          (detail['author'] as Map)['id'] =
              '77777777-7777-4777-8777-777777777777';
        }
        await env.eventQueue.enqueue(
          QueuedEvent.write(
            id: _savedRecordId,
            ownerId: testUser().id,
            deviceTime: DateTime.utc(2026, 10, 1),
            writeType: 'cooking_record.create',
            payload: {
              'record': {
                'client_id': _savedRecordId,
                'recipe_id': recipeId,
                'recipe_version_id': versionId,
                'dish_name': '番茄汤',
                'source': 'cooking_session',
                'verification': 'unverified',
                'occurred_at': '2026-10-01T00:00:00Z',
                'snapshot': {'detail': detail},
                'adjustments': [
                  {'ingredient_id': 'ingredient-1', 'quantity': 98},
                ],
                'co_diner_ids': <String>[],
                'source_context': <String, Object>{},
              },
            },
          ),
        );
        env.server.on(
          'GET',
          '/v1/records',
          (_) => FakeServer.error(503, 'offline', '暂不可用'),
        );
        env.server.on(
          'POST',
          '/v1/sync/writes',
          (_) => FakeServer.error(503, 'offline', '暂不可用'),
        );
        await pumpApp(tester, env: env);
        await tester.tap(find.text('记录'));
        await tester.pumpAndSettle();
        expect(find.text('番茄汤'), findsOneWidget);
        final label = own ? '存为我的新一版' : '存成改良版';
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.textContaining(own ? '已存为我的新一版' : '已存成改良版'), findsNothing);
        await restartApp(tester, env);
        await tester.tap(find.text('记录'));
        await tester.pumpAndSettle();
        expect(find.text(label), findsOneWidget);
        _recordRoutes(
          env,
          own: own,
          serverId: '99999999-9999-4999-8999-999999999999',
        );
        env.server.on('POST', '/v1/sync/writes', _recordConfirmation);
        final container = ProviderScope.containerOf(
          tester.element(find.text(label)),
        );
        unawaited(container.read(eventUploaderProvider).networkRestored());
        await tester.pumpAndSettle();
        expect(
          find.text('番茄汤'),
          findsOneWidget,
          reason: 'confirmed parent replaces local card, not a duplicate',
        );
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(
          find.textContaining(own ? '已存为我的新一版' : '已存成改良版'),
          findsOneWidget,
        );
        final saves = _recordWrites(env).toList();
        expect(saves.map((write) => write['write_id']).toSet(), hasLength(1));
        for (final save in saves) {
          expect(save['dependencies'], [_savedRecordId]);
          expect((save['payload'] as Map)['record_write_id'], _savedRecordId);
          expect((save['payload'] as Map).containsKey('record_id'), isFalse);
        }
      },
    );
  }

  for (final nextChoice in ['taste', 'branch']) {
    testWidgets(
      'definite profile rejection requires fresh explicit $nextChoice',
      (tester) async {
        final env = TestEnv.signedIn();
        _recordRoutes(env, own: false);
        var version = 2;
        env.server.on('POST', '/v1/sync/writes', (request) {
          final (status, body) = _recordConfirmation(request, preview: true);
          for (final result in ((body as Map)['results'] as List).cast<Map>()) {
            final write =
                (((request.body as Map)['writes'] as List).cast<Map>())
                    .singleWhere(
                      (item) => item['write_id'] == result['write_id'],
                    );
            if (write['write_type'] != 'record_improvement.save') continue;
            final payload = write['payload'] as Map;
            if (payload['microadjust_choice'] == null) {
              final preview =
                  ((result['result'] as Map)['values'] as Map)['preview']
                      as Map;
              (preview['taste_proposal'] as Map)['profile_version'] = version;
            } else if (payload['microadjust_choice'] == 'taste' &&
                payload['expected_profile_version'] == 2) {
              result['status'] = 'failed';
              result['reason_code'] = 'profile_changed';
              result['result'] = null;
              version = 3;
            }
          }
          return (status, body);
        });
        await pumpApp(tester, env: env);
        await tester.tap(find.text('记录'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('存成改良版'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('存进我的口味'));
        await tester.pumpAndSettle();
        expect(find.textContaining('已存进我的口味'), findsNothing);
        final rejected = _recordWrites(env).last;
        expect((rejected['payload'] as Map)['expected_profile_version'], 2);
        await restartApp(tester, env);
        await tester.tap(find.text('记录'));
        await tester.pumpAndSettle();
        expect(find.text('这个改动更像个人口味'), findsNothing);
        await tester.tap(find.text('存成改良版'));
        await tester.pumpAndSettle();
        expect(find.textContaining('第 3 版'), findsOneWidget);
        expect(
          (rejected['payload'] as Map)['expected_profile_version'],
          2,
          reason: 'old rejected intent is immutable',
        );
        await tester.tap(find.text(nextChoice == 'taste' ? '存进我的口味' : '仍然保存'));
        await tester.pumpAndSettle();
        final selected = _recordWrites(env).last;
        expect(selected['write_id'], isNot(rejected['write_id']));
        expect((selected['payload'] as Map)['microadjust_choice'], nextChoice);
        if (nextChoice == 'taste') {
          expect((selected['payload'] as Map)['expected_profile_version'], 3);
        }
        expect(
          find.textContaining(nextChoice == 'taste' ? '已存进我的口味' : '已存成改良版'),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('record choice cannot cross same-owner login epoch', (
    tester,
  ) async {
    final env = TestEnv.signedIn();
    _recordRoutes(env, own: false);
    env.server.on(
      'POST',
      '/v1/sync/writes',
      (request) => _recordConfirmation(request, preview: true),
    );
    await pumpApp(tester, env: env);
    await tester.tap(find.text('记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('存成改良版'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AlertDialog)),
    );
    await container
        .read(sessionStoreProvider)
        .save(
          TokenPair(
            accessToken: 'replacement-login',
            refreshToken: 'replacement-refresh',
            accessExpiresIn: 1800,
            user: testUser(),
          ),
        );
    await tester.pumpAndSettle();
    await tester.tap(find.text('仍然保存'));
    await tester.pumpAndSettle();
    expect(_recordWrites(env), hasLength(1));
    expect(find.textContaining('已存成改良版'), findsNothing);
  });

  for (final failure in [
    FallbackInfoReasonCodeEnum.invalidData,
    FallbackInfoReasonCodeEnum.unknownComponent,
    FallbackInfoReasonCodeEnum.timeout,
  ]) {
    testWidgets('source attribution survives composition ${failure.value}', (
      tester,
    ) async {
      final env = TestEnv.signedIn();
      final detail = publicationRecipeFixture();
      await mount(
        tester,
        env,
        (_) => RecipeSafetyProtocolSection(
          result: null,
          legacyDerived: detail.version.derived,
          dishName: detail.dish.name,
          snapshot: detail.version.snapshot,
          recipeId: detail.id,
          versionId: detail.version.id,
          authoring: false,
          loading: false,
          composition: AsyncData(CompositionFailed(failure)),
          sourceAttribution: const {
            'label': '改良自 @已注销用户《原菜》第 1 版（已下架）',
            'chain': <Object>[],
          },
        ),
      );
      expect(find.text('改良自 @已注销用户《原菜》第 1 版（已下架）'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('source-attribution-chain')),
        findsOneWidget,
      );
    });
  }
  testWidgets('permanent attribution remains visible at every detail level', (
    tester,
  ) async {
    for (final detail in ['brief', 'standard', 'detailed']) {
      final env = TestEnv.signedIn();
      await mount(
        tester,
        env,
        (_) => SourceAttributionCard(
          attribution: const {
            'label': '改良自 @原作者《番茄汤》第 3 版（已下架）',
            'chain': [
              {
                'author': '已注销用户',
                'title': '原汤',
                'version_number': 1,
                'withdrawn': true,
              },
            ],
          },
          detail: detail,
        ),
      );
      expect(find.textContaining('改良自 @原作者《番茄汤》第 3 版'), findsOneWidget);
      expect(
        find.text('保留精确来源版本，来源署名和关系不能修改或删除。'),
        detail == 'brief' ? findsNothing : findsOneWidget,
      );
      expect(
        find.text('来源关系永久保留；下架来源不提供隐藏内容。'),
        detail == 'detailed' ? findsOneWidget : findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('source-attribution-chain')));
      await tester.pumpAndSettle();
      expect(find.textContaining('已注销用户'), findsOneWidget);
      expect(find.textContaining('已下架'), findsWidgets);
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets(
    'publication labels distinguish version verification from numeric evidence',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: PublicationStateLabel(state: 'pending_verification'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('已公开 · 待验证'), findsOneWidget);
      expect(find.text('已验证'), findsNothing);
    },
  );

  testWidgets(
    'draft explains automatic publication and missing exact-version conditions; risk can cancel',
    (tester) async {
      final env = TestEnv.signedIn();
      var cooked = 0;
      env.server.on(
        'GET',
        '/v1/recipes/$recipeId/publication',
        (_) => (
          200,
          panelFixture(
            missing: [
              {
                'code': 'not_cooked',
                'label': '还没做过',
                'action': 'start_cooking',
                'remaining_count': null,
              },
              {
                'code': 'risk_confirmation',
                'label': '确认高风险',
                'action': 'confirm_risk',
                'remaining_count': null,
              },
              {
                'code': 'incomplete',
                'label': '有待确定字段',
                'action': 'resolve_fields',
                'remaining_count': 2,
              },
            ],
          ),
        ),
      );
      env.server.on(
        'POST',
        '/v1/recipes/$recipeId/versions/$versionId/risk-confirmation',
        (_) => (200, publicationRecipeFixture().toJson()),
      );
      await mount(
        tester,
        env,
        (_) => PublicationPanelCard(
          detail: publicationRecipeFixture(),
          onChanged: () {},
          onCook: () => cooked++,
        ),
      );
      expect(find.textContaining('做过后会自动公开'), findsOneWidget);
      expect(find.text('有待确定字段（2 处）'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('publication-condition-not_cooked')),
      );
      await tester.pumpAndSettle();
      expect(cooked, 1);
      await tester.tap(
        find.byKey(const ValueKey('publication-condition-risk_confirmation')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('暂不确认'));
      await tester.pumpAndSettle();
      expect(
        env.server.calls(
          'POST',
          '/v1/recipes/$recipeId/versions/$versionId/risk-confirmation',
        ),
        isEmpty,
      );
      await tester.tap(
        find.byKey(const ValueKey('publication-condition-risk_confirmation')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('publication-confirm-risk')));
      await tester.pumpAndSettle();
      expect(
        env.server.calls(
          'POST',
          '/v1/recipes/$recipeId/versions/$versionId/risk-confirmation',
        ),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'published recipe can withdraw then restore, never offers delete in panel',
    (tester) async {
      final env = TestEnv.signedIn();
      var state = 'published';
      env.server.on(
        'GET',
        '/v1/recipes/$recipeId/publication',
        (_) => (200, panelFixture(state: state, public: true)),
      );
      for (final action in ['withdraw', 'restore']) {
        env.server.on('POST', '/v1/recipes/$recipeId/$action', (_) {
          state = action == 'withdraw' ? 'withdrawn' : 'published';
          return (200, publicationRecipeFixture().toJson());
        });
      }
      await mount(
        tester,
        env,
        (_) => PublicationPanelCard(
          detail: publicationRecipeFixture(),
          onChanged: () {},
          onCook: () {},
        ),
      );
      for (final expected in ['已下架', '已公开']) {
        await tester.tap(find.byKey(const ValueKey('publication-lifecycle')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('publication-confirm-lifecycle')),
        );
        await tester.pumpAndSettle();
        expect(find.text(expected), findsOneWidget);
      }
      expect(find.text('删除菜谱'), findsNothing);
    },
  );

  testWidgets('late publication refresh cannot reload an unmounted recipe', (
    tester,
  ) async {
    final env = TestEnv.signedIn();
    final refresh = Completer<(int, Object?)>();
    var reads = 0;
    var changed = 0;
    env.server.on('GET', '/v1/recipes/$recipeId/publication', (_) {
      reads++;
      return reads == 1
          ? (200, panelFixture(state: 'published', public: true))
          : refresh.future;
    });
    env.server.on(
      'POST',
      '/v1/recipes/$recipeId/withdraw',
      (_) => (200, publicationRecipeFixture().toJson()),
    );
    await mount(
      tester,
      env,
      (_) => PublicationPanelCard(
        detail: publicationRecipeFixture(),
        onChanged: () => changed++,
        onCook: () {},
      ),
    );
    await tester.tap(find.byKey(const ValueKey('publication-lifecycle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('publication-confirm-lifecycle')));
    await tester.pumpAndSettle();
    expect(reads, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    refresh.complete((200, panelFixture(state: 'withdrawn', public: true)));
    await tester.pumpAndSettle();
    expect(changed, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'first license is shown without extra consent and acknowledged only once',
    (tester) async {
      final env = TestEnv.signedIn();
      var seen = false;
      env.server.on(
        'GET',
        '/v1/recipes/publication/notifications',
        (_) => (
          200,
          {
            'items': <Object>[],
            'license_notice': seen
                ? null
                : '菜谱内容按 CC BY-NC-SA 4.0 共享；照片版权归上传者。',
          },
        ),
      );
      env.server.on(
        'POST',
        '/v1/recipes/publication/notifications/acknowledge',
        (request) {
          seen = (request.body as Map)['license_seen'] == true;
          return (204, null);
        },
      );
      await mount(tester, env, (_) => const PublicationNotices());
      expect(find.textContaining('CC BY-NC-SA 4.0'), findsOneWidget);
      expect(find.text('同意许可'), findsNothing);
      expect(
        env.server.calls(
          'POST',
          '/v1/recipes/publication/notifications/acknowledge',
        ),
        isEmpty,
      );
      final navigator = Navigator.of(
        tester.element(find.byType(PublicationNotices)),
      );
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('其他页面')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('其他页面'), findsOneWidget);
      expect(
        env.server.calls(
          'POST',
          '/v1/recipes/publication/notifications/acknowledge',
        ),
        isEmpty,
      );
      navigator.pop();
      await tester.pumpAndSettle();
      expect(find.textContaining('CC BY-NC-SA 4.0'), findsOneWidget);
      await tester.tap(find.text('知道了'));
      await tester.pumpAndSettle();
      final acknowledgements = env.server.calls(
        'POST',
        '/v1/recipes/publication/notifications/acknowledge',
      );
      expect(acknowledgements, hasLength(1));
      expect((acknowledgements.single.body as Map)['license_seen'], isTrue);
      expect(find.textContaining('CC BY-NC-SA 4.0'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await mount(tester, env, (_) => const PublicationNotices());
      expect(find.textContaining('CC BY-NC-SA 4.0'), findsNothing);
      expect(
        env.server.calls(
          'POST',
          '/v1/recipes/publication/notifications/acknowledge',
        ),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'publication notices page all 101 items with explicit bounded retryable dismissal',
    (tester) async {
      final env = TestEnv.signedIn();
      const endpoint = '/v1/recipes/publication/notifications';
      var failAck = true;
      var licenseSeen = false;
      String noticeId(int n) =>
          '55555555-5555-4555-8555-${n.toString().padLeft(12, '0')}';
      Map<String, Object?> notice(int n) => {
        'id': noticeId(n),
        'recipe_id': recipeId,
        'version_id': versionId,
        'version_number': n,
        'message': '第 $n 版已公开',
        'title': '番茄汤',
      };
      env.server.on('GET', endpoint, (request) {
        expect(request.query['limit'], 20);
        final offset = int.parse(request.query['cursor'] as String? ?? '0');
        final last = offset == 100;
        return (
          200,
          {
            'items': [
              for (var n = offset + 1; n <= (last ? 101 : offset + 20); n++)
                notice(n),
            ],
            'next_cursor': last ? null : '${offset + 20}',
            'license_notice': licenseSeen ? null : 'CC BY-NC-SA 4.0',
          },
        );
      });
      env.server.on('POST', '$endpoint/acknowledge', (request) {
        if (failAck) return FakeServer.error(503, 'retry', '稍后重试');
        licenseSeen =
            (request.body as Map)['license_seen'] == true || licenseSeen;
        return (204, null);
      });
      await mount(tester, env, (_) => const PublicationNotices());
      expect(find.text('第 1 版已公开'), findsOneWidget);
      expect(find.text('第 20 版已公开'), findsOneWidget);
      expect(env.server.calls('POST', '$endpoint/acknowledge'), isEmpty);
      await tester.ensureVisible(find.text('查看下一页公开提示'));
      await tester.tap(find.text('查看下一页公开提示'));
      await tester.pumpAndSettle();
      expect(find.text('第 20 版已公开'), findsOneWidget);
      expect(env.server.calls('GET', endpoint), hasLength(1));
      failAck = false;
      for (var page = 0; page < 5; page++) {
        await tester.ensureVisible(find.text('查看下一页公开提示'));
        await tester.tap(find.text('查看下一页公开提示'));
        await tester.pumpAndSettle();
        expect(find.text('第 ${page * 20 + 21} 版已公开'), findsOneWidget);
        expect(find.textContaining('CC BY-NC-SA'), findsNothing);
      }
      expect(find.text('第 101 版已公开'), findsOneWidget);
      expect(find.text('第 100 版已公开'), findsNothing);
      expect(find.textContaining('CC BY-NC-SA'), findsNothing);
      await tester.ensureVisible(find.text('知道了'));
      await tester.tap(find.text('知道了'));
      await tester.pumpAndSettle();
      expect(find.text('第 101 版已公开'), findsNothing);
      final calls = env.server.calls('POST', '$endpoint/acknowledge').toList();
      expect(calls, hasLength(7));
      expect(env.server.calls('GET', endpoint), hasLength(6));
      expect((calls.first.body as Map)['notification_ids'], hasLength(20));
      final acknowledged = <Object?>[];
      for (var page = 0; page < 6; page++) {
        final body = calls[page + 1].body as Map;
        final ids = body['notification_ids'] as List;
        expect(ids.length, lessThanOrEqualTo(100));
        expect(ids, [
          for (
            var n = page * 20 + 1;
            n <= (page == 5 ? 101 : page * 20 + 20);
            n++
          )
            noticeId(n),
        ]);
        expect(body['license_seen'], page == 0);
        acknowledged.addAll(ids);
      }
      expect(acknowledged, hasLength(101));
      expect(acknowledged.toSet(), hasLength(101));
    },
  );

  testWidgets(
    'unchanged working copy shows server rejection without creating a recipe',
    (tester) async {
      final env = TestEnv.signedIn();
      env.server.on(
        'POST',
        '/v1/recipes/$recipeId/improvements/preview',
        (_) => FakeServer.error(422, 'no_change', '请先修改配方再保存改良版'),
      );
      await mountImprovement(tester, env);
      final command = find.byKey(const ValueKey('recipe-operation-command'));
      await tester.scrollUntilVisible(
        command,
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('recipe-editor-content')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(command, '保存改良版');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.textContaining('请先修改配方再保存改良版'), findsWidgets);
      expect(
        env.server.calls('POST', '/v1/recipes/$recipeId/improvements'),
        isEmpty,
      );
      expect(env.server.calls('POST', '/v1/recipes'), isEmpty);
    },
  );

  testWidgets(
    'quantity-only improvement preserves unknown source execution metadata',
    (tester) async {
      final env = TestEnv.signedIn();
      env.server.on(
        'POST',
        '/v1/recipes/$recipeId/improvements/preview',
        (_) => FakeServer.error(422, 'preview_stopped', '仅检查本次提交的配方'),
      );
      await mountImprovement(tester, env);
      final content = find.byKey(const ValueKey('recipe-editor-content'));
      final quantity = find.byKey(const ValueKey('recipe-ingredient-quantity'));
      await tester.scrollUntilVisible(
        quantity,
        300,
        scrollable: find
            .descendant(of: content, matching: find.byType(Scrollable))
            .first,
      );
      await tester.enterText(quantity, '98');
      for (var i = 0; i < 4; i++) {
        await tester.drag(content, const Offset(0, 2000));
        await tester.pumpAndSettle();
      }
      await saveEditor(tester);
      final submitted =
          (env.server
                      .calls(
                        'POST',
                        '/v1/recipes/$recipeId/improvements/preview',
                      )
                      .single
                      .body
                  as Map)['snapshot']
              as Map;
      expect(submitted['difficulty'], isNull);
      expect(submitted['dish_type'], isNull);
      final ingredient = (submitted['ingredients'] as List).single as Map;
      expect(ingredient['quantity'], 98);
      expect(ingredient['flavor_contribution'], isNull);
      expect(find.textContaining('仅检查本次提交的配方'), findsWidgets);
      expect(
        env.server.calls('POST', '/v1/recipes/$recipeId/improvements'),
        isEmpty,
      );
    },
  );

  for (final choice in ['cancel', 'taste', 'branch']) {
    testWidgets(
      'microadjust $choice is explicit and cancellation does not save',
      (tester) async {
        final env = TestEnv.signedIn();
        env.server.on(
          'POST',
          '/v1/recipes/$recipeId/improvements/preview',
          (_) => (200, improvementPreviewFixture()),
        );
        env.server.on(
          'POST',
          '/v1/recipes/$recipeId/improvements',
          (_) =>
              (200, {'outcome': 'taste', 'recipe': null, 'profile_version': 3}),
        );
        await mountImprovement(tester, env);
        await saveEditor(tester);
        expect(find.text('这个改动更像个人口味'), findsOneWidget);
        if (choice == 'cancel') {
          await tester.tap(find.text('取消'));
        } else {
          await tester.tap(find.byKey(ValueKey('improvement-save-$choice')));
        }
        await tester.pumpAndSettle();
        final calls = env.server.calls(
          'POST',
          '/v1/recipes/$recipeId/improvements',
        );
        if (choice == 'cancel') {
          expect(calls, isEmpty);
        } else {
          expect(calls, hasLength(1));
          expect((calls.single.body as Map)['microadjust_choice'], choice);
        }
        expect(
          env.server.calls('POST', '/v1/recipes'),
          isEmpty,
          reason: 'working copy cannot accidentally create an original recipe',
        );
      },
    );
  }

  for (final choice in ['cancel', 'taste', 'branch']) {
    testWidgets(
      'actual router improvement $choice preserves visible navigation',
      (tester) async {
        final env = TestEnv.signedIn();
        const branchId = '55555555-5555-4555-8555-555555555555';
        final source = publicationRecipeFixture().toJson();
        (source['author'] as Map)['id'] =
            '77777777-7777-4777-8777-777777777777';
        source['visibility'] = 'public';
        source['ever_public'] = true;
        (source['version'] as Map)['publication_state'] = 'published';
        final branch = publicationRecipeFixture().toJson();
        branch['id'] = branchId;
        (branch['dish'] as Map)['name'] = '我的改良番茄汤';
        env.server.on('GET', '/v1/recipes/$recipeId', (_) => (200, source));
        env.server.on('GET', '/v1/recipes/$branchId', (_) => (200, branch));
        env.server.on(
          'GET',
          '/v1/recipes/$branchId/publication',
          (_) => (200, panelFixture()),
        );
        env.server.on(
          'POST',
          '/v1/recipes/$recipeId/improvement-drafts',
          (_) => (
            201,
            ImprovementDraftOut(
              id: '44444444-4444-4444-8444-444444444444',
              sourceRecipeId: recipeId,
              sourceVersionId: versionId,
              snapshot: publicationRecipeFixture().version.snapshot,
              dishName: '番茄汤',
              aiAssisted: false,
            ).toJson(),
          ),
        );
        env.server.on(
          'POST',
          '/v1/recipes/$recipeId/improvements/preview',
          (_) => (200, improvementPreviewFixture()),
        );
        env.server.on(
          'POST',
          '/v1/recipes/$recipeId/improvements',
          (_) => (
            201,
            {
              'outcome': choice,
              'recipe': choice == 'branch' ? branch : null,
              'profile_version': choice == 'taste' ? 3 : null,
            },
          ),
        );
        await pumpApp(tester, env: env);
        unawaited(
          GoRouter.of(tester.element(find.byType(Scaffold).first))
              .push<void>('/recipes/$recipeId'),
        );
        await tester.pumpAndSettle();
        final start = find.byKey(const ValueKey('improve-recipe-button'));
        await tester.ensureVisible(start);
        await tester.pumpAndSettle();
        await tester.tap(start);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('recipe-editor-content')),
          findsOneWidget,
        );
        expect(find.textContaining('改良工作副本'), findsOneWidget);
        await saveEditor(tester);
        expect(find.text('这个改动更像个人口味'), findsOneWidget);
        if (choice == 'cancel') {
          await tester.tap(find.text('取消'));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('recipe-editor-content')),
            findsOneWidget,
          );
          expect(
            env.server.calls('POST', '/v1/recipes/$recipeId/improvements'),
            isEmpty,
          );
          expect(env.server.calls('POST', '/v1/recipes'), isEmpty);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          return;
        } else {
          await tester.tap(find.byKey(ValueKey('improvement-save-$choice')));
        }
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('recipe-editor-content')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('recipe-detail-content')),
          findsOneWidget,
        );
        if (choice == 'branch') {
          expect(find.text('我的改良番茄汤'), findsWidgets);
          expect(env.server.calls('GET', '/v1/recipes/$branchId'), isNotEmpty);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('recipe-detail-content')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('improve-recipe-button')),
            findsOneWidget,
          );
          expect(find.text('我的改良番茄汤'), findsNothing);
        } else {
          expect(
            find.byKey(const ValueKey('improve-recipe-button')),
            findsOneWidget,
          );
        }
        final saves = env.server.calls(
          'POST',
          '/v1/recipes/$recipeId/improvements',
        );
        expect(saves, choice == 'cancel' ? isEmpty : hasLength(1));
        if (saves.isNotEmpty) {
          expect((saves.single.body as Map)['microadjust_choice'], choice);
          expect((saves.single.body as Map)['source_version_id'], versionId);
        }
        expect(env.server.calls('POST', '/v1/recipes'), isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('mounted notices refresh after confirmed queued record upload', (
    tester,
  ) async {
    final env = TestEnv.signedIn();
    var published = false;
    env.server.on(
      'GET',
      '/v1/recipes/publication/notifications',
      (_) => (
        200,
        {
          'items': <Object>[],
          'license_notice': published ? '首次公开 · CC BY-NC-SA 4.0' : null,
        },
      ),
    );
    env.server.on(
      'POST',
      '/v1/recipes/publication/notifications/acknowledge',
      (_) => (204, null),
    );
    await mount(tester, env, (_) => const PublicationNotices());
    expect(find.textContaining('首次公开'), findsNothing);
    published = true;
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PublicationNotices)),
    );
    container.read(confirmedCookingRecordRevisionProvider.notifier).confirmed();
    await tester.pumpAndSettle();
    expect(find.textContaining('首次公开'), findsOneWidget);
  });

  testWidgets(
    'late publication notice never leaks into another account or acknowledges it',
    (tester) async {
      final env = TestEnv.signedIn();
      final pending = Completer<(int, Object?)>();
      var first = true;
      env.server.on('GET', '/v1/recipes/publication/notifications', (_) {
        if (first) {
          first = false;
          return pending.future;
        }
        return (200, {'items': <Object>[], 'license_notice': null});
      });
      await mount(tester, env, (_) => const PublicationNotices());
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PublicationNotices)),
      );
      await container
          .read(sessionStoreProvider)
          .save(
            TokenPair(
              accessToken: 'second',
              refreshToken: 'second-refresh',
              accessExpiresIn: 1800,
              user: testUser().copyWith(
                id: '55555555-5555-4555-8555-555555555555',
              ),
            ),
          );
      await tester.pumpAndSettle();
      pending.complete((
        200,
        {'items': <Object>[], 'license_notice': '第一账号私有许可通知'},
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('第一账号'), findsNothing);
      expect(
        env.server
            .calls('POST', '/v1/recipes/publication/notifications/acknowledge')
            .where((call) => (call.body as Map)['license_seen'] == true),
        isEmpty,
      );
    },
  );

  testWidgets(
    'account switch while microadjust dialog is open cannot commit to new account',
    (tester) async {
      final env = TestEnv.signedIn();
      env.server.on(
        'POST',
        '/v1/recipes/$recipeId/improvements/preview',
        (_) => (200, improvementPreviewFixture()),
      );
      await mountImprovement(tester, env);
      await saveEditor(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(RecipeEditorPage)),
      );
      await container.read(sessionStoreProvider).clear();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('improvement-save-branch')),
        findsNothing,
      );
      expect(find.text('登录味谱'), findsOneWidget);
      expect(
        env.server.calls('POST', '/v1/recipes/$recipeId/improvements'),
        isEmpty,
      );
    },
  );

  testWidgets(
    'unconvertible microadjust explains reason and disables taste option',
    (tester) async {
      final env = TestEnv.signedIn();
      env.server.on(
        'POST',
        '/v1/recipes/$recipeId/improvements/preview',
        (_) => (200, improvementPreviewFixture(convertible: false)),
      );
      await mountImprovement(tester, env);
      await saveEditor(tester);
      expect(find.text('非用量微调不能转换'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('improvement-save-taste')));
      await tester.pumpAndSettle();
      expect(find.text('非用量微调不能转换'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        env.server.calls('POST', '/v1/recipes/$recipeId/improvements'),
        isEmpty,
      );
      expect(
        (await env.eventQueue.entries(ownerId: env.server.user.id)).where(
          (entry) =>
              entry.write.eventType == 'recipe.improvement_saved_to_taste' ||
              entry.write.eventType == 'recipe.improvement_created',
        ),
        isEmpty,
      );
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
    },
  );
}
