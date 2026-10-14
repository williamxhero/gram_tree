import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../app/theme.dart';
import '../component_registry.dart';
import '../intent_registry.dart';
import '../source_mark.dart';
import '../source_types.dart';

/// Scenario decisions come from the server; the client only renders evidence.
Widget buildScenarioNoticeComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
) {
  final data = component.data is Map
      ? Map<String, dynamic>.from(component.data as Map)
      : <String, dynamic>{};
  final source = data['source'];
  final basis = source is Map ? source['basis'] : null;
  final colors = GramTreeColors.of(context);
  final differences = data['differences'];
  return Card(
    key: ValueKey(component.id),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                data['conclusion'] as String? ?? emptyState.title,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: colors.accent),
              ),
              if (source is Map && basis is Map)
                SourceMark(
                  sourceType: sourceTypeScenarioAdjusted,
                  componentId: component.id,
                  value: source['value'] as String? ?? '',
                  basisText: basis['text'] as String? ?? component.reason.text,
                  citation: basis['citation'] as String?,
                  required: component.required_ ?? false,
                  onAction: onAction,
                ),
            ],
          ),
          if (data['problem'] is String) Text(data['problem'] as String),
          if (data['advice'] is String) Text(data['advice'] as String),
          if (differences is List)
            for (final item in differences.whereType<Map>())
              Text('${item['label']}：上次 ${item['before']}，本次 ${item['after']}'),
          if (data['record_date'] is String)
            Text('依据做过记录：${data['record_date']}'),
          if (data['change_date'] is String)
            Text('口味变化：${data['change_date']}'),
          if (component.detail == ComponentDescriptorDetailEnum.detailed)
            Text(component.reason.text),
          if ((component.actions ?? const []).isNotEmpty)
            Wrap(
              spacing: 8,
              children: [
                for (final action in component.actions!)
                  TextButton(
                    key: ValueKey('${component.id}:${action.intent}'),
                    onPressed: () => onAction(action),
                    child: Text(intentDefaultLabel(action.intent)),
                  ),
              ],
            ),
        ],
      ),
    ),
  );
}
