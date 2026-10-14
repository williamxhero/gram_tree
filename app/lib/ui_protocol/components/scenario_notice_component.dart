import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../app/theme.dart';
import '../component_registry.dart';
import '../intent_registry.dart';
import '../source_mark.dart';
import '../source_types.dart';
import 'component_scaffold.dart';

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
  final theme = Theme.of(context);
  final colors = GramTreeColors.of(context);
  final numberStyle = colors.numberStyle(theme.textTheme.bodyMedium!);
  final conclusion = data['conclusion'] as String? ?? emptyState.title;
  final differences = data['differences'];
  final actions = component.actions ?? const <ActionDescriptor>[];
  // SPEC-009.2 keeps the compact difference entry and both taste-change flows
  // directly reachable. Failure advice is part of the conclusion, not evidence.
  final directActions = component.type == 'taste_change_notice'
      ? actions
      : actions.take(1);

  Widget actionButton(ActionDescriptor action) => TextButton(
    key: ValueKey('${component.id}:${action.intent}'),
    onPressed: callbackForAction(context, action, onAction),
    child: Text(intentDefaultLabel(action.intent)),
  );

  return ComponentCard(
    key: ValueKey(component.id),
    detail: component.detail,
    conclusionSemanticsText: conclusion,
    preserveConclusionSemantics: true,
    conclusion: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              container: true,
              child: Text(conclusion, style: theme.textTheme.titleSmall),
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
        if (data['problem'] is String)
          Semantics(container: true, child: Text(data['problem'] as String)),
        if (data['advice'] is String)
          Semantics(container: true, child: Text(data['advice'] as String)),
        // The failure reminder's date anchors the warning to a real past cook,
        // including in compact cooking mode; other evidence follows detail.
        if (component.type == 'failure_reminder' &&
            data['record_date'] is String)
          Text('依据做过记录：${data['record_date']}'),
        if (differences is List)
          Material(
            type: MaterialType.transparency,
            child: ExpansionTile(
              key: ValueKey('${component.id}:expand'),
              title: const Text('查看本次与上次的差异'),
              initiallyExpanded:
                  component.detail == ComponentDescriptorDetailEnum.detailed,
              children: [
                for (final item in differences.whereType<Map>())
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Semantics(
                      container: true,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${item['label']}：上次 '),
                            TextSpan(
                              text: '${item['before']}',
                              style:
                                  item['kind'] == 'quantity' ||
                                      item['kind'] == 'servings'
                                  ? numberStyle
                                  : null,
                            ),
                            const TextSpan(text: '，本次 '),
                            TextSpan(
                              text: '${item['after']}',
                              style:
                                  item['kind'] == 'quantity' ||
                                      item['kind'] == 'servings'
                                  ? numberStyle.copyWith(
                                      color: item['after'] != item['before']
                                          ? colors.accent
                                          : colors.ink,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (directActions.isNotEmpty)
          Wrap(spacing: 8, children: directActions.map(actionButton).toList()),
      ],
    ),
    standardExtra: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (component.type != 'failure_reminder' &&
            data['record_date'] is String)
          Text('依据做过记录：${data['record_date']}'),
        if (data['change_date'] is String) Text('口味变化：${data['change_date']}'),
      ],
    ),
    detailedExtra: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (basis is Map && basis['text'] is String)
          Text(basis['text'] as String),
        Text(component.reason.text),
        if (component.type != 'taste_change_notice' && actions.length > 1)
          Wrap(
            spacing: 8,
            children: actions.skip(1).map(actionButton).toList(),
          ),
      ],
    ),
  );
}
