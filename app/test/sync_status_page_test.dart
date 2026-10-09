import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:gram_tree/events/event_uploader.dart';
import 'package:gram_tree/features/me/sync_status_page.dart';
import 'package:gram_tree/l10n/app_localizations.dart';

import 'helpers.dart';

QueuedEvent write(String owner, int number) => QueuedEvent.write(
  id: '77777777-7777-4777-8777-${number.toString().padLeft(12, '0')}',
  ownerId: owner,
  writeType: 'experience.event',
  deviceTime: DateTime.utc(2026, 10, 8),
  payload: {
    'event_type': 'pipeline.self_check',
    'type_version': 1,
    'device_id': 'test',
    'app_version': 'test',
    'content': {'ping': 'private-content-never-render'},
  },
);

Future<void> page(WidgetTester tester, ProviderContainer root) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: root,
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: const SyncStatusPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('真实页面事件失败后手动重试复用原写入，连点不双投递，显示服务端确认时间', (tester) async {
    final server = FakeServer();
    final recovered = Completer<(int, Object?)>();
    var available = false;
    server.on('POST', '/v1/sync/writes', (request) {
      if (!available) return FakeServer.error(503, 'unavailable', '暂不可用');
      return recovered.future;
    });
    final env = TestEnv.signedIn(server: server);
    final root = ProviderContainer(
      overrides: [
        ...env.overrides,
        eventUploaderProvider.overrideWith((ref) {
          final uploader = EventUploader(ref, maxAttempts: 1);
          ref.onDispose(uploader.dispose);
          return uploader;
        }),
      ],
    );
    addTearDown(root.dispose);
    await root.read(sessionStoreProvider).load();
    await page(tester, root);
    await tester.tap(find.text('本机队列记录'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byKey(const ValueKey('why-panel')))).pop();
    await tester.pumpAndSettle();
    expect(find.text('失败 1 条'), findsOneWidget);
    expect(find.text('尚未同步'), findsOneWidget);
    final original = server.calls('POST', '/v1/sync/writes').single.body;
    available = true;
    await tester.tap(find.byKey(const ValueKey('sync-manual-retry')));
    await tester.tap(find.byKey(const ValueKey('sync-manual-retry')));
    await tester.pumpAndSettle();
    expect(server.calls('POST', '/v1/sync/writes'), hasLength(2));
    expect(server.calls('POST', '/v1/sync/writes').last.body, original);
    final id =
        (((original as Map)['writes'] as List).single as Map)['write_id'];
    recovered.complete((
      200,
      {
        'results': [
          {
            'write_id': id,
            'status': 'confirmed',
            'confirmed_at': '2026-10-08T10:11:12Z',
            'result': {'resource_type': 'experience.event', 'resource_id': id},
          },
        ],
      },
    ));
    await tester.pumpAndSettle();
    expect(find.text('未完成 0 条'), findsOneWidget);
    expect(find.text('失败 0 条'), findsOneWidget);
    expect(find.text('尚未同步'), findsNothing);
    expect(
      find.textContaining(
        DateTime.parse('2026-10-08T10:11:12Z').toLocal().toString(),
      ),
      findsOneWidget,
    );
    await root.read(eventUploaderProvider).triggerUpload();
    await tester.pumpAndSettle();
    expect(server.calls('POST', '/v1/sync/writes'), hasLength(2));
  });

  testWidgets('当前账号显示互斥分类与安全诊断，不显示别人的失败或私密内容', (tester) async {
    final env = TestEnv.signedIn(offline: true);
    final owner = env.server.user.id;
    final root = ProviderContainer(overrides: env.overrides);
    addTearDown(root.dispose);
    await root.read(sessionStoreProvider).load();
    await page(tester, root);
    final states = [
      WriteState.pending,
      WriteState.deferred,
      WriteState.loginPaused,
      WriteState.conflict,
      WriteState.failed,
      WriteState.uploading,
    ];
    final reasons = [
      null,
      'dependency_not_arrived',
      'login_required',
      'conflict_choice_required',
      'forbidden:private-token-and-stack',
      null,
    ];
    for (var i = 0; i < states.length; i++) {
      await env.eventQueue.enqueue(write(owner, i + 1));
      final entry = (await env.eventQueue.entries(ownerId: owner)).last;
      await env.eventQueue.update(
        entry.change(state: states[i], reasonCode: reasons[i]),
      );
    }
    await env.eventQueue.enqueue(
      write('88888888-8888-4888-8888-888888888888', 99),
    );
    await tester.pumpAndSettle();
    expect(find.text('未完成 6 条'), findsOneWidget);
    expect(find.text('待上传 2 条'), findsOneWidget);
    expect(find.text('暂缓 1 条'), findsOneWidget);
    expect(find.text('登录暂停 1 条'), findsOneWidget);
    expect(find.text('等待冲突选择 1 条'), findsOneWidget);
    expect(find.text('失败 1 条'), findsOneWidget);
    expect(find.text('尚未同步'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(
        const ValueKey('sync-item-77777777-7777-4777-8777-000000000005'),
      ),
      300,
    );
    expect(find.textContaining('权限或内容校验未通过'), findsOneWidget);
    expect(find.textContaining('private'), findsNothing);
    expect(find.textContaining('000000000099'), findsNothing);
  });
}
