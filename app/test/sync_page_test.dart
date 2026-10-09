import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/api/api_client.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/events/event_upload_lifecycle.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:gram_tree/events/event_queue_mobile.dart' as mobile;
import 'package:gram_tree/events/event_uploader.dart';
import 'package:gram_tree/events/sync_status.dart';
import 'package:gram_tree/l10n/app_localizations.dart';
import 'package:gram_tree/ui_protocol/source_mark.dart';

import 'event_queue_test_executor.dart';
import 'helpers.dart';

void main() {
  for (final confirmation in [false, true]) {
    testWidgets('页面重启等待已接纳事务（确认 $confirmation），保留原内容并恢复同步', (tester) async {
      final fixture = await tester.runAsync(createQueueTestDatabase);
      final database = fixture!;
      final gate = _TransactionGate(confirmation: confirmation);
      final roots = <ProviderContainer>[];
      final queues = <mobile.DriftEventQueue>[];
      Future<void> cleanup() async {
        await tester.runAsync(() async {
          if (!gate.release.isCompleted) gate.release.complete();
          for (final root in roots.reversed) {
            root.dispose();
          }
          final closed = Future.wait([
            for (final queue in queues) queue.close(),
          ]);
          // Failure can leave an admitted transaction and mounted page behind.
          // Pump its fake-zone completion before awaiting close; never await the
          // cached expectLater future inside runAsync or delete an open database.
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          await closed;
          await database.dispose();
        });
      }

      // A pending async expectation delays addTearDown after assertion failure.
      // Release and drain here before that failure reaches the test invoker.
      try {
        final executor = _GatedExecutor(database.open(), gate);
        final queue = mobile.DriftEventQueue(
          mobile.EventQueueDatabase.withExecutor(executor),
        );
        queues.add(queue);
        final env = TestEnv.signedIn(offline: true);
        final write = _dependencyWrite(
          '77777777-7777-4777-8777-000000000001',
          env.server.user.id,
          [],
        );
        await tester.runAsync(() => queue.enqueue(write));
        ProviderContainer root(mobile.DriftEventQueue queue) =>
            ProviderContainer(
              overrides: [
                for (final override in env.overrides)
                  if (override.origin != eventQueueProvider) override,
                eventQueueProvider.overrideWith((ref) {
                  ref.onDispose(queue.close);
                  return queue;
                }),
              ],
            );
        Future<void> page(ProviderContainer container) async {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: buildTheme(Brightness.light),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('zh'),
                home: const Scaffold(body: SyncPendingBadge()),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        final oldRoot = root(queue);
        roots.add(oldRoot);
        await oldRoot.read(sessionStoreProvider).load();
        await page(oldRoot);
        expect(find.text('待同步 1 条'), findsOneWidget);
        gate.armed = true;
        oldRoot.read(offlineSimulationProvider.notifier).set(false);
        final drain = oldRoot.read(eventUploaderProvider).networkRestored();
        // Attach the error consumer before disposal: transaction errors are never
        // suppressed by the production barrier or hidden in an unawaited task.
        final drained = expectLater(drain, completes);
        await tester.pumpAndSettle();
        expect(gate.started.isCompleted, isTrue);
        expect(find.text('待同步 1 条'), findsOneWidget);
        expect(
          env.server.calls('POST', '/v1/sync/writes'),
          hasLength(confirmation ? 1 : 0),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        oldRoot.dispose();
        final firstClose = queue.close();
        final repeatedClose = queue.close();
        await tester.pump();
        expect(gate.closeCalls, 0, reason: '关闭必须等待已接纳事务提交或回滚');
        await expectLater(queue.entries(), throwsStateError);
        gate.release.complete();
        await tester.pumpAndSettle();
        await Future.wait([drained, firstClose, repeatedClose]);
        expect(gate.closeCalls, 1);
        expect(gate.commits, greaterThan(0));
        expect(gate.rollbacks, 0);

        final recovered = mobile.DriftEventQueue(
          mobile.EventQueueDatabase.withExecutor(database.open()),
        );
        queues.add(recovered);
        // Open the same file, not a replacement fake queue or reconstructed count.
        await tester.runAsync(() => recovered.entries());
        final newRoot = root(recovered);
        roots.add(newRoot);
        newRoot.read(offlineSimulationProvider.notifier).set(true);
        await newRoot.read(sessionStoreProvider).load();
        await page(newRoot);
        if (confirmation) {
          expect(find.byKey(const ValueKey('sync-pending')), findsNothing);
        } else {
          expect(find.text('待同步 1 条'), findsOneWidget);
        }
        newRoot.read(offlineSimulationProvider.notifier).set(false);
        var replaySettled = false;
        final replay = newRoot
            .read(eventUploaderProvider)
            .networkRestored()
            .whenComplete(() => replaySettled = true);
        final replayed = expectLater(replay, completes);
        for (var frame = 0; frame < 50 && !replaySettled; frame++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(replaySettled, isTrue);
        await replayed;
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('sync-pending')), findsNothing);
        final calls = env.server.calls('POST', '/v1/sync/writes');
        expect(calls, hasLength(1));
        expect(
          ((calls.single.body as Map)['writes'] as List).single,
          write.toJson(),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        newRoot.dispose();
        final recoveredClose = recovered.close();
        await tester.pump();
        await recoveredClose;
      } finally {
        await cleanup();
      }
    }, skip: kIsWeb);
  }

  testWidgets('页面重启等待旧本机诊断查询结算，重复关闭不打断查询或污染新计数', (tester) async {
    final env = TestEnv.signedIn();
    final oldExecutor = _DiagnosticExecutor(ownerUnknownCount: 1);
    final oldQueue = _RefreshableDiagnosticQueue(oldExecutor);
    ProviderContainer root(mobile.DriftEventQueue queue) => ProviderContainer(
      overrides: [
        for (final override in env.overrides)
          if (override.origin != eventQueueProvider) override,
        eventQueueProvider.overrideWith((ref) {
          ref.onDispose(queue.close);
          return queue;
        }),
      ],
    );
    final oldRoot = root(oldQueue);
    addTearDown(() {
      if (!oldExecutor.releaseCount.isCompleted) {
        oldExecutor.releaseCount.complete();
      }
    });
    await oldRoot.read(sessionStoreProvider).load();
    await _pumpSyncBadge(tester, oldRoot);
    expect(find.text('本机有 1 条旧写入无法确定原账号，已隔离保留，不会上传'), findsOneWidget);
    oldExecutor.blockNextCount = true;
    oldQueue.refresh();
    await tester.pumpAndSettle();
    expect(oldExecutor.countStarted.isCompleted, isTrue);
    // A buffered update must not read from the disposed root.
    oldQueue.refresh();
    await tester.pumpWidget(const SizedBox.shrink());
    oldRoot.dispose();
    final firstClose = oldQueue.close();
    final repeatedClose = oldQueue.close();
    await tester.pump();
    expect(oldExecutor.closed, isFalse, reason: '已发出的真实诊断查询必须先结算再关闭连接');

    final newExecutor = _DiagnosticExecutor(ownerUnknownCount: 2);
    final newQueue = _RefreshableDiagnosticQueue(newExecutor);
    final newRoot = root(newQueue);
    addTearDown(newRoot.dispose);
    await newRoot.read(sessionStoreProvider).load();
    await _pumpSyncBadge(tester, newRoot);
    expect(find.text('本机有 2 条旧写入无法确定原账号，已隔离保留，不会上传'), findsOneWidget);
    oldExecutor.releaseCount.complete();
    await Future.wait([firstClose, repeatedClose]);
    await tester.pumpAndSettle();
    expect(oldExecutor.closed, isTrue);
    expect(oldExecutor.closeCalls, 1);
    expect(oldExecutor.interruptedQueries, 0);
    expect(oldExecutor.countRequests, 2);
    expect(find.text('本机有 1 条旧写入无法确定原账号，已隔离保留，不会上传'), findsNothing);
    expect(find.text('本机有 2 条旧写入无法确定原账号，已隔离保留，不会上传'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('页面两次为什么遇到503，后写入按已有期限重试且原封包保留', (tester) async {
    var available = false;
    final server = FakeServer()
      ..on('POST', '/v1/sync/writes', (request) {
        if (!available) {
          return FakeServer.error(503, 'unavailable', '暂不可用');
        }
        final write = ((request.body as Map)['writes'] as List).single as Map;
        return (
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
        );
      });
    final env = TestEnv.signedIn(server: server);
    final container = ProviderContainer(
      overrides: [
        ...env.overrides,
        eventUploaderProvider.overrideWith((ref) {
          final uploader = EventUploader(
            ref,
            initialBackoff: const Duration(seconds: 3),
            maxBackoff: const Duration(seconds: 12),
          );
          ref.onDispose(uploader.dispose);
          return uploader;
        }),
      ],
    );
    List<Map> sent() => server
        .calls('POST', '/v1/sync/writes')
        .map(
          (request) => ((request.body as Map)['writes'] as List).single as Map,
        )
        .toList();
    Future<void> waitForWrites(
      int count, {
      Duration timeout = const Duration(seconds: 8),
    }) async {
      final until = DateTime.now().add(timeout);
      // DateTime uses wall time while widget timers use fake time. Advance both,
      // polling observable HTTP instead of assuming a particular timer instant.
      while (sent().length < count && DateTime.now().isBefore(until)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump(const Duration(milliseconds: 25));
      }
      expect(sent(), hasLength(count), reason: '已有重试期限必须在前写入更长退避前唤醒');
      await tester.pumpAndSettle();
    }

    try {
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
      await waitForWrites(1);
      Navigator.of(tester.element(find.byKey(const ValueKey('why-panel'))))
          .pop();
      await tester.pumpAndSettle();
      // Separate the two existing deadlines generously, still before the first
      // initial backoff expires. No manual uploader trigger creates the retries.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      await tester.tap(find.text('AI 估算'));
      await tester.pumpAndSettle();
      expect(find.text('水量估算依据'), findsOneWidget);
      expect(find.text('待同步 2 条'), findsOneWidget);
      await waitForWrites(2);
      final originals = sent();
      expect(
        originals.map(
          (write) =>
              ((write['payload'] as Map)['content'] as Map)['component_id'],
        ),
        ['salt', 'water'],
      );
      expect(originals.map((write) => write['owner_id']), [
        server.user.id,
        server.user.id,
      ]);
      expect(originals.map((write) => write['write_id']).toSet(), hasLength(2));

      await waitForWrites(3);
      expect(sent()[2], originals[0]);
      final retained = await env.eventQueue.entries();
      expect(retained[1].nextAttemptAt, isNotNull);
      expect(
        retained[0].nextAttemptAt!.isAfter(retained[1].nextAttemptAt!),
        isTrue,
      );
      expect(
        retained[0].nextAttemptAt!.isAfter(
          DateTime.now().toUtc().add(const Duration(seconds: 3)),
        ),
        isTrue,
      );
      await waitForWrites(4, timeout: const Duration(seconds: 3));
      expect(sent()[3], originals[1]);
      expect(find.text('待同步 2 条'), findsOneWidget);

      available = true;
      container.read(offlineSimulationProvider.notifier).set(true);
      await tester.pumpAndSettle();
      container.read(offlineSimulationProvider.notifier).set(false);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('sync-pending')), findsNothing);
      expect(sent(), [...originals, ...originals, ...originals]);
      expect(tester.takeException(), isNull);
    } finally {
      container.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    }
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

// The production Drift adapter executes real query/close ordering against this
// gated transport. It needs no native SQLite import, so the page seam runs on
// both the VM and Chrome; business queue state is not mocked or inspected.
class _RefreshableDiagnosticQueue extends mobile.DriftEventQueue {
  _RefreshableDiagnosticQueue(drift.QueryExecutor executor)
    : super(mobile.EventQueueDatabase.withExecutor(executor));
  final _notifications = StreamController<void>.broadcast();
  @override
  Stream<void> get changes => _notifications.stream;
  void refresh() => _notifications.add(null);
  @override
  Future<void> close() async {
    await super.close();
    await _notifications.close();
  }
}

class _TransactionGate {
  _TransactionGate({required this.confirmation});
  final bool confirmation;
  bool armed = false;
  final started = Completer<void>();
  final release = Completer<void>();
  int closeCalls = 0;
  int commits = 0;
  int rollbacks = 0;

  Future<void> hold() async {
    armed = false;
    started.complete();
    await release.future;
  }
}

// Delegates every SQL statement to real SQLite. The gate holds an admitted
// transaction, not a fabricated queue state or count, across public root disposal.
class _GatedExecutor extends drift.QueryExecutor {
  _GatedExecutor(this.delegate, this.gate);
  final drift.QueryExecutor delegate;
  final _TransactionGate gate;
  @override
  drift.SqlDialect get dialect => delegate.dialect;
  @override
  Future<bool> ensureOpen(drift.QueryExecutorUser user) =>
      delegate.ensureOpen(user);
  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) async {
    if (gate.armed &&
        gate.confirmation &&
        statement.contains('queued_events') &&
        args.length == 2) {
      await gate.hold();
    }
    return delegate.runSelect(statement, args);
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async {
    if (gate.armed && !gate.confirmation && args.contains('uploading')) {
      await gate.hold();
    }
    return delegate.runUpdate(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) =>
      delegate.runInsert(statement, args);
  @override
  Future<int> runDelete(String statement, List<Object?> args) =>
      delegate.runDelete(statement, args);
  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) =>
      delegate.runCustom(statement, args);
  @override
  Future<void> runBatched(drift.BatchedStatements statements) =>
      delegate.runBatched(statements);
  @override
  drift.QueryExecutor beginExclusive() =>
      _GatedExecutor(delegate.beginExclusive(), gate);
  @override
  drift.TransactionExecutor beginTransaction() =>
      _GatedTransaction(delegate.beginTransaction(), gate);
  @override
  Future<void> close() {
    gate.closeCalls++;
    return delegate.close();
  }
}

class _GatedTransaction extends _GatedExecutor
    implements drift.TransactionExecutor {
  _GatedTransaction(drift.TransactionExecutor super.delegate, super.gate);
  drift.TransactionExecutor get transaction =>
      delegate as drift.TransactionExecutor;
  @override
  bool get supportsNestedTransactions => transaction.supportsNestedTransactions;
  @override
  Future<void> send() async {
    await transaction.send();
    gate.commits++;
  }

  @override
  Future<void> rollback() async {
    await transaction.rollback();
    gate.rollbacks++;
  }
}

class _DiagnosticExecutor extends drift.QueryExecutor {
  _DiagnosticExecutor({required this.ownerUnknownCount});
  final int ownerUnknownCount;
  bool blockNextCount = false;
  bool closed = false;
  int closeCalls = 0;
  int interruptedQueries = 0;
  int countRequests = 0;
  final countStarted = Completer<void>();
  final releaseCount = Completer<void>();
  @override
  drift.SqlDialect get dialect => drift.SqlDialect.sqlite;
  @override
  Future<bool> ensureOpen(drift.QueryExecutorUser user) async => true;
  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) async {
    if (closed) throw StateError('Query started after connection close');
    if (!statement.toLowerCase().contains('count(')) return [];
    countRequests++;
    if (blockNextCount) {
      blockNextCount = false;
      countStarted.complete();
      await releaseCount.future;
    }
    if (closed) {
      interruptedQueries++;
      throw StateError('Connection closed before diagnostic response');
    }
    return [
      {
        'c0': statement.contains('queued_events') ? ownerUnknownCount : 0,
        'owner_unknown_count': ownerUnknownCount,
        'rejected_count': 0,
      },
    ];
  }

  @override
  Future<void> close() async {
    closeCalls++;
    closed = true;
  }

  @override
  drift.QueryExecutor beginExclusive() => this;
  @override
  drift.TransactionExecutor beginTransaction() =>
      throw UnsupportedError('Read-only transport');
  @override
  Future<void> runBatched(drift.BatchedStatements statements) =>
      throw UnsupportedError('Read-only transport');
  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) =>
      throw UnsupportedError('Read-only transport');
  @override
  Future<int> runDelete(String statement, List<Object?> args) =>
      throw UnsupportedError('Read-only transport');
  @override
  Future<int> runInsert(String statement, List<Object?> args) =>
      throw UnsupportedError('Read-only transport');
  @override
  Future<int> runUpdate(String statement, List<Object?> args) =>
      throw UnsupportedError('Read-only transport');
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
