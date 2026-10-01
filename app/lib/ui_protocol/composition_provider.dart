import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart'
    show
        ComponentDescriptor,
        ComposeRequest,
        EventCorrelationIds,
        FallbackInfoReasonCodeEnum,
        PageDescription;

import '../api/api_client.dart';
import '../config/app_config.dart';
import '../events/event_recorder.dart';
import '../features_flags/features.dart';
import 'component_registry.dart';
import 'composition_cache.dart';
import 'intent_registry.dart';
import 'page_types.dart';
import 'protocol_paths.dart';
import 'protocol_schemas.dart';

/// 组合请求 + 校验后的结果。合法时是解析好的页面描述；不合法、请求出错或等待超时时
/// 带上结构化的兜底原因代码，由页面决定改显示标准布局（SPEC-009.1 #79）。
sealed class CompositionResult {
  const CompositionResult();
}

class CompositionReady extends CompositionResult {
  const CompositionReady(this.description);

  final PageDescription description;
}

/// 等待超时、或者请求本身连不上服务端（离线）时，本机有一份依赖版本和服务端最新
/// 一次下发的完全一致的缓存——用它顶上，不算"正常拿到组合结果"（不会再记一条
/// "组合展示"事件，[_fail] 已经先记过一条带兜底原因的事件了），所以是单独的一个
/// 结果变体，而不是复用 [CompositionReady]（SPEC-009.1 票 7，#83）。
class CompositionFromCache extends CompositionResult {
  const CompositionFromCache(this.description, this.savedAt);

  final PageDescription description;

  /// 这份描述本机保存下来的时间，页面上显示成"上次更新于 xx:xx"。
  final DateTime savedAt;
}

/// [reason] 和服务端 `FallbackReasonCode`（`app/assets/contracts/ui_protocol/
/// schema/1.0/page_description.schema.json` 的 `fallback.reason_code` 枚举）一一
/// 对应，是生成客户端里同一个枚举类型（[FallbackInfoReasonCodeEnum]），不是自由文本，
/// 两端记的兜底原因因此保证是同一套代码。
class CompositionFailed extends CompositionResult {
  const CompositionFailed(this.reason);

  final FallbackInfoReasonCodeEnum reason;
}

final componentRegistryProvider = Provider<ComponentRegistry>(
  (ref) => defaultComponentRegistry,
);

/// App 等组合接口返回的时限（毫秒），从 `/v1/client-config` 的 `params` 下发，
/// 拿不到时（配置还没拉到、拉取失败、字段缺失）用和服务端登记表一致的默认值
/// （SPEC-009.1 #79：初始 800 毫秒）。
const defaultCompositionTimeoutMs = 800;
const _compositionTimeoutConfigKey = 'ui.composition_timeout_ms';
// Android E2E can give its emulator process extra time without changing the
// server's persisted/default runtime budget. Web and production leave this empty.
const _e2eCompositionTimeoutMs = String.fromEnvironment(
  'E2E_COMPOSITION_TIMEOUT_MS',
);

final compositionTimeoutMsProvider = Provider<int>((ref) {
  final e2eOverride = int.tryParse(_e2eCompositionTimeoutMs);
  if (!ref.watch(appConfigProvider).isProd && e2eOverride != null) {
    return e2eOverride;
  }
  // ClientConfig.params 是生成客户端里的 Object（openapi 的
  // additionalProperties 没有生成更具体的 Map 类型），这里按字典读一层。
  final params = ref.watch(clientConfigProvider).value?.params;
  final raw = params is Map ? params[_compositionTimeoutConfigKey] : null;
  return raw is num ? raw.toInt() : defaultCompositionTimeoutMs;
});

final compositionProvider = FutureProvider.family<CompositionResult, String>(
  (ref, pageType) => fetchComposition(
    ref,
    pageType: pageType,
    registry: ref.watch(componentRegistryProvider),
  ),
);

