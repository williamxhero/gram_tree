import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/auth/session.dart';

import 'helpers.dart';

/// 我的 → 设置：昵称、退出登录、隐私文档、撤回同意、登录方式、注销账号（SPEC-013.2 票 3、4、5、6、8）。

Future<void> openSettings(WidgetTester tester) async {
  await tapTab(tester, 4);
  // 大字号下“设置”可能还没建出来（列表按需构建），先滚到它
  await tester.dragUntilVisible(
    find.text('设置'),
    find.byType(ListView),
    const Offset(0, -200),
  );
  await tapVisible(tester, find.text('设置'));
}

void main() {
  testWidgets('改昵称：超长时提示，保存后显示新昵称', (tester) async {
    final env = await pumpApp(tester);
    await tapTab(tester, 4);
    await tapVisible(tester, find.byTooltip('改昵称'));
    await tester.enterText(
      find.byKey(const ValueKey('nickname-input')),
      '这是一个非常非常非常非常非常非常长的昵称啊',
    );
    await tapVisible(tester, find.text('保存'));
    expect(find.text('最多 20 个字'), findsWidgets);
    expect(env.server.calls('PATCH', '/v1/me'), isEmpty);

    await tester.enterText(find.byKey(const ValueKey('nickname-input')), '小厨');
    await tapVisible(tester, find.text('保存'));
    expect(env.server.calls('PATCH', '/v1/me').single.body, {'nickname': '小厨'});
    expect(find.text('小厨'), findsOneWidget);
  });

  testWidgets('设置里显示登录方式和时区', (tester) async {
    await pumpApp(tester);
    await openSettings(tester);
    expect(find.text('邮箱'), findsOneWidget);
    expect(find.text('Asia/Shanghai'), findsOneWidget);
  });

  testWidgets('退出登录：确认后回到登录页，服务端吊销这台设备', (tester) async {
    final env = await pumpApp(tester);
    await openSettings(tester);
    await tapVisible(tester, find.text('退出登录'));
    expect(find.text('退出这台设备的登录？其他设备不受影响。'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '退出登录'));
    await tester.pumpAndSettle();

    expect(find.text('登录味谱'), findsOneWidget);
    final logout = env.server.calls('POST', '/v1/auth/logout').single;
    expect(logout.headers['Authorization'], 'Bearer access-0');
    expect(env.secure.values[sessionStorageKey], isNull);
  });

  testWidgets('三份隐私文档都能打开', (tester) async {
    final env = await pumpApp(tester);
    await openSettings(tester);

    await tapVisible(tester, find.text('隐私政策'));
    expect(find.text('在浏览器里看完整版'), findsOneWidget);
    await tapVisible(tester, find.text('在浏览器里看完整版'));
    expect(env.links.opened.single.path, '/legal/privacy.html');
    await goBack(tester);

    await tapVisible(tester, find.text('个人信息收集清单'));
    expect(find.text('邮箱地址'), findsWidgets);
    await goBack(tester);

    await tapVisible(tester, find.text('第三方 SDK 共享清单'));
    expect(find.textContaining('Sentry'), findsWidgets);
  });

  testWidgets('撤回同意：说明数据怎么处理，确认后上传撤回记录、退出登录、回到同意页', (tester) async {
    final env = await pumpApp(tester);
    await openSettings(tester);
    await tapVisible(tester, find.text('撤回同意'));
    expect(find.textContaining('撤回不会删除已保存的菜谱和记录'), findsOneWidget);
    await tapVisible(tester, find.text('撤回并退出'));

    expect(find.text('开始之前，先说清楚我们会用到什么'), findsOneWidget);
    final upload =
        env.server.calls('POST', '/v1/me/consents').single.body as Map;
    expect((upload['records'] as List).map((r) => r['action']), [
      'withdraw',
      'withdraw',
    ]);
    expect(env.server.calls('POST', '/v1/auth/logout'), hasLength(1));
    expect(env.secure.values[sessionStorageKey], isNull);

    // 撤回记录留在本机，已标为上传过
    final saved = (jsonDecode(env.local.getString('consent_records')!) as List)
        .cast<Map<String, dynamic>>();
    expect(saved.where((r) => r['agree'] == false), hasLength(2));
    expect(saved.every((r) => r['uploaded'] == true), isTrue);

    // 撤回后不再发请求
    final before = env.server.requests.length;
    await restartApp(tester, env);
    expect(env.server.requests.length, before);
  });

  testWidgets('绑定邮箱：收码输码后列表里多一个；已属于别的账号时提示不能绑定', (tester) async {
    final server = FakeServer()..identities = [];
    final env = await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await openSettings(tester);
    await tapVisible(tester, find.text('登录方式'));
    expect(find.text('未绑定'), findsNWidgets(2));

    await tapVisible(tester, find.text('绑定邮箱'));
    await tester.enterText(
      find.byKey(const ValueKey('bind-email')),
      'taken@example.com',
    );
    await tapVisible(tester, find.text('发送验证码'));
    expect(env.server.calls('POST', '/v1/auth/email/code').single.body, {
      'email': 'taken@example.com',
      'purpose': 'bind',
    });
    await tester.enterText(find.byKey(const ValueKey('code-input')), goodCode);
    await tester.pumpAndSettle();
    expect(find.text('这个登录方式已经属于另一个味谱账号，不能绑定'), findsOneWidget);

    await goBack(tester);
    await tapVisible(tester, find.text('绑定邮箱'));
    await tester.enterText(
      find.byKey(const ValueKey('bind-email')),
      'new@example.com',
    );
    await tapVisible(tester, find.text('发送验证码'));
    await tester.enterText(find.byKey(const ValueKey('code-input')), goodCode);
    await tester.pumpAndSettle();
    expect(find.text('登录方式'), findsWidgets);
    expect(find.text('new@example.com'), findsOneWidget);
  });

  testWidgets('注销账号：先验证身份，勾选确认后申请注销并退出', (tester) async {
    final env = await pumpApp(tester);
    await openSettings(tester);
    await tapVisible(tester, find.text('注销账号'));
    expect(find.text('先确认是你本人'), findsOneWidget);
    expect(find.text('验证码会发到 $testEmail。'), findsOneWidget);

    await tapVisible(tester, find.text('发送验证码'));
    expect(env.server.calls('POST', '/v1/auth/email/code').single.body, {
      'email': testEmail,
      'purpose': 'reauth',
    });
    await tester.enterText(find.byKey(const ValueKey('code-input')), goodCode);
    await tester.pumpAndSettle();
    expect(env.server.reauthed, isTrue);

    expect(find.text('这些会被删除'), findsOneWidget);
    final confirm = find.byKey(const ValueKey('delete-confirm'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await tapVisible(tester, find.byKey(const ValueKey('delete-check')));
    await tapVisible(tester, confirm);

    expect(env.server.calls('POST', '/v1/me/deletion'), hasLength(1));
    expect(find.text('登录味谱'), findsOneWidget);
    expect(find.text('已申请注销，账号不能再登录'), findsOneWidget);
    expect(env.secure.values[sessionStorageKey], isNull);
  });

  testWidgets('注销页拉不到登录方式时显示错误，可以重试', (tester) async {
    final server = FakeServer();
    var fail = true;
    server.on('GET', '/v1/me/identities', (_) {
      if (fail) return FakeServer.error(500, 'internal_error', '服务器出错了');
      return (200, [for (final i in server.identities) i.toJson()]);
    });
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await openSettings(tester);
    await tapVisible(tester, find.text('注销账号'));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('服务器出错了'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.text('验证码会发到 $testEmail。'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('设置页在 ${brightness.name} 模式、最大字号下不溢出', (tester) async {
      await pumpApp(
        tester,
        env: TestEnv.signedIn(),
        brightness: brightness,
        textScale: 3.0,
        size: const Size(320, 568),
      );
      await openSettings(tester);
      expect(tester.takeException(), isNull);
      await tester.dragUntilVisible(
        find.text('注销账号'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tapVisible(tester, find.text('注销账号'));
      expect(tester.takeException(), isNull);
    });
  }
}
