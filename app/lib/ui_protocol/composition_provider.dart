import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart'
    show
        ComponentDescriptor,
        ComposeRequest,
        EventCorrelationIds,
        PageDescription;

import '../api/api_client.dart';
import '../events/event_recorder.dart';
import 'component_registry.dart';
import 'protocol_paths.dart';
import 'protocol_schemas.dart';

/// 组合请求 + 校验后的结果。合法时是解析好的页面描述；不合法或请求出错时带上原因，
/// 由页面决定改显示标准布局（完整的兜底原因代码和事件记录在 SPEC-009.1 #79）。
sealed class CompositionResult {
  const CompositionResult();
}

class CompositionReady extends CompositionResult {
  const CompositionReady(this.description);

  final PageDescription description;
}

class CompositionFailed extends CompositionResult {
  const CompositionFailed(this.reason);

  final String reason;
}

final componentRegistryProvider = Provider<ComponentRegistry>(
  (ref) => defaultComponentRegistry,
);

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

  final Map<String, dynamic> raw;
  try {
    final response = await dio.post<Map<String, dynamic>>(
      '/v1/ui/compositions',
      data: request.toJson(),
    );
    final data = response.data;
    if (data == null) return const CompositionFailed('server_error');
    raw = data;
  } on DioException catch (e) {
    return CompositionFailed(ApiFailure.from(e).code);
  }

  final protocolMajor = raw['protocol'] as String?;
  if (protocolMajor == null) return const CompositionFailed('invalid_data');

  final schemas = ref.read(protocolSchemasProvider);
  final envelopeIssues = await schemas.validatePageDescription(
    protocolMajor,
    raw,
  );
  if (envelopeIssues.isNotEmpty) {
    return CompositionFailed('invalid_data: ${envelopeIssues.first}');
  }

  final components = raw['components'] as List<dynamic>? ?? const [];
  for (final entry in components) {
    final component = entry as Map<String, dynamic>;
    final type = component['type'] as String;
    if (!registry.isRegistered(type)) {
      return CompositionFailed('unknown_component: $type');
    }
    final data = component['data'] as Map<String, dynamic>? ?? const {};
    final issues = await schemas.validateComponentData(
      protocolMajor,
      type,
      data,
    );
    if (issues.isNotEmpty) {
      return CompositionFailed('invalid_data: ${issues.first}');
    }
  }

  final description = PageDescription.fromJson(raw);
  // SPEC-009.1 票 2（#78）：合法结果显示前记一条“组合展示”事件，content 和服务端
  // 那条（gramtree.ui_protocol.composition_events.composition_shown_content）
  // 保持同样的形状，方便日后核对两边是否一致。这里只覆盖“组合结果合法”这条路径
  // ——协议不合法/请求出错退回标准布局时该不该记、兜底原因怎么填，在 #79 里定。
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
