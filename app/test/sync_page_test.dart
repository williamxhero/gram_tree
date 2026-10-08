import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/api/api_client.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/events/event_upload_lifecycle.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:gram_tree/events/event_uploader.dart';
import 'package:gram_tree/events/sync_status.dart';
import 'package:gram_tree/l10n/app_localizations.dart';
import 'package:gram_tree/ui_protocol/source_mark.dart';

import 'helpers.dart';

void main() {
  testWidgets('21层逆序依赖不消耗等待重试额度，页面待同步全部确认且每条只发一次', (tester) async {
    final server = FakeServer();
    final committed = <String>{};
    server.on('POST', '/v1/sync/writes', (request) {
      final write = ((request.body as Map)['writes'] as List).single as Map;
      final id = write['write_id'] as String;
      final ready = (write['dependencies'] as List).every(committed.contains);
      if (ready) committed.add(id);
      return (
        200,
        WriteBatchResponse(
          results: [
            WriteResult(
              writeId: id,
              status: ready
                  ? WriteResultStatusEnum.confirmed
                  : WriteResultStatusEnum.deferred_,
              reasonCode: ready ? null : 'dependency_not_arrived',
              result: ready
                  ? WriteResourceResult(
                      resourceType: 'experience.event',
                      resourceId: id,
                    )
                  : null,
            ),
          ],
        ).toJson(),
      );
    });
    final env = TestEnv.signedIn(server: server, offline: true);
    String id(int i) =>
        '22222222-2222-4222-8222-${i.toString().padLeft(12, '0')}';
    for (var i = 1; i <= 21; i++) {
      await env.eventQueue.enqueue(
        QueuedEvent.write(
          id: id(i),
          ownerId: server.user.id,
          writeType: 'experience.event',
          deviceTime: DateTime.now().toUtc(),
          dependencies: i == 21 ? [] : [id(i + 1)],
          payload: {
            'event_type': 'pipeline.self_check',
            'type_version': 1,
            'device_id': 'chain-device',
            'app_version': 'test',
            'correlation': {},
            'content': {'ping': 'chain-$i'},
          },
        ),
      );
    }
    final container = ProviderContainer(overrides: env.overrides);
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: EventUploadTrigger(
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: const Scaffold(body: SyncPendingBadge()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('待同步 21 条'), findsOneWidget);
    container.read(offlineSimulationProvider.notifier).set(false);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sync-pending')), findsNothing);
    final calls = server.calls('POST', '/v1/sync/writes');
    expect(calls, hasLength(21));
    expect(
      calls.map(
        (r) => (((r.body as Map)['writes'] as List).single as Map)['write_id'],
      ),
      [for (var i = 21; i >= 1; i--) id(i)],
    );
  });

  testWidgets('页面为什么操作断网显示当前账号待同步，确认后减少', (tester) async {
    final server = FakeServer();
    server.on('POST', '/v1/sync/writes', (request) {
      final writes = ((request.body as Map)['writes'] as List).cast<Map>();
      return (
        200,
        {
          'results': [
            for (final write in writes)
              {
                'write_id': write['write_id'],
                'status': 'confirmed',
                'result': {
                  'resource_type': 'experience.event',
                  'resource_id': write['write_id'],
                },
              },
          ],
        },
      );
    });
    final env = TestEnv.signedIn(server: server, offline: true);
    final container = ProviderContainer(overrides: env.overrides);
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: EventUploadTrigger(
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: const Scaffold(
              body: Column(
                children: [
                  SourceMark(
                    sourceType: 'verified',
                    componentId: 'salt',
                    value: '3 g',
                    basisText: '已验证的作者用量',
                    required: true,
                    onAction: null,
                  ),
                  SyncPendingBadge(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('已验证'));
    await tester.pumpAndSettle();
    expect(find.text('已验证的作者用量'), findsOneWidget);
    expect(find.text('待同步 1 条'), findsOneWidget);
    expect(server.calls('POST', '/v1/sync/writes'), isEmpty);

    container.read(offlineSimulationProvider.notifier).set(false);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sync-pending')), findsNothing);
    final request = server.calls('POST', '/v1/sync/writes').single;
    final write = ((request.body as Map)['writes'] as List).single as Map;
    expect(write['owner_id'], server.user.id);
    expect((write['payload'] as Map)['event_type'], 'ui.why_panel_opened');
  });

  testWidgets('页面两次为什么操作断网计数递增，联网按动作顺序确认后减少', (tester) async {
    final env = TestEnv.signedIn(offline: true);
    final container = ProviderContainer(overrides: env.overrides);
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    await _pumpSyncBadge(
      tester,
      container,
      children: const [
        SourceMark(
          sourceType: 'verified',
          componentId: 'salt',
          value: '3 g',
          basisText: '作者用量',
          required: true,
          onAction: null,
        ),
        SourceMark(
          sourceType: 'ai_estimated',
          componentId: 'water',
          value: '200 ml',
          basisText: '水量估算依据',
          required: true,
          onAction: null,
        ),
      ],
    );
    await tester.tap(find.text('已验证'));
    await tester.pumpAndSettle();
    expect(find.text('作者用量'), findsOneWidget);
    expect(find.text('待同步 1 条'), findsOneWidget);
    expect(env.server.calls('POST', '/v1/sync/writes'), isEmpty);
    Navigator.of(tester.element(find.byKey(const ValueKey('why-panel')))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI 估算'));
    await tester.pumpAndSettle();
    expect(find.text('水量估算依据'), findsOneWidget);
    expect(find.text('待同步 2 条'), findsOneWidget);
    expect(env.server.calls('POST', '/v1/sync/writes'), isEmpty);
    container.read(offlineSimulationProvider.notifier).set(false);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sync-pending')), findsNothing);
    final calls = env.server.calls('POST', '/v1/sync/writes');
    expect(calls, hasLength(2));
    final writes = calls
        .map(
          (request) => ((request.body as Map)['writes'] as List).single as Map,
        )
        .toList();
    expect(writes.map((write) => write['owner_id']), [
      env.server.user.id,
      env.server.user.id,
    ]);
    expect(writes.map((write) => (write['payload'] as Map)['event_type']), [
      'ui.why_panel_opened',
      'ui.why_panel_opened',
    ]);
    expect(
      writes.map(
        (write) =>
            ((write['payload'] as Map)['content'] as Map)['component_id'],
      ),
      ['salt', 'water'],
    );
    expect(writes.map((write) => write['write_id']).toSet(), hasLength(2));
  });

  testWidgets('真实页面事件重试超限后显示原因，内容保留且不再自动上传', (tester) async {
    final server = FakeServer()
      ..on(
        'POST',
        '/v1/sync/writes',
        (_) => FakeServer.error(503, 'unavailable', '暂不可用'),
      );
    final env = TestEnv.signedIn(server: server, offline: true);
    final container = ProviderContainer(
      overrides: [
        ...env.overrides,
        eventUploaderProvider.overrideWith((ref) {
          // The real recorder first attempts the offline transport; reconnect
          // then performs the final server attempt without resetting its history.
          final uploader = EventUploader(ref, maxAttempts: 2);
          ref.onDispose(uploader.dispose);
          return uploader;
        }),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: EventUploadTrigger(
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: const Scaffold(
              body: Column(
                children: [
                  SourceMark(
                    sourceType: 'verified',
                    componentId: 'salt',
                    value: '3 g',
                    basisText: '作者用量',
                    required: true,
                    onAction: null,
                  ),
                  SyncPendingBadge(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('已验证'));
    await tester.pumpAndSettle();
    expect(find.text('待同步 1 条'), findsOneWidget);
    container.read(offlineSimulationProvider.notifier).set(false);
    await tester.pumpAndSettle();
    expect(find.text('待同步 1 条'), findsOneWidget);
    expect(find.text('重试次数已达上限，已保留 1 条内容'), findsOneWidget);
    final request = server.calls('POST', '/v1/sync/writes').single;
    final write = ((request.body as Map)['writes'] as List).single as Map;
    final retained = (await env.eventQueue.entries(ownerId: server.user.id))
        .single;
    expect(retained.write.toJson(), write);
    expect(retained.write.content, {
      'component_id': 'salt',
      'source_type': 'verified',
    });
    expect(
      retained.reasonCode,
      'retry_limit_exceeded:network_or_server_failure',
    );
    expect(retained.attempts, 2);
    await container.read(eventUploaderProvider).triggerUpload();
    await tester.pump(const Duration(minutes: 1));
    expect(server.calls('POST', '/v1/sync/writes'), hasLength(1));
    expect(find.text('重试次数已达上限，已保留 1 条内容'), findsOneWidget);
  });

  testWidgets('页面前置重试超限保留三条计数，不上传子写入或消耗无关写入尝试', (tester) async {
    const parentId = '77777777-7777-4777-8777-000000000001';
    const childId = '77777777-7777-4777-8777-000000000002';
    const unrelatedId = '77777777-7777-4777-8777-000000000003';
    final env = TestEnv.signedIn(offline: true);
    env.server.on(
      'POST',
      '/v1/sync/writes',
      (_) => FakeServer.error(503, 'unavailable', '暂不可用'),
    );
    for (final write in [
      _dependencyWrite(childId, env.server.user.id, [parentId]),
      _dependencyWrite(parentId, env.server.user.id, []),
      _dependencyWrite(unrelatedId, env.server.user.id, []),
    ]) {
      await env.eventQueue.enqueue(write);
    }
    final container = ProviderContainer(
      overrides: [
        ...env.overrides,
        eventUploaderProvider.overrideWith((ref) {
          final uploader = EventUploader(ref, maxAttempts: 2);
          ref.onDispose(uploader.dispose);
          return uploader;
        }),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    await _pumpSyncBadge(tester, container);
    expect(find.text('待同步 3 条'), findsOneWidget);
    expect(env.server.calls('POST', '/v1/sync/writes'), isEmpty);
    container.read(offlineSimulationProvider.notifier).set(false);
    await tester.pumpAndSettle();
    expect(find.text('待同步 3 条'), findsOneWidget);
    expect(find.text('重试次数已达上限，已保留 1 条内容'), findsOneWidget);
    expect(find.text('前置写入失败，已保留 1 条内容'), findsOneWidget);
    expect(
      env.server
          .calls('POST', '/v1/sync/writes')
          .map(
            (request) =>
                (((request.body as Map)['writes'] as List).single
                    as Map)['write_id'],
          ),
      [parentId],
    );
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('待同步 3 条'), findsOneWidget);
    expect(env.server.calls('POST', '/v1/sync/writes'), hasLength(1));
  });

  for (final outcome in ['failed', 'conflict']) {
    for (final parentFirst in [true, false]) {
      testWidgets('页面前置 $outcome（父先入队 $parentFirst）显示原因且不上传子写入', (
        tester,
      ) async {
        const parentId = '33333333-3333-4333-8333-000000000001';
        const childId = '33333333-3333-4333-8333-000000000002';
        final env = TestEnv.signedIn(offline: true);
        env.server.on(
          'POST',
          '/v1/sync/writes',
          (request) => (
            200,
            {
              'results': [
                {
                  'write_id':
                      (((request.body as Map)['writes'] as List).single
                          as Map)['write_id'],
                  'status': outcome,
                  'reason_code': 'private-parent-reason-do-not-display',
                },
              ],
            },
          ),
        );
        final parent = _dependencyWrite(parentId, env.server.user.id, []);
        final child = _dependencyWrite(childId, env.server.user.id, [parentId]);
        for (final write in parentFirst ? [parent, child] : [child, parent]) {
          await env.eventQueue.enqueue(write);
        }
        final container = ProviderContainer(overrides: env.overrides);
        addTearDown(container.dispose);
        await container.read(sessionStoreProvider).load();
        await _pumpSyncBadge(tester, container);
        expect(find.text('待同步 2 条'), findsOneWidget);
        container.read(offlineSimulationProvider.notifier).set(false);
        await tester.pumpAndSettle();
        expect(find.text('待同步 2 条'), findsOneWidget);
        expect(
          find.text(
            outcome == 'failed' ? '前置写入失败，已保留 1 条内容' : '前置写入存在冲突，1 条暂缓同步',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('private-parent'), findsNothing);
        final calls = env.server.calls('POST', '/v1/sync/writes');
        expect(calls, hasLength(1));
        expect(
          (((calls.single.body as Map)['writes'] as List).single
              as Map)['write_id'],
          parentId,
        );
        await container.read(eventUploaderProvider).triggerUpload();
        await tester.pumpAndSettle();
        expect(env.server.calls('POST', '/v1/sync/writes'), hasLength(1));
      });
    }
  }

  testWidgets('页面未知依赖暂缓并解释，内容保留而不假装确认', (tester) async {
    const id = '44444444-4444-4444-8444-000000000001';
    const missing = '44444444-4444-4444-8444-000000000002';
    final env = TestEnv.signedIn(offline: true);
    env.server.on(
      'POST',
      '/v1/sync/writes',
      (_) => (
        200,
        {
          'results': [
            {
              'write_id': id,
              'status': 'deferred',
              'reason_code': 'dependency_not_arrived',
            },
          ],
        },
      ),
    );
    await env.eventQueue.enqueue(
      _dependencyWrite(id, env.server.user.id, [missing]),
    );
    final container = ProviderContainer(overrides: env.overrides);
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    await _pumpSyncBadge(tester, container);
    expect(find.text('待同步 1 条'), findsOneWidget);
    container.read(offlineSimulationProvider.notifier).set(false);
    await tester.pumpAndSettle();
    expect(find.text('待同步 1 条'), findsOneWidget);
    expect(find.text('依赖写入尚未到达，1 条暂缓同步'), findsOneWidget);
    expect(env.server.calls('POST', '/v1/sync/writes'), hasLength(1));
    final retained = (await env.eventQueue.entries(ownerId: env.server.user.id))
        .single;
    expect(retained.state, WriteState.deferred);
    expect(retained.write.dependencies, [missing]);
    expect(retained.write.content, {'ping': 'retained'});
    // This case intentionally retains a live deferred retry. Flutter checks
    // timers before addTearDown; stop it here, after all behavior assertions.
    container.read(eventUploaderProvider).dispose();
  });

  testWidgets('页面依赖环保留两条内容并解释，不上传任何环内写入', (tester) async {
    const first = '55555555-5555-4555-8555-000000000001';
    const second = '55555555-5555-4555-8555-000000000002';
    final env = TestEnv.signedIn(offline: true);
    await env.eventQueue.enqueue(
      _dependencyWrite(first, env.server.user.id, [second]),
    );
    await env.eventQueue.enqueue(
      _dependencyWrite(second, env.server.user.id, [first]),
    );
    final container = ProviderContainer(overrides: env.overrides);
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    await _pumpSyncBadge(tester, container);
    expect(find.text('待同步 2 条'), findsOneWidget);
    container.read(offlineSimulationProvider.notifier).set(false);
    await tester.pumpAndSettle();
    expect(find.text('待同步 2 条'), findsOneWidget);
    expect(find.text('依赖写入存在循环，已保留 2 条内容'), findsOneWidget);
    expect(env.server.calls('POST', '/v1/sync/writes'), isEmpty);
  });

  for (final delayedKind in [
    'confirmation',
    'refresh_success',
    'refresh_failure',
  ]) {
    testWidgets('切换账号隔离旧响应 $delayedKind，原账号待同步仍保留', (tester) async {
      final server = FakeServer();
      final alice = server.user;
      final delayed = Completer<(int, Object?)>();
      final oldTokens = server.tokens();
      if (delayedKind == 'confirmation') {
        server.on('POST', '/v1/sync/writes', (_) => delayed.future);
      } else {
        server.on(
          'POST',
          '/v1/sync/writes',
          (_) => FakeServer.error(401, 'token_expired', '登录已过期'),
        );
        server.on('POST', '/v1/auth/refresh', (_) => delayed.future);
      }
      final env = TestEnv.signedIn(server: server, offline: true);
      final container = ProviderContainer(overrides: env.overrides);
      addTearDown(container.dispose);
      final session = container.read(sessionStoreProvider);
      await session.load();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: EventUploadTrigger(
            child: MaterialApp(
              theme: buildTheme(Brightness.light),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('zh'),
              home: const Scaffold(
                body: Column(
                  children: [
                    SourceMark(
                      sourceType: 'verified',
                      componentId: 'salt',
                      value: '3 g',
                      basisText: '作者用量',
                      required: true,
                      onAction: null,
                    ),
                    SyncPendingBadge(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('已验证'));
      await tester.pumpAndSettle();
      expect(find.text('待同步 1 条'), findsOneWidget);
      container.read(offlineSimulationProvider.notifier).set(false);
      await tester.pumpAndSettle();
      final original = server.calls('POST', '/v1/sync/writes').single;
      final write = ((original.body as Map)['writes'] as List).single as Map;
      server.user = UserOut.fromJson({
        ...alice.toJson(),
        'id': 'd54b2956-2f93-4ea9-a1d4-7701d258ae45',
        'nickname': '另一个账号',
      });
      await session.save(TokenPair.fromJson(server.tokens()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('sync-pending')), findsNothing);
      delayed.complete(
        delayedKind == 'refresh_success'
            ? (200, oldTokens)
            : delayedKind == 'refresh_failure'
            ? FakeServer.error(401, 'refresh_invalid', '旧会话已失效')
            : (
                200,
                {
                  'results': [
                    {
                      'write_id': write['write_id'],
                      'status': 'confirmed',
                      'result': {
                        'resource_type': 'experience.event',
                        'resource_id': write['write_id'],
                      },
                    },
                  ],
                },
              ),
      );
      await tester.pumpAndSettle();
      expect(server.calls('POST', '/v1/sync/writes'), hasLength(1));
      expect(original.headers['Authorization'], 'Bearer access-0');
      container.read(offlineSimulationProvider.notifier).set(true);
      server.user = alice;
      await session.save(TokenPair.fromJson(server.tokens()));
      await tester.pumpAndSettle();
      expect(find.text('待同步 1 条'), findsOneWidget);
    });
  }
}

Future<void> _pumpSyncBadge(
  WidgetTester tester,
  ProviderContainer container, {
  List<Widget> children = const [],
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: EventUploadTrigger(
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: Column(children: [...children, const SyncPendingBadge()]),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

QueuedEvent _dependencyWrite(
  String id,
  String owner,
  List<String> dependencies,
) => QueuedEvent.write(
  id: id,
  ownerId: owner,
  writeType: 'experience.event',
  deviceTime: DateTime.utc(2026, 10, 8),
  dependencies: dependencies,
  payload: {
    'event_type': 'pipeline.self_check',
    'type_version': 1,
    'device_id': 'test',
    'app_version': 'test',
    'content': {'ping': 'retained'},
  },
);
