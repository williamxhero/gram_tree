import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/api/api_client.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:gram_tree/main.dart' as app;
import 'package:gramtree_api/gramtree_api.dart';
import 'package:integration_test/integration_test.dart';

import 'event_pipeline_support.dart';

/// SPEC-010.1 票 7：安卓模拟器端到端——离线记事件，"杀进程"重开联网，服务端
/// 每条事件只收到一次。只在安卓模拟器上有意义，网页版直接跳过（见下面 main()）。
///
/// 两个"如实说明，不是操作系统级操作"的地方：
///
/// * **断网**：`integration_test` 跑在 App 进程内部，没有权限切系统飞行模式，也
///   没有 adb shell 权限去关网卡。这里换成"网络层强制失败"：
///   `lib/api/api_client.dart` 新增的 `offlineSimulationProvider`（默认 false，
///   生产代码永远不会把它设成 true），翻成 true 后 Dio 拦截链最外层直接把每个
///   请求拒绝成 `DioException.connectionError`，对 App 其余部分（事件队列、
///   上传器的重试逻辑）来说和真的断网没有区别。
/// * **"杀进程"**：跟 event_queue_persistence_check_mobile.dart（#72/#73）用的
///   是同一个手法——`pumpWidget(SizedBox())` 之后重新调用 `app.main()`，整个
///   Riverpod 容器（含 offlineSimulationProvider）从头重建，等价于"网络恢复"；
///   drift 落盘的事件队列和安全存储里的登录状态是磁盘文件，不受容器重建影响，
///   还在。这不是操作系统层面真的杀掉进程重启，是同一个效果的等价替代，
///   `integration_test` 框架本身做不到真的杀进程重启（这需要 adb/flutter_driver
///   层面的操作，不是单个测试用例内能做的事）。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('离线记事件，"杀进程"重开联网，服务端每条只收到一次', (tester) async {
    if (kIsWeb) return; // 断网/"杀进程"这两步只在安卓模拟器上跑，见文件头注释

    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);

    final signedIn = await signInFreshUser(tester);
    var container = containerOf(tester);
    final accessToken = accessTokenOf(container);

    // 打开"飞行模式"（网络层强制失败）。
    container.read(offlineSimulationProvider.notifier).set(true);

    const produced = 3;
    await recordSelfCheckEvents(container, produced, tag: 'offline-replay');

    // 离线时事件立即写进队列，上传尝试会失败，事件应该原样留着。
    final queuedBeforeRestart = await container
        .read(eventQueueProvider)
        .pending();
    expect(queuedBeforeRestart.length, produced);

    // "杀进程重开"：见文件头注释。
    await tester.pumpWidget(const SizedBox());
    await app.main();
    await waitFor(tester, find.text('今天还没有安排'));
    // 还是登录状态，不用重新走一遍登录（跟 app_test.dart 里"重新打开 App"那段一样）。
    expect(find.text('登录味谱'), findsNothing);
    container = containerOf(tester);

    // 冷启动会自动触发一次上传（event_upload_lifecycle.dart 的 EventUploadTrigger），
    // 新容器里 offlineSimulationProvider 恢复成默认的 false，这次请求能发出去。
    await waitUntil(
      tester,
      () async => (await container.read(eventQueueProvider).pending()).isEmpty,
    );

    final count = await selfCheckEventCount(
      accessToken,
      deviceId: signedIn.deviceId,
    );
    expect(count, produced, reason: '服务端应该收到全部 $produced 条，一条不多一条不少');

    // 重放同一批（模拟网络抖动时客户端对同一批重试一次）：服务端按事件 ID 去重，
    // 计数不应该翻倍。
    final resendResult = await resendEvents(container, queuedBeforeRestart);
    expect(resendResult.results.map((r) => r.status).toSet(), {
      EventUploadResultItemStatusEnum.duplicate,
    });
    final countAfterResend = await selfCheckEventCount(
      accessToken,
      deviceId: signedIn.deviceId,
    );
    expect(countAfterResend, produced, reason: '重复上传同一批不应该让计数变化');
  });
}
