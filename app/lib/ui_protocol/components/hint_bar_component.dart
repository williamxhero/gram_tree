import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../component_registry.dart';
import 'component_scaffold.dart';

/// 通用组件：提示条。结论层是一句话，整条可点触发主要动作（不单独画按钮）；
/// 依据、明细层是可选的（SPEC-009.1 #80：简略只显示结论，标准加依据占位，
/// 详细把依据摊开、加明细入口）。
Widget buildHintBarComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
) {
  final data = component.data as Map<String, dynamic>;
  final conclusion = data['conclusion'] as String?;
  if (conclusion == null || conclusion.isEmpty) {
    return ComponentEmptyCard(emptyState: emptyState);
  }

  final theme = Theme.of(context);
  final basisText = parseBasisText(data);
  final actions = resolveComponentActions(component.actions);
  final detailLabel = component.detail == ComponentDescriptorDetailEnum.detailed
      ? labelForAction(data, 'detail_label', actions.detail)
      : null;

  final conclusionRow = Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        Icons.info_outline,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(conclusion, style: theme.textTheme.bodyMedium)),
    ],
  );

  return ComponentCard(
    detail: component.detail,
    conclusion: conclusionRow,
    conclusionSemanticsText: conclusion,
    basisText: basisText,
    // 提示条整条就是主要动作的点击区域，不另外画一个按钮；仍然把动作文案报给
    // 读屏，方便用户知道点了会发生什么。
    primaryActionLabel: labelForAction(data, 'action_label', actions.primary),
    showPrimaryButton: false,
    onTapConclusion: callbackForAction(context, actions.primary, onAction),
    detailLabel: detailLabel,
    onDetail: callbackForAction(context, actions.detail, onAction),
  );
}
