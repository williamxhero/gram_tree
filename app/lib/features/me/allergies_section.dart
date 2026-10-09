import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../app/theme.dart';
import '../../auth/auth_controller.dart';
import '../../auth/session.dart';
import '../../l10n/app_localizations.dart';
import '../../events/event_recorder.dart';
import '../../ui_protocol/allergy_actions.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';
import 'allergies_data.dart';
import 'taste_profile_data.dart';

String _summary(Object? value, AppLocalizations l10n) {
  if (value is! Map) return l10n.allergyNotFilled;
  final categories = (value['categories'] as List?) ?? [];
  final ingredients = (value['ingredients'] as List?) ?? [];
  final names = [
    ...categories,
    for (final item in ingredients) (item as Map)['name'],
  ];
  return names.isEmpty ? l10n.allergyNotFilled : names.join('、');
}

class AllergiesSection extends ConsumerStatefulWidget {
  const AllergiesSection({super.key});
  @override
  ConsumerState<AllergiesSection> createState() => _AllergiesSectionState();
}

class _AllergiesSectionState extends ConsumerState<AllergiesSection> {
  bool _busy = false;
  Future<void> _edit() async {
    final account = ref.read(authProvider).value?.id;
    final epoch = ref.read(sensitiveMemoryProvider).epoch;
    bool current() =>
        mounted &&
        ref.read(authProvider).value?.id == account &&
        ref.read(sensitiveMemoryProvider).epoch == epoch;
    if (_busy || account == null) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      // A device receipt or old profile snapshot never authorizes this editor.
      ref.invalidate(allergiesProvider);
      AllergiesOut? state = await ref.read<Future<AllergiesOut?>>(
        allergiesProvider.future,
      );
      if (!mounted || !current() || state == null) return;
      if (state.consentId == null) {
        final agree = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.allergyConsentTitle),
            content: SingleChildScrollView(
              child: Text(l10n.allergyConsentBody),
            ),
            actions: [
              allergyAction(
                ref,
                'refuse',
                () => Navigator.pop(context, false),
                (run) => TextButton(
                  key: const ValueKey('allergies-refuse'),
                  onPressed: run,
                  child: Text(l10n.allergyRefuse),
                ),
              ),
              allergyAction(
                ref,
                'agree',
                () => Navigator.pop(context, true),
                (run) => FilledButton(
                  key: const ValueKey('allergies-agree'),
                  onPressed: run,
                  child: Text(l10n.allergyAgree),
                ),
              ),
            ],
          ),
        );
        if (agree != true || !current()) return;
        await uploadSensitiveConsent(ref, true, state.consentVersion);
        if (!current()) return;
        ref.invalidate(allergiesProvider);
        state = await ref.read<Future<AllergiesOut?>>(allergiesProvider.future);
        if (!current()) return;
        if (state?.consentId == null) {
          throw StateError('authorization_unconfirmed');
        }
      }
      if (!mounted || !current() || state == null) return;
      // The dialog widget contains only authorization/vocabulary metadata, not
      // a decrypted snapshot that would survive revocation in the route tree.
      final editor = _AllergyEditor(
        consentId: state.consentId!,
        authorizationVersion: state.authorizationVersion,
        availableCategories: state.availableCategories,
        account: account,
        epoch: epoch,
      );
      state = null;
      await showDialog<void>(context: context, builder: (_) => editor);
    } catch (_) {
      if (mounted && current()) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.allergyUnavailable)));
      }
    } finally {
      if (mounted && ref.read(authProvider).value?.id == account) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _openWhy(String changeId) async {
    final account = ref.read(authProvider).value?.id;
    final epoch = ref.read(sensitiveMemoryProvider).epoch;
    if (account == null || ref.read(sensitiveMemoryProvider).suppressed) return;
    try {
      await ref
          .read(eventRecorderProvider)
          .record(
            eventType: 'ui.why_panel_opened',
            typeVersion: 1,
            content: const {
              'component_id': 'allergies_history',
              'source_type': 'author_filled',
            },
          );
    } catch (_) {
      // Optional metadata telemetry cannot block access to privacy controls.
    }
    if (!mounted ||
        ref.read(authProvider).value?.id != account ||
        ref.read(sensitiveMemoryProvider).epoch != epoch) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) =>
          _AllergyWhy(changeId: changeId, account: account, epoch: epoch),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(allergiesProvider);
    final history = ref.watch(allergyChangesProvider);
    return ComponentCard(
      key: const ValueKey('allergies-section'),
      detail: ComponentDescriptorDetailEnum.standard,
      conclusion: Text(l10n.allergyTitle),
      conclusionSemanticsText: l10n.allergyTitle,
      standardExtra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.allergyIntro),
          state.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(l10n.allergyPrivateUnavailable),
            data: (value) {
              if (value == null) return Text(l10n.allergyHidden);
              if (value.categories.isEmpty && value.ingredients.isEmpty) {
                return Text(l10n.allergyEmpty);
              }
              return Text(
                [
                  ...value.categories,
                  ...value.ingredients.map((i) => i.name),
                ].join('、'),
              );
            },
          ),
          allergyAction(
            ref,
            'edit',
            _edit,
            (run) => OutlinedButton(
              key: const ValueKey('allergies-edit'),
              onPressed: _busy ? null : run,
              child: Text(l10n.allergyEdit),
            ),
          ),
          Text(l10n.allergyHistory),
          history.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(l10n.allergyHistoryUnavailable),
            data: (items) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (items.isEmpty) Text(l10n.allergyHistoryEmpty),
                for (final change in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${_summary(change.oldValue, l10n)} → ${_summary(change.newValue, l10n)}',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${change.reason} · ${change.status == TasteProfileChangeOutStatusEnum.active ? l10n.tasteActive : l10n.tasteReverted}',
                        ),
                        Text(
                          change.createdAt,
                          style: GramTreeColors.of(
                            context,
                          ).numberStyle(Theme.of(context).textTheme.bodySmall!),
                        ),
                      ],
                    ),
                    trailing: allergyAction(
                      ref,
                      'why',
                      () => _openWhy(change.id),
                      (run) => TextButton(
                        key: ValueKey('allergy-why-${change.id}'),
                        onPressed: run,
                        child: Text(l10n.allergyWhy),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllergyWhy extends ConsumerWidget {
  const _AllergyWhy({
    required this.changeId,
    required this.account,
    required this.epoch,
  });
  final String changeId;
  final String? account;
  final int epoch;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(authProvider).value?.id != account ||
        ref.watch(sensitiveMemoryProvider).epoch != epoch) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final items = ref.watch(allergyChangesProvider).value ?? [];
    final matches = items.where((row) => row.id == changeId);
    if (matches.isEmpty) return const SizedBox.shrink();
    final row = matches.first;
    return WhyPanel(
      key: const ValueKey('why-panel'),
      sourceType: sourceTypeAuthorFilled,
      titleOverride: l10n.allergyManual,
      value: _summary(row.newValue, l10n),
      originalValue: _summary(row.oldValue, l10n),
      basisText: row.reason,
      required: true,
      feedbackEnabled: false,
    );
  }
}

