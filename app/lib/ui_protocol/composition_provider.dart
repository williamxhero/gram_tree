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
import '../events/event_recorder.dart';
import '../features_flags/features.dart';
import 'component_registry.dart';
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

final compositionTimeoutMsProvider = Provider<int>((ref) {
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
/// 协议大版本不认识、信封结构不合法（含动作格式不对，即“未登记的动作”目前唯一覆盖
/// 的范围，真正的意图登记表是 #81 的事）、组件类型没登记过、组件数据不合法、缺应有的
/// 必显组件、请求本身出错（网络/服务端报错）、等待超过配置的时限。判断顺序和服务端
/// `gramtree.ui_protocol.validation.classify_invalid_description` 保持一致，两边对
/// 同一份 `samples/invalid/` 样例的判定才会一样。
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
    return _fail(ref, pageType, FallbackInfoReasonCodeEnum.timeout);
  } on DioException {
    // ApiFailure 区分的网络/接口错误码是给用户提示用的；这里的兜底原因代码只有
    // FallbackReasonCode 这几种取值，没有更细的"网络不通"，都算作"服务端报错"。
    return _fail(ref, pageType, FallbackInfoReasonCodeEnum.serverError);
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
  return CompositionReady(description);
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
Future<CompositionResult> _fail(
  Ref ref,
  String pageType,
  FallbackInfoReasonCodeEnum reason, {
  String? compositionId,
}) async {
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
