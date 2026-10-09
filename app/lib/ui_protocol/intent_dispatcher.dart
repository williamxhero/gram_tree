import 'package:flutter/material.dart';

import '../network/reachability.dart';
import '../network/online_features.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart'
    show ActionDescriptor, EventCorrelationIds;

import '../events/event_recorder.dart';
import 'intent_registry.dart';

/// "从组合页面进入下一页时带上来源组合 ID"的传递机制（SPEC-009.1 #81）：记住
/// 最近一次触发动作时用的组合 ID，后续页面/事件可以读它，填进自己发出事件的
/// 关联 ID 里的"界面组合"字段（`EventCorrelationIds.uiCompositionId`）。
///
/// 这张票只提供这一个简单的 Provider 作为传递机制本身，并测试"派发动作时写入、
/// 别处能读到"这条链路；具体哪个业务事件要带上它、带上之后怎么用，由用到它的
/// 后续子 SPEC 决定（票面点名的"开始做"和做菜记录事件）。用"最近一次"而不是
/// 给每个意图单独接一条传递路径：从组合页面点进下一页，天然就是线性的，读到的
/// 总是"最近一次点进来是从哪个组合来的"就够用；[IntentDispatcher.dispatch] 对
/// 任何意图都会写入，不局限于会跳转页面的意图。
class SourceCompositionId extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? compositionId) => state = compositionId;
}

final sourceCompositionIdProvider =
    NotifierProvider<SourceCompositionId, String?>(SourceCompositionId.new);

/// 统一的意图派发入口（SPEC-009.1 #81）：组件上的动作只能是 [IntentRegistry] 里
/// 登记过的意图，不管按钮、菜单、还是以后的一句话输入，都调这一个方法——同一个
/// 意图因此不管从哪个入口触发，都会走同一个处理器、得到同样的结果。
///
/// 具体做的事，顺序固定：
/// 1. 记下来源组合 ID（[sourceCompositionIdProvider]）。
/// 2. 记一条 `ui.component_action` 事件（组合 ID、组件实例 ID、意图名——SPEC-009.1
///    #78 登记的事件类型，`content` 形状见 `ComponentActionContentV1`）。
/// 3. 调用这个意图登记的处理器（如果有）。
class IntentDispatcher {
  IntentDispatcher(this._ref);

  final Ref _ref;

  Future<void> dispatch(
    BuildContext context, {
    String? compositionId,
    required String componentId,
    required ActionDescriptor action,
  }) async {
    final registry = _ref.read(intentRegistryProvider);
    final params = _asParamsMap(action.params);
    final spec = registry[action.intent];
    // 组合结果显示前已经在 composition_provider.dart 里校验过"意图是否已登记、
    // 参数格式合不合法"，正常渲染出来的动作到这里理应总是合法的；这里再判一次是
    // 给"测试直接构造 ComponentDescriptor、绕开协议 Schema 校验"这种情况兜底
    // （component_scaffold.dart 顶部注释提到过这个口子）——不合法就安静地什么都
    // 不做，不抛异常、不影响界面。
    if (spec == null || !spec.validateParams(params)) return;

    if (OnlineFeatures.forIntent(action.intent, params) != null) {
      final status = _ref.read(apiReachabilityProvider);
      final allowed =
          status.canRequest &&
          await _ref.read(apiReachabilityProvider.notifier).check();
      if (!allowed) {
        if (context.mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text(_ref.read(apiReachabilityProvider).message)),
          );
        }
        return;
      }
    }

    // Fixed business pages have no server composition; never invent its ID.
    if (compositionId != null) {
      _ref.read(sourceCompositionIdProvider.notifier).set(compositionId);
    }

    try {
      await _ref
          .read(eventRecorderProvider)
          .record(
            eventType: 'ui.component_action',
            typeVersion: 1,
            correlation: compositionId == null
                ? null
                : EventCorrelationIds(uiCompositionId: compositionId),
            content: {'component_id': componentId, 'intent': action.intent},
          );
    } catch (_) {
      // Optional telemetry must never block privacy controls. Keep ordinary
      // intent behavior unchanged and never log queue errors/private payloads.
      if (!action.intent.startsWith('allergies_')) rethrow;
    }

    final handler = spec.handler;
    if (handler != null && context.mounted) {
      await handler(context, _ref, params);
    }
  }
}

Map<String, dynamic> _asParamsMap(Object? params) =>
    params is Map ? Map<String, dynamic>.from(params) : const {};

final intentDispatcherProvider = Provider<IntentDispatcher>(
  (ref) => IntentDispatcher(ref),
);