class _AllergyEditor extends ConsumerStatefulWidget {
  const _AllergyEditor({
    required this.consentId,
    required this.authorizationVersion,
    required this.availableCategories,
    required this.account,
    required this.epoch,
  });
  final String consentId;
  final int authorizationVersion;
  final List<String> availableCategories;
  final String account;
  final int epoch;
  @override
  ConsumerState<_AllergyEditor> createState() => _AllergyEditorState();
}

class _AllergyEditorState extends ConsumerState<_AllergyEditor> {
  late final _categories =
      (ref.read(allergiesProvider).value?.categories ?? <String>[]).toSet();
  late final _ingredients = {
    for (final item
        in ref.read(allergiesProvider).value?.ingredients ??
            <AllergyIngredientOut>[])
      item.ingredientId: item.name,
  };
  final _query = TextEditingController();
  List<SearchIngredientOut> _results = [];
  bool _busy = false;
  String? _error;
  int _searchGeneration = 0;
  bool get _current =>
      mounted &&
      ref.read(authProvider).value?.id == widget.account &&
      ref.read(sensitiveMemoryProvider).epoch == widget.epoch;
  void _erase() {
    _categories.clear();
    _ingredients.clear();
    _results.clear();
  }

  @override
  void dispose() {
    _erase();
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (!_current || _query.text.trim().isEmpty) return;
    final generation = ++_searchGeneration;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final result =
          (await ref
                  .read(apiClientProvider)
                  .getIngredientsApi()
                  .searchIngredients(
                    searchQuery: SearchQuery(query: _query.text.trim()),
                    headers: sensitiveAccountHeaders(
                      ref.read(sessionStoreProvider),
                    ),
                    extra: sensitiveAccountExtra(
                      ref.read(sessionStoreProvider),
                    ),
                  ))
              .data!;
      if (_current && generation == _searchGeneration) {
        setState(() => _results = result.items);
      }
    } catch (_) {
      if (_current) setState(() => _error = l10n.allergySearchUnavailable);
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_current || _busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(apiClientProvider)
          .getAllergiesApi()
          .setAllergies(
            headers: sensitiveAccountHeaders(ref.read(sessionStoreProvider)),
            extra: sensitiveAccountExtra(ref.read(sessionStoreProvider)),
            allergiesWrite: AllergiesWrite(
              consentId: widget.consentId,
              authorizationVersion: widget.authorizationVersion,
              categories: _categories.toList(),
              ingredientIds: _ingredients.keys.toList(),
            ),
          );
      if (!mounted || !_current) return;
      ref.invalidate(allergiesProvider);
      ref.invalidate(allergyChangesProvider);
      ref.invalidate(tasteProfileProvider);
      Navigator.pop(context);
    } catch (_) {
      if (_current) setState(() => _error = l10n.allergySaveUnconfirmed);
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (ref.watch(authProvider).value?.id != widget.account ||
        ref.watch(sensitiveMemoryProvider).epoch != widget.epoch) {
      _erase();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _query.clear();
        if (ModalRoute.of(context)?.isCurrent == true) Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }
    return AlertDialog(
      title: Text(l10n.allergyEditorTitle),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final category in widget.availableCategories)
                allergyAction(
                  ref,
                  'toggle',
                  () {
                    if (_current) {
                      setState(
                        () => _categories.contains(category)
                            ? _categories.remove(category)
                            : _categories.add(category),
                      );
                    }
                  },
                  (run) => CheckboxListTile(
                    key: ValueKey('allergy-category-$category'),
                    title: Text(category),
                    value: _categories.contains(category),
                    onChanged: _busy ? null : (_) => run(),
                  ),
                ),
              for (final item in _ingredients.entries)
                ListTile(
                  title: Text(item.value),
                  trailing: allergyAction(
                    ref,
                    'remove',
                    () {
                      if (_current) {
                        setState(() => _ingredients.remove(item.key));
                      }
                    },
                    (run) => IconButton(
                      key: ValueKey('allergy-delete-${item.key}'),
                      tooltip: l10n.allergyDeleteIngredient,
                      onPressed: _busy ? null : run,
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ),
              TextField(
                key: const ValueKey('allergy-search'),
                controller: _query,
                decoration: InputDecoration(labelText: l10n.allergySearchLabel),
              ),
              allergyAction(
                ref,
                'search',
                _search,
                (run) => TextButton(
                  key: const ValueKey('allergy-search-submit'),
                  onPressed: _busy ? null : run,
                  child: Text(l10n.allergySearch),
                ),
              ),
              for (final item in _results)
                allergyAction(
                  ref,
                  'pick',
                  () {
                    if (_current) {
                      setState(() {
                        _ingredients[item.id] = item.standardName;
                        _results = [];
                        _query.clear();
                      });
                    }
                  },
                  (run) => TextButton(
                    key: ValueKey('allergy-result-${item.id}'),
                    onPressed: _busy ? null : run,
                    child: Text(item.standardName),
                  ),
                ),
              if (_error != null) Text(_error!),
            ],
          ),
        ),
      ),
      actions: [
        allergyAction(
          ref,
          'cancel',
          () => Navigator.pop(context),
          (run) => TextButton(
            onPressed: _busy ? null : run,
            child: Text(l10n.cancel),
          ),
        ),
        allergyAction(
          ref,
          'save',
          _save,
          (run) => FilledButton(
            key: const ValueKey('allergies-save'),
            onPressed: _busy ? null : run,
            child: Text(l10n.allergySave),
          ),
        ),
      ],
    );
  }
}

