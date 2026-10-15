import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../events/event_uploader.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import '../../ui_protocol/intent_dispatcher.dart';
import '../../ui_protocol/recipe_operations.dart';
import '../../util/ids.dart';
import '../../l10n/app_localizations.dart';
import 'comparison_cards.dart';

String publicationLabel(AppLocalizations l10n, String state) => switch (state) {
  'published' => l10n.publicationPublished,
  'pending_verification' => l10n.publicationPending,
  'withdrawn' => l10n.publicationWithdrawn,
  _ => l10n.publicationDraft,
};

class PublicationStateLabel extends StatelessWidget {
  const PublicationStateLabel({super.key, required this.state});
  final String state;
  @override
  Widget build(BuildContext context) =>
      Text(publicationLabel(AppLocalizations.of(context), state));
}

/// No client eligibility calculation: every missing condition comes from the
/// exact saved version on the server, including the cumulative cooked baseline.
class PublicationPanelCard extends ConsumerStatefulWidget {
  const PublicationPanelCard({
    super.key,
    required this.detail,
    required this.onChanged,
    required this.onCook,
  });
  final RecipeDetail detail;
  final VoidCallback onChanged;
  final VoidCallback onCook;
  @override
  ConsumerState<PublicationPanelCard> createState() =>
      _PublicationPanelCardState();
}

class _PublicationPanelCardState extends ConsumerState<PublicationPanelCard> {
  PublicationPanel? _panel;
  String? _error;
  bool _busy = false;
  final _compositionId = newUuidV4();
  late final String? _owner;
  bool get _sameOwner => ref.read(authProvider).value?.id == _owner;

