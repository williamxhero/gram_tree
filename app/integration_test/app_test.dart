import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/config/app_config.dart';
import 'package:gram_tree/main.dart' as app;
import 'package:integration_test/integration_test.dart';

import 'event_pipeline_support.dart' show resetLocalAppState;

/// 端到端：连真的服务端（tool/e2e_server.sh 起的 test 环境），走一遍首次启动。
/// 同意隐私政策 → 邮箱验证码登录 → 五个入口逐个打开 → 重新打开 App 仍是登录状态 → 退出登录。
///
/// 在哪跑（见 CLAUDE.md 测试一节）：
/// * 网页版（主力）：tool/web_test.sh，云端线程和 CI 都跑。
/// * 安卓模拟器：只在 CI 跑，覆盖网页测不到的手机能力（这里是安全存储里的登录状态）。
/// * iOS 模拟器：CI 里手动触发。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final server = Dio(
    BaseOptions(baseUrl: AppConfig.fromEnvironment().apiBaseUrl),
  );

  /// 测试环境的服务端能读出刚发给某个邮箱的验证码。
  Future<String> latestCode(String email) async {
    final resp = await server.get<Map<String, dynamic>>(
      '/v1/dev/latest-email-code',
      queryParameters: {'email': email},
    );
    return resp.data!['code'] as String;
  }

  Future<void> settle(WidgetTester tester) =>
      tester.pumpAndSettle(const Duration(milliseconds: 200));

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await settle(tester);
    await tester.tap(find.text(text).last);
    await settle(tester);
  }

  /// 等到 [finder] 出现（网络请求要一点时间）。
  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await settle(tester);
    expect(finder, findsWidgets);
  }

  testWidgets('首次启动：同意、登录、五个入口、重开保持登录、退出', (tester) async {
    // 每次运行用新邮箱，服务端的发送间隔和每日上限不会互相影响
    final email = 'e2e-${DateTime.now().microsecondsSinceEpoch}@example.com';
    // 端到端的 binding 默认不接管键盘输入，enterText 的文字到不了输入框
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);

    // Independent actors must not inherit iOS Keychain sessions; preserve the
    // later reopen unchanged so it still tests real session persistence.
    await resetLocalAppState();
    await app.main();
    await waitFor(tester, find.text('开始之前，先说清楚我们会用到什么'));
    await tester.ensureVisible(find.byKey(const ValueKey('consent-agree')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('consent-agree')));
    await settle(tester);

    await waitFor(tester, find.text('登录味谱'));
    await tester.enterText(find.byKey(const ValueKey('login-email')), email);
    await tapText(tester, '发送验证码');
    await waitFor(tester, find.text('输入验证码'));
    await tester.enterText(
      find.byKey(const ValueKey('code-input')),
      await latestCode(email),
    );
    // 这句话只出现在服务端下发的组合结果里（SPEC-009.1 #77），标准布局兜底没有它，
    // 确认走的确实是"今天"页面描述协议这条路，不是碰巧退回了兜底布局。
    // 不能拿"今天还没有安排"当就绪信号：标准布局在组合结果返回前也显示它，一进页面就
    // 满足，慢的模拟器上断言会赶在组合结果校验完之前执行。这里等组合结果自己的句子，
    // 组合真的退回了标准布局就等到超时失败。
    await waitFor(tester, find.text('先添加一道你常做的菜'));
    expect(find.text('先添加一道你常做的菜'), findsOneWidget);
    expect(find.text('今天还没有安排'), findsOneWidget);

    for (final label in ['今天', '发现', '新建', '记录', '我的']) {
      expect(find.bySemanticsLabel(label), findsWidgets, reason: label);
    }
    const pages = {'发现': '还没有可发现的内容', '记录': '还没有做菜记录'};
    for (final entry in pages.entries) {
      await tapText(tester, entry.key);
      expect(find.text(entry.value), findsOneWidget, reason: entry.key);
    }
    await tester.tap(find.byKey(const ValueKey('primary-create-button')));
    await settle(tester);
    expect(find.text('想做点什么？'), findsOneWidget);

    await tapText(tester, '我的');
    await waitFor(tester, find.text(email));
    final nickname = tester
        .widget<Text>(find.byKey(const ValueKey('me-nickname')))
        .data!;
    expect(nickname, startsWith('味友'));

    // 重新打开 App：不再问同意，也不用重新登录
    await tester.pumpWidget(const SizedBox());
    await app.main();
    await waitFor(tester, find.text('今天还没有安排'));
    expect(find.text('登录味谱'), findsNothing);

    await tapText(tester, '我的');
    await waitFor(tester, find.text('设置'));
    await tapText(tester, '设置');
    // The privacy controls place logout below a phone's lazy viewport.
    await tester.scrollUntilVisible(
      find.text('退出登录'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tapText(tester, '退出登录');
    await tester.tap(find.widgetWithText(FilledButton, '退出登录'));
    await waitFor(tester, find.text('登录味谱'));
  });
}