/// Independent of the encrypted GET: missing/wrong keys cannot block erasure.
class SensitiveWithdrawalTile extends ConsumerStatefulWidget {
  const SensitiveWithdrawalTile({super.key});
  @override
  ConsumerState<SensitiveWithdrawalTile> createState() =>
      _SensitiveWithdrawalTileState();
}

class _SensitiveWithdrawalTileState
    extends ConsumerState<SensitiveWithdrawalTile> {
  bool _busy = false;
  String? _message;
  Future<void> _withdraw() async {
    final account = ref.read(authProvider).value?.id;
    if (account == null || _busy) return;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.allergyWithdrawTitle),
        content: Text(l10n.allergyWithdrawBody),
        actions: [
          allergyAction(
            ref,
            'cancel',
            () => Navigator.pop(context, false),
            (run) => TextButton(onPressed: run, child: Text(l10n.cancel)),
          ),
          allergyAction(
            ref,
            'confirm_withdraw',
            () => Navigator.pop(context, true),
            (run) => FilledButton(
              key: const ValueKey('sensitive-withdraw-confirm'),
              onPressed: run,
              child: Text(l10n.allergyWithdrawConfirm),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted || ref.read(authProvider).value?.id != account) {
      return;
    }
    ref.read(sensitiveMemoryProvider.notifier).suppress();
    final epoch = ref.read(sensitiveMemoryProvider).epoch;
    bool current() =>
        mounted &&
        ref.read(authProvider).value?.id == account &&
        ref.read(sensitiveMemoryProvider).epoch == epoch;
    setState(() {
      _busy = true;
      _message = l10n.allergyWithdrawing;
    });
    try {
      await uploadSensitiveConsent(ref, false, 'allergies-v1');
      if (!current()) return;
      final result =
          (await ref
                  .read(apiClientProvider)
                  .getAllergiesApi()
                  .getAllergies(
                    headers: sensitiveAccountHeaders(
                      ref.read(sessionStoreProvider),
                    ),
                    extra: sensitiveAccountExtra(
                      ref.read(sessionStoreProvider),
                    ),
                  ))
              .data!;
      if (!current()) return;
      final family =
          (await ref
                  .read(apiClientProvider)
                  .getFamilyMembersApi()
                  .listFamilyMembers(
                    headers: sensitiveAccountHeaders(
                      ref.read(sessionStoreProvider),
                    ),
                    extra: sensitiveAccountExtra(
                      ref.read(sessionStoreProvider),
                    ),
                  ))
              .data!;
      if (!current()) return;
      if (result.consentId != null ||
          result.categories.isNotEmpty ||
          result.ingredients.isNotEmpty ||
          family.consentId != null ||
          family.items.isNotEmpty ||
          family.nextCursor != null) {
        throw StateError('withdrawal_unconfirmed');
      }
      setState(() => _message = l10n.allergyWithdrawn);
      ref.read(sensitiveMemoryProvider.notifier).reload();
      ref.invalidate(tasteProfileProvider);
    } catch (_) {
      if (current()) setState(() => _message = l10n.allergyWithdrawUnconfirmed);
    } finally {
      if (mounted && ref.read(authProvider).value?.id == account) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return allergyAction(
      ref,
      'withdraw',
      _withdraw,
      (run) => ListTile(
        title: Text(l10n.allergyWithdrawEntry),
        subtitle: Text(_message ?? l10n.allergyWithdrawDetail),
        trailing: const Icon(Icons.chevron_right),
        key: const ValueKey('sensitive-withdraw'),
        onTap: _busy ? null : run,
      ),
    );
  }
}
