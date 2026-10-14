import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'component_registry.dart';
import 'components/component_scaffold.dart';
import 'intent_dispatcher.dart';
import 'recipe_operations.dart';
import '../util/ids.dart';
import '../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    final label = _label(l10n, data);
    final chain = data['chain'] is List ? data['chain'] as List : const [];
    final compositionId = 'source-${data['source_version_id'] ?? newUuidV4()}';
    Future<void> showChain() async {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.sourceChainTitle),
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
                      child: Text(
                        _label(l10n, Map<String, dynamic>.from(node)),
                      ),
                    ),
                const SizedBox(height: 12),
                Text(l10n.sourceChainPreserved),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.familyClose),
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
          detail: ComponentDescriptorDetailEnum.values.firstWhere(
            (value) => value.value == detail,
            orElse: () => ComponentDescriptorDetailEnum.standard,
          ),
          preserveConclusionSemantics: true,
          conclusionSemanticsText: label,
          basisText: l10n.sourceImmutableBasis,
          detailedExtra: Text(l10n.sourceChainPreserved),
          // The chain is the primary action, available even in brief.
          conclusion: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              TextButton(
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
                child: Text(l10n.sourceViewChain),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _label(AppLocalizations l10n, Map<String, dynamic> data) {
  final raw = data['label'];
  final withdrawn =
      data['withdrawn'] == true || data['source_withdrawn'] == true;
  if (raw is String && raw.isNotEmpty) {
    return '$raw${withdrawn && !raw.contains(l10n.publicationWithdrawn) ? l10n.sourceWithdrawnSuffix : ''}';
  }
  final author =
      data['author_deleted'] == true || data['deleted_author'] == true
      ? l10n.sourceDeletedAuthor
      : data['author'] ??
            data['author_name'] ??
            data['author_nickname'] ??
            data['source_author_nickname'];
  final dish = data['title'] ?? data['dish_name'] ?? data['source_dish_name'];
  final number = data['version_number'] ?? data['source_version_number'];
  if (author == null || dish == null || number == null) {
    return l10n.sourceUnavailable;
  }
  return l10n.sourceLineage(
    '$author',
    '$dish',
    '$number',
    withdrawn ? l10n.sourceWithdrawnSuffix : '',
  );
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
