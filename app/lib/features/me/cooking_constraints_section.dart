import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../auth/session.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../ui_protocol/cooking_constraint_actions.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import 'taste_profile_cache.dart';
import 'taste_profile_data.dart';

final cookingConstraintsProvider =
    FutureProvider.autoDispose<CookingConstraintsOut>((ref) async {
      final account = ref.watch(authProvider).value?.id;
      if (account == null) throw StateError('做菜约束需要登录');
      final session = ref.read(sessionStoreProvider);
      final identity = session.identity;
      if (identity == null || identity.ownerId != account) {
        throw StateError('account_unavailable');
      }
      final cache = ref.read(tasteProfileCacheProvider);
      try {
        final value =
            (await ref
                    .watch(apiClientProvider)
                    .getTasteProfileApi()
                    .getCookingConstraints())
                .data!;
        if (!ref.mounted || !session.matches(identity)) {
          throw StateError('stale_profile_response');
        }
        await cache.writeConstraints(
          account,
          value,
          stillCurrent: () => ref.mounted && session.matches(identity),
        );
        if (!ref.mounted || !session.matches(identity)) {
          throw StateError('stale_profile_response');
        }
        return value;
      } catch (error) {
        if (!isNetworkFailure(error) || !session.matches(identity)) rethrow;
        final snapshot = await cache.read(account);
        if (!ref.mounted || !session.matches(identity)) {
          throw StateError('stale_profile_response');
        }
        if (snapshot?.profile == null ||
            snapshot?.constraints == null ||
            !snapshot!.hasCurrentProfile) {
          rethrow;
        }
        return snapshot.constraints!;
      }
    });

const _days = ['weekday', 'weekend'];
const _meals = ['breakfast', 'lunch', 'dinner'];

Map<String, String> _dishLabels(AppLocalizations l10n) => {
  'meat': l10n.cookingDishMeat,
  'vegetable': l10n.cookingDishVegetable,
  'soup': l10n.cookingDishSoup,
  'staple': l10n.cookingDishStaple,
  'other': l10n.cookingDishOther,
};

String _mealLabel(String day, String meal, AppLocalizations l10n) =>
    l10n.cookingMealSlot(
      switch (day) {
        'weekday' => l10n.cookingWeekday,
        'weekend' => l10n.cookingWeekend,
        _ => day,
      },
      switch (meal) {
        'breakfast' => l10n.cookingBreakfast,
        'lunch' => l10n.cookingLunch,
        'dinner' => l10n.cookingDinner,
        _ => meal,
      },
    );

String cookingConstraintsHistoryLabel(
  Object value,
  AppLocalizations l10n, {
  Map<String, String> equipmentNames = const {},
}) {
  if (value is! Map) return l10n.cookingConstraintsTitle;
  final parts = <String>[];
  final household = value['household_servings'];
  if (household != null) {
    parts.add(l10n.cookingHouseholdHistory(household.toString()));
  }
  final equipment = value['equipment'];
  if (equipment is List && equipment.isNotEmpty) {
    // Retain an ID when equipment has since left the configured vocabulary.
    parts.add(
      l10n.cookingEquipmentSummary(
        equipment
            .map((id) => equipmentNames[id] ?? id)
            .join(l10n.cookingListSeparator),
      ),
    );
  }
  String mealLabel(Map slot) =>
      _mealLabel(slot['day_type'].toString(), slot['meal'].toString(), l10n);
  final times = value['meal_times'];
  if (times is List) {
    for (final slot in times.whereType<Map>()) {
      parts.add(
        l10n.cookingMealTimeSummary(
          mealLabel(slot),
          slot['minutes'].toString(),
        ),
      );
    }
  }
  final templates = value['meal_templates'];
  if (templates is List) {
    final labels = _dishLabels(l10n);
    for (final slot in templates.whereType<Map>()) {
      final composition = slot['composition'];
      final dishes = composition is List
          ? composition
                .map((type) => labels[type] ?? type)
                .join(l10n.cookingListSeparator)
          : '—';
      parts.add(
        l10n.cookingMealTemplateSummary(
          mealLabel(slot),
          slot['dish_count'].toString(),
          dishes,
        ),
      );
    }
  }
  return parts.isEmpty
      ? l10n.cookingConstraintsUnset
      : parts.join(l10n.cookingListSeparator);
}

