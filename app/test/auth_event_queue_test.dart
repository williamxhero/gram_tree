import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gram_tree/api/api_client.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:gram_tree/events/fake_event_queue.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';
import 'login_test.dart' show enterEmail, enterCode;
import 'settings_test.dart' show openSettings;

const _aliceWrite = '54ba0efd-13fd-4728-bfcb-1f56d35eb3e8';
const _bobWrite = '2662fbcd-a038-44ed-81a4-b54f0884d2f6';
const _bobId = 'd54b2956-2f93-4ea9-a1d4-7701d258ae45';

Future<TestEnv> _fixture() async {
  final env = TestEnv.signedIn();
  for (final item in [(_aliceWrite, env.server.user.id), (_bobWrite, _bobId)]) {
    await env.eventQueue.enqueue(
      QueuedEvent(
        id: item.$1,
        ownerId: item.$2,
        eventType: 'pipeline.self_check',
        typeVersion: 1,
        deviceId: 'device-1',
        deviceTime: DateTime.utc(2026, 10, 8),
        appVersion: 'test',
        content: {'ping': 'retained'},
      ),
    );
    // Fixture represents already rejected payloads. They still count as work
    // needing attention, and must survive an ordinary logout without leaking.
    await env.eventQueue.reject(item.$1, reasonCode: 'invalid_content');
  }
  env.server.on('POST', '/v1/sync/writes', (request) {
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
  return env;
}

Future<void> _logout(WidgetTester tester) async {
  await openSettings(tester);
  await tapVisible(tester, find.text('退出登录'));
  await tester.tap(find.widgetWithText(FilledButton, '退出登录'));
  await tester.pumpAndSettle();
  expect(find.text('登录味谱'), findsOneWidget);
}

Future<void> _login(WidgetTester tester) async {
  await enterEmail(tester, testEmail);
  await enterCode(tester, goodCode);
}

void main() {
  testWidgets('Alice 的延迟昵称保存不能将 Bob 令牌绑定到 Alice，重启仍显示 Bob', (tester) async {
    final env = await _fixture();
    final alice = env.server.user;
    await pumpApp(tester, env: env);
    final session = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    ).read(sessionStoreProvider);
    final delayed = Completer<(int, Object?)>();
    env.server.on('PATCH', '/v1/me', (_) => delayed.future);
    await tapTab(tester, 4);
    await tapVisible(tester, find.byTooltip('改昵称'));
    await tester.enterText(
      find.byKey(const ValueKey('nickname-input')),
      'Alice 新昵称',
    );
    await tester.tap(find.text('保存'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(env.server.calls('PATCH', '/v1/me'), hasLength(1));
    env.server.user = UserOut.fromJson({
      ...alice.toJson(),
      'id': _bobId,
      'nickname': 'Bob 的账号',
    });
    await session.save(TokenPair.fromJson(env.server.tokens()));
    delayed.complete((200, {...alice.toJson(), 'nickname': 'Alice 新昵称'}));
    await tester.pumpAndSettle();
    expect(find.text('Bob 的账号'), findsOneWidget);
    expect(find.text('待同步 1 条'), findsOneWidget);
    await restartApp(tester, env);
    await tapTab(tester, 4);
    expect(find.text('Bob 的账号'), findsOneWidget);
    expect(find.text('Alice 新昵称'), findsNothing);
    expect(find.text('待同步 1 条'), findsOneWidget);
    expect(find.text('登录味谱'), findsNothing);
  });

  testWidgets('确认退出立即隔离账号，不等待服务端退出或在途上传', (tester) async {
    final env = await _fixture();
    await pumpApp(tester, env: env);
    final delayed = Completer<(int, Object?)>();
    env.server.on('POST', '/v1/auth/logout', (_) => delayed.future);
    await openSettings(tester);
    await tapVisible(tester, find.text('退出登录'));
    await tester.tap(find.widgetWithText(FilledButton, '退出登录'));
    await tester.pumpAndSettle();
    expect(find.text('登录味谱'), findsOneWidget);
    expect(env.server.calls('POST', '/v1/auth/logout'), hasLength(1));
    delayed.complete((204, null));
    await tester.pumpAndSettle();
    await restartApp(tester, env);
    expect(find.text('登录味谱'), findsOneWidget);
    await _login(tester);
    expect(find.text('待同步 1 条'), findsOneWidget);
  });

  testWidgets('旧退出响应不能退出刚重新登录的同一账号，重启仍保持新登录', (tester) async {
    final env = await _fixture();
    await pumpApp(tester, env: env);
    final session = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    ).read(sessionStoreProvider);
    final delayed = Completer<(int, Object?)>();
    env.server.on('POST', '/v1/auth/logout', (_) => delayed.future);
    await openSettings(tester);
    await tapVisible(tester, find.text('退出登录'));
    await tester.tap(find.widgetWithText(FilledButton, '退出登录'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(env.server.calls('POST', '/v1/auth/logout'), hasLength(1));
    await session.save(TokenPair.fromJson(env.server.tokens()));
    delayed.complete((204, null));
    await tester.pumpAndSettle();
    await restartApp(tester, env);
    expect(find.text('登录味谱'), findsNothing);
    expect(find.text('待同步 1 条'), findsOneWidget);
    await tapTab(tester, 4);
    expect(find.text('味友0001'), findsOneWidget);
  });

  for (final operation in ['logout', 'deletion', 'withdrawal']) {
    testWidgets('Alice 的延迟 $operation 不退出 Bob、不删除 Bob 内容，重启仍隔离', (
      tester,
    ) async {
      final env = await _fixture();
      final alice = env.server.user;
      await pumpApp(tester, env: env);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );
      final session = container.read(sessionStoreProvider);
      final delayed = Completer<(int, Object?)>();
      final endpoint = operation == 'logout'
          ? '/v1/auth/logout'
          : operation == 'deletion'
          ? '/v1/me/deletion'
          : '/v1/me/consents';
      env.server.on('POST', endpoint, (_) => delayed.future);
      await openSettings(tester);
      if (operation == 'logout') {
        await tapVisible(tester, find.text('退出登录'));
        await tester.tap(find.widgetWithText(FilledButton, '退出登录'));
      } else if (operation == 'deletion') {
        await tapVisible(tester, find.text('注销账号'));
        await tapVisible(tester, find.text('发送验证码'));
        await tester.enterText(
          find.byKey(const ValueKey('code-input')),
          goodCode,
        );
        await tester.pumpAndSettle();
        await tapVisible(tester, find.byKey(const ValueKey('delete-check')));
        await tester.tap(find.byKey(const ValueKey('delete-confirm')));
      } else {
        await tapVisible(tester, find.text('撤回同意'));
        await tester.tap(find.text('撤回并退出'));
      }
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(env.server.calls('POST', endpoint), hasLength(1));
      env.server.user = UserOut.fromJson({
        ...alice.toJson(),
        'id': _bobId,
        'nickname': 'Bob 的账号',
      });
      // Another login arrives at the authentication boundary while the visible
      // Alice operation is awaiting HTTP. All assertions remain on real pages.
      await session.save(TokenPair.fromJson(env.server.tokens()));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      delayed.complete(
        operation == 'deletion'
            ? (
                202,
                {
                  'status': 'deleting',
                  'deletion_due_at': '2026-11-01T00:00:00Z',
                  'recovery_available': true,
                },
              )
            : (204, null),
      );
      await tester.pumpAndSettle();
      if (operation == 'withdrawal') {
        expect(find.byKey(const ValueKey('consent-agree')), findsOneWidget);
        await tapVisible(tester, find.byKey(const ValueKey('consent-agree')));
      }
      await restartApp(tester, env);
      expect(find.text('登录味谱'), findsNothing);
      expect(find.text('待同步 1 条'), findsOneWidget);
      await tapTab(tester, 4);
      expect(find.text('Bob 的账号'), findsOneWidget);
      await _logout(tester);
      env.server.user = alice;
      await _login(tester);
      if (operation == 'logout') {
        expect(find.text('待同步 1 条'), findsOneWidget);
      } else {
        expect(find.byKey(const ValueKey('sync-pending')), findsNothing);
      }
    });
  }

  testWidgets('旧无归属写入和旧拒收只显示本机数量，退出切换账号不泄露内容或他人失败数', (tester) async {
    final base = await _fixture();
    final queue = FakeEventQueue(legacyRejectedCount: 2);
    for (final entry in await base.eventQueue.entries()) {
      await queue.enqueue(entry.write);
      await queue.update(entry);
    }
    await queue.enqueue(
      QueuedEvent(
        id: '66666666-6666-4666-8666-000000000001',
        eventType: 'pipeline.self_check',
        typeVersion: 1,
        deviceId: 'old-device',
        deviceTime: DateTime.utc(2026, 9, 1),
        appVersion: 'old',
        content: {'ping': 'private-legacy-content'},
      ),
    );
    final env = TestEnv(
      server: base.server,
      local: base.local,
      secure: base.secure,
      eventQueue: queue,
    );
    final alice = env.server.user;
    final ownersAtUpload = <Recorded, String>{};
    env.server.on('POST', '/v1/sync/writes', (request) {
      ownersAtUpload[request] = env.server.user.id;
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
    void expectNoLegacyUpload() {
      for (final request in env.server.calls('POST', '/v1/sync/writes')) {
        final write = ((request.body as Map)['writes'] as List).single as Map;
        expect(write['owner_id'], ownersAtUpload[request]);
        expect(
          write['write_id'],
          isNot(
            isIn([
              _aliceWrite,
              _bobWrite,
              '66666666-6666-4666-8666-000000000001',
            ]),
          ),
        );
        expect(write['write_type'], 'experience.event');
        final payload = write['payload'] as Map;
        expect(payload['event_type'], 'ui.composition_shown');
        expect(payload['device_id'], 'device-test');
        expect(payload.toString(), isNot(contains('private-legacy-content')));
      }
    }

    void expectDeviceOnly() {
      expect(find.text('本机有 1 条旧写入无法确定原账号，已隔离保留，不会上传'), findsOneWidget);
      expect(find.text('本机保留 2 条旧拒收记录，仅有拒收凭据，无法恢复原内容'), findsOneWidget);
      expect(find.textContaining('private-legacy-content'), findsNothing);
      expect(find.textContaining('old-device'), findsNothing);
      expect(find.textContaining(_aliceWrite), findsNothing);
      expect(find.textContaining(_bobWrite), findsNothing);
      expect(find.textContaining('invalid_content'), findsNothing);
    }

    await pumpApp(tester, env: env);
    expect(find.text('待同步 1 条'), findsOneWidget);
    expectDeviceOnly();
    expectNoLegacyUpload();
    await _logout(tester);
    expect(find.byKey(const ValueKey('sync-pending')), findsNothing);
    // The login page has no shared badge; observe the next account's real page.
    env.server.user = UserOut.fromJson({
      ...alice.toJson(),
      'id': _bobId,
      'nickname': 'Bob 的账号',
    });
    await _login(tester);
    expect(find.text('待同步 1 条'), findsOneWidget);
    expectDeviceOnly();
    await restartApp(tester, env);
    expect(find.text('待同步 1 条'), findsOneWidget);
    expectDeviceOnly();
    expectNoLegacyUpload();
    final retained = await queue.entries();
    final legacy = retained.singleWhere(
      (entry) => entry.write.id == '66666666-6666-4666-8666-000000000001',
    );
    expect(legacy.write.ownerId, isNull);
    expect(legacy.state, WriteState.quarantined);
    expect(legacy.reasonCode, 'legacy_owner_unknown');
    expect(legacy.write.content, {'ping': 'private-legacy-content'});
    for (final id in [_aliceWrite, _bobWrite]) {
      final rejected = retained.singleWhere((entry) => entry.write.id == id);
      expect(rejected.state, WriteState.failed);
      expect(rejected.write.content, {'ping': 'retained'});
    }
  });

  testWidgets('退出提醒包含当前账号失败条数及保留说明，取消不退出也不删除', (tester) async {
    final env = await _fixture();
    await pumpApp(tester, env: env);
    await openSettings(tester);
    await tapVisible(tester, find.text('退出登录'));
    expect(find.text('还有 1 条内容未同步'), findsOneWidget);
    expect(find.textContaining('保留在这台设备'), findsOneWidget);
    expect(find.textContaining('同一账号'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('设置'), findsOneWidget);
    expect(env.server.calls('POST', '/v1/auth/logout'), isEmpty);
    await restartApp(tester, env);
    expect(find.text('待同步 1 条'), findsOneWidget);
    expect(find.text('登录味谱'), findsNothing);
  });

  testWidgets('离线退出提醒同时统计待同步、失败及冲突，明确确认后保留到同账号恢复', (tester) async {
    final base = await _fixture();
    const pendingId = '99999999-9999-4999-8999-000000000001';
    const conflictId = '99999999-9999-4999-8999-000000000002';
    for (final id in [pendingId, conflictId]) {
      await base.eventQueue.enqueue(
        QueuedEvent(
          id: id,
          ownerId: base.server.user.id,
          eventType: 'pipeline.self_check',
          typeVersion: 1,
          deviceId: 'device-1',
          deviceTime: DateTime.utc(2026, 10, 8),
          appVersion: 'test',
          content: {'ping': 'retained'},
        ),
      );
    }
    final candidate = (await base.eventQueue.entries()).singleWhere(
      (e) => e.write.id == conflictId,
    );
    await base.eventQueue.update(
      candidate.change(
        state: WriteState.conflict,
        reasonCode: 'recipe_version_changed',
        result: {
          'local': {'title': '我的候选'},
          'server': {'title': '另一份候选'},
        },
      ),
    );
    final env = TestEnv(
      server: base.server,
      local: base.local,
      secure: base.secure,
      eventQueue: base.eventQueue,
      offline: true,
    );
    await pumpApp(tester, env: env, textScale: 3.0, size: const Size(320, 568));
    await openSettings(tester);
    await tester.dragUntilVisible(
      find.text('退出登录'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tapVisible(tester, find.text('退出登录'));
    // Three fixture writes plus the real Today page's offline composition
    // observation. The other owner's failed write is deliberately excluded.
    expect(find.text('还有 4 条内容未同步'), findsOneWidget);
    expect(find.textContaining('包括待同步、失败和冲突'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.widgetWithText(FilledButton, '退出登录'));
    await tester.pumpAndSettle();
    expect(find.text('登录味谱'), findsOneWidget);
    expect(env.server.calls('POST', '/v1/sync/writes'), isEmpty);
    expect(env.server.calls('POST', '/v1/auth/refresh'), isEmpty);
    final resumed = TestEnv(
      server: env.server,
      local: env.local,
      secure: env.secure,
      eventQueue: env.eventQueue,
    );
    await restartApp(tester, resumed);
    await _login(tester);
    expect(find.text('待同步 2 条'), findsOneWidget);
    await openSettings(tester);
    await tester.dragUntilVisible(
      find.text('退出登录'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tapVisible(tester, find.text('退出登录'));
    expect(find.text('还有 2 条内容未同步'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    final sent = env.server
        .calls('POST', '/v1/sync/writes')
        .where(
          (r) =>
              (((r.body as Map)['writes'] as List).single as Map)['write_id'] ==
              pendingId,
        );
    expect(sent, hasLength(1));
  });

  for (final recovery in ['refresh', 'relogin']) {
    testWidgets('写入过期后 $recovery 恢复原 ID 和依赖，不把失败或登录拒绝标为同步成功', (tester) async {
      final env = await _fixture();
      const parentId = 'aaaaaaaa-aaaa-4aaa-8aaa-000000000001';
      const childId = 'aaaaaaaa-aaaa-4aaa-8aaa-000000000002';
      for (final item in [
        (childId, [parentId]),
        (parentId, <String>[]),
      ]) {
        await env.eventQueue.enqueue(
          QueuedEvent.write(
            id: item.$1,
            ownerId: env.server.user.id,
            writeType: 'experience.event',
            deviceTime: DateTime.utc(2026, 10, 8),
            dependencies: item.$2,
            payload: {
              'event_type': 'pipeline.self_check',
              'type_version': 1,
              'device_id': 'device-1',
              'app_version': 'test',
              'correlation': {},
              'content': {'ping': 'original-offline-content'},
            },
          ),
        );
      }
      env.server.on('POST', '/v1/sync/writes', (request) {
        if (request.headers['Authorization'] == 'Bearer access-0') {
          return FakeServer.error(401, 'token_expired', '登录已过期');
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
      if (recovery == 'relogin') {
        env.server.on(
          'POST',
          '/v1/auth/refresh',
          (_) => FakeServer.error(401, 'refresh_invalid', '登录已失效，请重新登录'),
        );
      }
      await pumpApp(tester, env: env);
      if (recovery == 'relogin') {
        expect(find.text('登录味谱'), findsOneWidget);
        expect(find.text('登录已失效，请重新登录'), findsOneWidget);
        await tester.pump(const Duration(seconds: 30));
        expect(env.server.calls('POST', '/v1/auth/refresh'), hasLength(1));
        expect(env.server.calls('POST', '/v1/sync/writes'), hasLength(1));
        await _login(tester);
      }
      expect(find.text('登录味谱'), findsNothing);
      // The original permanent refusal remains visible; authentication recovery
      // only resumes eligible work, never silently confirms or discards failure.
      expect(find.text('待同步 1 条'), findsOneWidget);
      final requests = env.server.calls('POST', '/v1/sync/writes');
      Map sentWrite(Recorded request) =>
          ((request.body as Map)['writes'] as List).single as Map;
      final parentRequests = requests
          .where((request) => sentWrite(request)['write_id'] == parentId)
          .toList();
      expect(parentRequests, hasLength(2));
      expect(parentRequests.first.body, parentRequests.last.body);
      expect(parentRequests.first.headers['Authorization'], 'Bearer access-0');
      expect(parentRequests.last.headers['Authorization'], 'Bearer access-1');
      final child = sentWrite(
        requests.singleWhere(
          (request) => sentWrite(request)['write_id'] == childId,
        ),
      );
      expect(child['owner_id'], env.server.user.id);
      expect(child['dependencies'], [parentId]);
      expect((child['payload'] as Map)['content'], {
        'ping': 'original-offline-content',
      });
      await restartApp(tester, env);
      expect(find.text('待同步 1 条'), findsOneWidget);
    });
  }

  for (final result in ['success', 'failure', 'confirmation']) {
    testWidgets('A 在途响应迟到 $result 不改变 B 页面、令牌或队列，A 返回后原写入才恢复', (tester) async {
      final env = await _fixture();
      final alice = env.server.user;
      const id = 'bbbbbbbb-bbbb-4bbb-8bbb-000000000001';
      await env.eventQueue.enqueue(
        QueuedEvent(
          id: id,
          ownerId: alice.id,
          eventType: 'pipeline.self_check',
          typeVersion: 1,
          deviceId: 'device-1',
          deviceTime: DateTime.utc(2026, 10, 8),
          appVersion: 'test',
          content: {'ping': 'alice-private'},
        ),
      );
      final delayed = Completer<(int, Object?)>();
      final aliceTokens = env.server.tokens();
      env.server.on('POST', '/v1/auth/refresh', (_) => delayed.future);
      env.server.on('POST', '/v1/sync/writes', (request) {
        if (request.headers['Authorization'] == 'Bearer access-0') {
          if (result == 'confirmation') return delayed.future;
          return FakeServer.error(401, 'token_expired', '登录已过期');
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
      await pumpApp(tester, env: env);
      expect(
        env.server.calls('POST', '/v1/auth/refresh'),
        hasLength(result == 'confirmation' ? 0 : 1),
      );
      final session = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      ).read(sessionStoreProvider);
      env.server.user = UserOut.fromJson({
        ...alice.toJson(),
        'id': _bobId,
        'nickname': 'Bob 的账号',
      });
      await session.save(TokenPair.fromJson(env.server.tokens()));
      await tester.pumpAndSettle();
      delayed.complete(
        result == 'success'
            ? (200, aliceTokens)
            : result == 'failure'
            ? FakeServer.error(401, 'refresh_invalid', '旧账号登录失效')
            : (
                200,
                {
                  'results': [
                    {
                      'write_id': id,
                      'status': 'confirmed',
                      'result': {
                        'resource_type': 'experience.event',
                        'resource_id': id,
                      },
                    },
                  ],
                },
              ),
      );
      await tester.pumpAndSettle();
      await restartApp(tester, env);
      await tapTab(tester, 4);
      expect(find.text('Bob 的账号'), findsOneWidget);
      expect(find.text('登录味谱'), findsNothing);
      expect(find.text('待同步 1 条'), findsOneWidget);
      final aliceRequests = env.server
          .calls('POST', '/v1/sync/writes')
          .where(
            (request) =>
                (((request.body as Map)['writes'] as List).single
                    as Map)['write_id'] ==
                id,
          )
          .toList();
      expect(aliceRequests, hasLength(1));
      await _logout(tester);
      env.server.user = alice;
      await _login(tester);
      expect(find.text('待同步 1 条'), findsOneWidget);
      final resumed = env.server
          .calls('POST', '/v1/sync/writes')
          .where(
            (request) =>
                (((request.body as Map)['writes'] as List).single
                    as Map)['write_id'] ==
                id,
          )
          .toList();
      expect(resumed, hasLength(2));
      expect(resumed.last.body, resumed.first.body);
      expect(resumed.last.headers['Authorization'], 'Bearer access-3');
    });
  }

  testWidgets('普通退出保留拒收内容，新账号只显示自己的数量，原账号回来仍可见', (tester) async {
    final env = await _fixture();
    final alice = env.server.user;
    await pumpApp(tester, env: env);
    expect(find.text('待同步 1 条'), findsOneWidget);
    await _logout(tester);
    expect(find.byKey(const ValueKey('sync-pending')), findsNothing);
    env.server.user = UserOut.fromJson({
      ...alice.toJson(),
      'id': _bobId,
      'nickname': '另一个账号',
    });
    await _login(tester);
    expect(find.text('待同步 1 条'), findsOneWidget);
    await _logout(tester);
    env.server.user = alice;
    await _login(tester);
    expect(find.text('待同步 1 条'), findsOneWidget);
  });

  for (final operation in ['withdrawal', 'deletion']) {
    testWidgets('确认 $operation 后等待远端回执期间不继续上传，迟到同步不复活已清理内容', (tester) async {
      final env = await _fixture();
      final delayedUpload = Completer<(int, Object?)>();
      env.server.on('POST', '/v1/sync/writes', (_) => delayedUpload.future);
      for (final id in [
        '88888888-8888-4888-8888-000000000001',
        '88888888-8888-4888-8888-000000000002',
      ]) {
        await env.eventQueue.enqueue(
          QueuedEvent(
            id: id,
            ownerId: env.server.user.id,
            eventType: 'pipeline.self_check',
            typeVersion: 1,
            deviceId: 'device-1',
            deviceTime: DateTime.utc(2026, 10, 8),
            appVersion: 'test',
            content: {'ping': 'withdrawn'},
          ),
        );
      }
      await pumpApp(tester, env: env);
      final delayedConsent = Completer<(int, Object?)>();
      final endpoint = operation == 'withdrawal'
          ? '/v1/me/consents'
          : '/v1/me/deletion';
      env.server.on('POST', endpoint, (_) => delayedConsent.future);
      await openSettings(tester);
      if (operation == 'withdrawal') {
        await tapVisible(tester, find.text('撤回同意'));
        await tester.tap(find.text('撤回并退出'));
      } else {
        await tapVisible(tester, find.text('注销账号'));
        await tapVisible(tester, find.text('发送验证码'));
        await tester.enterText(
          find.byKey(const ValueKey('code-input')),
          goodCode,
        );
        await tester.pumpAndSettle();
        await tapVisible(tester, find.byKey(const ValueKey('delete-check')));
        await tester.tap(find.byKey(const ValueKey('delete-confirm')));
      }
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(env.server.calls('POST', endpoint), hasLength(1));
      final original = env.server.calls('POST', '/v1/sync/writes').single;
      final write = ((original.body as Map)['writes'] as List).single as Map;
      delayedUpload.complete((
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
      ));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(env.server.calls('POST', '/v1/sync/writes'), hasLength(1));
      delayedConsent.complete(
        operation == 'withdrawal'
            ? (204, null)
            : (
                202,
                {
                  'status': 'deleting',
                  'deletion_due_at': '2026-11-01T00:00:00Z',
                  'recovery_available': true,
                },
              ),
      );
      await tester.pumpAndSettle();
      if (operation == 'withdrawal') {
        expect(find.byKey(const ValueKey('consent-agree')), findsOneWidget);
        await tapVisible(tester, find.byKey(const ValueKey('consent-agree')));
      }
      // The fake identity boundary permits reentering the deleted owner's fixture
      // solely to observe cleanup. Production server rejects that identity.
      await _login(tester);
      expect(find.byKey(const ValueKey('sync-pending')), findsNothing);
    });
  }

  for (final operation in ['logout', 'withdrawal', 'deletion']) {
    testWidgets('$operation 对个人量具和历史缓存遵守保留与隐私清理区别', (tester) async {
      final env = await _fixture();
      const measureId = 'cccccccc-cccc-4ccc-8ccc-000000000001';
      final measure = {
        'id': measureId,
        'name': '原账号白瓷勺',
        'kind': 'spoon',
        'capacity_ml': 20,
        'created_at': '2026-10-08T00:00:00Z',
        'updated_at': '2026-10-08T00:00:00Z',
      };
      await env.local.setString(
        'personal_measures:v1:${env.server.user.id}',
        jsonEncode({
          'account_id': env.server.user.id,
          'items': [measure],
        }),
      );
      await env.local.setString(
        'measure_history:v1:${env.server.user.id}',
        jsonEncode({
          measureId: [
            {
              'field': 'capacity_ml',
              'old_value': 15,
              'new_value': 20,
              'device_time': '2026-10-08T00:00:00Z',
              'outcome': 'applied',
            },
          ],
        }),
      );
      await pumpApp(tester, env: env);
      if (operation == 'logout') {
        await _logout(tester);
      } else {
        await openSettings(tester);
        if (operation == 'withdrawal') {
          await tapVisible(tester, find.text('撤回同意'));
          await tapVisible(tester, find.text('撤回并退出'));
          await tapVisible(tester, find.byKey(const ValueKey('consent-agree')));
        } else {
          await tapVisible(tester, find.text('注销账号'));
          await tapVisible(tester, find.text('发送验证码'));
          await tester.enterText(
            find.byKey(const ValueKey('code-input')),
            goodCode,
          );
          await tester.pumpAndSettle();
          await tapVisible(tester, find.byKey(const ValueKey('delete-check')));
          await tapVisible(
            tester,
            find.byKey(const ValueKey('delete-confirm')),
          );
        }
      }
      await _login(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );
      container.read(offlineSimulationProvider.notifier).set(true);
      env.reachability.reachable = false;
      await tapTab(tester, 4);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('personal-measures-entry')),
      );
      if (operation == 'logout') {
        expect(find.text('原账号白瓷勺'), findsOneWidget);
      } else {
        expect(find.text('原账号白瓷勺'), findsNothing);
        await goBack(tester);
        env.reachability.reachable = true;
        container.read(offlineSimulationProvider.notifier).set(false);
        // A new server read may legitimately make the measure visible again;
        // an offline history read must not resurrect the erased old history.
        env.server.on(
          'GET',
          '/v1/me/measures',
          (_) => (
            200,
            {
              'items': [measure],
              'next_cursor': null,
            },
          ),
        );
        await tapVisible(
          tester,
          find.byKey(const ValueKey('personal-measures-entry')),
        );
        expect(find.text('原账号白瓷勺'), findsOneWidget);
        container.read(offlineSimulationProvider.notifier).set(true);
      }
      await tapVisible(
        tester,
        find.byKey(const ValueKey('measure-history-$measureId')),
      );
      if (operation == 'logout') {
        expect(find.textContaining('15 → 20'), findsOneWidget);
      } else {
        expect(find.textContaining('15 → 20'), findsNothing);
        expect(find.text('暂无修改记录'), findsOneWidget);
      }
      await tapVisible(tester, find.text('关闭'));
    });
  }

  testWidgets('确认注销删除当前账号待同步内容，不清除另一个账号的拒收内容', (tester) async {
    final env = await _fixture();
    final alice = env.server.user;
    await pumpApp(tester, env: env);
    expect(find.text('待同步 1 条'), findsOneWidget);
    await openSettings(tester);
    await tapVisible(tester, find.text('注销账号'));
    await tapVisible(tester, find.text('发送验证码'));
    await tester.enterText(find.byKey(const ValueKey('code-input')), goodCode);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('delete-check')));
    await tapVisible(tester, find.byKey(const ValueKey('delete-confirm')));
    expect(find.text('登录味谱'), findsOneWidget);
    expect(find.byKey(const ValueKey('sync-pending')), findsNothing);
    env.server.user = UserOut.fromJson({
      ...alice.toJson(),
      'id': _bobId,
      'nickname': '另一个账号',
    });
    await _login(tester);
    expect(find.text('待同步 1 条'), findsOneWidget);
    await _logout(tester);
    // The fake identity boundary permits reentering the deleted owner's fixture
    // solely to observe cleanup. Production server rejects that identity.
    env.server.user = alice;
    await _login(tester);
    expect(find.byKey(const ValueKey('sync-pending')), findsNothing);
  });
}
