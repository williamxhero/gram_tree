import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../app/theme.dart';
import '../../auth/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';
import 'taste_profile_data.dart';

class TasteProfilePage extends ConsumerWidget {
  const TasteProfilePage({super.key});
  static const path = '/me/taste-profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountId = ref.watch(authProvider).value?.id;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).tasteTitle)),
      body: accountId == null
          ? const SizedBox.shrink()
          : _TasteBody(key: ValueKey(accountId), accountId: accountId),
    );
  }
}

class _TasteBody extends ConsumerStatefulWidget {
  const _TasteBody({super.key, required this.accountId});
  final String accountId;

  @override
  ConsumerState<_TasteBody> createState() => _TasteBodyState();
}

class _TasteBodyState extends ConsumerState<_TasteBody> {
  bool _busy = false;

  bool get _isCurrentAccount =>
      mounted && ref.read(authProvider).value?.id == widget.accountId;

  Future<void> _mutate(
    Future<TasteProfileOut> Function(TasteProfileRepository) action,
  ) async {
    if (_busy || !_isCurrentAccount) return;
    setState(() => _busy = true);
    try {
      await action(ref.read(tasteProfileRepositoryProvider));
      if (!_isCurrentAccount) return;
      ref.invalidate(tasteProfileProvider);
      ref.invalidate(tasteProfileChangesProvider);
    } catch (error) {
      if (mounted && _isCurrentAccount) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiFailure.from(error).message)));
      }
    } finally {
      if (_isCurrentAccount) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.tasteReset),
        content: Text(l10n.tasteResetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('taste-reset-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.tasteReset),
          ),
        ],
      ),
    );
    if (confirmed == true && _isCurrentAccount) {
      await _mutate((repository) => repository.reset());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(tasteProfileProvider);
    final changes = ref.watch(tasteProfileChangesProvider);
    return profile.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: _Retry(
          error: error,
          retry: () => ref.invalidate(tasteProfileProvider),
        ),
      ),
      data: (value) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tasteProfileProvider);
          ref.invalidate(tasteProfileChangesProvider);
          await ref.read(tasteProfileProvider.future);
        },
        child: ListView(
          key: const ValueKey('taste-profile-content'),
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text(l10n.tasteIntro),
            const SizedBox(height: 12),
            for (final flavor in value.flavors.entries)
              ComponentCard(
                key: ValueKey('taste-flavor-${flavor.key}'),
                detail: ComponentDescriptorDetailEnum.standard,
                conclusion: Text(
                  '${_flavorName(flavor.key, l10n)} · ${flavor.value.label}',
                ),
                conclusionSemanticsText:
                    '${_flavorName(flavor.key, l10n)}，${flavor.value.label}',
                standardExtra: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButton<int>(
                      key: ValueKey('taste-level-${flavor.key}'),
                      value: flavor.value.level,
                      isExpanded: true,
                      items: [
                        for (var i = 0; i < value.scale.levels.length; i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text(value.scale.levels[i].label),
                          ),
                      ],
                      onChanged: _busy
                          ? null
                          : (level) {
                              if (level != null) {
                                _mutate(
                                  (repository) => repository.setLevel(
                                    flavor.key,
                                    value.scale.levels[level].coefficient,
                                  ),
                                );
                              }
                            },
                    ),
                    const SizedBox(height: 8),
                    Text(flavor.value.confidenceText),
                    const SizedBox(height: 8),
                    SourceMark(
                      key: ValueKey('taste-why-${flavor.key}'),
                      sourceType: sourceTypeAuthorFilled,
                      componentId: 'taste-${flavor.key}',
                      value: flavor.value.label,
                      basisText: flavor.value.confidenceText,
                      required: false,
                      neutral: true,
                      feedbackEnabled: false,
                      showWhenAuthorFilled: true,
                      labelOverride:
                          flavor.value.confidence ==
                              TasteFlavorOutConfidenceEnum.high
                          ? l10n.tasteManual
                          : l10n.tasteDefault,
                      whyTitleOverride: l10n.tasteWhy,
                      onAction: null,
                    ),
                  ],
                ),
              ),
            OutlinedButton(
              key: const ValueKey('taste-reset'),
              onPressed: _busy ? null : _reset,
              child: Text(l10n.tasteReset),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.tasteLocal,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(l10n.tasteLocalReadonly),
            if (value.localCuisines.isEmpty) Text(l10n.tasteLocalEmpty),
            for (final cuisine in value.localCuisines)
              ComponentCard(
                detail: ComponentDescriptorDetailEnum.standard,
                conclusion: Text(cuisine.cuisine),
                conclusionSemanticsText: cuisine.cuisine,
                standardExtra: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final adjustment in cuisine.adjustments.entries)
                      Text(
                        '${_flavorName(adjustment.key, l10n)} · ${_levelLabel(adjustment.value, value.scale)}',
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Text(
              l10n.tasteHistory,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(l10n.tasteHistoryReadonly),
            changes.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => _Retry(
                error: error,
                retry: () => ref.invalidate(tasteProfileChangesProvider),
              ),
              data: (items) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (items.isEmpty) Text(l10n.tasteHistoryEmpty),
                  for (final change in items)
                    _HistoryCard(change: change, scale: value.scale),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.change, required this.scale});
  final TasteProfileChangeOut change;
  final TasteScale scale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final field = _flavorName(change.field.replaceFirst('flavors.', ''), l10n);
    final oldLabel = _historyLabel(change.oldValue, scale);
    final newLabel = _historyLabel(change.newValue, scale);
    final status = change.status == TasteProfileChangeOutStatusEnum.active
        ? l10n.tasteActive
        : l10n.tasteReverted;
    final timestamp = DateTime.parse(change.createdAt).toLocal();
    final local = MaterialLocalizations.of(context);
    final time =
        '${local.formatShortDate(timestamp)} ${local.formatTimeOfDay(TimeOfDay.fromDateTime(timestamp))}';
    return ComponentCard(
      detail: ComponentDescriptorDetailEnum.standard,
      conclusion: Text('$field：$oldLabel → $newLabel'),
      conclusionSemanticsText: '$field，$oldLabel，$newLabel',
      standardExtra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${change.reason} · $status'),
          Text(
            time,
            style: GramTreeColors.of(context)
                .numberStyle(Theme.of(context).textTheme.bodyMedium!),
          ),
          SourceMark(
            key: ValueKey('taste-history-why-${change.id}'),
            sourceType: sourceTypeAuthorFilled,
            componentId: 'taste-history',
            value: '$field · $newLabel',
            originalValue: '$field · $oldLabel',
            valueChanged: false,
            basisText: '${change.reason} · $status · $time',
            required: false,
            feedbackEnabled: false,
            neutral: true,
            showWhenAuthorFilled: true,
            labelOverride: l10n.tasteManual,
            whyTitleOverride: l10n.tasteWhy,
            onAction: null,
          ),
        ],
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.error, required this.retry});
  final Object error;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(ApiFailure.from(error).message),
      TextButton(
        onPressed: retry,
        child: Text(AppLocalizations.of(context).retry),
      ),
    ],
  );
}

String _flavorName(String key, AppLocalizations l10n) => switch (key) {
  'salty' => l10n.tasteSalty,
  'sweet' => l10n.tasteSweet,
  'sour' => l10n.tasteSour,
  'spicy' => l10n.tasteSpicy,
  'numbing' => l10n.tasteNumbing,
  'umami' => l10n.tasteUmami,
  'oily' => l10n.tasteOily,
  _ => key,
};

String _historyLabel(Object value, TasteScale scale) =>
    value is Map && value['coefficient'] is num
    ? _levelLabel(value['coefficient'] as num, scale)
    : '—';

// Formatting only: use the server's configured mapping, never duplicate coefficients.
String _levelLabel(num coefficient, TasteScale scale) {
  var closest = scale.levels.first;
  for (final level in scale.levels.skip(1)) {
    if ((level.coefficient - coefficient).abs() <
        (closest.coefficient - coefficient).abs()) {
      closest = level;
    }
  }
  return closest.label;
}