  @override
  void initState() {
    super.initState();
    _owner = ref.read(authProvider).value?.id;
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final response = await ref
          .read(apiClientProvider)
          .getRecipesApi()
          .getRecipePublication(
            recipeId: widget.detail.id,
            versionId: widget.detail.version.id,
          );
      if (mounted && _sameOwner) {
        setState(() {
          _panel = response.data;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted && _sameOwner) {
        setState(
          () => _error = AppLocalizations.of(context).publicationLoadError,
        );
      }
    }
  }

  Future<void> _risk() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).publicationRiskTitle),
        content: Text(AppLocalizations.of(context).publicationRiskBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).publicationRiskLater),
          ),
          FilledButton(
            key: const ValueKey('publication-confirm-risk'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).publicationRiskConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || !_sameOwner) return;
    await _mutate(() async {
      await ref
          .read(apiClientProvider)
          .getRecipesApi()
          .confirmRecipePublicationRisk(
            recipeId: widget.detail.id,
            versionId: widget.detail.version.id,
          );
    });
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (_busy || !_sameOwner) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && _sameOwner) {
        await _load();
        widget.onChanged();
      }
    } catch (_) {
      if (mounted && _sameOwner) {
        setState(
          () => _error = AppLocalizations.of(context).publicationMutationError,
        );
      }
    } finally {
      if (mounted && _sameOwner) setState(() => _busy = false);
    }
  }

  Future<void> _lifecycle() async {
    final restore = _panel?.state.value == 'withdrawn';
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          restore
              ? AppLocalizations.of(context).publicationRestoreTitle
              : AppLocalizations.of(context).publicationWithdrawTitle,
        ),
        content: Text(
          restore
              ? AppLocalizations.of(context).publicationRestoreBody
              : AppLocalizations.of(context).publicationWithdrawBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            key: const ValueKey('publication-confirm-lifecycle'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              restore
                  ? AppLocalizations.of(context).publicationRestore
                  : AppLocalizations.of(context).publicationWithdraw,
            ),
          ),
        ],
      ),
    );
    if (yes != true || !mounted || !_sameOwner) return;
    await _mutate(() async {
      final api = ref.read(apiClientProvider).getRecipesApi();
      if (restore) {
        await api.restoreRecipe(recipeId: widget.detail.id);
      } else {
        await api.withdrawRecipe(recipeId: widget.detail.id);
      }
    });
  }

  Future<void> _condition(PublicationCondition condition) async {
    switch (condition.action) {
      case 'confirm_risk':
      case 'risk_confirmation':
        await _risk();
      case 'cook':
      case 'start_cooking':
        widget.onCook();
      case 'review':
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).publicationReview),
            ),
          );
        }
      case 'verify_identity':
      case 'real_name':
        if (mounted) context.push('/me/identities');
      default:
        if (mounted) {
          context.push(
            '/recipes/${widget.detail.id}/edit?versionId=${widget.detail.version.id}',
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(authProvider).value?.id != _owner) {
      return const SizedBox.shrink();
    }
    final panel = _panel;
    return RecipeOperationScope(
      handlers: {
        'publication_refresh': (_) => _load(),
        'publication_risk': (_) => _risk(),
        'publication_lifecycle': (_) => _lifecycle(),
        'publication_condition': (params) async {
          final condition = panel?.missing
              ?.where((item) => item.code == params['condition'])
              .firstOrNull;
          if (condition != null) await _condition(condition);
        },
      },
      child: Builder(
        builder: (context) {
          Future<void> dispatch(String operation, [String? condition]) => ref
              .read(intentDispatcherProvider)
              .dispatch(
                context,
                compositionId: _compositionId,
                componentId: 'publication-panel',
                action: ActionDescriptor(
                  intent: 'recipe_operation',
                  params: {'operation': operation, 'condition': ?condition},
                ),
              );
          final l10n = AppLocalizations.of(context);
          final state =
              panel?.state.value ??
              widget.detail.version.publicationState.value;
          final label = publicationLabel(l10n, state);
          // A cooked version can remain draft for risk or identity conditions.
          // Prefer the server's exact cooking gates over the publication label.
          final needsCooking = panel == null
              ? state != 'published'
              : state == 'pending_verification' ||
                    (panel.missing?.any(
                          (condition) =>
                              condition.code == 'not_cooked' ||
                              condition.code == 'cook_again',
                        ) ??
                        false);
          return ComponentCard(
            key: const ValueKey('publication-panel'),
            detail: ComponentDescriptorDetailEnum.standard,
            conclusion: Text(label),
            conclusionSemanticsText: label,
            basisText: panel?.baselineVersionId == null
                ? l10n.publicationBasis
                : l10n.publicationComparisonBasis(
                    comparisonConclusionLabel(
                      panel!.cumulativeConclusion ??
                          l10n.publicationUndetermined,
                    ),
                    panel.rulesVersion ?? '',
                  ),
            standardExtra: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.detail.version.aiAssisted && needsCooking)
                  Text(l10n.publicationAiUnverified),
                if ((panel?.state.value ??
                        widget.detail.version.publicationState.value) ==
                    'draft')
                  Text(
                    l10n.publicationDraftConditions,
                    key: const ValueKey('draft-auto-public'),
                  ),
                if (panel == null && _error == null)
                  const LinearProgressIndicator(),
                if (_error != null) Text(_error!, semanticsLabel: _error),
                for (final condition
                    in panel?.missing ?? <PublicationCondition>[])
                  TextButton(
                    key: ValueKey('publication-condition-${condition.code}'),
                    onPressed: _busy
                        ? null
                        : () =>
                              dispatch('publication_condition', condition.code),
                    child: Text(
                      condition.remainingCount == null
                          ? condition.label
                          : l10n.publicationConditionCount(
                              condition.label,
                              condition.remainingCount!,
                            ),
                    ),
                  ),
                if (panel?.highRisk == true) Text(l10n.publicationRiskGuidance),
                if (panel?.everPublic == true)
                  OutlinedButton(
                    key: const ValueKey('publication-lifecycle'),
                    onPressed: _busy
                        ? null
                        : () => dispatch('publication_lifecycle'),
                    child: Text(
                      panel?.state.value == 'withdrawn'
                          ? l10n.publicationRestore
                          : l10n.publicationWithdrawRecipe,
                    ),
                  ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => dispatch('publication_refresh'),
                  child: Text(l10n.publicationRefresh),
                ),
                TextField(
                  key: const ValueKey('publication-command'),
                  decoration: InputDecoration(
                    labelText: l10n.publicationCommand,
                    hintText: l10n.publicationCommandHint,
                  ),
                  onSubmitted: (text) {
                    final action = recipeCommand(text);
                    if (!_busy && action != null) {
                      unawaited(
                        ref
                            .read(intentDispatcherProvider)
                            .dispatch(
                              context,
                              compositionId: _compositionId,
                              componentId: 'publication-panel',
                              action: action,
                            ),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Server persists first-license acknowledgement per account. Rendering the
/// notice is not a consent gate and never prevents the automatic publication.
class PublicationNotices extends ConsumerStatefulWidget {
  const PublicationNotices({super.key});
  @override
  ConsumerState<PublicationNotices> createState() => _PublicationNoticesState();
}

class _PublicationNoticesState extends ConsumerState<PublicationNotices> {
  PublicationNotifications? _notices;
  String? _account;
  int _generation = 0;
  bool _acknowledging = false;
  Future<void> _load(String account, {String? cursor}) async {
    final generation = ++_generation;
    try {
      final api = ref.read(apiClientProvider).getRecipesApi();
      final result = (await api.getPublicationNotifications(cursor: cursor))
          .data;
      if (!mounted ||
          generation != _generation ||
          ref.read(authProvider).value?.id != account ||
          result == null) {
        return;
      }
      setState(() => _notices = result);
    } catch (_) {
      /* A failed notice read cannot block records or recipes. */
    }
  }

  Future<void> _acknowledge() async {
    final account = _account;
    final notices = _notices;
    final generation = _generation;
    if (_acknowledging ||
        account == null ||
        notices == null ||
        ref.read(authProvider).value?.id != account ||
        ModalRoute.of(context)?.isCurrent == false ||
        !TickerMode.valuesOf(context).enabled) {
      return;
    }
    setState(() => _acknowledging = true);
    try {
      await ref
          .read(apiClientProvider)
          .getRecipesApi()
          .acknowledgePublicationNotifications(
            publicationNotificationAck: PublicationNotificationAck(
              notificationIds:
                  (notices.items ?? const <PublicationNotificationOut>[])
                      .map((item) => item.id)
                      .toList(),
              licenseSeen: notices.licenseNotice != null,
            ),
          );
      if (!mounted ||
          generation != _generation ||
          ref.read(authProvider).value?.id != account) {
        return;
      }
      if (notices.nextCursor != null) {
        await _load(account, cursor: notices.nextCursor);
      } else {
        setState(() => _notices = null);
      }
    } catch (_) {
      // Leave this page visible and retryable; never consume an unseen license.
    } finally {
      if (mounted) setState(() => _acknowledging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(authProvider).value?.id;
    ref.listen(confirmedCookingRecordRevisionProvider, (previous, next) {
      final current = ref.read(authProvider).value?.id;
      if (current != null && current == _account && next != previous) {
        unawaited(_load(current));
      }
    });
    if (account != _account) {
      _account = account;
      _notices = null;
      _generation++;
      if (account != null) unawaited(_load(account));
    }
    final notices = _notices;
    if (notices == null ||
        ((notices.items?.isEmpty ?? true) && notices.licenseNotice == null)) {
      return const SizedBox.shrink();
    }
    // Keep a full page of notices reachable without overflowing the Today tab.
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .45,
      ),
      child: SingleChildScrollView(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item
                    in notices.items ?? const <PublicationNotificationOut>[])
                  Text(
                    item.message,
                    key: ValueKey('publication-notice-${item.id}'),
                  ),
                if (notices.licenseNotice != null)
                  Text(
                    notices.licenseNotice!,
                    key: const ValueKey('publication-license-notice'),
                  ),
                TextButton(
                  onPressed: _acknowledging ? null : _acknowledge,
                  child: Text(
                    notices.nextCursor == null
                        ? AppLocalizations.of(context).publicationUnderstood
                        : AppLocalizations.of(context).publicationMoreNotices,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
