import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../widgets/empty_state.dart';
import '../intent_labels.dart';

/// 通用组件：标准空态。结论层是标题，依据层（可选）是一句说明，第一个动作
/// （如果有）渲染成主按钮，文案是 `data.action_label`（没有就退回按意图给的通用
/// 文案）。复用现成的 [EmptyState]，图标先用一个通用的“做饭”图标——具体空态图标
/// 由业务组件登记时各自决定，通用组件不认场景（SPEC-009.1 #77，#80 定稿设计系统
/// 时再细化）。
Widget buildEmptyStateComponent(
  BuildContext context,
  ComponentDescriptor component,
  void Function(ActionDescriptor action) onAction,
) {
  final data = component.data as Map<String, dynamic>;
  final conclusion = data['conclusion'] as String? ?? '';
  final basis = data['basis'] as Map<String, dynamic>?;
  final message = basis?['text'] as String? ?? '';
  final actionLabel = data['action_label'] as String?;
  final actions = component.actions ?? const [];
  final action = actions.isEmpty ? null : actions.first;

  return EmptyState(
    icon: Icons.restaurant_outlined,
    title: conclusion,
    message: message,
    actionLabel: action == null
        ? null
        : (actionLabel ?? intentDefaultLabel(action.intent)),
    onAction: action == null ? null : () => onAction(action),
  );
}
