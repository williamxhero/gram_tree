import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../app/theme.dart';
import '../component_registry.dart';
import 'component_scaffold.dart';

/// 通用组件：分区标题。结论层是标题文字，`meta`（可选）是标准档起显示的附加说明
/// （比如"3 道"这种计数），依据、明细层和其它组件一样可选
/// （SPEC-009.1 #80：简略只显示标题，标准加计数，详细把依据摊开、加明细入口）。
Widget buildSectionTitleComponent(
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
  final meta = data['meta'] as String?;
  final basisText = parseBasisText(data);
  final actions = resolveComponentActions(component.actions);
  final detailLabel = component.detail == ComponentDescriptorDetailEnum.detailed
      ? labelForAction(data, 'detail_label', actions.detail)
      : null;

  return ComponentCard(
    detail: component.detail,
    conclusion: Text(
      conclusion,
      style: theme.textTheme.titleMedium?.copyWith(fontFamily: titleFont),
    ),
    conclusionSemanticsText: conclusion,
    standardExtra: meta == null
        ? null
        : Align(
            alignment: Alignment.centerRight,
            child: Text(
              meta,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
    basisText: basisText,
    primaryActionLabel: labelForAction(data, 'action_label', actions.primary),
    onPrimaryAction: callbackForAction(context, actions.primary, onAction),
    detailLabel: detailLabel,
    onDetail: callbackForAction(context, actions.detail, onAction),
  );
}
