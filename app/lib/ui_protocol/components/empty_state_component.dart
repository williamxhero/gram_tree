import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../widgets/empty_state.dart';
import '../component_registry.dart';
import 'component_scaffold.dart';

/// 通用组件：标准空态。结论层是标题，依据层（可选）是一句说明，第一个动作
/// （如果有）渲染成主按钮；第二个动作（如果有）只在详细档显示成一个次要入口
/// （SPEC-009.1 #80：简略只显示标题和主按钮，标准加依据说明，详细再加明细入口）。
///
/// 复用现成的 [EmptyState]（`widgets/empty_state.dart`），图标先用一个通用的
/// "做饭"图标——具体空态图标由业务组件登记时各自决定，通用组件不认场景。
Widget buildEmptyStateComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
) {
  final data = component.data as Map<String, dynamic>;
  final conclusion = data['conclusion'] as String?;
  if (conclusion == null || conclusion.isEmpty) {
    return EmptyState(
      icon: Icons.restaurant_outlined,
      title: emptyState.title,
      message: emptyState.message ?? '',
    );
  }

  final basisText = parseBasisText(data);
  final actions = resolveComponentActions(component.actions);
  final showBasis = component.detail != ComponentDescriptorDetailEnum.brief;
  final showDetail = component.detail == ComponentDescriptorDetailEnum.detailed;
  final detailLabel = showDetail
      ? labelForAction(data, 'detail_label', actions.detail)
      : null;

  return EmptyState(
    icon: Icons.restaurant_outlined,
    title: conclusion,
    message: showBasis ? (basisText ?? '') : '',
    actionLabel: actions.primary == null
        ? null
        : labelForAction(data, 'action_label', actions.primary),
    onAction: callbackForAction(context, actions.primary, onAction),
    footer: showDetail && actions.detail != null
        ? Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextButton(
              onPressed: callbackForAction(context, actions.detail, onAction),
              child: Text(detailLabel ?? ''),
            ),
          )
        : null,
  );
}
