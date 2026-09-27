import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/storage/local_store.dart';

import 'helpers.dart';

/// 首次启动的隐私同意（SPEC-013.2 票 1）。

const consentTitle = '开始之前，先说清楚我们会用到什么';

void main() {
  testWidgets('首次启动只显示同意页，同意前不发任何请求', (tester) async {
    final env = await pumpApp(tester, env: TestEnv());
    expect(find.text(consentTitle), findsOneWidget);
    expect(find.text('同意并继续'), findsOneWidget);
    for (final tab in tabLabels) {
      expect(find.text(tab), findsNothing);
    }
    expect(env.server.requests, isEmpty);
    expect(env.permissions.requested, isEmpty);
  });

  testWidgets('不同意 → 再说明一次 → 仍不同意就退出', (tester) async {
    final env = await pumpApp(tester, env: TestEnv());
    await tapVisible(tester, find.text('不同意'));
    expect(find.text('不同意的话，味谱没法工作'), findsOneWidget);
    await tapVisible(tester, find.text('仍不同意，退出'));
    expect(env.exit.calls, 1);
    expect(env.server.requests, isEmpty);
    // 没有留下同意记录，下次打开还会问
    expect(env.local.getString('consent_records'), isNull);
  });

  testWidgets('不能自己退出的平台显示已退出页，可以重新考虑', (tester) async {
    final env = TestEnv(exit: FakeAppExit(canExit: false));
    await pumpApp(tester, env: env);
    await tapVisible(tester, find.text('不同意'));
    await tapVisible(tester, find.text('仍不同意，退出'));
    expect(find.text('你没有同意隐私政策'), findsOneWidget);
    await tapVisible(tester, find.text('重新考虑'));
    expect(find.text(consentTitle), findsOneWidget);
  });

  testWidgets('再说明页也可以直接同意', (tester) async {
    await pumpApp(tester, env: TestEnv());
    await tapVisible(tester, find.text('不同意'));
    await tapVisible(tester, find.text('同意并继续'));
    expect(find.text('登录味谱'), findsOneWidget);
  });

  testWidgets('同意后记录存在本机并进入登录页，重启后不再询问', (tester) async {
    final env = await pumpApp(tester, env: TestEnv());
    await tapVisible(tester, find.byKey(const ValueKey('consent-agree')));
    expect(find.text('登录味谱'), findsOneWidget);

    final saved = (jsonDecode(env.local.getString('consent_records')!) as List)
        .cast<Map<String, dynamic>>();
    expect(
      saved.map((r) => (r['kind'], r['version'], r['agree'], r['uploaded'])),
      [('terms', 'v1', true, false), ('privacy', 'v1', true, false)],
    );
    expect(saved.first['device_id'], env.local.getString('device_id'));

    await restartApp(tester, env);
    expect(find.text(consentTitle), findsNothing);
    expect(find.text('登录味谱'), findsOneWidget);
  });

  testWidgets('隐私政策改版后，已登录用户先看到变更摘要，重新同意才继续', (tester) async {
    final server = FakeServer();
    final env = TestEnv(
      server: server,
      local: MemoryLocalStore(consentedStore(privacy: 'v0')),
      secure: TestEnv.signedIn(server: server).secure,
    );
    await pumpApp(tester, env: env);
    expect(find.text('隐私政策已更新'), findsOneWidget);
    expect(find.text('这次改了什么'), findsOneWidget);
    expect(find.text('v0 → v1'), findsOneWidget);
    expect(find.text('今天'), findsNothing);
    expect(server.requests, isEmpty);

    await tapVisible(tester, find.text('同意新版本'));
    expect(find.text('今天还没有安排'), findsOneWidget);
    // 新的同意记录上传到了账号
    final upload = server.calls('POST', '/v1/me/consents').single.body as Map;
    expect((upload['records'] as List).map((r) => (r['kind'], r['version'])), [
      ('terms', 'v1'),
      ('privacy', 'v1'),
    ]);
  });

  testWidgets('全文链接打开服务端的静态网页', (tester) async {
    final env = await pumpApp(tester, env: TestEnv());
    await tester.tapOnText(find.textRange.ofSubstring('隐私政策'));
    await tester.pumpAndSettle();
    expect(
      env.links.opened.single.toString(),
      'http://localhost:8000/legal/privacy.html',
    );
  });

  for (final brightness in Brightness.values) {
    testWidgets('同意页在 ${brightness.name} 模式、最大字号下不溢出', (tester) async {
      await pumpApp(
        tester,
        env: TestEnv(),
        brightness: brightness,
        textScale: 3.0,
        size: const Size(320, 568),
      );
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.text('不同意'));
      expect(tester.takeException(), isNull);
      expect(find.text('仍不同意，退出'), findsOneWidget);
    });
  }
}
