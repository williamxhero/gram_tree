// SPEC-010.1 票 7：经验层事件管道端到端测试的公共工具。
//
// 给 event_pipeline_upload_test.dart（网页版 + 安卓都跑的简化流程）和
// event_offline_replay_test.dart（安卓专属的断网/"杀进程"流程）共用，本身不是
// `_test.dart`，flutter test / flutter drive 不会把它当独立测试跑。
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/api/api_client.dart';
import 'package:gram_tree/app/app.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/config/app_config.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:gram_tree/events/event_recorder.dart';
import 'package:gram_tree/main.dart' as app;
import 'package:gram_tree/storage/device_id.dart';
import 'package:gramtree_api/gramtree_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 直连测试环境服务端（tool/e2e_server.sh 起的 dev/test 环境），不经过 App 的
/// Dio/拦截链——跟 app_test.dart 里 `latestCode` 用的是同一个思路：这是"测试专用
/// 检查手段"，不是产品接口，不应该混进 App 自己的网络层。
final devServer = Dio(
  BaseOptions(baseUrl: AppConfig.fromEnvironment().apiBaseUrl),
);

/// 测试环境的服务端能读出刚发给某个邮箱的验证码（见 accounts/dev.py）。
Future<String> latestEmailCode(String email) async {
  final resp = await devServer.get<Map<String, dynamic>>(
    '/v1/dev/latest-email-code',
    queryParameters: {'email': email},
  );
  return resp.data!['code'] as String;
}

/// 票 7 新增的 dev-only 接口（events/dev.py）：查当前登录用户已入库的
/// `pipeline.self_check` 事件条数，按 deviceId 过滤，只回一个数字。
Future<int> selfCheckEventCount(
  String accessToken, {
  required String deviceId,
}) async {
  final resp = await devServer.get<Map<String, dynamic>>(
    '/v1/dev/events/count',
    queryParameters: {
      'event_type': 'pipeline.self_check',
      'device_id': deviceId,
    },
    options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
  );
  return resp.data!['count'] as int;
}

Future<void> settle(WidgetTester tester) =>
    tester.pumpAndSettle(const Duration(milliseconds: 200));

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await settle(tester);
  await tester.tap(find.text(text).last);
  await settle(tester);
}

