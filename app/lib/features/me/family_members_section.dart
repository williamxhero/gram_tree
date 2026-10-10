import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../app/theme.dart';
import '../../auth/auth_controller.dart';
import '../../auth/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import '../../ui_protocol/family_actions.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';
import 'allergies_data.dart';
import 'family_members_data.dart';
import 'ingredient_preferences_section.dart';
import 'taste_profile_cache.dart';
import 'taste_profile_data.dart';

String familyAgeLabel(String age, AppLocalizations l) => switch (age) {
  'under_1' => l.familyAgeUnder1,
  '1_to_3' => l.familyAge1To3,
  '3_to_6' => l.familyAge3To6,
  '6_to_12' => l.familyAge6To12,
  '12_to_18' => l.familyAge12To18,
  'adult' => l.familyAgeAdult,
  'elder' => l.familyAgeElder,
  _ => age,
};

String _flavorLabel(String key, AppLocalizations l) => switch (key) {
  'salty' => l.tasteSalty,
  'sweet' => l.tasteSweet,
  'sour' => l.tasteSour,
  'spicy' => l.tasteSpicy,
  'numbing' => l.tasteNumbing,
  'umami' => l.tasteUmami,
  'oily' => l.tasteOily,
  _ => key,
};

String _coefficientLabel(
  String key,
  num value,
  TasteScale scale,
  AppLocalizations l,
) {
  if (key == 'spicy' && value == 0) return l.familyNoChili;
  var closest = scale.levels.first;
  for (final level in scale.levels.skip(1)) {
    if ((level.coefficient - value).abs() <
        (closest.coefficient - value).abs()) {
      closest = level;
    }
  }
  return closest.label;
}

String _historySummary(Object? value, AppLocalizations l, TasteScale scale) {
  if (value is! Map || value['nickname'] == null) {
    return value is Map && value['present'] == false
        ? l.familyDeletedReceipt
        : l.familyUnset;
  }
  final flavors = value['flavors'] as Map? ?? {};
  final allergies = value['allergies'] as Map? ?? {};
  return [
    '${value['nickname']} · ${familyAgeLabel(value['age_band'] as String, l)}',
    for (final entry in flavors.entries)
      '${_flavorLabel(entry.key as String, l)} · ${_coefficientLabel(entry.key as String, entry.value as num, scale, l)}',
    for (final item in (value['avoidances'] as List? ?? []))
      '${l.familyAvoidances} · ${(item as Map)['name']}',
    for (final item in (allergies['categories'] as List? ?? []))
      '${l.familyAllergies} · $item',
    for (final item in (allergies['ingredients'] as List? ?? []))
      '${l.familyAllergies} · ${(item as Map)['name']}',
  ].join('；');
}

/// Dialogs keep only account/generation/ID metadata in their route constructor.
class _FamilyScope {
  const _FamilyScope(this.account, this.sensitiveEpoch, this.familyEpoch);
  factory _FamilyScope.capture(WidgetRef ref) => _FamilyScope(
    ref.read(authProvider).value?.id,
    ref.read(sensitiveMemoryProvider).epoch,
    ref.read(familyMemoryProvider).epoch,
  );
  final String? account;
  final int sensitiveEpoch;
  final int familyEpoch;
  bool current(WidgetRef ref) =>
      account != null &&
      ref.read(authProvider).value?.id == account &&
      ref.read(sensitiveMemoryProvider).epoch == sensitiveEpoch &&
      ref.read(familyMemoryProvider).epoch == familyEpoch;
  bool watch(WidgetRef ref) =>
      account != null &&
      ref.watch(authProvider).value?.id == account &&
      ref.watch(sensitiveMemoryProvider).epoch == sensitiveEpoch &&
      ref.watch(familyMemoryProvider).epoch == familyEpoch;
}

Widget _familyAction(
  WidgetRef ref,
  String name,
  Widget Function(void Function(FutureOr<void> Function() run) dispatch)
  builder,
) {
  // Bind to the rendered account/generations before dispatch awaits telemetry.
  final scope = _FamilyScope.capture(ref);
  return FamilyAction(
    name: name,
    builder: (dispatch) => builder(
      (run) => dispatch(() {
        if (ref.context.mounted && scope.current(ref)) return run();
      }),
    ),
  );
}

