import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../ui_protocol/component_registry.dart';
import '../ui_protocol/source_mark.dart';
import 'components/component_scaffold.dart';

/// Registered recipe surfaces from SPEC-009.1. The recipe pages use the same
/// builders as protocol-driven surfaces, so a recipe card cannot invent a
/// second component vocabulary or action route.
Widget buildRecipeHeaderComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
) => _buildRecipeTextComponent(context, component, emptyState, onAction);

Widget buildRecipeIngredientsComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
) => _buildRecipeListComponent(context, component, emptyState, onAction);

Widget buildRecipeStepsComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
) => _buildRecipeListComponent(context, component, emptyState, onAction);

Widget buildRecipeCardComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
) => _buildRecipeTextComponent(context, component, emptyState, onAction);

Widget _buildRecipeTextComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
) {
  final data = _data(component);
  final conclusion = data['conclusion'];
  if (conclusion is! String || conclusion.isEmpty) {
    return ComponentEmptyCard(emptyState: emptyState);
  }
  final actions = resolveComponentActions(component.actions);
  final primary = actions.primary;
  final detail = actions.detail;
  return ComponentCard(
    detail: component.detail,
    conclusion: Row(
      children: [
        Expanded(child: Text(conclusion)),
        if (data['source'] is Map)
          SourceMark(
            sourceType:
                (data['source'] as Map)['source_type'] as String? ??
                'author_filled',
            componentId: component.id,
            value: (data['source'] as Map)['value'] as String? ?? conclusion,
            basisText: parseBasisText(data) ?? '',
            required: component.required_ ?? false,
            onAction: onAction,
          ),
      ],
    ),
    conclusionSemanticsText: conclusion,
    basisText: parseBasisText(data),
    primaryActionLabel: primary == null
        ? null
        : labelForAction(data, 'action_label', primary),
    onPrimaryAction: primary == null ? null : () => onAction(primary),
    detailLabel: detail == null
        ? null
        : labelForAction(data, 'detail_label', detail),
    onDetail: detail == null ? null : () => onAction(detail),
  );
}

Widget _buildRecipeListComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
) {
  final data = _data(component);
  final conclusion = data['conclusion'];
  final items = data['items'];
  if (conclusion is! String || items is! List || items.isEmpty) {
    return ComponentEmptyCard(emptyState: emptyState);
  }
  final rows = [
    for (final item in items)
      if (item is Map)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(item['name'] as String? ?? ''),
          subtitle: item['detail'] is String
              ? Text(item['detail'] as String)
              : null,
        ),
  ];
  return ComponentCard(
    detail: component.detail,
    conclusion: Text(conclusion),
    conclusionSemanticsText: conclusion,
    standardExtra: Column(children: rows),
    basisText: parseBasisText(data),
  );
}

Map<String, dynamic> _data(ComponentDescriptor component) {
  final data = component.data;
  return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
}