/// 请求组合结果，并在渲染前按协议信封 Schema 和每个组件的 data Schema 各校验一次
/// （#18 的硬性要求）。这里拿原始 JSON（而不是走生成客户端直接拿到的强类型对象）
/// 校验，因为生成的 Dart 模型只保证“反序列化不出错”，不保证“符合协议语义”——
/// 未登记组件、协议大版本这类语义校验要照共用的 Schema 文件走。
///
/// SPEC-009.1 #79：以下情况都整页退回标准布局，并各自带上结构化的兜底原因代码——
/// 协议大版本不认识、信封结构不合法（含动作格式不对）、组件类型没登记过、组件数据
/// 不合法、缺应有的必显组件、请求本身出错（网络/服务端报错）、等待超过配置的时限。
/// 判断顺序和服务端 `gramtree.ui_protocol.validation.classify_invalid_description`
/// 保持一致，两边对同一份 `samples/invalid/` 样例的判定才会一样。
///
/// SPEC-009.1 #81：在"信封结构合不合法"之外，这里还多一层"意图是不是已登记、参数
/// 格式对不对"的语义校验（[IntentRegistry.isValidAction]）——协议信封 Schema 只
/// 保证 `actions[].intent`/`actions[].params` 这两个字段本身的结构（字符串、对象）
/// 合法，未登记的意图名（例如服务端 bug 下发了一个 App 不认识的意图）、已登记意图但
/// 参数格式不对（比如 `open_page` 缺 `page`）、`open_page` 想跳到一个没登记过的页面
/// （含任意网址）都在这一层被识别成非法动作，同样按 `illegal_action` 整页退回标准
/// 布局。
Future<CompositionResult> fetchComposition(
  Ref ref, {
  required String pageType,
  required ComponentRegistry registry,
}) async {
  final dio = ref.read(dioProvider);
  final request = ComposeRequest(
    pageType: pageType,
    protocolVersion: supportedProtocolVersion,
    supportedComponents: registry.supportedTypes.toList(),
  );
  final timeoutMs = ref.watch(compositionTimeoutMsProvider);

  final Map<String, dynamic> raw;
  try {
    final response = await dio
        .post<Map<String, dynamic>>(
          '/v1/ui/compositions',
          data: request.toJson(),
        )
        .timeout(Duration(milliseconds: timeoutMs));
    final data = response.data;
    if (data == null) {
      return await _fail(ref, pageType, FallbackInfoReasonCodeEnum.serverError);
    }
    raw = data;
  } on TimeoutException {
    // 等待超过配置的时限（票 3，#79）：本机如果有依赖版本一致的缓存，先显示它，
    // 不直接退回标准布局（票 7，#83）。
    return _fail(
      ref,
      pageType,
      FallbackInfoReasonCodeEnum.timeout,
      tryCache: true,
    );
  } on DioException catch (e) {
    // ApiFailure 区分的网络/接口错误码是给用户提示用的；这里的兜底原因代码只有
    // FallbackReasonCode 这几种取值，没有更细的"网络不通"，都算作"服务端报错"。
    //
    // 票 7（#83）：只有"请求本身没能完成一个来回"（连不上、DNS 解析失败、被中途
    // 断开……，DioException 的 connectionError/unknown 这类）才尝试用本机缓存
    // 顶上——这才是"离线"；服务端已经收到请求、只是回了一个 4xx/5xx
    // （`DioExceptionType.badResponse`）不算"离线"，是服务端本身出了问题，不应该
    // 拿一份可能已经过期的本机内容顶上去掩盖它。
    final tryCache = e.type != DioExceptionType.badResponse;
    return _fail(
      ref,
      pageType,
      FallbackInfoReasonCodeEnum.serverError,
      tryCache: tryCache,
    );
  }

  final compositionId = raw['composition_id'] as String?;

  // 服务端自己已经判定这次组合该退回标准布局时，直接下发一份 fallback 非空、
  // components 为空的描述（SPEC-009.1 #79，见 docs/adr/0005）；这种情况不用再走
  // 一遍下面的 Schema 校验（反正内容本来就是空的），直接按服务端给的原因代码退回。
  final fallbackRaw = raw['fallback'];
  if (fallbackRaw is Map) {
    final reasonCode = fallbackRaw['reason_code'] as String?;
    return _fail(
      ref,
      pageType,
      _reasonFromValue(reasonCode),
      compositionId: compositionId,
    );
  }

  final protocol = raw['protocol'] as String?;
  if (protocol == null) {
    return _fail(
      ref,
      pageType,
      FallbackInfoReasonCodeEnum.invalidData,
      compositionId: compositionId,
    );
  }

  final schemas = ref.read(protocolSchemasProvider);
  if (schemas.resolveMajorDir(protocol) == null) {
    return _fail(
      ref,
      pageType,
      FallbackInfoReasonCodeEnum.unknownMajor,
      compositionId: compositionId,
    );
  }

  final envelopeIssues = await schemas.validatePageDescription(protocol, raw);
  if (envelopeIssues.isNotEmpty) {
    final isActionIssue = envelopeIssues.any(
      (issue) => issue.path.split('/').contains('actions'),
    );
    return _fail(
      ref,
      pageType,
      isActionIssue
          ? FallbackInfoReasonCodeEnum.illegalAction
          : FallbackInfoReasonCodeEnum.invalidData,
      compositionId: compositionId,
    );
  }

  final intentRegistry = ref.read(intentRegistryProvider);
  final components = raw['components'] as List<dynamic>? ?? const [];
  for (final entry in components) {
    final component = entry as Map<String, dynamic>;
    final type = component['type'] as String;
    if (!registry.isRegistered(type)) {
      return _fail(
        ref,
        pageType,
        FallbackInfoReasonCodeEnum.unknownComponent,
        compositionId: compositionId,
      );
    }
    final data = component['data'] as Map<String, dynamic>? ?? const {};
    final issues = await schemas.validateComponentData(protocol, type, data);
    if (issues.isNotEmpty) {
      return _fail(
        ref,
        pageType,
        FallbackInfoReasonCodeEnum.invalidData,
        compositionId: compositionId,
      );
    }
    // SPEC-009.1 #81：信封 Schema 只校验了 actions 的结构，这里再校验语义——每个
    // 动作的意图名必须已登记、参数必须符合这个意图的格式（未登记意图、参数格式错、
    // open_page 跳到未登记页面/任意网址都在这一步被挡下）。
    final actions = component['actions'] as List<dynamic>? ?? const [];
    for (final actionEntry in actions) {
      final action = actionEntry as Map<String, dynamic>;
      final intent = action['intent'] as String?;
      final params = action['params'] as Map<String, dynamic>? ?? const {};
      if (intent == null || !intentRegistry.isValidAction(intent, params)) {
        return _fail(
          ref,
          pageType,
          FallbackInfoReasonCodeEnum.illegalAction,
          compositionId: compositionId,
        );
      }
    }
  }

  final requiredTypes =
      ref.read(requiredComponentTypesProvider)[pageType] ?? const <String>{};
  if (requiredTypes.isNotEmpty) {
    final presentRequiredTypes = {
      for (final entry in components)
        if ((entry as Map<String, dynamic>)['required'] == true)
          entry['type'] as String,
    };
    if (!presentRequiredTypes.containsAll(requiredTypes)) {
      return _fail(
        ref,
        pageType,
        FallbackInfoReasonCodeEnum.missingRequired,
        compositionId: compositionId,
      );
    }
  }

  final description = PageDescription.fromJson(raw);
  // SPEC-009.1 票 2（#78）：合法结果显示前记一条“组合展示”事件，content 和服务端
  // 那条（gramtree.ui_protocol.composition_events.composition_shown_content）
  // 保持同样的形状，方便日后核对两边是否一致。
  await ref
      .read(eventRecorderProvider)
      .record(
        eventType: 'ui.composition_shown',
        typeVersion: 1,
        correlation: EventCorrelationIds(
          uiCompositionId: description.compositionId,
        ),
        content: _compositionShownContent(description),
      );
  // SPEC-009.1 票 7（#83）：成功拿到的描述连同它依赖的内容版本存到本机，供下次
  // 离线/超时时使用（见 [_fail] 的 tryCache 分支）。
  await ref
      .read(compositionCacheStoreProvider)
      .save(pageType, description, DateTime.now().toUtc());
  return CompositionReady(description);
}

