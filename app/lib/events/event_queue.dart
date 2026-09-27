import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart' show EventCorrelationIds;

import 'event_queue_stub.dart'
    if (dart.library.io) 'event_queue_mobile.dart'
    if (dart.library.js_interop) 'event_queue_web.dart';

/// 待上传队列里的一条事件，字段和 #69 的 `POST /v1/events/upload` 一一对应。
class QueuedEvent {
  QueuedEvent({
    required this.id,
    required this.eventType,
    required this.typeVersion,
    required this.deviceId,
    required this.deviceTime,
    required this.appVersion,
    this.correlation,
    this.content,
  });

  /// 客户端生成的事件 ID（UUID v4），全局唯一，服务端按它去重。
  final String id;
  final String eventType;

  /// 事件类型的版本号（对应服务端事件登记表）。
  final int typeVersion;
  final String deviceId;

  /// 记事件时的设备时间，已经转成 UTC（带时区，满足接口要求）。
  final DateTime deviceTime;
  final String appVersion;
  final EventCorrelationIds? correlation;

  /// 事件内容。不要放 user_id：服务端按登录状态填入，客户端自报无效。
  final Map<String, dynamic>? content;
}

/// 本机待上传事件队列：只负责存取，不知道要不要联网、怎么上传（见 event_uploader.dart）。
///
/// 手机端用 drift 落盘（event_queue_mobile.dart），网页端和测试用内存替身
/// （event_queue_web.dart / fake_event_queue.dart）——按 CLAUDE.md
/// “手机专有能力放接口后面，网页端用替身实现”的约定。
abstract class EventQueue {
  /// 立即写入队列就返回，不等网络。相同 [QueuedEvent.id] 的记录会被替换
  /// （正常不会发生：事件 ID 由 event_recorder.dart 生成一次；重复只可能是
  /// 调用方自己用同一个 ID 重试写入）。
  Future<void> enqueue(QueuedEvent event);

  /// 还没上传成功的事件，按 [QueuedEvent.deviceTime] 从早到晚排好序；
  /// [limit] 限制一次最多取几条（不传就是全部）。
  Future<List<QueuedEvent>> pending({int? limit});

  /// 服务端确认收到（accepted 或 duplicate）后删除这一条。
  Future<void> remove(String id);

  /// 批量删除，等价于多次 [remove]，但落盘实现只需要一次事务。
  Future<void> removeAll(Iterable<String> ids);

  /// 服务端答复"拒收"（未通过登记表校验）后调用：把这一条从待上传队列移到
  /// 本机拒收区，记下原因代码，之后 [pending] 不会再返回它，也不会再重试上传
  /// （票 5 / #73）。不认识的 [id]（已经不在队列里）安静忽略。
  Future<void> reject(String id, {required String reasonCode});

  /// 拒收区里当前有多少条，诊断/测试用，不涉及事件内容。
  Future<int> rejectedCount();

  /// 清空待上传队列和拒收区的全部内容（不上传、不上报，直接丢弃）。
  ///
  /// 退出登录、注销账号时调用：本机队列里可能还留着上一个用户没传完的事件，
  /// 不清掉的话，下一个在同一台设备登录的用户会把这些事件当成自己的传上去
  /// （服务端按登录状态把 user_id 填成当时登录的那个人）。调用方应该先尽力
  /// 上传一次（能传的传掉），再调用这个方法丢弃剩下传不出去的。
  Future<void> clear();

  /// 释放底层资源（drift 的数据库连接等）；内存替身不需要做什么。
  Future<void> close();
}

/// 当前平台的队列实现。
final eventQueueProvider = Provider<EventQueue>((ref) {
  final queue = createEventQueue();
  ref.onDispose(queue.close);
  return queue;
});
