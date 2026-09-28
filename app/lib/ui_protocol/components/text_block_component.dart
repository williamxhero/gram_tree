import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../component_registry.dart';
import 'component_scaffold.dart';

/// 通用组件：文字块。结论层就是要显示的一段正文，依据、明细层可选
/// （SPEC-009.1 #80：简略只显示这段文字和一个主要动作，标准加依据占位，
/// 详细把依据摊开、加明细入口）。
Widget buildTextBlockComponent(
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

  return ComponentCard(
    detail: component.detail,
    conclusion: Text(
      conclusion,
      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
    ),
    conclusionSemanticsText: conclusion,
    basisText: basisText,
    primaryActionLabel: labelForAction(data, 'action_label', actions.primary),
    onPrimaryAction: actions.primary == null
        ? null
        : () => onAction(actions.primary!),
    detailLabel: detailLabel,
    onDetail: actions.detail == null ? null : () => onAction(actions.detail!),
  );
}
