// 构造函数里的具名参数（initialBackoff/maxBackoff/batchSize）要能从测试里按名字传，
// 不能直接用同名的私有字段做 initializing formal（外部调用不了以下划线开头的具名参数）。
// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../api/api_client.dart';
import '../auth/session.dart';
import '../observability/crash_reporting.dart';
import 'event_queue.dart';

/// 服务端答复"这一整批超过上限"用的错误码（#70：`events.upload_max_items`/
/// `events.upload_max_bytes`），命中时要自动砍小批次重传，不是走网络失败那套
/// 退避重试（同样大小的批次再重试多少次也还是会被拒）。
const _batchTooLargeCodes = {'too_many_events', 'payload_too_large'};

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
       _effectiveBatchSize = batchSize {
    _backoff = _initialBackoff;
  }

  final Ref _ref;
  final Duration _initialBackoff;
  final Duration _maxBackoff;

  /// 一次最多传几条；一开始是构造函数传的 `batchSize`（服务端单批硬上限是可配置
  /// 的正式上限，见 #70 的 `events.upload_max_items`/`events.upload_max_bytes`，
  /// 这里给个明显更小的默认值，避免单次请求体太大）。服务端答复"超过上限"之后
  /// 会砍半，直到不再超限或跌到 [_minBatchSize]（票 5 / #73）；砍小之后不再自动
  /// 恢复——同一个上传器的生命周期内没必要反复试探服务端的上限在哪。
  int _effectiveBatchSize;

  static const _minBatchSize = 1;

  /// 队列条数超过这个数就发一次积压告警（不删除任何事件）。
  static const backlogCountThreshold = 500;

  /// 最老一条距今超过这个时长也发一次积压告警。
  static const backlogAgeThreshold = Duration(hours: 24);

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
      // 尽力上传完之后再看一眼积压情况：不管这次有没有传完，队列还是那么大/
      // 那么老就报一次告警，不删除任何事件。同一次 triggerUpload 只检查这一次，
      // 不会因为上面的 do-while 跑了好几轮就报好几次。
      await _checkBacklog();
    } finally {
      if (_ref.mounted) _uploading = false;
    }
  }

  Future<void> _drain() async {
    // 未登录（或者还没同意隐私政策）时不发请求：ConsentGate/AuthInterceptor 会让
    // 请求失败，与其那样不如直接跳过，事件照样留在队列里，登录后再传。
    if (_session.current == null) return;
    while (true) {
      final batch = await _queue.pending(limit: _effectiveBatchSize);
      if (!_ref.mounted) return;
      if (batch.isEmpty) {
        _backoff = _initialBackoff;
        return;
      }
      final outcome = await _uploadBatch(batch);
      if (!_ref.mounted) return;
      switch (outcome) {
        case _BatchOutcome.done:
          // 批次还有剩（队列比一批多）就继续 while 循环马上传下一批。
          _backoff = _initialBackoff;
          break;
        case _BatchOutcome.retrySmaller:
          // 已经在 _uploadBatch 里砍小 _effectiveBatchSize 了，什么都不用做：
          // 循环回到顶部会直接用新的批次大小重新取一批，不是网络问题，不用等退避。
          break;
        case _BatchOutcome.retryLater:
          _scheduleRetry();
          return;
      }
    }
  }

  /// 上传一批，返回这一批接下来该怎么办（见 [_BatchOutcome]）。
  Future<_BatchOutcome> _uploadBatch(List<QueuedEvent> batch) async {
    final EventUploadResponse response;
    try {
      final resp = await _api.getEventsApi().uploadEvents(
        eventUploadRequest: EventUploadRequest(
          events: [for (final e in batch) _toItem(e)],
        ),
      );
      if (!_ref.mounted) {
        return _BatchOutcome.done; // 容器没了，别再碰 _ref，也别再排重试
      }
      final data = resp.data;
      if (data == null) return _BatchOutcome.retryLater;
      response = data;
    } on DioException catch (e) {
      if (_isBatchTooLarge(e)) {
        _shrinkBatchSize();
        return _BatchOutcome.retrySmaller;
      }
      // 网络错误、服务端 5xx 都保守处理成“这批没传成功”：不崩溃，事件留在队列里，
      // 外层按退避间隔重试。
      return _BatchOutcome.retryLater;
    } catch (_) {
      // 响应解析失败（比如遇到这份客户端还不认识的取值）同样保守处理。
      return _BatchOutcome.retryLater;
    }
    final done = <String>[];
    final handled = <String>{};
    for (final result in response.results) {
      switch (result.status) {
        case EventUploadResultItemStatusEnum.accepted:
        case EventUploadResultItemStatusEnum.duplicate:
          done.add(result.id);
          handled.add(result.id);
        case EventUploadResultItemStatusEnum.rejected:
          await _handleRejected(batch, result);
          handled.add(result.id);
      }
    }
    if (!_ref.mounted) return _BatchOutcome.done;
    if (done.isNotEmpty) await _queue.removeAll(done);
    return handled.length == batch.length
        ? _BatchOutcome.done
        : _BatchOutcome.retryLater;
  }

  /// 挪进本机拒收区、通过崩溃/错误上报通道报告原因（不带事件内容），不再重试。
  Future<void> _handleRejected(
    List<QueuedEvent> batch,
    EventUploadResultItem result,
  ) async {
    final reasonCode = result.reason?.code ?? 'unknown';
    await _queue.reject(result.id, reasonCode: reasonCode);
    if (!_ref.mounted) return;
    final event = _findEvent(batch, result.id);
    reportEventRejection(
      _ref,
      eventId: result.id,
      eventType: event?.eventType ?? 'unknown',
      typeVersion: event?.typeVersion ?? 0,
      reasonCode: reasonCode,
    );
  }

  /// 队列条数或最老一条积压时间超限时报一次告警，不删除任何事件。
  Future<void> _checkBacklog() async {
    final pending = await _queue.pending();
    if (!_ref.mounted || pending.isEmpty) return;
    // pending() 按 deviceTime 从早到晚排好序，第一条就是最老的。
    final oldestAge = DateTime.now().toUtc().difference(
      pending.first.deviceTime,
    );
    if (pending.length > backlogCountThreshold ||
        oldestAge > backlogAgeThreshold) {
      reportEventBacklogAlert(
        _ref,
        count: pending.length,
        oldestAge: oldestAge,
      );
    }
  }

  bool _isBatchTooLarge(DioException error) =>
      _batchTooLargeCodes.contains(ApiFailure.from(error).code);

  void _shrinkBatchSize() {
    _effectiveBatchSize = math.max(_minBatchSize, _effectiveBatchSize ~/ 2);
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

QueuedEvent? _findEvent(List<QueuedEvent> batch, String id) {
  for (final e in batch) {
    if (e.id == id) return e;
  }
  return null;
}

/// 一批上传完之后接下来该怎么办。
enum _BatchOutcome {
  /// 这一批里的每条都有了结论（accepted/duplicate 已删除，rejected 已挪进拒收区），
  /// 队列里如果还有更多待上传事件，外层会立刻接着传下一批。
  done,

  /// 服务端答复"这一批超过上限"：已经把 [EventUploader._effectiveBatchSize] 砍小，
  /// 外层应该立刻用新的批次大小重试，不用等退避。
  retrySmaller,

  /// 网络问题、服务端 5xx、或者响应里有解析不了/不认识的取值：这一批原样留在
  /// 队列里，外层按退避间隔重试。
  retryLater,
}
