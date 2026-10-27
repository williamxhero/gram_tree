import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../component_registry.dart';
import 'component_scaffold.dart';

Widget buildRecordsCalendarComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
) {
  final data = component.data as Map<String, dynamic>;
  final conclusion = data['conclusion'] as String?;
  final days = (data['days'] as List<dynamic>? ?? const []).cast<Map>();
  if (conclusion == null || conclusion.isEmpty || days.isEmpty) {
    return ComponentEmptyCard(emptyState: emptyState);
  }
  final detailed = component.detail == ComponentDescriptorDetailEnum.detailed;
  final standard = component.detail != ComponentDescriptorDetailEnum.brief;
  return ComponentCard(
    detail: component.detail,
    conclusion: Text(conclusion),
    conclusionSemanticsText: conclusion,
    basisText: parseBasisText(data),
    standardExtra: standard
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final day in days)
                Semantics(
                  container: true,
                  label: _dayLabel(day, detailed),
                  child: ListTile(
                    dense: true,
                    title: Text('${day['date']} · ${day['count']} 条'),
                    subtitle: Text(
                      (day['types'] as List? ?? const []).join('、'),
                    ),
                    leading: _photo(day['photos'] as List?),
                  ),
                ),
            ],
          )
        : null,
    primaryActionLabel: labelForAction(
      data,
      'action_label',
      resolveComponentActions(component.actions).primary,
    ),
    onPrimaryAction: callbackForAction(
      context,
      resolveComponentActions(component.actions).primary,
      onAction,
    ),
    detailLabel: detailed
        ? labelForAction(
            data,
            'detail_label',
            resolveComponentActions(component.actions).detail,
          )
        : null,
    onDetail: callbackForAction(
      context,
      resolveComponentActions(component.actions).detail,
      onAction,
    ),
  );
}

String _dayLabel(Map day, bool detailed) {
  final types = (day['types'] as List? ?? const []).join('、');
  return '${day['date']}，${day['count']} 条${types.isEmpty ? '' : '，$types'}';
}

Widget? _photo(List? values) {
  final raw = values?.whereType<String>().firstOrNull;
  if (raw == null) return null;
  return ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: Image.memory(
      UriData.parse(raw).contentAsBytes(),
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      semanticLabel: '本人记录照片',
    ),
  );
}
