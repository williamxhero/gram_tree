import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../component_registry.dart';
import '../source_mark.dart';
import '../source_types.dart';
import 'component_scaffold.dart';

Widget buildScenarioSummaryComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
) {
  final data = component.data is Map
      ? Map<String, dynamic>.from(component.data as Map)
      : <String, dynamic>{};
  final source = data['source'];
  if (source is! Map || source['basis'] is! Map) {
    return ComponentEmptyCard(emptyState: emptyState);
  }
  final basis = source['basis'] as Map;
  final conclusion = data['conclusion'] as String? ?? emptyState.title;
  return ComponentCard(
    detail: component.detail,
    conclusionSemanticsText: '$conclusion，按场景调整',
    showPrimaryButton: false,
    conclusion: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(conclusion),
            SourceMark(
              sourceType: sourceTypeScenarioAdjusted,
              componentId: component.id,
              value: source['value'] as String,
              basisText: basis['text'] as String,
              citation: basis['citation'] as String?,
              // Preference changes belong to the explicit setting/switch, not
              // source suppression; later notice components have feedback.
              feedbackEnabled: false,
              required: false,
              onAction: null,
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final action in component.actions ?? <ActionDescriptor>[])
              TextButton(
                key: ValueKey(
                  'scenario-detail-${(action.params as Map)['detail']}',
                ),
                onPressed: () => onAction(action),
                child: Text(switch ((action.params as Map)['detail']) {
                  'brief' => '本页简洁',
                  'detailed' => '本页详细',
                  _ => '恢复默认',
                }),
              ),
          ],
        ),
      ],
    ),
  );
}
