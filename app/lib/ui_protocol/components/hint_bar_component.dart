import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../app/theme.dart';
import '../intent_labels.dart';

/// 通用组件：提示条。结论层是一句话，可选一个动作（点整条触发）。没有依据/明细层，
/// 三档详略下显示效果相同（SPEC-009.1 #77，三档详略在 #80 定稿时细化）。
Widget buildHintBarComponent(
  BuildContext context,
  ComponentDescriptor component,
  void Function(ActionDescriptor action) onAction,
) {
  final data = component.data as Map<String, dynamic>;
  final conclusion = data['conclusion'] as String? ?? '';
  final theme = Theme.of(context);
  final colors = GramTreeColors.of(context);
  final actions = component.actions ?? const [];
  final action = actions.isEmpty ? null : actions.first;

  final row = Row(
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

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(
      color: colors.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: theme.colorScheme.outlineVariant),
    ),
    clipBehavior: Clip.antiAlias,
    child: Semantics(
      label: action == null
          ? conclusion
          : '$conclusion，${intentDefaultLabel(action.intent)}',
      button: action != null,
      child: InkWell(
        onTap: action == null ? null : () => onAction(action),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: row,
        ),
      ),
    ),
  );
}