void _dismiss(BuildContext context) =>
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.pop(context);
      }
    });

class FamilyMembersSection extends ConsumerStatefulWidget {
  const FamilyMembersSection({super.key});
  @override
  ConsumerState<FamilyMembersSection> createState() =>
      _FamilyMembersSectionState();
}

class _FamilyMembersSectionState extends ConsumerState<FamilyMembersSection> {
  bool _busy = false;

  Future<void> _edit([String? id]) async {
    final scope = _FamilyScope.capture(ref);
    if (_busy ||
        !scope.current(ref) ||
        ref.read(tasteProfileSnapshotProvider).value?.fromCache == true) {
      return;
    }
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      ref.invalidate(familyMembersProvider);
      var state = await ref.read<Future<FamilyMembersOut?>>(
        familyMembersProvider.future,
      );
      if (!mounted || !scope.current(ref) || state == null) return;
      if (state.consentId == null || (id == null && state.items.isEmpty)) {
        final agree = await showDialog<bool>(
          context: context,
          builder: (_) => _FamilyConsent(scope: scope),
        );
        if (agree != true || !mounted || !scope.current(ref)) return;
        if (state.consentId == null) {
          await uploadSensitiveConsent(ref, true, state.consentVersion);
          if (!mounted || !scope.current(ref)) return;
          ref.invalidate(allergiesProvider);
        }
        // Reuse a valid receipt, but still explain the first family/child scope.
        ref.invalidate(familyMembersProvider);
        state = await ref.read<Future<FamilyMembersOut?>>(
          familyMembersProvider.future,
        );
        if (!mounted || !scope.current(ref)) return;
        if (state?.consentId == null) {
          throw StateError('authorization_unconfirmed');
        }
      }
      if (!mounted || !scope.current(ref) || state == null) return;
      final editor = _FamilyEditor(
        scope: scope,
        memberId: id,
        consentId: state.consentId!,
        authorizationVersion: state.authorizationVersion,
        ageBands: state.availableAgeBands.map((age) => age.value).toList(),
        allergenCategories: state.availableAllergenCategories,
      );
      state = null;
      if (id != null) ref.invalidate(familyMemberProvider(id));
      await showDialog<void>(context: context, builder: (_) => editor);
    } catch (_) {
      if (mounted && scope.current(ref)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.familyUnavailable)));
      }
    } finally {
      if (mounted && ref.read(authProvider).value?.id == scope.account) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _view(String id) async {
    final scope = _FamilyScope.capture(ref);
    if (!scope.current(ref)) return;
    ref.invalidate(familyMemberProvider(id));
    await showDialog<void>(
      context: context,
      builder: (_) => _FamilyDetail(scope: scope, memberId: id),
    );
  }

  Future<bool> _confirmMissing(String id, _FamilyScope scope) async {
    if (!mounted || !scope.current(ref)) return false;
    final store = ref.read(sessionStoreProvider);
    final api = ref.read(apiClientProvider).getFamilyMembersApi();
    final headers = sensitiveAccountHeaders(store);
    final extra = sensitiveAccountExtra(store);
    try {
      await api.getFamilyMember(memberId: id, headers: headers, extra: extra);
      return false;
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) rethrow;
    }
    if (!mounted || !scope.current(ref)) return false;
    // Probe raw history, not the tombstone-filtered provider: hiding data is not
    // proof of server erasure after a committed DELETE lost its response.
    String? cursor;
    do {
      final page = (await api.listFamilyMemberChanges(
        cursor: cursor,
        headers: headers,
        extra: extra,
      )).data!;
      if (!mounted || !scope.current(ref)) return false;
      if (page.items.any((row) => row.field == 'family_members.$id')) {
        return false;
      }
      cursor = page.nextCursor;
    } while (cursor != null);
    return true;
  }

  Future<void> _delete(String id, {bool retry = false}) async {
    final before = _FamilyScope.capture(ref);
    if (_busy ||
        !before.current(ref) ||
        ref.read(tasteProfileSnapshotProvider).value?.fromCache == true) {
      return;
    }
    final l = AppLocalizations.of(context);
    if (!retry) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.familyDeleteTitle),
          content: Text(l.familyDeleteBody),
          actions: [
            _familyAction(
              ref,
              'cancel',
              (dispatch) => TextButton(
                onPressed: () => dispatch(() => Navigator.pop(context, false)),
                child: Text(l.cancel),
              ),
            ),
            _familyAction(
              ref,
              'confirm_delete',
              (dispatch) => FilledButton(
                key: const ValueKey('family-delete-confirm'),
                onPressed: () => dispatch(() => Navigator.pop(context, true)),
                child: Text(l.familyDelete),
              ),
            ),
          ],
        ),
      );
      if (ok != true || !mounted || !before.current(ref)) return;
      // Evict first, before awaiting keyless deletion. Never restore failed data.
      ref.read(familyMemoryProvider.notifier).evict(id);
    }
    final scope = _FamilyScope.capture(ref);
    setState(() => _busy = true);
    try {
      final store = ref.read(sessionStoreProvider);
      try {
        await ref
            .read(apiClientProvider)
            .getFamilyMembersApi()
            .deleteFamilyMember(
              memberId: id,
              headers: sensitiveAccountHeaders(store),
              extra: sensitiveAccountExtra(store),
            );
      } on DioException catch (error) {
        if (error.response?.statusCode != 404 ||
            !await _confirmMissing(id, scope)) {
          rethrow;
        }
      }
      if (!mounted || !scope.current(ref)) return;
      await ref
          .read(tasteProfileCacheProvider)
          .removeFamilyMember(
            scope.account!,
            id,
            stillCurrent: () => mounted && scope.current(ref),
          );
      ref.invalidate(familyMembersProvider);
      ref.invalidate(familyChangesProvider);
      ref.invalidate(tasteProfileProvider);
      ref.read(familyMemoryProvider.notifier).confirmDeletion(id);
    } catch (_) {
      // Retain the ID-only retry until server deletion is confirmed, including
      // failed requests followed by leaving/reopening this section.
    } finally {
      if (mounted && ref.read(authProvider).value?.id == scope.account) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(familyMembersProvider);
    final changes = ref.watch(familyChangesProvider);
    final scale = ref.watch(tasteProfileProvider).value?.scale;
    final pending = ref.watch(familyMemoryProvider).pending;
    ref.listen(sensitiveMemoryProvider, (_, _) {
      if (mounted) setState(() => _busy = false);
    });
    return ComponentCard(
      key: const ValueKey('family-section'),
      detail: ComponentDescriptorDetailEnum.standard,
      conclusion: Text(l.familyTitle),
      conclusionSemanticsText: l.familyTitle,
      standardExtra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.familyIntro),
          state.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(l.familyUnavailable),
            data: (value) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (value == null)
                  Text(l.familyHidden)
                else if (value.items.isEmpty)
                  Text(l.familyEmpty),
                for (final member in value?.items ?? <FamilyMemberOut>[])
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${member.nickname} · ${familyAgeLabel(member.ageBand.value, l)}',
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          _familyAction(
                            ref,
                            'view',
                            (dispatch) => TextButton(
                              key: ValueKey('family-view-${member.id}'),
                              onPressed: _busy
                                  ? null
                                  : () => dispatch(() => _view(member.id)),
                              child: Text(l.familyView),
                            ),
                          ),
                          _familyAction(
                            ref,
                            'edit',
                            (dispatch) => TextButton(
                              key: ValueKey('family-edit-${member.id}'),
                              onPressed: _busy
                                  ? null
                                  : () => dispatch(() => _edit(member.id)),
                              child: Text(l.familyEdit),
                            ),
                          ),
                          _familyAction(
                            ref,
                            'delete',
                            (dispatch) => TextButton(
                              key: ValueKey('family-delete-${member.id}'),
                              onPressed: _busy
                                  ? null
                                  : () => dispatch(() => _delete(member.id)),
                              child: Text(l.familyDelete),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
          _familyAction(
            ref,
            'add',
            (dispatch) => OutlinedButton(
              key: const ValueKey('family-add'),
              onPressed: _busy ? null : () => dispatch(_edit),
              child: Text(l.familyAdd),
            ),
          ),
          if (pending.isNotEmpty) ...[
            Text(l.familyDeleteUnconfirmed),
            Column(
              key: const ValueKey('family-delete-retry'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final id in pending)
                  _familyAction(
                    ref,
                    'retry_delete',
                    (dispatch) => TextButton(
                      key: ValueKey('family-delete-retry-$id'),
                      onPressed: _busy
                          ? null
                          : () => dispatch(() => _delete(id, retry: true)),
                      child: Text(l.familyDeleteRetry),
                    ),
                  ),
              ],
            ),
          ],
          Text(l.familyHistory),
          changes.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(l.familyHistoryUnavailable),
            data: (items) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (items.isEmpty) Text(l.familyHistoryEmpty),
                if (scale != null)
                  for (final row in items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${_historySummary(row.oldValue, l, scale)} → ${_historySummary(row.newValue, l, scale)}',
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${row.reason} · ${row.status == TasteProfileChangeOutStatusEnum.active ? l.tasteActive : l.tasteReverted}',
                          ),
                          Text(
                            row.createdAt,
                            style: GramTreeColors.of(context).numberStyle(
                              Theme.of(context).textTheme.bodySmall!,
                            ),
                          ),
                        ],
                      ),
                      trailing: _familyAction(
                        ref,
                        'why',
                        (dispatch) => TextButton(
                          key: ValueKey('family-why-${row.id}'),
                          child: Text(l.familyWhy),
                          onPressed: () => dispatch(() {
                            final scope = _FamilyScope.capture(ref);
                            if (!scope.current(ref)) return;
                            showModalBottomSheet<void>(
                              context: context,
                              builder: (_) =>
                                  _FamilyWhy(scope: scope, changeId: row.id),
                            );
                          }),
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

class _FamilyConsent extends ConsumerWidget {
  const _FamilyConsent({required this.scope});
  final _FamilyScope scope;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!scope.watch(ref)) {
      _dismiss(context);
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.familyConsentTitle),
      content: SingleChildScrollView(child: Text(l.familyConsentBody)),
      actions: [
        _familyAction(
          ref,
          'refuse',
          (dispatch) => TextButton(
            key: const ValueKey('family-consent-refuse'),
            onPressed: () => dispatch(() => Navigator.pop(context, false)),
            child: Text(l.familyRefuse),
          ),
        ),
        _familyAction(
          ref,
          'agree',
          (dispatch) => FilledButton(
            key: const ValueKey('family-consent-agree'),
            onPressed: () => dispatch(() => Navigator.pop(context, true)),
            child: Text(l.familyAgree),
          ),
        ),
      ],
    );
  }
}

