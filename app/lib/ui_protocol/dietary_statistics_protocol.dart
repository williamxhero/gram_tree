import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'component_registry.dart';

Map<String, dynamic> _data(Object raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};

Widget buildDietaryStatisticsComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
) {
  final data = _data(component.data);
  final count = data['cooking_count'];
  final period = data['period'];
  final conclusion = data['conclusion'];
  return Semantics(
    container: true,
    label: '$conclusion，${period ?? ''}，做菜 $count 次',
    child: Card(
      child: ListTile(
        title: Text(conclusion as String? ?? emptyState.title),
        subtitle: Text('做菜次数'),
        trailing: Text('$count'),
      ),
    ),
  );
}

Widget buildDietaryDistributionComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
) {
  final data = _data(component.data);
  final items = (data['items'] as List? ?? const [])
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
  return Semantics(
    container: true,
    label: data['conclusion'] as String? ?? emptyState.title,
    child: ExpansionTile(
      title: Text(data['title'] as String? ?? emptyState.title),
      children: [
        for (final item in items)
          ListTile(
            title: Text(item['key'] as String? ?? '未分类'),
            trailing: Text('${item['count'] ?? 0}'),
          ),
      ],
    ),
  );
}
