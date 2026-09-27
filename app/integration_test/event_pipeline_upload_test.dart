import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:integration_test/integration_test.dart';

import 'event_pipeline_support.dart';

/// SPEC-010.1 票 7：经验层事件管道端到端的简化流程——记一条事件，联网后自动
/// 上传，服务端确认收到一次。不涉及断网/"杀进程"，两个平台都跑：
///
/// * 网页版（tool/web_test.sh）：这是"网页版端到端简化流程"要求的那条用例。
/// * 安卓模拟器（CI 的 android-e2e）：跟安卓专属的
///   event_offline_replay_test.dart 一起跑，多一层覆盖不会互相干扰
///   （各自用全新账号、服务端按用户隔离）。
///
/// 怎么确认"服务端收到"：调用票 7 新增的 dev-only 接口 `GET /v1/dev/events/count`
///（`server/gramtree/events/dev.py`），只在 dev/test 环境挂载、不进 OpenAPI，只
/// 回一个数字，不是对外可读的事件明细接口。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('记一条事件，联网后自动上传，服务端收到一次', (tester) async {
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);

    final signedIn = await signInFreshUser(tester);
    final container = containerOf(tester);
    final accessToken = accessTokenOf(container);

    const produced = 2;
    await recordSelfCheckEvents(container, produced, tag: 'upload-test');

    // 记事件后 EventRecorder 会自己触发一次上传（联网、已登录），等它传完。
    await waitUntil(
      tester,
      () async => (await container.read(eventQueueProvider).pending()).isEmpty,
    );

    final count = await selfCheckEventCount(
      accessToken,
      deviceId: signedIn.deviceId,
    );
    expect(count, produced);
  });
}
