import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../ui_protocol/components/component_scaffold.dart';

class IngredientPreferencesSection extends StatelessWidget {
  const IngredientPreferencesSection({
    super.key,
    required this.profile,
    required this.accountId,
    required this.busy,
    required this.onSave,
  });

  final TasteProfileOut profile;
  final String accountId;
  final bool busy;
  final Future<void> Function(List<IngredientPreference>) onSave;

  Future<void> _add(BuildContext context) async {
    final selected = await showDialog<IngredientPreference>(
      context: context,
      builder: (_) => _PreferenceDialog(
        accountId: accountId,
        categories: profile.ingredientCategories,
      ),
    );
    if (selected == null || !context.mounted) return;
    await onSave([
      for (final item in profile.ingredientPreferences)
        if (item.ingredientId != selected.ingredientId ||
            item.category != selected.category)
          IngredientPreference.fromJson({
            if (item.ingredientId != null) 'ingredient_id': item.ingredientId,
            if (item.category != null) 'category': item.category,
            'preference': item.preference.value,
          }),
      selected,
    ]);
  }

  Future<void> _delete(
    BuildContext context,
    IngredientPreferenceOut target,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.tastePreferenceDelete} · ${target.name}'),
        content: Text(l10n.tastePreferenceDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('taste-preference-delete-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.tastePreferenceDelete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await onSave([
        for (final item in profile.ingredientPreferences)
          if (_targetKey(item) != _targetKey(target)) _input(item),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ComponentCard(
      key: const ValueKey('taste-ingredient-preferences'),
      detail: ComponentDescriptorDetailEnum.standard,
      conclusion: Text(l10n.tasteIngredients),
      conclusionSemanticsText: l10n.tasteIngredients,
      standardExtra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.tasteIngredientsIntro),
          if (profile.ingredientPreferences.isEmpty)
            Text(l10n.tasteIngredientsEmpty),
          for (final item in profile.ingredientPreferences)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.name} · ${preferenceLabel(item.preference.value, l10n)}',
                ),
                DropdownButton<String>(
                  key: ValueKey('taste-preference-kind-${_targetKey(item)}'),
                  value: item.preference.value,
                  isExpanded: true,
                  items: [
                    for (final kind
                        in IngredientPreferencePreferenceEnum.values)
                      DropdownMenuItem(
                        value: kind.value,
                        child: Text(preferenceLabel(kind.value, l10n)),
                      ),
                  ],
                  onChanged: busy
                      ? null
                      : (kind) {
                          if (kind == null) return;
                          onSave([
                            for (final entry in profile.ingredientPreferences)
                              _input(
                                entry,
                                preference:
                                    _targetKey(entry) == _targetKey(item)
                                    ? kind
                                    : null,
                              ),
                          ]);
                        },
                ),
                TextButton(
                  key: ValueKey('taste-preference-delete-${_targetKey(item)}'),
                  onPressed: busy ? null : () => _delete(context, item),
                  child: Text('${l10n.tastePreferenceDelete} · ${item.name}'),
                ),
              ],
            ),
          OutlinedButton(
            key: const ValueKey('taste-preference-add'),
            onPressed: busy ? null : () => _add(context),
            child: Text(l10n.tastePreferenceAdd),
          ),
        ],
      ),
    );
  }
}

class _PreferenceDialog extends ConsumerStatefulWidget {
  const _PreferenceDialog({required this.accountId, required this.categories});
  final String accountId;
  final List<String> categories;

  @override
  ConsumerState<_PreferenceDialog> createState() => _PreferenceDialogState();
}

class _PreferenceDialogState extends ConsumerState<_PreferenceDialog> {
  final _query = TextEditingController();
  List<SearchIngredientOut> _results = [];
  SearchIngredientOut? _selected;
  String? _category;
  String _preference = 'liked';
  bool _loading = false;
  bool _searched = false;
  Object? _error;
  int _request = 0;

