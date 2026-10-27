import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../l10n/app_localizations.dart';
import 'component_registry.dart';
import 'components/component_scaffold.dart';
import 'source_mark.dart';

Map<String, dynamic> _data(Object? raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};

Widget? _sourceMark(
  ComponentDescriptor component,
  Map<String, dynamic> source,
  void Function(ActionDescriptor) onAction,
) {
  final sourceType = source['source_type'] as String?;
  if (sourceType == null) return null;
  return SourceMark(
    sourceType: sourceType,
    componentId: component.id,
    value: source['value'] as String? ?? '',
    basisText: parseBasisText(source) ?? '',
    citation: _data(source['basis'])['citation'] as String?,
    required: component.required_ ?? false,
    feedbackEnabled: false,
    onAction: onAction,
  );
}

Widget buildDietaryStatisticsComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
) {
  final data = _data(component.data);
  final conclusion = data['conclusion'] as String?;
  if (conclusion == null || conclusion.isEmpty) {
    return ComponentEmptyCard(emptyState: emptyState);
  }
  final l10n = AppLocalizations.of(context);
  final source = _data(data['source']);
  final mark = _sourceMark(component, source, onAction);
  final actions = resolveComponentActions(component.actions);

  return ComponentCard(
    detail: component.detail,
    conclusion: Text(conclusion, style: Theme.of(context).textTheme.bodyMedium),
    conclusionSemanticsText: conclusion,
    standardExtra: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ?mark,
        Text('${l10n.dietaryStatisticsCookingCount}：${data['cooking_count']}'),
      ],
    ),
    basisText: parseBasisText(data) ?? parseBasisText(source),
    primaryActionLabel: labelForAction(data, 'action_label', actions.primary),
    onPrimaryAction: callbackForAction(context, actions.primary, onAction),
    detailLabel: labelForAction(data, 'detail_label', actions.detail),
    onDetail: callbackForAction(context, actions.detail, onAction),
  );
}

Widget buildDietaryDistributionComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
) {
  final data = _data(component.data);
  final conclusion = data['conclusion'] as String?;
  if (conclusion == null || conclusion.isEmpty) {
    return ComponentEmptyCard(emptyState: emptyState);
  }
  final l10n = AppLocalizations.of(context);
  final source = _data(data['source']);
  final mark = _sourceMark(component, source, onAction);
  final actions = resolveComponentActions(component.actions);
  final items = (data['items'] as List? ?? const []).whereType<Map>();

  return ComponentCard(
    detail: component.detail,
    conclusion: Text(conclusion, style: Theme.of(context).textTheme.bodyMedium),
    conclusionSemanticsText: conclusion,
    standardExtra: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mark != null) Align(alignment: Alignment.centerLeft, child: mark),
        for (final item in items)
          ListTile(
            title: Text(
              item['key'] as String? ?? l10n.dietaryStatisticsUnknown,
            ),
            trailing: Text('${item['count'] ?? 0}'),
          ),
      ],
    ),
    basisText: parseBasisText(data) ?? parseBasisText(source),
    primaryActionLabel: labelForAction(data, 'action_label', actions.primary),
    onPrimaryAction: callbackForAction(context, actions.primary, onAction),
    detailLabel: labelForAction(data, 'detail_label', actions.detail),
    onDetail: callbackForAction(context, actions.detail, onAction),
  );
}