class CookingConstraintsSection extends ConsumerStatefulWidget {
  const CookingConstraintsSection({super.key});

  @override
  ConsumerState<CookingConstraintsSection> createState() =>
      _CookingConstraintsSectionState();
}

class _CookingConstraintsSectionState
    extends ConsumerState<CookingConstraintsSection> {
  bool _busy = false;

  Future<void> _save(CookingConstraints values) async {
    final account = ref.read(authProvider).value?.id;
    if (_busy ||
        account == null ||
        ref.read(tasteProfileSnapshotProvider).value?.fromCache == true) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(apiClientProvider)
          .getTasteProfileApi()
          .replaceCookingConstraints(cookingConstraints: values);
      if (!mounted || ref.read(authProvider).value?.id != account) return;
      ref.invalidate(cookingConstraintsProvider);
      ref.invalidate(tasteProfileProvider);
      ref.invalidate(tasteProfileChangesProvider);
    } catch (error) {
      if (mounted && ref.read(authProvider).value?.id == account) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiFailure.from(error).message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(CookingConstraintsOut current) async {
    final account = ref.read(authProvider).value?.id;
    final values = await showDialog<CookingConstraints>(
      context: context,
      builder: (_) => _ConstraintsDialog(current: current),
    );
    if (values != null &&
        mounted &&
        ref.read(authProvider).value?.id == account) {
      await _save(values);
    }
  }

  Future<void> _clear() async {
    final l10n = AppLocalizations.of(context);
    final account = ref.read(authProvider).value?.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cookingConstraintsClearTitle),
        content: Text(l10n.cookingConstraintsClearBody),
        actions: [
          cookingConstraintAction(
            ref,
            'cooking_constraints_cancel',
            () => Navigator.pop(context, false),
            (dispatch) =>
                TextButton(onPressed: dispatch, child: Text(l10n.cancel)),
          ),
          cookingConstraintAction(
            ref,
            'cooking_constraints_confirm_clear',
            () => Navigator.pop(context, true),
            (dispatch) => FilledButton(
              key: const ValueKey('cooking-constraints-clear-confirm'),
              onPressed: dispatch,
              child: Text(l10n.cookingConstraintsClearConfirm),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true &&
        mounted &&
        ref.read(authProvider).value?.id == account) {
      await _save(CookingConstraints());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final offline =
        ref.watch(tasteProfileSnapshotProvider).value?.fromCache == true;
    final numberStyle = GramTreeColors.of(context)
        .numberStyle(Theme.of(context).textTheme.bodyMedium!);
    final dishes = _dishLabels(l10n);
    return ref
        .watch(cookingConstraintsProvider)
        .when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.cookingConstraintsLoadError),
              cookingConstraintAction(
                ref,
                'cooking_constraints_retry',
                () => ref.invalidate(cookingConstraintsProvider),
                (dispatch) =>
                    TextButton(onPressed: dispatch, child: Text(l10n.retry)),
              ),
            ],
          ),
          data: (current) {
            final values = current.constraints;
            final names = {
              for (final item in current.equipmentVocabulary)
                item.id: item.label,
            };
            return ComponentCard(
              key: const ValueKey('cooking-constraints'),
              detail: ComponentDescriptorDetailEnum.standard,
              conclusion: Text(
                values.householdServings == null
                    ? l10n.cookingHouseholdEmpty
                    : l10n.cookingHouseholdDefault(
                        values.householdServings.toString(),
                      ),
                style: values.householdServings == null ? null : numberStyle,
              ),
              conclusionSemanticsText: l10n.cookingConstraintsTitle,
              standardExtra: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.cookingConstraintsIntro),
                  SourceMark(
                    key: const ValueKey('cooking-constraints-why'),
                    sourceType: sourceTypeAuthorFilled,
                    componentId: 'cooking-constraints',
                    value: l10n.cookingConstraintsSourceValue,
                    basisText: l10n.cookingConstraintsBasis,
                    required: false,
                    neutral: true,
                    feedbackEnabled: false,
                    showWhenAuthorFilled: true,
                    labelOverride: l10n.cookingConstraintsManual,
                    onAction: null,
                  ),
                  Text(
                    values.equipment?.isNotEmpty == true
                        ? l10n.cookingEquipmentSummary(
                            values.equipment!
                                .map((id) => names[id] ?? id)
                                .join(l10n.cookingListSeparator),
                          )
                        : l10n.cookingEquipmentEmpty,
                  ),
                  if (values.mealTimes?.isEmpty != false)
                    Text(l10n.cookingMealTimesEmpty),
                  for (final slot in values.mealTimes ?? <CookingMealTime>[])
                    Text(
                      l10n.cookingMealTimeSummary(
                        _mealLabel(slot.dayType.value, slot.meal.value, l10n),
                        slot.minutes.toString(),
                      ),
                      style: numberStyle,
                    ),
                  if (values.mealTemplates?.isEmpty != false)
                    Text(l10n.cookingMealTemplatesEmpty),
                  for (final slot
                      in values.mealTemplates ?? <CookingMealTemplate>[])
                    Text(
                      l10n.cookingMealTemplateSummary(
                        _mealLabel(slot.dayType.value, slot.meal.value, l10n),
                        slot.dishCount.toString(),
                        slot.composition
                            .map((type) => dishes[type.value])
                            .join(l10n.cookingListSeparator),
                      ),
                      style: numberStyle,
                    ),
                  Wrap(
                    spacing: 12,
                    children: [
                      cookingConstraintAction(
                        ref,
                        'cooking_constraints_edit',
                        () => _edit(current),
                        (dispatch) => OutlinedButton(
                          key: const ValueKey('cooking-constraints-edit'),
                          onPressed: _busy || offline ? null : dispatch,
                          child: Text(l10n.cookingConstraintsEdit),
                        ),
                      ),
                      cookingConstraintAction(
                        ref,
                        'cooking_constraints_clear',
                        _clear,
                        (dispatch) => TextButton(
                          key: const ValueKey('cooking-constraints-clear'),
                          onPressed: _busy || offline ? null : dispatch,
                          child: Text(l10n.cookingConstraintsClear),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
  }
}

class _ConstraintsDialog extends ConsumerStatefulWidget {
  const _ConstraintsDialog({required this.current});
  final CookingConstraintsOut current;

  @override
  ConsumerState<_ConstraintsDialog> createState() => _ConstraintsDialogState();
}

class _ConstraintsDialogState extends ConsumerState<_ConstraintsDialog> {
  bool _templatesInitialized = false;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _household;
  final _times = <String, TextEditingController>{};
  final _templates = <String, TextEditingController>{};
  final _equipment = <String>{};

  @override
  void initState() {
    super.initState();
    final values = widget.current.constraints;
    _household = TextEditingController(
      text: values.householdServings?.toString() ?? '',
    );
    _equipment.addAll(values.equipment ?? []);
    for (final day in _days) {
      for (final meal in _meals) {
        final key = '$day-$meal';
        _times[key] = TextEditingController();
        _templates[key] = TextEditingController();
      }
    }
    for (final slot in values.mealTimes ?? <CookingMealTime>[]) {
      _times['${slot.dayType.value}-${slot.meal.value}']!.text = slot.minutes
          .toString();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_templatesInitialized) return;
    _templatesInitialized = true;
    final labels = _dishLabels(AppLocalizations.of(context));
    for (final slot
        in widget.current.constraints.mealTemplates ??
            <CookingMealTemplate>[]) {
      _templates['${slot.dayType.value}-${slot.meal.value}']!.text = slot
          .composition
          .map((type) => labels[type.value])
          .join(',');
    }
  }

  @override
  void dispose() {
    _household.dispose();
    for (final controller in [..._times.values, ..._templates.values]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _integer(String? text, int minimum, int maximum) {
    if (text == null || text.trim().isEmpty) return null;
    final value = int.tryParse(text.trim());
    return value == null || value < minimum || value > maximum
        ? AppLocalizations.of(context)
              .cookingIntegerValidation(minimum, maximum)
        : null;
  }

  List<String> _composition(String text) => text
      .split(RegExp('[,，、]'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final dishes = _dishLabels(AppLocalizations.of(context));
    final times = <CookingMealTime>[];
    final templates = <CookingMealTemplate>[];
    for (final day in _days) {
      for (final meal in _meals) {
        final key = '$day-$meal';
        final minutes = int.tryParse(_times[key]!.text.trim());
        if (minutes != null) {
          times.add(
            CookingMealTime.fromJson({
              'day_type': day,
              'meal': meal,
              'minutes': minutes,
            }),
          );
        }
        final composition = _composition(_templates[key]!.text);
        if (composition.isNotEmpty) {
          templates.add(
            CookingMealTemplate.fromJson({
              'day_type': day,
              'meal': meal,
              'dish_count': composition.length,
              'composition': composition
                  .map(
                    (label) => dishes.entries
                        .singleWhere((item) => item.value == label)
                        .key,
                  )
                  .toList(),
            }),
          );
        }
      }
    }
    Navigator.pop(
      context,
      CookingConstraints(
        householdServings: int.tryParse(_household.text.trim()),
        equipment: _equipment.toList()..sort(),
        mealTimes: times,
        mealTemplates: templates,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dishes = _dishLabels(l10n);
    return AlertDialog(
      title: Text(l10n.cookingConstraintsTitle),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const ValueKey('household-servings'),
                  controller: _household,
                  style: GramTreeColors.of(context)
                      .numberStyle(Theme.of(context).textTheme.bodyLarge!),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.cookingHouseholdInput,
                  ),
                  validator: (text) => _integer(
                    text,
                    widget.current.servingsMin,
                    widget.current.servingsMax,
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.cookingEquipmentInput),
                for (final item in widget.current.equipmentVocabulary)
                  CheckboxListTile(
                    key: ValueKey('equipment-${item.id}'),
                    title: Text(item.label),
                    value: _equipment.contains(item.id),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _equipment.add(item.id);
                      } else {
                        _equipment.remove(item.id);
                      }
                    }),
                  ),
                Text(l10n.cookingMealInput),
                Text(
                  l10n.cookingMealTemplateHint(
                    dishes.values.join(l10n.cookingListSeparator),
                  ),
                ),
                for (final day in _days)
                  for (final meal in _meals) ...[
                    const SizedBox(height: 12),
                    Text(_mealLabel(day, meal, l10n)),
                    TextFormField(
                      key: ValueKey('meal-minutes-$day-$meal'),
                      controller: _times['$day-$meal'],
                      style: GramTreeColors.of(context)
                          .numberStyle(Theme.of(context).textTheme.bodyLarge!),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.cookingMealMinutesInput,
                      ),
                      validator: (text) => _integer(text, 1, 1440),
                    ),
                    TextFormField(
                      key: ValueKey('meal-template-$day-$meal'),
                      controller: _templates['$day-$meal'],
                      decoration: InputDecoration(
                        labelText: l10n.cookingMealTemplateInput(
                          [
                            l10n.cookingDishMeat,
                            l10n.cookingDishVegetable,
                            l10n.cookingDishSoup,
                          ].join(','),
                        ),
                      ),
                      validator: (text) {
                        final values = _composition(text ?? '');
                        return values.length > 20 ||
                                values.any(
                                  (label) => !dishes.containsValue(label),
                                )
                            ? l10n.cookingTemplateValidation(20)
                            : null;
                      },
                    ),
                  ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        cookingConstraintAction(
          ref,
          'cooking_constraints_cancel',
          () => Navigator.pop(context),
          (dispatch) =>
              TextButton(onPressed: dispatch, child: Text(l10n.cancel)),
        ),
        cookingConstraintAction(
          ref,
          'cooking_constraints_save',
          _submit,
          (dispatch) => FilledButton(
            key: const ValueKey('cooking-constraints-save'),
            onPressed: dispatch,
            child: Text(l10n.save),
          ),
        ),
      ],
    );
  }
}