  bool get _current =>
      mounted && ref.read(authProvider).value?.id == widget.accountId;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _query.text.trim();
    if (query.isEmpty || !_current) return;
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _selected = null;
    });
    try {
      final result =
          (await ref
                  .read(apiClientProvider)
                  .getIngredientsApi()
                  .searchIngredients(searchQuery: SearchQuery(query: query)))
              .data!;
      if (!_current || request != _request) return;
      setState(() {
        _results = result.items;
        _searched = true;
      });
    } catch (error) {
      if (_current && request == _request) setState(() => _error = error);
    } finally {
      if (_current && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (ref.watch(authProvider).value?.id != widget.accountId) {
      return const SizedBox.shrink();
    }
    return AlertDialog(
      title: Text(l10n.tastePreferenceAdd),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.tasteIngredientsIntro),
              TextField(
                key: const ValueKey('taste-ingredient-search'),
                controller: _query,
                decoration: InputDecoration(
                  labelText: l10n.tasteIngredientSearch,
                ),
                onSubmitted: (_) => _search(),
                onChanged: (_) => setState(() {
                  _request++;
                  _loading = false;
                  _selected = null;
                  _results = [];
                  _searched = false;
                  _error = null;
                }),
              ),
              TextButton(
                key: const ValueKey('taste-ingredient-search-submit'),
                onPressed: _loading ? null : _search,
                child: Text(l10n.tasteSearch),
              ),
              if (_loading) const LinearProgressIndicator(),
              if (_error != null) Text(ApiFailure.from(_error!).message),
              if (_searched && _results.isEmpty) Text(l10n.tasteSearchEmpty),
              for (final item in _results)
                ListTile(
                  key: ValueKey('taste-search-${item.id}'),
                  title: Text(item.standardName),
                  subtitle: Text(item.category),
                  selected: _selected?.id == item.id,
                  trailing: _selected?.id == item.id
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => setState(() {
                    _selected = item;
                    _category = null;
                  }),
                ),
              DropdownButton<String>(
                key: const ValueKey('taste-preference-category'),
                hint: Text(l10n.tasteCategory),
                value: _category,
                isExpanded: true,
                items: [
                  for (final category in widget.categories)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                onChanged: (category) => setState(() {
                  _category = category;
                  _selected = null;
                  _request++;
                  _loading = false;
                  _results = [];
                  _searched = false;
                }),
              ),
              DropdownButton<String>(
                key: const ValueKey('taste-preference-choice'),
                value: _preference,
                isExpanded: true,
                items: [
                  for (final kind in IngredientPreferencePreferenceEnum.values)
                    DropdownMenuItem(
                      value: kind.value,
                      child: Text(preferenceLabel(kind.value, l10n)),
                    ),
                ],
                onChanged: (kind) {
                  if (kind != null) setState(() => _preference = kind);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('taste-preference-save'),
          onPressed: _selected == null && _category == null
              ? null
              : () => Navigator.pop(
                  context,
                  IngredientPreference.fromJson({
                    if (_selected != null) 'ingredient_id': _selected!.id,
                    if (_category != null) 'category': _category,
                    'preference': _preference,
                  }),
                ),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

String _targetKey(IngredientPreferenceOut item) => item.ingredientId != null
    ? 'ingredient:${item.ingredientId}'
    : 'category:${item.category}';

IngredientPreference _input(
  IngredientPreferenceOut item, {
  String? preference,
}) => IngredientPreference.fromJson({
  if (item.ingredientId != null) 'ingredient_id': item.ingredientId,
  if (item.category != null) 'category': item.category,
  'preference': preference ?? item.preference.value,
});

String preferenceLabel(String value, AppLocalizations l10n) => switch (value) {
  'liked' => l10n.tasteLiked,
  'disliked' => l10n.tasteDisliked,
  'avoided' => l10n.tasteAvoided,
  _ => value,
};

String preferenceHistoryLabel(Object value, AppLocalizations l10n) {
  if (value is! Map ||
      value['items'] is! List ||
      (value['items'] as List).isEmpty) {
    return l10n.tasteUnset;
  }
  return (value['items'] as List)
      .whereType<Map>()
      .map(
        (item) =>
            '${item['name']} · ${preferenceLabel(item['preference'] as String, l10n)}',
      )
      .join('、');
}