class _FamilyDetail extends ConsumerWidget {
  const _FamilyDetail({required this.scope, required this.memberId});
  final _FamilyScope scope;
  final String memberId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!scope.watch(ref)) {
      _dismiss(context);
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context);
    final scale = ref.watch(tasteProfileProvider).value?.scale;
    final member = ref.watch(familyMemberProvider(memberId));
    return AlertDialog(
      title: Text(l.familyDetailTitle),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: member.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(l.familyUnavailable),
            data: (value) => value == null || scale == null
                ? Text(l.familyHidden)
                : Text(_historySummary(value.toJson(), l, scale)),
          ),
        ),
      ),
      actions: [
        _familyAction(
          ref,
          'close',
          (dispatch) => TextButton(
            key: const ValueKey('family-detail-close'),
            onPressed: () => dispatch(() => Navigator.pop(context)),
            child: Text(l.familyClose),
          ),
        ),
      ],
    );
  }
}

class _FamilyWhy extends ConsumerWidget {
  const _FamilyWhy({required this.scope, required this.changeId});
  final _FamilyScope scope;
  final String changeId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!scope.watch(ref)) {
      _dismiss(context);
      return const SizedBox.shrink();
    }
    final rows = ref.watch(familyChangesProvider).value ?? [];
    final matches = rows.where((row) => row.id == changeId);
    final scale = ref.watch(tasteProfileProvider).value?.scale;
    if (matches.isEmpty || scale == null) return const SizedBox.shrink();
    final row = matches.first;
    final l = AppLocalizations.of(context);
    return WhyPanel(
      key: const ValueKey('why-panel'),
      sourceType: sourceTypeAuthorFilled,
      titleOverride: l.familyManual,
      value: _historySummary(row.newValue, l, scale),
      originalValue: _historySummary(row.oldValue, l, scale),
      basisText: row.reason,
      required: true,
      feedbackEnabled: false,
    );
  }
}

