import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtree_api/gramtree_api.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/features/me/export_data_page.dart';

import 'helpers.dart';
import 'integration_navigation.dart' as integration;
import 'settings_test.dart' show openSettings;

const _jobId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
const _zip = <int>[
  80,
  75,
  5,
  6,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
];

Map<String, dynamic> job(
  String status, {
  String? url,
}) => ExportJobView.fromJson({
  'id': _jobId,
  'status': status,
  'created_at': '2026-10-15T00:00:00Z',
  'completed_at': status == 'completed' ? '2026-10-15T00:00:01Z' : null,
  'expires_at': status == 'completed' ? '2026-10-16T00:00:01Z' : null,
  'download_url': status == 'completed'
      ? url ??
            '/v1/me/exports/$_jobId/download?expires=1792108801&signature=test'
      : null,
  'error_code': status == 'failed' ? 'export_failed' : null,
}).toJson();

Future<void> verify(WidgetTester tester) async {
  await tapVisible(tester, find.text('发送验证码'));
  await tester.enterText(find.byKey(const ValueKey('code-input')), goodCode);
  await tester.pumpAndSettle();
}

Future<void> openExport(WidgetTester tester) async {
  await openSettings(tester);
  await tapVisible(tester, find.text('导出我的数据'));
}

void main() {
  for (final item in ['导出我的数据', '注销账号']) {
    testWidgets('端到端设置导航：手机视口可滚动打开屏幕外的$item', (tester) async {
      await pumpApp(tester, size: const Size(360, 640));
      await integration.tapText(tester, '我的');
      expect(find.text('设置'), findsOneWidget);
      await integration.tapText(tester, '设置');
      // The entry starts outside the phone viewport and cannot yet be tapped.
      expect(find.text(item).hitTestable(), findsNothing);

      await integration.tapPortabilitySettingsItem(tester, item);

      expect(find.text('发送验证码'), findsOneWidget);
      if (item == '导出我的数据') {
        expect(find.text('把自己的味谱带走'), findsOneWidget);
        expect(find.byKey(const ValueKey('export-start')), findsOneWidget);
      } else {
        expect(find.text('先确认是你本人'), findsOneWidget);
        expect(find.byKey(const ValueKey('delete-confirm')), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('导出：重新验证、后台进度、完成提醒和登录下载系统保存', (tester) async {
    final server = FakeServer();
    String? status;
    server.on(
      'GET',
      '/v1/me/exports',
      (_) => (
        200,
        ExportJobList(
          items: status == null
              ? const []
              : [ExportJobView.fromJson(job(status!))],
        ).toJson(),
      ),
    );
    server.on('POST', '/v1/me/exports', (_) {
      expect(server.reauthed, isTrue);
      status = 'pending';
      return (202, job(status!));
    });
    server.on('GET', '/v1/me/exports/$_jobId/download', (_) => (200, _zip));
    final env = await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await openExport(tester);
    final start = find.descendant(
      of: find.byKey(const ValueKey('export-start')),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(start).onPressed, isNull);
    expect(server.calls('POST', '/v1/me/exports'), isEmpty);
    await verify(tester);
    await tapVisible(tester, start);
    expect(find.text('正在后台打包'), findsOneWidget);
    expect(find.text('下载并保存 ZIP'), findsNothing);

    status = 'completed';
    await tapVisible(tester, find.text('刷新导出状态'));
    expect(find.text('导出已完成'), findsOneWidget);
    expect(find.text('导出已完成，可在设置 → 导出我的数据中下载'), findsOneWidget);
    await tapVisible(tester, find.text('下载并保存 ZIP'));
    final download = server
        .calls('GET', '/v1/me/exports/$_jobId/download')
        .single;
    expect(download.headers['Authorization'], 'Bearer access-0');
    expect(download.query['signature'], 'test');
    expect(env.exports.files.single.$1, 'gramtree-$_jobId.zip');
    expect(env.exports.files.single.$2, _zip);
    expect(env.links.opened, isEmpty);
    // Dismiss the two notices as a user would before tapping the footer.
    for (var i = 0; i < 2; i++) {
      await tester.drag(find.byType(SnackBar), const Offset(0, 100));
      await tester.pumpAndSettle();
    }
    await tapVisible(tester, find.text('查看导出格式说明'));
    expect(env.links.opened.single.path, '/data-export-format');
  });

  testWidgets('旧轮询响应不能覆盖新任务或停止完成通知', (tester) async {
    final server = FakeServer();
    final delayed = Completer<(int, Object?)>();
    var delayNext = false;
    var hasSecond = false;
    var secondCompleted = false;
    const secondId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
    server.on('GET', '/v1/me/exports', (_) {
      if (delayNext) {
        delayNext = false;
        return delayed.future;
      }
      return (
        200,
        {
          'items': [
            job(hasSecond ? 'completed' : 'pending'),
            if (hasSecond)
              {
                ...job(secondCompleted ? 'completed' : 'pending'),
                'id': secondId,
              },
          ],
        },
      );
    });
    server.on('POST', '/v1/me/exports', (_) {
      hasSecond = true;
      return (202, {...job('pending'), 'id': secondId});
    });
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await openExport(tester);
    await verify(tester);
    delayNext = true;
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tapVisible(tester, find.byKey(const ValueKey('export-start')));
    expect(find.text('正在后台打包'), findsOneWidget);
    delayed.complete((
      200,
      {
        'items': [job('completed')],
      },
    ));
    await tester.pumpAndSettle();
    expect(find.text('正在后台打包'), findsOneWidget);
    secondCompleted = true;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('正在后台打包'), findsNothing);
    expect(find.text('导出已完成'), findsNWidgets(2));
    expect(find.text('导出已完成，可在设置 → 导出我的数据中下载'), findsOneWidget);
  });

  testWidgets('重新验证过期和独立额度错误不自动重试导出', (tester) async {
    final server = FakeServer();
    var code = 'reauth_required';
    server.on(
      'POST',
      '/v1/me/exports',
      (_) => FakeServer.error(
        code == 'reauth_required' ? 403 : 429,
        code,
        code == 'reauth_required' ? '为了安全，请先重新验证身份' : '今日导出次数已用完',
      ),
    );
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await openExport(tester);
    await verify(tester);
    await tapVisible(tester, find.byKey(const ValueKey('export-start')));
    expect(find.text('为了安全，请先重新验证身份'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(const ValueKey('export-start')),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );
    code = 'export_daily_limit';
    await verify(tester);
    await tapVisible(tester, find.byKey(const ValueKey('export-start')));
    expect(find.text('今日导出次数已用完'), findsOneWidget);
    expect(server.calls('POST', '/v1/me/exports'), hasLength(2));
  });

  testWidgets('禁止把带认证的下载送往外部地址', (tester) async {
    final server = FakeServer();
    server.on(
      'GET',
      '/v1/me/exports',
      (_) => (
        200,
        {
          'items': [job('completed', url: 'https://example.com/leak.zip')],
        },
      ),
    );
    final env = await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await openExport(tester);
    await tapVisible(tester, find.text('下载并保存 ZIP'));
    expect(env.exports.files, isEmpty);
    expect(env.links.opened, isEmpty);
    expect(server.requests.where((r) => r.path == '/leak.zip'), isEmpty);
    expect(find.text('出了点问题，请稍后再试'), findsOneWidget);
  });

  testWidgets('过期下载不调用分享，失败任务验证后可重试且不新建任务', (tester) async {
    final server = FakeServer();
    var status = 'completed';
    server.on(
      'GET',
      '/v1/me/exports',
      (_) => (
        200,
        {
          'items': [job(status)],
        },
      ),
    );
    server.on(
      'GET',
      '/v1/me/exports/$_jobId/download',
      (_) => FakeServer.error(410, 'export_expired', '导出已过期，请重新发起'),
    );
    server.on('POST', '/v1/me/exports/$_jobId/retry', (_) {
      status = 'pending';
      return (202, job(status));
    });
    final env = await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await openExport(tester);
    await tapVisible(tester, find.text('下载并保存 ZIP'));
    expect(find.text('导出已过期，请重新发起'), findsOneWidget);
    expect(env.exports.files, isEmpty);
    status = 'failed';
    await tapVisible(tester, find.text('刷新导出状态'));
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '重试导出'))
          .onPressed,
      isNull,
    );
    await verify(tester);
    await tapVisible(tester, find.text('重试导出'));
    expect(find.text('正在后台打包'), findsOneWidget);
    expect(server.calls('POST', '/v1/me/exports'), isEmpty);
    expect(server.calls('POST', '/v1/me/exports/$_jobId/retry'), hasLength(1));
  });

  testWidgets('ZIP 的字节错误响应仍刷新过期令牌并保持本人身份', (tester) async {
    final server = FakeServer();
    server.on(
      'GET',
      '/v1/me/exports',
      (_) => (
        200,
        {
          'items': [job('completed')],
        },
      ),
    );
    server.on('GET', '/v1/me/exports/$_jobId/download', (request) {
      if (request.headers['Authorization'] == 'Bearer access-0') {
        return FakeServer.error(401, 'token_expired', '访问令牌已过期');
      }
      expect(request.headers['Authorization'], 'Bearer access-1');
      return (200, _zip);
    });
    final env = await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await openExport(tester);
    await tapVisible(tester, find.text('下载并保存 ZIP'));
    expect(server.calls('POST', '/v1/auth/refresh'), hasLength(1));
    expect(
      server.calls('GET', '/v1/me/exports/$_jobId/download'),
      hasLength(2),
    );
    expect(env.exports.files.single.$2, _zip);
    expect(env.links.opened, isEmpty);
  });

  testWidgets('账号切换隔离：旧账号在途 ZIP 不交给新账号分享', (tester) async {
    final server = FakeServer();
    final bytes = Completer<(int, Object?)>();
    server.on(
      'GET',
      '/v1/me/exports',
      (_) => (
        200,
        {
          'items': [job('completed')],
        },
      ),
    );
    server.on('GET', '/v1/me/exports/$_jobId/download', (_) => bytes.future);
    final env = await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await openExport(tester);
    final scope = ProviderScope.containerOf(
      tester.element(find.byType(ExportDataPage)),
    );
    final session = scope.read(sessionStoreProvider);
    await tester.ensureVisible(find.text('下载并保存 ZIP'));
    await tester.tap(find.text('下载并保存 ZIP'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      server.calls('GET', '/v1/me/exports/$_jobId/download'),
      hasLength(1),
    );
    server.user = server.user.copyWith(
      id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    );
    server.on('GET', '/v1/me/exports', (_) => (200, {'items': []}));
    await session.save(TokenPair.fromJson(server.tokens()));
    bytes.complete((200, _zip));
    await tester.pumpAndSettle();
    expect(env.exports.files, isEmpty);
    expect(find.text('下载并保存 ZIP'), findsNothing);
    expect(find.text('ZIP 已下载（网页测试替身，不保存到磁盘）'), findsNothing);
  });

  for (final boundary in ['logout', 'switch', 'privacy_pause']) {
    testWidgets('原生 ZIP 准备途中 $boundary 立即取消，不能晚到交付', (tester) async {
      final server = FakeServer();
      server.on(
        'GET',
        '/v1/me/exports',
        (_) => (
          200,
          {
            'items': [job('completed')],
          },
        ),
      );
      server.on('GET', '/v1/me/exports/$_jobId/download', (_) => (200, _zip));
      final env = TestEnv.signedIn(server: server);
      final gate = Completer<void>();
      env.exports.preparation = gate;
      await pumpApp(tester, env: env);
      await openExport(tester);
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(ExportDataPage)),
      );
      final session = scope.read(sessionStoreProvider);
      await tester.ensureVisible(find.text('下载并保存 ZIP'));
      await tester.tap(find.text('下载并保存 ZIP'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        server.calls('GET', '/v1/me/exports/$_jobId/download'),
        hasLength(1),
      );
      expect(env.exports.files, isEmpty);
      final before = env.exports.cancellations;
      if (boundary == 'logout') {
        await session.clear();
      } else if (boundary == 'switch') {
        server.user = server.user.copyWith(
          id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        );
        server.on('GET', '/v1/me/exports', (_) => (200, {'items': []}));
        await session.save(TokenPair.fromJson(server.tokens()));
      } else {
        await session.pauseAccountUploads(session.identity!);
      }
      expect(env.exports.cancellations, before + 1);
      gate.complete();
      await tester.pumpAndSettle();
      expect(env.exports.files, isEmpty);
      expect(find.text('ZIP 已下载（网页测试替身，不保存到磁盘）'), findsNothing);
    });
  }

  for (final action in ['keep_anonymous', 'withdraw']) {
    testWidgets('注销公开菜谱：无默认选择、勾选仍禁用，显式选择 $action 后提交', (tester) async {
      final server = FakeServer();
      server.on(
        'GET',
        '/v1/me/deletion',
        (_) => (
          200,
          DeletionPreview.fromJson({
            'public_recipes': [
              {'id': _jobId, 'title': '测试菜', 'published_versions': 1},
            ],
            'public_recipe_action_required': true,
            'deletes': ['私人资料和照片'],
            'retains': ['其他用户的历史'],
            'can_export': true,
          }).toJson(),
        ),
      );
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await openSettings(tester);
      await tapVisible(tester, find.text('注销账号'));
      await verify(tester);
      await tapVisible(tester, find.byKey(const ValueKey('delete-check')));
      final confirm = find.byKey(const ValueKey('delete-confirm'));
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      expect(server.calls('POST', '/v1/me/deletion'), isEmpty);
      await tapVisible(
        tester,
        find.byKey(
          ValueKey(
            action == 'withdraw' ? 'delete-withdraw' : 'delete-keep-anonymous',
          ),
        ),
      );
      await tapVisible(tester, confirm);
      expect(
        (server.calls('POST', '/v1/me/deletion').single.body
            as Map)['public_recipe_action'],
        action,
      );
      expect(find.text('登录味谱'), findsOneWidget);
    });
  }

  testWidgets('注销预览遇到验证过期时回到验证，不循环重试受保护预览', (tester) async {
    final server = FakeServer();
    var expired = true;
    server.on(
      'GET',
      '/v1/me/deletion',
      (_) => expired
          ? FakeServer.error(403, 'reauth_required', '请重新验证后查看注销范围')
          : (
              200,
              DeletionPreview.fromJson({
                'public_recipes': [],
                'public_recipe_action_required': false,
                'deletes': ['本人私密数据'],
                'retains': ['匿名统计'],
                'can_export': true,
              }).toJson(),
            ),
    );
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await openSettings(tester);
    await tapVisible(tester, find.text('注销账号'));
    await verify(tester);
    expect(find.text('发送验证码'), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-confirm')), findsNothing);
    expect(server.calls('POST', '/v1/me/deletion'), isEmpty);
    expired = false;
    await verify(tester);
    await tapVisible(tester, find.byKey(const ValueKey('delete-check')));
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('delete-confirm')))
          .onPressed,
      isNotNull,
    );
    expect(server.calls('GET', '/v1/me/deletion'), hasLength(2));
  });

  testWidgets('注销预览失败不可确认；撤回页提供导出和注销入口', (tester) async {
    final server = FakeServer();
    server.on(
      'GET',
      '/v1/me/deletion',
      (_) => FakeServer.error(500, 'internal_error', '预览读取失败'),
    );
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await openSettings(tester);
    await tapVisible(tester, find.text('撤回同意'));
    expect(find.text('先导出我的数据'), findsOneWidget);
    await tapVisible(tester, find.text('注销账号'));
    await verify(tester);
    await tapVisible(tester, find.byKey(const ValueKey('delete-check')));
    expect(find.text('预览读取失败'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('delete-confirm')))
          .onPressed,
      isNull,
    );
    expect(server.calls('POST', '/v1/me/deletion'), isEmpty);
  });

  for (final brightness in Brightness.values) {
    testWidgets('导出页面 ${brightness.name} / 320px / 大字号不溢出', (tester) async {
      await pumpApp(
        tester,
        brightness: brightness,
        textScale: 3,
        size: const Size(320, 568),
      );
      await openExport(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
