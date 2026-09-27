import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/main.dart' as app;
import 'package:integration_test/integration_test.dart';

/// 端到端样板：启动真正的 App，看到五个入口，逐个点开看到空态。
///
/// 在哪跑（见 CLAUDE.md 测试一节）：
/// * 网页版（主力）：tool/web_test.sh，云端线程和 CI 都跑。
/// * 安卓模拟器：只在 CI 跑，覆盖网页测不到的手机能力（锁屏计时、离线同步等）。
/// * iOS 模拟器：CI 里手动触发。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('启动 App，看到五个入口并能逐个打开', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    for (final label in ['今天', '发现', '新建', '记录', '我的']) {
      expect(find.bySemanticsLabel(label), findsWidgets, reason: label);
    }
    expect(find.text('今天还没有安排'), findsOneWidget);

    const pages = {'发现': '还没有可发现的内容', '记录': '还没有做菜记录', '我的': '个人中心'};
    for (final entry in pages.entries) {
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget, reason: entry.key);
    }

    await tester.tap(find.byKey(const ValueKey('primary-create-button')));
    await tester.pumpAndSettle();
    expect(find.text('想做点什么？'), findsOneWidget);
  });
}