class _FamilyEditor extends ConsumerStatefulWidget {
  const _FamilyEditor({
    required this.scope,
    required this.memberId,
    required this.consentId,
    required this.authorizationVersion,
    required this.ageBands,
    required this.allergenCategories,
  });
  final _FamilyScope scope;
  final String? memberId;
  final String consentId;
  final int authorizationVersion;
  final List<String> ageBands;
  final List<String> allergenCategories;
  @override
  ConsumerState<_FamilyEditor> createState() => _FamilyEditorState();
}

class _FamilyEditorState extends ConsumerState<_FamilyEditor> {
  final _nickname = TextEditingController();
  String? _age;
  final _flavors = <String, num>{};
  final _avoidances = <CanonicalIngredientChoice>[];
  final _categories = <String>{};
  final _ingredients = <String, String>{};
  bool _initialized = false;
  bool _busy = false;
  bool _createUnconfirmed = false;
  String? _error;
  bool get _current => mounted && widget.scope.current(ref);

  void _erase() {
    _flavors.clear();
    _avoidances.clear();
    _categories.clear();
    _ingredients.clear();
    _age = null;
    _error = null;
  }

  @override
  void dispose() {
    _erase();
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _pick(bool allergy) async {
    if (!_current || _busy) return;
    final profile = ref.read(tasteProfileProvider).value;
    final choice = await showFamilyIngredientChooser(
      context,
      accountId: widget.scope.account!,
      sensitiveEpoch: widget.scope.sensitiveEpoch,
      familyEpoch: widget.scope.familyEpoch,
      categories: allergy ? [] : profile?.ingredientCategories ?? [],
    );
    if (!_current || choice == null) return;
    setState(() {
      if (allergy) {
        _ingredients[choice.ingredientId!] = choice.name;
      } else {
        _avoidances.removeWhere(
          (item) =>
              item.ingredientId == choice.ingredientId &&
              item.category == choice.category,
        );
        _avoidances.add(choice);
      }
    });
  }

  Future<void> _save() async {
    if (!_current || _busy || _createUnconfirmed) return;
    final l = AppLocalizations.of(context);
    if (_nickname.text.trim().isEmpty || _age == null) {
      setState(() => _error = l.familyNicknameRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final request = FamilyMemberWrite.fromJson({
        'consent_id': widget.consentId,
        'authorization_version': widget.authorizationVersion,
        'nickname': _nickname.text.trim(),
        'age_band': _age,
        'flavors': _flavors,
        'avoidances': [
          for (final choice in _avoidances)
            {
              if (choice.ingredientId != null)
                'ingredient_id': choice.ingredientId,
              if (choice.category != null) 'category': choice.category,
            },
        ],
        'allergies': {
          'categories': _categories.toList(),
          'ingredient_ids': _ingredients.keys.toList(),
        },
      });
      final store = ref.read(sessionStoreProvider);
      final api = ref.read(apiClientProvider).getFamilyMembersApi();
      if (widget.memberId == null) {
        await api.createFamilyMember(
          familyMemberWrite: request,
          headers: sensitiveAccountHeaders(store),
          extra: sensitiveAccountExtra(store),
        );
      } else {
        await api.updateFamilyMember(
          memberId: widget.memberId!,
          familyMemberWrite: request,
          headers: sensitiveAccountHeaders(store),
          extra: sensitiveAccountExtra(store),
        );
      }
      if (!mounted || !_current) return;
      ref.invalidate(familyMembersProvider);
      ref.invalidate(familyChangesProvider);
      ref.invalidate(tasteProfileProvider);
      if (widget.memberId != null) {
        ref.invalidate(familyMemberProvider(widget.memberId!));
      }
      Navigator.pop(context);
    } catch (_) {
      if (_current) {
        if (widget.memberId == null) {
          // A failed response does not prove creation failed. Require the user
          // to inspect refreshed server state instead of blindly POSTing again.
          ref.invalidate(familyMembersProvider);
          ref.invalidate(familyChangesProvider);
          setState(() {
            _createUnconfirmed = true;
            _error = l.familyCreateUnconfirmed;
          });
        } else {
          setState(() => _error = l.familySaveUnconfirmed);
        }
      }
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.scope.watch(ref)) {
      _erase();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nickname.clear();
      });
      _dismiss(context);
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context);
    final profile = ref.watch(tasteProfileProvider).value;
    final member = widget.memberId == null
        ? null
        : ref.watch(familyMemberProvider(widget.memberId!));
    if (!_initialized && (widget.memberId == null || member?.value != null)) {
      final value = member?.value;
      _nickname.text = value?.nickname ?? '';
      _age = value?.ageBand.value;
      _flavors.addAll(value?.flavors ?? {});
      _avoidances.addAll([
        for (final item in value?.avoidances ?? <FamilyAvoidanceOut>[])
          (
            ingredientId: item.ingredientId,
            category: item.category,
            name: item.name,
          ),
      ]);
      _categories.addAll(value?.allergies.categories ?? []);
      _ingredients.addAll({
        for (final item
            in value?.allergies.ingredients ?? <AllergyIngredientOut>[])
          item.ingredientId: item.name,
      });
      _initialized = true;
    }
    return AlertDialog(
      key: const ValueKey('family-editor'),
      title: Text(l.familyEditorTitle),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: !_initialized || profile == null
              ? (member?.hasError == true
                    ? Text(l.familyUnavailable)
                    : const LinearProgressIndicator())
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      key: const ValueKey('family-nickname'),
                      controller: _nickname,
                      maxLength: 40,
                      enabled: !_busy,
                      decoration: InputDecoration(labelText: l.familyNickname),
                    ),
                    _familyAction(
                      ref,
                      'age',
                      (dispatch) => DropdownButton<String>(
                        key: const ValueKey('family-age-band'),
                        value: _age,
                        hint: Text(l.familyAgeBand),
                        isExpanded: true,
                        items: [
                          for (final age in widget.ageBands)
                            DropdownMenuItem(
                              value: age,
                              child: Text(familyAgeLabel(age, l)),
                            ),
                        ],
                        onChanged: _busy
                            ? null
                            : (value) => dispatch(() {
                                if (_current) setState(() => _age = value);
                              }),
                      ),
                    ),
                    Text(l.familyFlavors),
                    for (final key in profile.flavors.keys)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_flavorLabel(key, l)),
                          _familyAction(
                            ref,
                            'flavor',
                            (dispatch) => DropdownButton<num>(
                              key: ValueKey('family-flavor-$key'),
                              value: _flavors[key] ?? profile.scale.default_,
                              isExpanded: true,
                              items: [
                                // A valid saved sparse value can outlive the scale
                                // that offered it. Preserve it unless explicitly
                                // changed rather than snapping to a nearby step.
                                if (_flavors.containsKey(key) &&
                                    !(key == 'spicy' && _flavors[key] == 0) &&
                                    !profile.scale.levels.any(
                                      (level) =>
                                          level.coefficient == _flavors[key],
                                    ))
                                  DropdownMenuItem(
                                    value: _flavors[key],
                                    child: Text(
                                      '${l.familySavedCoefficient} · ${_flavors[key]}',
                                    ),
                                  ),
                                if (key == 'spicy')
                                  DropdownMenuItem(
                                    value: 0,
                                    child: Text(l.familyNoChili),
                                  ),
                                for (final level in profile.scale.levels)
                                  DropdownMenuItem(
                                    value: level.coefficient,
                                    child: Text(
                                      level.coefficient ==
                                              profile.scale.default_
                                          ? l.familyStandard
                                          : level.label,
                                    ),
                                  ),
                              ],
                              onChanged: _busy
                                  ? null
                                  : (value) => dispatch(() {
                                      if (_current && value != null) {
                                        setState(() {
                                          if (value == profile.scale.default_) {
                                            _flavors.remove(key);
                                          } else {
                                            _flavors[key] = value;
                                          }
                                        });
                                      }
                                    }),
                            ),
                          ),
                        ],
                      ),
                    Text(l.familyAvoidances),
                    for (final item in _avoidances)
                      ListTile(
                        title: Text(item.name),
                        trailing: _familyAction(
                          ref,
                          'avoidance_remove',
                          (dispatch) => IconButton(
                            key: ValueKey(
                              'family-avoidance-remove-${item.ingredientId ?? item.category}',
                            ),
                            tooltip: l.familyRemove,
                            icon: const Icon(Icons.close),
                            onPressed: _busy
                                ? null
                                : () => dispatch(() {
                                    if (_current) {
                                      setState(() => _avoidances.remove(item));
                                    }
                                  }),
                          ),
                        ),
                      ),
                    _familyAction(
                      ref,
                      'avoidance_add',
                      (dispatch) => TextButton(
                        key: const ValueKey('family-avoidance-add'),
                        onPressed: _busy
                            ? null
                            : () => dispatch(() => _pick(false)),
                        child: Text(l.familyAvoidanceAdd),
                      ),
                    ),
                    Text(l.familyAllergies),
                    for (final category in widget.allergenCategories)
                      _familyAction(
                        ref,
                        'allergy_toggle',
                        (dispatch) => CheckboxListTile(
                          key: ValueKey('family-allergy-category-$category'),
                          title: Text(category),
                          value: _categories.contains(category),
                          onChanged: _busy
                              ? null
                              : (value) => dispatch(() {
                                  if (_current) {
                                    setState(() {
                                      if (value == true) {
                                        _categories.add(category);
                                      } else {
                                        _categories.remove(category);
                                      }
                                    });
                                  }
                                }),
                        ),
                      ),
                    for (final item in _ingredients.entries)
                      ListTile(
                        title: Text(item.value),
                        trailing: _familyAction(
                          ref,
                          'allergy_remove',
                          (dispatch) => IconButton(
                            key: ValueKey('family-allergy-remove-${item.key}'),
                            tooltip: l.familyRemove,
                            icon: const Icon(Icons.close),
                            onPressed: _busy
                                ? null
                                : () => dispatch(() {
                                    if (_current) {
                                      setState(
                                        () => _ingredients.remove(item.key),
                                      );
                                    }
                                  }),
                          ),
                        ),
                      ),
                    _familyAction(
                      ref,
                      'allergy_add',
                      (dispatch) => TextButton(
                        key: const ValueKey('family-allergy-add'),
                        onPressed: _busy
                            ? null
                            : () => dispatch(() => _pick(true)),
                        child: Text(l.familyAllergyAdd),
                      ),
                    ),
                    if (_error != null) Text(_error!),
                  ],
                ),
        ),
      ),
      actions: [
        _familyAction(
          ref,
          'cancel',
          (dispatch) => TextButton(
            key: const ValueKey('family-editor-cancel'),
            onPressed: () => dispatch(() => Navigator.pop(context)),
            child: Text(l.cancel),
          ),
        ),
        _familyAction(
          ref,
          'save',
          (dispatch) => FilledButton(
            key: const ValueKey('family-save'),
            onPressed: _busy || !_initialized || _createUnconfirmed
                ? null
                : () => dispatch(_save),
            child: Text(l.save),
          ),
        ),
      ],
    );
  }
}