/// 等到 [finder] 出现（网络请求要一点时间），跟 app_test.dart 里的写法一样。
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  int tries = 100,
}) async {
  for (var i = 0; i < tries && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await settle(tester);
  expect(finder, findsWidgets);
}

/// 反复检查一个条件直到成立或超时——用来等后台上传器把队列传完。
Future<void> waitUntil(
  WidgetTester tester,
  FutureOr<bool> Function() condition, {
  int tries = 150,
  Duration step = const Duration(milliseconds: 200),
}) async {
  for (var i = 0; i < tries; i++) {
    if (await condition()) return;
    await tester.pump(step);
  }
  expect(await condition(), isTrue, reason: '等待超时');
}

/// 清掉本机安全存储和普通键值存储（登录状态、同意记录、设备 ID 全部清空）。
///
/// 安卓的 `flutter test integration_test` 会把目录下每个 `_test.dart` 文件当一个
/// 独立测试跑，但不保证每个文件之间会重装 App、清空本机存储——如果前一个文件
/// （比如 app_test.dart）已经在这台模拟器上走完登录流程，这里不清空的话
/// `app.main()` 会直接跳过同意和登录页，后面找"登录味谱"这几个断言全部落空。
/// 每个新测试文件开头都调用这个函数，保证不管执行顺序如何，看到的都是"首次启动"。
Future<void> resetLocalAppState() async {
  await const FlutterSecureStorage().deleteAll();
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

/// 从当前正在跑的 App（`app.main()` 建的那棵树）拿到真正在用的 Riverpod 容器，
/// 不新建一个假的——这样后面调用 [eventRecorderProvider] 记的是生产代码的
/// EventRecorder → EventQueue → EventUploader 全套真实链路，不是伪造数据。
///
/// 目前 App 里没有任何业务功能真的调用 `EventRecorder.record()`（纯基础设施，见
/// event_recorder.dart 顶部注释），这里也不为了这条端到端测试专门在正式业务里加一个
/// 用户能看到的按钮：直接用 Riverpod 公开的 `ProviderScope.containerOf` 从测试代码
/// 里拿到容器再调用，等价于"debug 专用入口"，但不需要往生产代码里加任何新 UI。
ProviderContainer containerOf(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(GramTreeApp)),
  listen: false,
);

/// 首次启动走到已登录的主界面，返回登录用的邮箱和这台设备的 deviceId。
/// 每次用一个新邮箱，服务端天然按用户隔离，不用清服务端的数据。
Future<({String email, String deviceId})> signInFreshUser(
  WidgetTester tester,
) async {
  await resetLocalAppState();
  final email =
      'e2e-events-${DateTime.now().microsecondsSinceEpoch}@example.com';

  await app.main();
  await waitFor(tester, find.text('开始之前，先说清楚我们会用到什么'));
  await tester.tap(find.byKey(const ValueKey('consent-agree')));
  await settle(tester);

  await waitFor(tester, find.text('登录味谱'));
  await tester.enterText(find.byKey(const ValueKey('login-email')), email);
  await tapText(tester, '发送验证码');
  await waitFor(tester, find.text('输入验证码'));
  await tester.enterText(
    find.byKey(const ValueKey('code-input')),
    await latestEmailCode(email),
  );
  await waitFor(tester, find.text('今天还没有安排'));

  final container = containerOf(tester);
  final deviceId = container.read(deviceIdProvider);
  // 安卓的 drift 队列落在磁盘文件里，`resetLocalAppState` 清的是安全存储/键值
  // 存储，清不到它——保险起见把上一次可能留下的未上传事件先清空，避免它们
  // 混进这次测试的事件计数里（网页版是内存队列，本来就是空的，这里不会有影响）。
  final queue = container.read(eventQueueProvider);
  await queue.removeAll((await queue.pending()).map((e) => e.id));
  return (email: email, deviceId: deviceId);
}

/// 当前登录用户的访问令牌，给 [devServer] 直接调用 dev-only 接口用（App 自己的
/// Dio 走的是生产的 GramtreeApi 客户端，不应该混进测试专用的接口调用里）。
String accessTokenOf(ProviderContainer container) =>
    container.read(sessionStoreProvider).current!.accessToken;

/// 记几条 `pipeline.self_check` 自检事件（服务端登记表 v1，见
/// gramtree/events/registry.py），走真实的 EventRecorder。
Future<void> recordSelfCheckEvents(
  ProviderContainer container,
  int count, {
  String tag = 'e2e',
}) async {
  for (var i = 0; i < count; i++) {
    await container
        .read(eventRecorderProvider)
        .record(
          eventType: 'pipeline.self_check',
          typeVersion: 1,
          content: {'ping': '$tag-$i'},
        );
  }
}

/// 直接调用上传接口重放一批已经上传过的事件（模拟客户端在网络抖动时对同一批
/// 重试一次），用来确认服务端按事件 ID 去重、不会重复计数。
Future<EventUploadResponse> resendEvents(
  ProviderContainer container,
  List<QueuedEvent> events,
) async {
  final resp = await container
      .read(apiClientProvider)
      .getEventsApi()
      .uploadEvents(
        eventUploadRequest: EventUploadRequest(
          events: [
            for (final e in events)
              EventUploadItem(
                id: e.id,
                eventType: e.eventType,
                typeVersion: e.typeVersion,
                deviceId: e.deviceId,
                deviceTime: e.deviceTime,
                appVersion: e.appVersion,
                correlation: e.correlation,
                content: e.content == null
                    ? null
                    : Map<String, Object>.from(e.content!),
              ),
          ],
        ),
      );
  return resp.data!;
}
