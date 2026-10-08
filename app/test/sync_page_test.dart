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
