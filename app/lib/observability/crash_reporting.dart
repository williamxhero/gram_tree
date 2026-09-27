import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/app_config.dart';
import '../privacy/consent.dart';

/// 崩溃和错误上报（兼容 Sentry 协议，默认指向自建的 GlitchTip，不交给外部第三方）。
///
/// 规则：
/// * 用户同意隐私政策之前不初始化，不上报任何东西（[privacyConsentProvider]）；
///   撤回同意后立刻关闭。
/// * 开发和测试构建可以用 `--dart-define=CRASH_REPORTING_DEV=true` 手动打开；正式构建无效。
/// * 地址用 `--dart-define=SENTRY_DSN=...` 传入，没配就不初始化。
/// * 上报前用 [scrubEvent] 去掉菜谱内容、口味档案、健康信息和请求内容。

/// 真正去初始化上报 SDK 的那一层，测试里换成假的。
abstract class CrashReporterBackend {
  Future<void> init({
    required String dsn,
    required String environment,
    required BeforeSendCallback beforeSend,
  });

  /// 用户撤回同意时关闭上报。
  Future<void> close();
}

class SentryCrashReporterBackend implements CrashReporterBackend {
  const SentryCrashReporterBackend();

  @override
  Future<void> init({
    required String dsn,
    required String environment,
    required BeforeSendCallback beforeSend,
  }) => SentryFlutter.init((options) {
    options
      ..dsn = dsn
      ..environment = environment
      ..sendDefaultPii = false
      ..attachScreenshot = false
      ..beforeSend = beforeSend;
  });

  @override
  Future<void> close() => Sentry.close();
}

final crashReporterBackendProvider = Provider<CrashReporterBackend>(
  (ref) => const SentryCrashReporterBackend(),
);

/// 构建时的上报设置。
class CrashReportingConfig {
  const CrashReportingConfig({required this.dsn, required this.devOverride});

  factory CrashReportingConfig.fromEnvironment() => const CrashReportingConfig(
    dsn: String.fromEnvironment('SENTRY_DSN'),
    devOverride: bool.fromEnvironment('CRASH_REPORTING_DEV'),
  );

  final String dsn;
  final bool devOverride;
}

final crashReportingConfigProvider = Provider<CrashReportingConfig>(
  (ref) => CrashReportingConfig.fromEnvironment(),
);

/// 上报是否正在运行。在 App 根部 watch 它：条件满足时初始化，撤回同意时关闭。
final crashReportingProvider = NotifierProvider<CrashReporting, bool>(
  CrashReporting.new,
);

class CrashReporting extends Notifier<bool> {
  @override
  bool build() {
    final consent = ref.watch(privacyConsentProvider);
    final config = ref.watch(crashReportingConfigProvider);
    final app = ref.watch(appConfigProvider);
    final allowed = consent || (config.devOverride && !app.isProd);
    final running = stateOrNull ?? false;
    if (!allowed || config.dsn.isEmpty) {
      // 撤回同意后立刻停止上报
      if (running) ref.read(crashReporterBackendProvider).close();
      return false;
    }
    if (running) return true;
    ref
        .read(crashReporterBackendProvider)
        .init(
          dsn: config.dsn,
          environment: app.env.name,
          beforeSend: (event, hint) => scrubEvent(event),
        );
    return true;
  }
}

/// 字段名里带这些词的内容一律不上报。
final _sensitiveKey = RegExp(
  r'recipe|ingredient|step|taste|flavor|preference|family|health|allerg|diet|note|菜谱|口味|健康|过敏',
  caseSensitive: false,
);

/// 去掉可能带有菜谱内容、口味档案、健康信息的字段，只留定位问题需要的信息。
SentryEvent scrubEvent(SentryEvent event) {
  event
    ..request = null
    ..user = event.user == null ? null : SentryUser(id: event.user!.id)
    ..serverName = null;
  // extra 已不推荐使用，但第三方代码仍可能往里写，照样要清理
  // ignore: deprecated_member_use
  event.extra?.removeWhere((key, _) => _sensitiveKey.hasMatch(key));
  event.tags?.removeWhere((key, _) => _sensitiveKey.hasMatch(key));
  event.contexts.removeWhere((key, _) => _sensitiveKey.hasMatch(key));
  // 面包屑只留类别、级别和时间，不留文字和附带数据
  event.breadcrumbs = event.breadcrumbs
      ?.map(
        (b) => Breadcrumb(
          category: b.category,
          type: b.type,
          level: b.level,
          timestamp: b.timestamp,
        ),
      )
      .toList();
  return event;
}

/// 拒收原因、积压告警这类"需要关注但不是崩溃"的情况，走同一条上报通道（同样
/// 只在用户同意隐私政策后才真正发送——未初始化时 Sentry 的静态方法是空操作，
/// 不需要在这里重复判断一遍）。接口很窄：只是一句不含事件内容的消息，方便测试
/// 用假实现替换、断言到底报了什么。
abstract class EventReportBackend {
  void report(String message, {required SentryLevel level});
}

class SentryEventReportBackend implements EventReportBackend {
  const SentryEventReportBackend();

  @override
  void report(String message, {required SentryLevel level}) {
    unawaited(Sentry.captureMessage(message, level: level));
  }
}

final eventReportBackendProvider = Provider<EventReportBackend>(
  (ref) => const SentryEventReportBackend(),
);

/// 一条事件被服务端拒收（未通过登记表校验）、挪进本机拒收区之后调用。
///
/// 只报事件 ID、类型、版本号和原因代码，不带事件内容——[content] 本来就不在这个
/// 函数的参数里，不是靠上报前再过滤一遍。
void reportEventRejection(
  Ref ref, {
  required String eventId,
  required String eventType,
  required int typeVersion,
  required String reasonCode,
}) {
  ref
      .read(eventReportBackendProvider)
      .report(
        'event_rejected id=$eventId type=$eventType v$typeVersion '
        'reason=$reasonCode',
        level: SentryLevel.warning,
      );
}

/// 本机待上传事件积压（数量或最老一条距今的时间）超过阈值时调用。
/// 只报数量和积压时长，不删除、不读取任何事件内容。
void reportEventBacklogAlert(
  Ref ref, {
  required int count,
  required Duration oldestAge,
}) {
  ref
      .read(eventReportBackendProvider)
      .report(
        'event_backlog_alert count=$count oldest_age_seconds=${oldestAge.inSeconds}',
        level: SentryLevel.warning,
      );
}
