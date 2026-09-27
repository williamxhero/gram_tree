import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../api/api_client.dart';
import '../privacy/consent.dart';
import '../storage/device_id.dart';
import '../util/ids.dart';

/// 产品埋点：只报页面访问、入口点击、加载耗时这类使用情况，和经验层事件完全分开。
///
/// 规则：
/// * 同意隐私政策之前不发（[privacyConsentProvider]）。
/// * 关掉设置里的“产品改进统计”开关之后也不发（[ConsentState.productAnalyticsEnabled]）。
/// * 不需要像经验层事件那样有离线队列：不满足条件时直接返回；请求失败也直接丢弃，不重试、
///   不落本地——这些数据只用来改进产品，不是用户资产。
/// * 内容只允许事件类型、页面/入口标识、可选耗时、发生时间、设备 ID；不夹带菜谱内容、
///   口味档案、过敏和健康信息。
/// * 阶段一不接入任何第三方统计 SDK，调用只会发到味谱自己的服务端。
class ProductAnalytics {
  ProductAnalytics(this._ref);

  final Ref _ref;

  /// 是否允许采集：已同意隐私政策，并且没有关闭“产品改进统计”开关。
  bool get allowed =>
      _ref.read(privacyConsentProvider) &&
      _ref.read(consentProvider).productAnalyticsEnabled;

  Future<void> _send(
    AnalyticsEventInEventTypeEnum type,
    String target, {
    int? durationMs,
  }) async {
    if (!allowed) return;
    final event = AnalyticsEventIn(
      id: newUuidV4(),
      eventType: type,
      target: target,
      durationMs: durationMs,
      occurredAt: DateTime.now().toUtc(),
      deviceId: _ref.read(deviceIdProvider),
    );
    try {
      await _ref
          .read(apiClientProvider)
          .getAnalyticsApi()
          .uploadAnalyticsEvents(
            analyticsUploadRequest: AnalyticsUploadRequest(events: [event]),
          );
    } catch (_) {
      // 埋点失败不影响使用，也不重试
    }
  }

  /// 记一次页面访问，[name] 是页面标识（例如 'today'）。
  Future<void> reportPageView(String name) =>
      _send(AnalyticsEventInEventTypeEnum.pageView, name);

  /// 记一次入口点击，[id] 是入口标识（例如 'today.cook_button'）。
  Future<void> reportTap(String id) =>
      _send(AnalyticsEventInEventTypeEnum.tap, id);

  /// 记一次加载耗时，[name] 是被计时的页面/操作标识，[ms] 是耗时（毫秒）。
  Future<void> reportLoadDuration(String name, int ms) =>
      _send(AnalyticsEventInEventTypeEnum.loadDuration, name, durationMs: ms);
}

final productAnalyticsProvider = Provider<ProductAnalytics>(
  (ref) => ProductAnalytics(ref),
);