/// 本机是否有一份"依赖版本和现在完全一致"的缓存——离线/超时时用它，不一致（含
/// 本机根本没存过）时返回 `null`，调用方退回标准布局。
CachedComposition? _usableCache(Ref ref, String pageType) {
  final cached = ref.read(compositionCacheStoreProvider).read(pageType);
  if (cached == null) return null;
  final cachedDependsOn = cached.description.cache.dependsOn ?? const {};
  final current = ref.read(localDependencyVersionsProvider);
  if (!dependsOnMatches(cachedDependsOn, current)) return null;
  return cached;
}

FallbackInfoReasonCodeEnum _reasonFromValue(String? value) {
  for (final reason in FallbackInfoReasonCodeEnum.values) {
    if (reason.value == value) return reason;
  }
  return FallbackInfoReasonCodeEnum.serverError;
}

/// 整页退回标准布局时记一条同样的“组合展示”事件，`is_fallback: true`，
/// `fallback_reason` 是这次退回的原因代码；没有拿到 `composition_id`（请求出错、
/// 超时、响应里根本没有这个字段）时关联 ID 留空，不编造一个假的。
///
/// [tryCache] 为 true（超时、或者请求本身没能完成一个来回）时，先查本机有没有
/// 依赖版本一致的缓存（SPEC-009.1 票 7，#83）——有就用它顶上，返回
/// [CompositionFromCache] 而不是退回标准布局；这不算"重新拿到组合结果"，记的
/// "组合展示"事件内容和正常成功时一样（用户确实看到了这些组件），沿用缓存里那份
/// 描述自带的 composition_id，不是一次新的组合决定，只是 App 自己把上一次的决定
/// 又显示了一遍——服务端这次请求根本没收到、不知道这件事，所以仍然要在本机记一条，
/// 不能像服务端命中缓存那样直接不记。
Future<CompositionResult> _fail(
  Ref ref,
  String pageType,
  FallbackInfoReasonCodeEnum reason, {
  String? compositionId,
  bool tryCache = false,
}) async {
  if (tryCache) {
    final cached = _usableCache(ref, pageType);
    if (cached != null) {
      await ref
          .read(eventRecorderProvider)
          .record(
            eventType: 'ui.composition_shown',
            typeVersion: 1,
            correlation: EventCorrelationIds(
              uiCompositionId: cached.description.compositionId,
            ),
            content: _compositionShownContent(cached.description),
          );
      return CompositionFromCache(cached.description, cached.savedAt);
    }
  }

  await ref
      .read(eventRecorderProvider)
      .record(
        eventType: 'ui.composition_shown',
        typeVersion: 1,
        correlation: compositionId == null
            ? null
            : EventCorrelationIds(uiCompositionId: compositionId),
        content: {
          'page_type': pageType,
          'components': const [],
          'is_fallback': true,
          'fallback_reason': reason.value,
        },
      );
  return CompositionFailed(reason);
}

Map<String, dynamic> _compositionShownContent(PageDescription description) {
  final components = description.components ?? const <ComponentDescriptor>[];
  final fallback = description.fallback;
  final experiment = description.experiment;
  return {
    'page_type': description.pageType,
    'components': [
      for (final c in components)
        {
          'type': c.type,
          'detail': c.detail.value,
          'reason_code': c.reason.code,
          'reason_text': c.reason.text,
        },
    ],
    'is_fallback': fallback != null,
    // 上传时事件内容会被转成 Map<String, Object>（不接受 null 值，见
    // event_uploader.dart 的 _toItem），所以没有兜底/实验分组时干脆不带这两个
    // key，不写 null 值；服务端 content_schema 里这两个字段本来就是可选的。
    if (fallback != null) 'fallback_reason': fallback.reasonCode.value,
    if (experiment != null)
      'experiment': {
        'experiment': experiment.experiment,
        'variant': experiment.variant,
      },
  };
}
