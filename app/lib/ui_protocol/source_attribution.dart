import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'component_registry.dart';
import 'components/component_scaffold.dart';
import 'intent_dispatcher.dart';
import 'recipe_operations.dart';
import '../util/ids.dart';

/// Recipe lineage is not a numeric evidence mark. It cannot be skipped or
/// hidden by the chosen composition/detail level, including local fallbacks.
class SourceAttributionCard extends ConsumerWidget {
  const SourceAttributionCard({
    super.key,
    required this.attribution,
    this.detail = 'standard',
  });
  final Object? attribution;
  final String detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = attribution is Map
        ? Map<String, dynamic>.from(attribution as Map)
        : <String, dynamic>{};
    final label = _label(data);
    final chain = data['chain'] is List ? data['chain'] as List : const [];
    final compositionId = 'source-${data['source_version_id'] ?? newUuidV4()}';
    Future<void> showChain() async {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('到根菜谱的来源链'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(label),
                for (final node in chain)
                  if (node is Map)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_label(Map<String, dynamic>.from(node))),
                    ),
                const SizedBox(height: 12),
                const Text('来源关系永久保留；下架来源不提供隐藏内容。'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    }

    return RecipeOperationScope(
      handlers: {'source_chain': (_) => showChain()},
      child: Builder(
        builder: (context) => ComponentCard(
          key: const ValueKey('source-attribution'),
          // Even brief displays the attribution and chain action.
          detail: ComponentDescriptorDetailEnum.standard,
          conclusion: Text(label),
          conclusionSemanticsText: label,
          basisText: '保留精确来源版本，来源署名和关系不能修改或删除。',
          standardExtra: TextButton(
            key: const ValueKey('source-attribution-chain'),
            onPressed: () => unawaited(
              ref
                  .read(intentDispatcherProvider)
                  .dispatch(
                    context,
                    compositionId: compositionId,
                    componentId: 'source-attribution',
                    action: ActionDescriptor(
                      intent: 'recipe_operation',
                      params: {'operation': 'source_chain'},
                    ),
                  ),
            ),
            child: const Text('查看来源链'),
          ),
        ),
      ),
    );
  }
}

String _label(Map<String, dynamic> data) {
  final raw = data['label'];
  final withdrawn =
      data['withdrawn'] == true || data['source_withdrawn'] == true;
  if (raw is String && raw.isNotEmpty) {
    return '$raw${withdrawn && !raw.contains('已下架') ? ' · 已下架' : ''}';
  }
  final author =
      data['author_deleted'] == true || data['deleted_author'] == true
      ? '已注销用户'
      : data['author'] ??
            data['author_name'] ??
            data['author_nickname'] ??
            data['source_author_nickname'];
  final dish = data['title'] ?? data['dish_name'] ?? data['source_dish_name'];
  final number = data['version_number'] ?? data['source_version_number'];
  if (author == null || dish == null || number == null) {
    return '来源署名暂不可用 · 来源关系仍永久保留';
  }
  return '改良自 @$author《$dish》第 $number 版${withdrawn ? ' · 已下架' : ''}';
}

Widget buildSourceAttributionComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor) onAction,
) {
  final data = component.data is Map ? component.data as Map : const {};
  return SourceAttributionCard(
    attribution:
        data['attribution'] ??
        {'label': data['conclusion'], 'chain': <Object>[]},
    detail: component.detail.value,
  );
}
