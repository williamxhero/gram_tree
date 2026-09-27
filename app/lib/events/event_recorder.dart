import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart' show EventCorrelationIds;
import 'package:package_info_plus/package_info_plus.dart';

import '../storage/device_id.dart';
import '../util/ids.dart';
import 'event_queue.dart';
import 'event_uploader.dart';

/// App 版本号，读一次就缓存（测试里覆盖成固定值，不用真的走插件通道）。
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

/// 给各功能用的“记一条事件”简单调用：传事件类型、版本、关联 ID 和内容，
/// 立刻写进本机队列就返回，不等网络。存储、上传、重试都不用调用方关心
/// （见 event_queue.dart、event_uploader.dart）。
final eventRecorderProvider = Provider<EventRecorder>(
  (ref) => EventRecorder(ref),
);

class EventRecorder {
  EventRecorder(this._ref);

  final Ref _ref;

  /// 记一条事件。
  ///
  /// * [eventType]/[typeVersion]：服务端事件登记表里的类型和版本号。
  /// * [correlation]：关联的业务对象 ID（菜谱版本、做菜记录……都可以留空）。
  /// * [content]：事件内容，不要放 user_id（服务端按登录状态填入，客户端自报无效）。
  ///
  /// 返回时事件已经写进本机队列；是否已经上传、什么时候上传由后台的
  /// [EventUploader] 决定，这次调用不等它。
  Future<void> record({
    required String eventType,
    required int typeVersion,
    EventCorrelationIds? correlation,
    Map<String, dynamic>? content,
  }) async {
    final appVersion = await _ref.read(appVersionProvider.future);
    final event = QueuedEvent(
      id: newUuidV4(),
      eventType: eventType,
      typeVersion: typeVersion,
      deviceId: _ref.read(deviceIdProvider),
      deviceTime: DateTime.now().toUtc(),
      appVersion: appVersion,
      correlation: correlation,
      content: content,
    );
    await _ref.read(eventQueueProvider).enqueue(event);
    // 已登录且联网时后台尝试上传；未登录或离线时这次调用直接跳过，
    // 不阻塞、不抛错，事件留在队列里等下次触发。
    unawaited(_ref.read(eventUploaderProvider).triggerUpload());
  }
}
