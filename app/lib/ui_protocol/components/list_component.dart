import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../app/theme.dart';
import '../component_registry.dart';
import 'component_scaffold.dart';

/// 通用组件：列表容器。结论层是一句概述（比如"共 3 项"），`items` 是要显示的行
/// （每行至少一个 `label`，`value` 可选，`note` 是这行的附加说明，只在详细档显示）。
/// 依据、明细层和其它组件一样可选（SPEC-009.1 #80：简略只显示概述和一个主要
/// 动作，标准加上各行，详细再加每行的附注和依据、明细入口）。
///
/// 一项都没有时（`items` 是空数组）当作"没有内容"，显示登记的标准空态。
Widget buildListComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
) {
  final data = component.data as Map<String, dynamic>;
  final conclusion = data['conclusion'] as String?;
  final items = (data['items'] as List<dynamic>? ?? const [])
      .cast<Map<String, dynamic>>();
  if (conclusion == null || conclusion.isEmpty || items.isEmpty) {
    return ComponentEmptyCard(emptyState: emptyState);
  }

  final theme = Theme.of(context);
  final colors = GramTreeColors.of(context);
  final basisText = parseBasisText(data);
  final actions = resolveComponentActions(component.actions);
  final showItems = component.detail != ComponentDescriptorDetailEnum.brief;
  final detailedMode =
      component.detail == ComponentDescriptorDetailEnum.detailed;
  final detailLabel = detailedMode
      ? labelForAction(data, 'detail_label', actions.detail)
      : null;

  return ComponentCard(
    detail: component.detail,
    conclusion: Text(conclusion, style: theme.textTheme.bodyMedium),
    conclusionSemanticsText: conclusion,
    standardExtra: showItems
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, color: theme.colorScheme.outlineVariant),
                _ListRow(
                  item: items[i],
                  showNote: detailedMode,
                  theme: theme,
                  colors: colors,
                ),
              ],
            ],
          )
        : null,
    basisText: basisText,
    primaryActionLabel: labelForAction(data, 'action_label', actions.primary),
    onPrimaryAction: callbackForAction(context, actions.primary, onAction),
    detailLabel: detailLabel,
    onDetail: callbackForAction(context, actions.detail, onAction),
  );
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.item,
    required this.showNote,
    required this.theme,
    required this.colors,
  });

  final Map<String, dynamic> item;
  final bool showNote;
  final ThemeData theme;
  final GramTreeColors colors;

  @override
  Widget build(BuildContext context) {
    final label = item['label'] as String? ?? '';
    final value = item['value'] as String?;
    final note = item['note'] as String?;
    final semanticsLabel = [label, ?value, if (showNote) ?note].join('，');

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        // 这一行的名称、数值、附注都是纯展示，读屏文案已经拼进上面的 [semanticsLabel]
        // 了，排除掉子级 Text 各自默认的读屏文案，不让它们重复读一遍。
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(label, style: theme.textTheme.bodyMedium),
                  ),
                  if (value != null)
                    Text(
                      value,
                      style: colors.numberStyle(theme.textTheme.bodyMedium!),
                    ),
                ],
              ),
              if (showNote && note != null) ...[
                const SizedBox(height: 2),
                Text(
                  note,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
