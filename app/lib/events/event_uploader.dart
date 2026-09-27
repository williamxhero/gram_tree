// 构造函数里的具名参数（initialBackoff/maxBackoff/batchSize）要能从测试里按名字传，
// 不能直接用同名的私有字段做 initializing formal（外部调用不了以下划线开头的具名参数）。
// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../api/api_client.dart';
import '../auth/session.dart';
import 'event_queue.dart';

/// 把本机队列里的事件按顺序传给 #69 的批量上传接口，失败按退避间隔重试。
///
/// 触发时机（各只是“再试一次”，具体传不传、传哪些、传完删哪些都在这里决定）：
/// * 记一条新事件之后（event_recorder.dart）；
/// * 登录成功之后（auth/auth_controller.dart 的 `_afterSignIn()`）；
/// * App 回到前台、App 冷启动之后（event_upload_lifecycle.dart）。
///
/// 没有引入 connectivity 类的依赖包：失败后按退避间隔自动定时重试，网络恢复后
/// 下一次定时重试自然会成功，兼顾“网络恢复也要触发一次”的要求，不用单独监听连接状态。
final eventUploaderProvider = Provider<EventUploader>((ref) {
  final uploader = EventUploader(ref);
  ref.onDispose(uploader.dispose);
  return uploader;
});

class EventUploader {
  EventUploader(
    this._ref, {
    Duration initialBackoff = const Duration(seconds: 5),
    Duration maxBackoff = const Duration(minutes: 10),
    int batchSize = 100,
  }) : _initialBackoff = initialBackoff,
       _maxBackoff = maxBackoff,
       _batchSize = batchSize {
    _backoff = _initialBackoff;
  }

  final Ref _ref;
  final Duration _initialBackoff;
  final Duration _maxBackoff;

  /// 一次最多传几条；服务端单批硬上限是 500（票 2 起会换成可配置的正式上限），
  /// 这里给个明显更小的默认值，避免单次请求体太大。超限之后的自动分批重传是票 5（#73）的范围。
  final int _batchSize;

  late Duration _backoff;
  Timer? _retryTimer;
  bool _uploading = false;

  /// 跑的时候又有新的触发进来：跑完这一轮后立刻再补一轮，不丢这次触发。
  bool _rerunRequested = false;

  SessionStore get _session => _ref.read(sessionStoreProvider);
  GramtreeApi get _api => _ref.read(apiClientProvider);
  EventQueue get _queue => _ref.read(eventQueueProvider);

  /// 触发一次尝试上传。未登录时直接跳过、不发请求；同一时间只有一轮在跑，
  /// 重复调用不会并发发请求。
  ///
  /// 每次跨过一个 `await` 之后都要先检查 [Ref.mounted]：这个 uploader 绑在
  /// [eventUploaderProvider] 上，触发它的调用方（记事件、登录成功、回到前台）
  /// 不受这个 provider 生命周期控制，如果在等网络请求的当口整个容器已经销毁
  /// （比如页面测试重启 App），后面不能再碰 [_ref]，安静退出就好，不能崩溃。
  Future<void> triggerUpload() async {
    if (!_ref.mounted || _uploading) {
      if (_ref.mounted) _rerunRequested = true;
      return;
    }
    _uploading = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    try {
      do {
        _rerunRequested = false;
        await _drain();
        if (!_ref.mounted) return;
      } while (_rerunRequested);
    } finally {
      if (_ref.mounted) _uploading = false;
    }
  }

  Future<void> _drain() async {
    // 未登录（或者还没同意隐私政策）时不发请求：ConsentGate/AuthInterceptor 会让
    // 请求失败，与其那样不如直接跳过，事件照样留在队列里，登录后再传。
    if (_session.current == null) return;
    while (true) {
      final batch = await _queue.pending(limit: _batchSize);
      if (!_ref.mounted) return;
      if (batch.isEmpty) {
        _backoff = _initialBackoff;
        return;
      }
      final allDone = await _uploadBatch(batch);
      if (!_ref.mounted) return;
      if (!allDone) {
        _scheduleRetry();
        return;
      }
      _backoff = _initialBackoff;
    }
  }

  /// 上传一批，返回这一批是不是已经整批都能从队列里删除。
  Future<bool> _uploadBatch(List<QueuedEvent> batch) async {
    final EventUploadResponse response;
    try {
      final resp = await _api.getEventsApi().uploadEvents(
        eventUploadRequest: EventUploadRequest(
          events: [for (final e in batch) _toItem(e)],
        ),
      );
      if (!_ref.mounted) return true; // 容器没了，别再碰 _ref，也别再排重试
      final data = resp.data;
      if (data == null) return false;
      response = data;
    } catch (_) {
      // 网络错误、服务端 5xx、响应解析失败（比如遇到这份客户端还不认识的取值）
      // 都保守处理成“这批没传成功”：不崩溃，事件留在队列里，外层按退避间隔重试。
      return false;
    }
    final done = <String>[];
    for (final result in response.results) {
      switch (result.status) {
        case EventUploadResultItemStatusEnum.accepted:
        case EventUploadResultItemStatusEnum.duplicate:
          done.add(result.id);
        case EventUploadResultItemStatusEnum.rejected:
          // 票 5（#73）会在这里挪进拒收区、通过现有错误上报通道报告（不带内容），
          // 同样从队列删除。这一票暂不处理，事件留在队列里等 #73 落地。
          break;
      }
    }
    if (done.isNotEmpty) await _queue.removeAll(done);
    return done.length == batch.length;
  }

  EventUploadItem _toItem(QueuedEvent e) => EventUploadItem(
    id: e.id,
    eventType: e.eventType,
    typeVersion: e.typeVersion,
    deviceId: e.deviceId,
    deviceTime: e.deviceTime,
    appVersion: e.appVersion,
    correlation: e.correlation,
    // 生成的模型要求 Map<String, Object>（不接受 null 值）；事件内容本来就
    // 应该是结构化数据，不应该带 null，这里显式转换，带了 null 会直接报错而不是悄悄丢字段。
    content: e.content == null ? null : Map<String, Object>.from(e.content!),
  );

  void _scheduleRetry() {
    _retryTimer?.cancel();
    final wait = _backoff;
    _retryTimer = Timer(wait, () => unawaited(triggerUpload()));
    final next = wait * 2;
    _backoff = next > _maxBackoff ? _maxBackoff : next;
  }

  void dispose() {
    _retryTimer?.cancel();
  }
}
