import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../auth/auth_controller.dart';
import '../../ingredients/ingredient_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../recipes/recipe_draft.dart';
import '../../recipes/recipe_repository.dart';
import 'recipe_photo_panel.dart';
import '../../storage/local_store.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';
import '../../widgets/empty_state.dart';

final myRecipesProvider = FutureProvider.autoDispose<RecipeList>((ref) async {
  return ref.watch(recipeRepositoryProvider).list();
});

class RecipeListPage extends ConsumerWidget {
  const RecipeListPage({super.key});

  static const path = '/recipes';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recipes = ref.watch(myRecipesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myRecipes)),
      body: recipes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _RecipeError(
          message: l10n.recipeLoadError,
          onRetry: () => ref.invalidate(myRecipesProvider),
        ),
        data: (page) => page.items.isEmpty
            ? EmptyState(
                icon: Icons.menu_book_outlined,
                title: l10n.recipeEmptyTitle,
                message: l10n.recipeEmptyBody,
                footer: _NewRecipeButton(),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(myRecipesProvider),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _NewRecipeButton(),
                    const SizedBox(height: 12),
                    for (final item in page.items)
                      Card(
                        child: ListTile(
                          key: ValueKey('recipe-card-${item.id}'),
                          title: Text(item.dish.name),
                          subtitle: Text(
                            l10n.recipeListSummary(
                              item.versionNumber,
                              item.servings,
                              _minutes(item.totalTimeSeconds),
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/recipes/${item.id}'),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _NewRecipeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FilledButton.icon(
      key: const ValueKey('new-recipe-button'),
      onPressed: () => context.push(RecipeEditorPage.path),
      icon: const Icon(Icons.add),
      label: Text(l10n.newRecipe),
    );
  }
}

class RecipeEditorPage extends ConsumerStatefulWidget {
  const RecipeEditorPage({super.key, this.recipeId, this.versionId});

  static const path = '/recipes/new';
  final String? recipeId;
  final String? versionId;

  @override
  ConsumerState<RecipeEditorPage> createState() => _RecipeEditorPageState();
}

class _RecipeEditorPageState extends ConsumerState<RecipeEditorPage> {
  late RecipeForm _form;
  late final RecipeDraftStore _draftStore;
  RecipeDetail? _loaded;
  RecipeDraft? _draft;
  String? _error;
  bool _loading = true;
  bool _loadFailed = false;
  bool _saving = false;
  int _editorRevision = 0;
  Timer? _draftTimer;
  Future<void>? _draftWrite;
  int _draftGeneration = 0;
  final Map<String, List<IngredientDetail>> _ingredientResults = {};
  final Map<String, List<IngredientDetail>> _replacementResults = {};
  final Map<String, bool> _searching = {};

  String get _recipeKey => widget.recipeId ?? 'new';
  String get _accountId => ref.read(authProvider).value?.id ?? 'anonymous';

  @override
  void initState() {
    super.initState();
    _draftStore = RecipeDraftStore(ref.read(localStoreProvider));
    _form = RecipeForm(dishName: '');
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      if (widget.recipeId != null) {
        final repo = ref.read(recipeRepositoryProvider);
        _loaded = widget.versionId == null
            ? await repo.get(widget.recipeId!)
            : await repo.getVersion(widget.recipeId!, widget.versionId!);
        _form =
            RecipeForm.fromSnapshot(
                _loaded!.version.snapshot,
                _loaded!.dish.name,
              )
              ..imageIds = [
                for (final image in _loaded!.version.images ?? const [])
                  image.id,
              ];
      }
      _draft = _draftStore.read(
        recipeKey: _recipeKey,
        accountId: _accountId,
        baselineVersionId: _loaded?.version.id,
      );
      if (_draft != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _askRestore());
      }
    } catch (_) {
      _loadFailed = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _askRestore() async {
    final l10n = AppLocalizations.of(context);
    final draft = _draft;
    if (!mounted || draft == null) return;
    final restore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recipeRestoreTitle),
        content: Text(l10n.recipeRestoreBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.recipeDiscardDraftAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.recipeRestore),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (restore == true) {
      _form = RecipeForm.fromDraft(draft.payload);
      _editorRevision++;
      setState(() {});
    } else {
      await _discardDraft();
    }
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    _draftTimer?.cancel();
    final generation = ++_draftGeneration;
    _draftTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted || generation != _draftGeneration) return;
      final draft = RecipeDraft(
        accountId: _accountId,
        recipeKey: _recipeKey,
        baselineVersionId: _loaded?.version.id,
        payload: _form.toDraft(),
      );
      _draftWrite = _draftStore.save(draft);
    });
  }

  Future<void> _flushDraft() async {
    _draftTimer?.cancel();
    _draftTimer = null;
    final generation = ++_draftGeneration;
    final draft = RecipeDraft(
      accountId: _accountId,
      recipeKey: _recipeKey,
      baselineVersionId: _loaded?.version.id,
      payload: _form.toDraft(),
    );
    final write = _draftStore.save(draft);
    _draftWrite = write;
    await write;
    if (generation != _draftGeneration) return;
  }

  Future<void> _discardDraft() async {
    ++_draftGeneration;
    _draftTimer?.cancel();
    _draftTimer = null;
    try {
      await _draftWrite;
    } catch (_) {
      // A failed local write must not prevent leaving the editor.
    }
    await _draftStore.discard(_recipeKey, accountId: _accountId);
    _draftWrite = null;
    _draft = null;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _flushDraft();
      final repo = ref.read(recipeRepositoryProvider);
      final detail = _loaded == null
          ? await repo.create(_form)
          : await repo.saveVersion(
              widget.recipeId!,
              _form,
              baseVersionId: _loaded!.version.id,
            );
      await _discardDraft();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.recipeSaveSuccess)));
      context.go('/recipes/${detail.id}');
    } catch (error) {
      if (mounted) {
        setState(() => _error = l10n.recipeSaveFailed(_message(error)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _validate() {
    final l10n = AppLocalizations.of(context);
    if (_form.dishName.trim().isEmpty) {
      setState(() => _error = l10n.recipeDishRequired);
      return false;
    }
    if (_form.servings < 1 ||
        _form.ingredients.any(
          (item) => item.quantity < 0 || item.baseQuantity < 0,
        ) ||
        _form.steps.any((item) => item.durationSeconds < 0)) {
      setState(() => _error = l10n.recipeInvalidNumber);
      return false;
    }
    final ingredientIds = _form.ingredients.map((item) => item.id).toSet();
    final stepIds = _form.steps.map((item) => item.id).toSet();
    if (_form.steps.any(
      (item) =>
          item.ingredientIds.any((id) => !ingredientIds.contains(id)) ||
          item.dependsOn.any((id) => !stepIds.contains(id)),
    )) {
      setState(() => _error = l10n.recipeInvalidStepReference);
      return false;
    }
    return true;
  }

  Future<void> _searchIngredient(String id, {required bool replacement}) async {
    final item = _form.ingredients.firstWhere((value) => value.id == id);
    final query = replacement
        ? (item.replacement?.displayName ?? '')
        : item.displayName;
    if (query.trim().isEmpty) return;
    final key = replacement ? 'replacement:$id' : 'ingredient:$id';
    setState(() => _searching[key] = true);
    try {
      final repository = ref.read(ingredientRepositoryProvider);
      await repository.sync();
      final results = await repository.search(query);
      if (!mounted) return;
      setState(() {
        if (replacement) {
          _replacementResults[id] = results;
        } else {
          _ingredientResults[id] = results;
        }
      });
    } finally {
      if (mounted) setState(() => _searching[key] = false);
    }
  }

  void _selectIngredient(String id, IngredientDetail value) {
    final item = _form.ingredients.firstWhere((item) => item.id == id);
    item.ingredientId = value.id;
    item.displayName = value.standardName;
    _ingredientResults.remove(id);
    _changed();
  }

  void _selectReplacement(String id, IngredientDetail value) {
    final item = _form.ingredients.firstWhere((item) => item.id == id);
    item.replacement ??= RecipeReplacementDraft(
      ingredientId: value.id,
      displayName: value.standardName,
    );
    item.replacement!
      ..ingredientId = value.id
      ..displayName = value.standardName;
    _replacementResults.remove(id);
    _changed();
  }

  void _addIngredient() {
    _form.ingredients.add(
      RecipeIngredientDraft(
        id: 'ingredient-${DateTime.now().microsecondsSinceEpoch}',
        displayName: '',
      ),
    );
    _changed();
  }

  void _deleteIngredient(int index) {
    if (_form.ingredients.length == 1) return;
    final removed = _form.ingredients.removeAt(index).id;
    for (final step in _form.steps) {
      step.ingredientIds.remove(removed);
    }
    _ingredientResults.remove(removed);
    _replacementResults.remove(removed);
    _changed();
  }

  void _moveIngredient(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _form.ingredients.length) return;
    final item = _form.ingredients.removeAt(index);
    _form.ingredients.insert(target, item);
    _changed();
  }

  void _addStep() {
    _form.steps.add(
      RecipeStepDraft(id: 'step-${DateTime.now().microsecondsSinceEpoch}'),
    );
    _changed();
  }

  void _deleteStep(int index) {
    if (_form.steps.length == 1) return;
    final removed = _form.steps.removeAt(index).id;
    for (final step in _form.steps) {
      step.dependsOn.remove(removed);
    }
    _changed();
  }

  void _moveStep(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _form.steps.length) return;
    final item = _form.steps.removeAt(index);
    _form.steps.insert(target, item);
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadFailed) {
      return Scaffold(
        body: _RecipeError(
          message: l10n.recipeLoadError,
          onRetry: () => setState(() {
            _loadFailed = false;
            _loading = true;
            unawaited(_load());
          }),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_loaded == null ? l10n.newRecipe : l10n.recipeContinueEdit),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          FilledButton(
            key: const ValueKey('save-recipe-button'),
            onPressed: _saving ? null : _save,
            child: Text(_saving ? l10n.recipeSaving : l10n.recipeSaveVersion),
          ),
          OutlinedButton(
            key: const ValueKey('discard-recipe-draft'),
            onPressed: () async {
              await _discardDraft();
              if (!context.mounted) return;
              context.pop();
            },
            child: Text(l10n.recipeDiscardDraftAction),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              key: const ValueKey('recipe-save-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          KeyedSubtree(
            key: ValueKey('recipe-info-$_editorRevision'),
            child: _RecipeInfoFields(form: _form, onChanged: _changed),
          ),
          const SizedBox(height: 20),
          RecipePhotoPanel(
            recipeId: _loaded?.id,
            onUploaded: (result) {
              if (_loaded == null) {
                _form.imageIds.add(result.id);
                _changed();
              }
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.recipeFood,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                l10n.recipeSteps,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final entry in _form.ingredients.indexed)
            _IngredientEditorCard(
              key: ValueKey(
                'recipe-ingredient-${entry.$2.id}-$_editorRevision',
              ),
              item: entry.$2,
              index: entry.$1,
              count: _form.ingredients.length,
              results: _ingredientResults[entry.$2.id] ?? const [],
              replacementResults: _replacementResults[entry.$2.id] ?? const [],
              searching: _searching['ingredient:${entry.$2.id}'] == true,
              replacementSearching:
                  _searching['replacement:${entry.$2.id}'] == true,
              onChanged: _changed,
              onSearch: () =>
                  _searchIngredient(entry.$2.id, replacement: false),
              onReplacementSearch: () =>
                  _searchIngredient(entry.$2.id, replacement: true),
              onSelect: (value) => _selectIngredient(entry.$2.id, value),
              onSelectReplacement: (value) =>
                  _selectReplacement(entry.$2.id, value),
              onDelete: () => _deleteIngredient(entry.$1),
              onMoveUp: () => _moveIngredient(entry.$1, -1),
              onMoveDown: () => _moveIngredient(entry.$1, 1),
            ),
          OutlinedButton.icon(
            key: const ValueKey('recipe-add-ingredient'),
            onPressed: _addIngredient,
            icon: const Icon(Icons.add),
            label: Text(l10n.recipeIngredientAdd),
          ),
          const SizedBox(height: 20),
          for (final entry in _form.steps.indexed)
            _StepEditorCard(
              key: ValueKey(
                'recipe-step-editor-${entry.$2.id}-$_editorRevision',
              ),
              item: entry.$2,
              index: entry.$1,
              count: _form.steps.length,
              ingredients: _form.ingredients,
              steps: _form.steps,
              onChanged: _changed,
              onDelete: () => _deleteStep(entry.$1),
              onMoveUp: () => _moveStep(entry.$1, -1),
              onMoveDown: () => _moveStep(entry.$1, 1),
            ),
          OutlinedButton.icon(
            key: const ValueKey('recipe-add-step'),
            onPressed: _addStep,
            icon: const Icon(Icons.add),
            label: Text(l10n.recipeStepAdd),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RecipeInfoFields extends StatelessWidget {
  const _RecipeInfoFields({required this.form, required this.onChanged});
  final RecipeForm form;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _text(
          key: const ValueKey('recipe-dish-name'),
          label: l10n.recipeName,
          value: form.dishName,
          onChanged: (value) {
            form.dishName = value.trim();
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _text(
          label: l10n.recipeAliases,
          value: form.aliases.join('，'),
          onChanged: (value) {
            form.aliases = _split(value);
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _number(
          label: l10n.recipeServings,
          value: form.servings,
          onChanged: (value) {
            form.servings = int.tryParse(value) ?? 0;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _text(
          label: l10n.recipeDifficulty,
          value: form.difficulty,
          onChanged: (value) {
            form.difficulty = value.trim();
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _text(
          label: l10n.recipeDishType,
          value: form.dishType,
          onChanged: (value) {
            form.dishType = value.trim();
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _text(
          label: l10n.recipeTags,
          value: form.tags.join('，'),
          onChanged: (value) {
            form.tags = _split(value);
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _number(
          label: l10n.recipeTotalTime,
          value: form.totalTimeSeconds,
          onChanged: (value) {
            form.totalTimeSeconds = int.tryParse(value) ?? 0;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _number(
          label: l10n.recipeActiveTime,
          value: form.activeTimeSeconds,
          onChanged: (value) {
            form.activeTimeSeconds = int.tryParse(value) ?? 0;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _text(
          label: l10n.recipeChangeNote,
          value: form.changeNote,
          onChanged: (value) {
            form.changeNote = value.trim();
            onChanged();
          },
        ),
      ],
    );
  }
}

class _IngredientEditorCard extends StatefulWidget {
  const _IngredientEditorCard({
    super.key,
    required this.item,
    required this.index,
    required this.count,
    required this.results,
    required this.replacementResults,
    required this.searching,
    required this.replacementSearching,
    required this.onChanged,
    required this.onSearch,
    required this.onReplacementSearch,
    required this.onSelect,
    required this.onSelectReplacement,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final RecipeIngredientDraft item;
  final int index;
  final int count;
  final List<IngredientDetail> results;
  final List<IngredientDetail> replacementResults;
  final bool searching;
  final bool replacementSearching;
  final VoidCallback onChanged;
  final VoidCallback onSearch;
  final VoidCallback onReplacementSearch;
  final ValueChanged<IngredientDetail> onSelect;
  final ValueChanged<IngredientDetail> onSelectReplacement;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  State<_IngredientEditorCard> createState() => _IngredientEditorCardState();
}

class _IngredientEditorCardState extends State<_IngredientEditorCard> {
  late final TextEditingController _displayController;

  RecipeIngredientDraft get item => widget.item;
  int get index => widget.index;
  int get count => widget.count;
  List<IngredientDetail> get results => widget.results;
  List<IngredientDetail> get replacementResults => widget.replacementResults;
  bool get searching => widget.searching;
  bool get replacementSearching => widget.replacementSearching;
  VoidCallback get onChanged => widget.onChanged;
  VoidCallback get onSearch => widget.onSearch;
  VoidCallback get onReplacementSearch => widget.onReplacementSearch;
  ValueChanged<IngredientDetail> get onSelect => widget.onSelect;
  ValueChanged<IngredientDetail> get onSelectReplacement =>
      widget.onSelectReplacement;
  VoidCallback get onDelete => widget.onDelete;
  VoidCallback get onMoveUp => widget.onMoveUp;
  VoidCallback get onMoveDown => widget.onMoveDown;

  @override
  void initState() {
    super.initState();
    _displayController = TextEditingController(text: item.displayName);
  }

  @override
  void didUpdateWidget(covariant _IngredientEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_displayController.text != item.displayName) {
      _displayController.value = TextEditingValue(
        text: item.displayName,
        selection: TextSelection.collapsed(offset: item.displayName.length),
      );
    }
  }

  @override
  void dispose() {
    _displayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = item.id;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('${index + 1}. ${l10n.recipeFood}')),
                IconButton(
                  key: ValueKey('recipe-move-ingredient-up-$id'),
                  tooltip: l10n.recipeIngredientMoveUp,
                  onPressed: index == 0 ? null : onMoveUp,
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  key: ValueKey('recipe-move-ingredient-down-$id'),
                  tooltip: l10n.recipeIngredientMoveDown,
                  onPressed: index == count - 1 ? null : onMoveDown,
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  key: ValueKey('recipe-delete-ingredient-$id'),
                  tooltip: l10n.recipeIngredientDelete,
                  onPressed: count == 1 ? null : onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            _text(
              key: _ingredientKey(id, 'search'),
              label: l10n.recipeSearchStandard,
              value: item.displayName,
              controller: _displayController,
              onChanged: (value) {
                final hadStandardId = item.ingredientId != null;
                item.displayName = value;
                if (hadStandardId) item.ingredientId = null;
                onChanged();
              },
              suffixIcon: IconButton(
                key: _ingredientKey(id, 'search-button'),
                onPressed: searching ? null : onSearch,
                icon: searching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
              ),
            ),
            if (item.ingredientId == null)
              _SmallHint(text: l10n.recipeUnknownIngredient),
            for (final result in results)
              ListTile(
                key: ValueKey('ingredient-result-${result.id}-$id'),
                dense: true,
                title: Text(result.standardName),
                subtitle: Text(result.aliases.join('、')),
                onTap: () => onSelect(result),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _number(
                    key: _ingredientKey(id, 'quantity'),
                    label: l10n.recipeQuantity,
                    value: item.quantity,
                    onChanged: (value) {
                      item.quantity = double.tryParse(value) ?? 0;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _text(
                    key: _ingredientKey(id, 'unit'),
                    label: l10n.recipeUnit,
                    value: item.unit,
                    onChanged: (value) {
                      item.unit = value;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _text(
              key: _ingredientKey(id, 'preparation'),
              label: l10n.recipePreparationGroup,
              value: item.preparation,
              onChanged: (value) {
                item.preparation = value;
                onChanged();
              },
            ),
            ExpansionTile(
              key: ValueKey('recipe-ingredient-advanced-$id'),
              title: Text(l10n.recipeStandardIngredient),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _number(
                        key: ValueKey('recipe-ingredient-base-quantity-$id'),
                        label: l10n.recipeBaseQuantity,
                        value: item.baseQuantity,
                        onChanged: (value) {
                          item.baseQuantity = double.tryParse(value) ?? 0;
                          onChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _text(
                        key: ValueKey('recipe-ingredient-base-unit-$id'),
                        label: l10n.recipeBaseUnit,
                        value: item.baseUnit,
                        onChanged: (value) {
                          item.baseUnit = value;
                          onChanged();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _text(
                  key: ValueKey('recipe-ingredient-group-$id'),
                  label: l10n.recipeIngredientGroup,
                  value: item.group,
                  onChanged: (value) {
                    item.group = value;
                    onChanged();
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<RecipeIngredientScalingModeEnum>(
                  key: ValueKey('recipe-ingredient-scaling-$id'),
                  initialValue: item.scalingMode,
                  decoration: InputDecoration(
                    labelText: l10n.recipeScalingMode,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: RecipeIngredientScalingModeEnum.proportional,
                      child: Text(l10n.recipeScalingProportional),
                    ),
                    DropdownMenuItem(
                      value: RecipeIngredientScalingModeEnum.unchanged,
                      child: Text(l10n.recipeScalingUnchanged),
                    ),
                    DropdownMenuItem(
                      value: RecipeIngredientScalingModeEnum.round,
                      child: Text(l10n.recipeScalingRound),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    item.scalingMode = value;
                    onChanged();
                  },
                ),
                CheckboxListTile(
                  key: ValueKey('recipe-ingredient-optional-$id'),
                  value: item.optional,
                  title: Text(l10n.recipeOptionalToggle),
                  onChanged: (value) {
                    item.optional = value == true;
                    onChanged();
                  },
                ),
                CheckboxListTile(
                  key: ValueKey('recipe-ingredient-functional-$id'),
                  value: item.functional,
                  title: Text(l10n.recipeFunctionalToggle),
                  onChanged: (value) {
                    item.functional = value == true;
                    onChanged();
                  },
                ),
                const SizedBox(height: 8),
                _ReplacementEditor(
                  item: item,
                  results: replacementResults,
                  searching: replacementSearching,
                  onChanged: onChanged,
                  onSearch: onReplacementSearch,
                  onSelect: onSelectReplacement,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplacementEditor extends StatelessWidget {
  const _ReplacementEditor({
    required this.item,
    required this.results,
    required this.searching,
    required this.onChanged,
    required this.onSearch,
    required this.onSelect,
  });

  final RecipeIngredientDraft item;
  final List<IngredientDetail> results;
  final bool searching;
  final VoidCallback onChanged;
  final VoidCallback onSearch;
  final ValueChanged<IngredientDetail> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final replacement = item.replacement;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.recipeReplacement,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _text(
          key: ValueKey('recipe-replacement-name-${item.id}'),
          label: l10n.recipeReplacementSearch,
          value: replacement?.displayName ?? '',
          onChanged: (value) {
            item.replacement ??= RecipeReplacementDraft(
              ingredientId: '',
              displayName: value,
            );
            item.replacement!.displayName = value;
            if (item.replacement!.ingredientId?.isNotEmpty == true) {
              item.replacement!.ingredientId = null;
            }
            onChanged();
          },
          suffixIcon: IconButton(
            key: ValueKey('recipe-search-replacement-${item.id}'),
            onPressed: searching ? null : onSearch,
            icon: searching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
          ),
        ),
        for (final result in results)
          ListTile(
            key: ValueKey('replacement-result-${result.id}-${item.id}'),
            dense: true,
            title: Text(result.standardName),
            onTap: () => onSelect(result),
          ),
        if (replacement != null) ...[
          const SizedBox(height: 8),
          _number(
            key: ValueKey('recipe-replacement-ratio-${item.id}'),
            label: l10n.recipeReplacementRatio,
            value: replacement.ratio,
            onChanged: (value) {
              replacement.ratio = double.tryParse(value) ?? 1;
              onChanged();
            },
          ),
          const SizedBox(height: 8),
          _text(
            key: ValueKey('recipe-replacement-note-${item.id}'),
            label: l10n.recipeReplacementNote,
            value: replacement.note,
            onChanged: (value) {
              replacement.note = value;
              onChanged();
            },
          ),
        ],
      ],
    );
  }
}

class _StepEditorCard extends StatelessWidget {
  const _StepEditorCard({
    super.key,
    required this.item,
    required this.index,
    required this.count,
    required this.ingredients,
    required this.steps,
    required this.onChanged,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final RecipeStepDraft item;
  final int index;
  final int count;
  final List<RecipeIngredientDraft> ingredients;
  final List<RecipeStepDraft> steps;
  final VoidCallback onChanged;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = item.id;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('${index + 1}. ${l10n.recipeSteps}')),
                IconButton(
                  key: ValueKey('recipe-move-step-up-$id'),
                  tooltip: l10n.recipeStepMoveUp,
                  onPressed: index == 0 ? null : onMoveUp,
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  key: ValueKey('recipe-move-step-down-$id'),
                  tooltip: l10n.recipeStepMoveDown,
                  onPressed: index == count - 1 ? null : onMoveDown,
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  key: ValueKey('recipe-delete-step-$id'),
                  tooltip: l10n.recipeStepDelete,
                  onPressed: count == 1 ? null : onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            _text(
              key: ValueKey('recipe-step-action-$id'),
              label: l10n.recipeStepAction,
              value: item.action,
              onChanged: (value) {
                item.action = value;
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            _text(
              key: _stepKey(id, 'instruction'),
              label: l10n.recipeInstruction,
              value: item.instruction,
              maxLines: 3,
              onChanged: (value) {
                item.instruction = value;
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            Text(l10n.recipeStepIngredientRefs),
            for (final ingredient in ingredients)
              CheckboxListTile(
                key: ValueKey('recipe-step-ref-$id-${ingredient.id}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: item.ingredientIds.contains(ingredient.id),
                title: Text(
                  ingredient.displayName.isEmpty
                      ? l10n.recipeUnknownIngredient
                      : ingredient.displayName,
                ),
                onChanged: (value) {
                  if (value == true) {
                    if (!item.ingredientIds.contains(ingredient.id)) {
                      item.ingredientIds.add(ingredient.id);
                    }
                  } else {
                    item.ingredientIds.remove(ingredient.id);
                  }
                  onChanged();
                },
              ),
            Row(
              children: [
                Expanded(
                  child: _number(
                    key: ValueKey('recipe-step-duration-$id'),
                    label: l10n.recipeStepDuration,
                    value: item.durationSeconds,
                    onChanged: (value) {
                      item.durationSeconds = int.tryParse(value) ?? 0;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _number(
                    key: ValueKey('recipe-step-temperature-$id'),
                    label: l10n.recipeStepTemperature,
                    value: item.temperatureCelsius,
                    onChanged: (value) {
                      item.temperatureCelsius = double.tryParse(value) ?? 0;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _text(
              key: ValueKey('recipe-step-heat-$id'),
              label: l10n.recipeStepHeat,
              value: item.heat,
              onChanged: (value) {
                item.heat = value;
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            _text(
              key: ValueKey('recipe-step-cookware-$id'),
              label: l10n.recipeStepCookware,
              value: item.cookware,
              onChanged: (value) {
                item.cookware = value;
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            _text(
              key: ValueKey('recipe-step-doneness-$id'),
              label: l10n.recipeStepDoneness,
              value: item.doneness,
              onChanged: (value) {
                item.doneness = value;
                onChanged();
              },
            ),
            CheckboxListTile(
              key: ValueKey('recipe-step-unattended-$id'),
              contentPadding: EdgeInsets.zero,
              value: item.unattended,
              title: Text(l10n.recipeStepUnattended),
              onChanged: (value) {
                item.unattended = value == true;
                onChanged();
              },
            ),
            Text(l10n.recipeStepDepends),
            for (final previous in steps.where((step) => step.id != item.id))
              CheckboxListTile(
                key: ValueKey('recipe-step-depends-$id-${previous.id}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: item.dependsOn.contains(previous.id),
                title: Text(
                  previous.instruction.isEmpty
                      ? l10n.recipeCompleteStep
                      : previous.instruction,
                ),
                onChanged: (value) {
                  if (value == true) {
                    if (!item.dependsOn.contains(previous.id)) {
                      item.dependsOn.add(previous.id);
                    }
                  } else {
                    item.dependsOn.remove(previous.id);
                  }
                  onChanged();
                },
              ),
            const SizedBox(height: 8),
            _text(
              key: ValueKey('recipe-step-notes-$id'),
              label: l10n.recipeStepNotes,
              value: item.notes,
              maxLines: 2,
              onChanged: (value) {
                item.notes = value;
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            _text(
              key: _stepKey(id, 'why'),
              label: l10n.recipeStepWhy,
              value: item.why,
              maxLines: 2,
              onChanged: (value) {
                item.why = value;
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeDetailPage extends ConsumerStatefulWidget {
  const RecipeDetailPage({super.key, required this.recipeId, this.versionId});

  final String recipeId;
  final String? versionId;

  @override
  ConsumerState<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends ConsumerState<RecipeDetailPage> {
  RecipeDetail? _detail;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(recipeRepositoryProvider);
      _detail = widget.versionId == null
          ? await repo.get(widget.recipeId)
          : await repo.getVersion(widget.recipeId, widget.versionId!);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'not_found');
      }
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recipeDeleteConfirmTitle),
        content: Text(l10n.recipeDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.recipeCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.recipeDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(recipeRepositoryProvider).delete(widget.recipeId);
    if (!mounted) return;
    ref.invalidate(myRecipesProvider);
    context.go(RecipeListPage.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_error != null) {
      return Scaffold(body: Center(child: Text(l10n.recipeNotFound)));
    }
    final detail = _detail;
    if (detail == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final snapshot = detail.version.snapshot;
    final derived = detail.version.derived;
    final groups = <String, List<RecipeIngredient>>{};
    for (final ingredient in snapshot.ingredients ?? const []) {
      groups.putIfAbsent(ingredient.group, () => []).add(ingredient);
    }
    final Map<String, String> ingredientNames = {
      for (final ingredient
          in snapshot.ingredients ?? const <RecipeIngredient>[])
        ingredient.id: ingredient.displayName,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(detail.dish.name),
        actions: [
          IconButton(
            key: const ValueKey('recipe-history-button'),
            tooltip: l10n.recipeHistory,
            icon: const Icon(Icons.history),
            onPressed: () =>
                context.push('/recipes/${widget.recipeId}/history'),
          ),
          if (widget.versionId == null)
            IconButton(
              key: const ValueKey('edit-recipe-button'),
              tooltip: l10n.recipeEditAction,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/recipes/${widget.recipeId}/edit'),
            )
          else
            IconButton(
              key: const ValueKey('edit-old-recipe-button'),
              tooltip: l10n.recipeBaseOnVersion,
              icon: const Icon(Icons.edit_note),
              onPressed: () => context.push(
                '/recipes/${widget.recipeId}/edit?versionId=${widget.versionId}',
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _RecipePhotoDisplay(images: detail.version.images),
          if (widget.versionId == null)
            RecipePhotoPanel(
              recipeId: widget.recipeId,
              onUploaded: (_) => _load(),
            ),
          Text(
            detail.dish.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            detail.author.nickname,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(
                  l10n.recipeAuthorVersion(
                    detail.version.versionNumber,
                    snapshot.servings,
                  ),
                ),
              ),
              Chip(
                label: Text(
                  l10n.recipeDuration(
                    _minutes(derived.totalTimeSeconds),
                    _minutes(derived.activeTimeSeconds),
                  ),
                ),
              ),
              if (snapshot.difficulty?.isNotEmpty == true)
                Chip(
                  label: Text(l10n.recipeDifficultyValue(snapshot.difficulty!)),
                ),
              if (snapshot.dishType?.isNotEmpty == true)
                Chip(label: Text(l10n.recipeDishTypeValue(snapshot.dishType!))),
              for (final tag in snapshot.tags ?? const [])
                Chip(label: Text(tag)),
            ],
          ),
          const SizedBox(height: 16),
          if ((derived.allergens ?? const []).isNotEmpty)
            _InfoSection(
              title: l10n.recipeAllergens(
                (derived.allergens ?? const []).join('、'),
                derived.allergensIncomplete == true
                    ? l10n.recipeIncomplete
                    : '',
              ),
            ),
          _NutritionSection(nutrition: derived.nutritionPerServing),
          if ((derived.cookware ?? const []).isNotEmpty)
            Text(l10n.recipeCookware((derived.cookware ?? const []).join('、'))),
          const SizedBox(height: 20),
          Text(
            l10n.recipeIngredients,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (groups.isEmpty) Text(l10n.recipeNoIngredients),
          for (final entry in groups.entries) ...[
            const SizedBox(height: 8),
            Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
            for (final ingredient in entry.value)
              _IngredientDetailRow(ingredient: ingredient),
          ],
          const SizedBox(height: 20),
          Text(
            l10n.recipeStepsTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if ((snapshot.steps ?? const []).isEmpty) Text(l10n.recipeNoSteps),
          for (final (index, step) in (snapshot.steps ?? const []).indexed)
            _StepDetailTile(
              index: index,
              step: step,
              ingredientNames: ingredientNames,
              l10n: l10n,
            ),
          const SizedBox(height: 16),
          if (widget.versionId == null)
            TextButton(
              key: const ValueKey('delete-recipe-button'),
              onPressed: _delete,
              child: Text(l10n.recipeDelete),
            ),
        ],
      ),
    );
  }
}

class _RecipePhotoDisplay extends StatelessWidget {
  const _RecipePhotoDisplay({this.images});
  final List<RecipeImageOut>? images;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final image = images?.firstOrNull;
    if (image == null) {
      return Container(
        height: 160,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(l10n.recipeImagePlaceholder),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        image.url,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          height: 160,
          alignment: Alignment.center,
          child: Text(l10n.recipeImagePlaceholder),
        ),
      ),
    );
  }
}

class _IngredientDetailRow extends StatelessWidget {
  const _IngredientDetailRow({required this.ingredient});
  final RecipeIngredient ingredient;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quantity = '${ingredient.quantity} ${ingredient.unit}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Expanded(
            child: Text(
              ingredient.displayName.isEmpty
                  ? l10n.recipeUnknownIngredient
                  : ingredient.displayName,
            ),
          ),
          SourceMark(
            sourceType:
                ingredient.quantitySource?.source_.value ??
                sourceTypeAuthorFilled,
            componentId: 'recipe-ingredient-${ingredient.id}-quantity',
            value: quantity,
            originalValue: ingredient.quantitySource?.original,
            basisText:
                ingredient.quantitySource?.basis ??
                l10n.recipeSourceAuthorFilled,
            required: true,
            onAction: (_) {},
          ),
        ],
      ),
      subtitle: Text(
        [
          quantity,
          if (ingredient.preparation?.isNotEmpty == true)
            ingredient.preparation!,
          if (ingredient.optional == true) l10n.recipeOptional,
          if (ingredient.functional == true) l10n.recipeFunctionalToggle,
          if (_replacementLabel(ingredient.replacement).isNotEmpty)
            '${l10n.recipeReplacement}：${_replacementLabel(ingredient.replacement)}',
        ].join(' · '),
      ),
    );
  }
}

class _StepDetailTile extends StatelessWidget {
  const _StepDetailTile({
    required this.index,
    required this.step,
    required this.ingredientNames,
    required this.l10n,
  });

  final int index;
  final RecipeStep step;
  final Map<String, String> ingredientNames;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final references = (step.ingredientIds ?? const [])
        .map((id) => ingredientNames[id])
        .whereType<String>()
        .join('、');
    final details = [
      if (references.isNotEmpty) '${l10n.recipeStepIngredientRefs}：$references',
      if ((step.durationSeconds ?? 0) > 0)
        l10n.recipeSeconds(step.durationSeconds ?? 0),
      if (step.unattended == true) l10n.recipeStepUnattended,
      if (step.heat?.isNotEmpty == true) '${l10n.recipeStepHeat}：${step.heat}',
      if ((step.temperatureCelsius ?? 0) != 0)
        '${l10n.recipeStepTemperature}：${step.temperatureCelsius}',
      if (step.cookware?.isNotEmpty == true)
        '${l10n.recipeStepCookware}：${step.cookware}',
      if (step.doneness?.isNotEmpty == true)
        '${l10n.recipeStepDoneness}：${step.doneness}',
      if ((step.dependsOn ?? const []).isNotEmpty)
        '${l10n.recipeStepDepends}：${step.dependsOn!.join('、')}',
    ].join(' · ');
    return ExpansionTile(
      key: ValueKey('recipe-step-$index'),
      title: Text('${index + 1}. ${step.instruction}'),
      subtitle: Text(
        details.isEmpty
            ? (step.action ?? '')
            : '${step.action ?? ''} · $details',
      ),
      children: [
        if (step.notes?.isNotEmpty == true)
          ListTile(
            title: Text(l10n.recipeStepNotes),
            subtitle: Text(step.notes!),
          ),
        if (step.why?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: WhyPanel(
              sourceType: sourceTypeAuthorFilled,
              value: step.why!,
              basisText: l10n.recipeStepWhy,
              required: true,
            ),
          ),
      ],
    );
  }
}

class _NutritionSection extends StatelessWidget {
  const _NutritionSection({required this.nutrition});
  final NutritionEstimate? nutrition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (nutrition == null) return Text(l10n.recipeNoNutrition);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        l10n.recipeNutritionValues(
          _decimal(nutrition!.energyKcal),
          _decimal(nutrition!.proteinG),
          _decimal(nutrition!.fatG),
          _decimal(nutrition!.carbohydrateG),
          _decimal(nutrition!.sodiumMg),
          nutrition!.incomplete == true ? l10n.recipeIncomplete : '',
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Text(title);
}

class RecipeHistoryPage extends ConsumerStatefulWidget {
  const RecipeHistoryPage({super.key, required this.recipeId});
  final String recipeId;

  @override
  ConsumerState<RecipeHistoryPage> createState() => _RecipeHistoryPageState();
}

class _RecipeHistoryPageState extends ConsumerState<RecipeHistoryPage> {
  late Future<RecipeVersionHistory> _future;

  Future<RecipeVersionHistory> _load() =>
      ref.read(recipeRepositoryProvider).history(widget.recipeId);

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recipeHistory)),
      body: FutureBuilder<RecipeVersionHistory>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _RecipeError(
              message: l10n.recipeLoadError,
              onRetry: () => setState(() {
                _future = _load();
              }),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!.items;
          if (items.isEmpty) return Center(child: Text(l10n.recipeNoHistory));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                key: ValueKey('recipe-version-${item.versionNumber}'),
                title: Text(
                  l10n.recipeVersionTitle(
                    item.versionNumber,
                    item.aiAssisted ? l10n.recipeAiAssisted : '',
                  ),
                ),
                subtitle: Text(
                  '${item.changeNote.isEmpty ? l10n.recipeNoChangeNote : item.changeNote}\n${l10n.recipeVersionDate(_formatDate(item.createdAt))}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  '/recipes/${widget.recipeId}/versions/${item.id}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SmallHint extends StatelessWidget {
  const _SmallHint({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

class _RecipeError extends StatelessWidget {
  const _RecipeError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        TextButton(
          onPressed: onRetry,
          child: Text(AppLocalizations.of(context).recipeRetry),
        ),
      ],
    ),
  );
}

Key _ingredientKey(String id, String field) {
  if (id == 'ingredient-1') {
    return ValueKey(
      field == 'search-button'
          ? 'recipe-search-ingredient'
          : 'recipe-ingredient-$field',
    );
  }
  return ValueKey(
    field == 'search-button'
        ? 'recipe-search-ingredient-$id'
        : 'recipe-ingredient-$field-$id',
  );
}

Key _stepKey(String id, String field) =>
    ValueKey(id == 'step-1' ? 'recipe-step-$field' : 'recipe-step-$field-$id');

Widget _text({
  Key? key,
  required String label,
  required String value,
  required ValueChanged<String> onChanged,
  TextEditingController? controller,
  Widget? suffixIcon,
  int maxLines = 1,
}) => TextFormField(
  key: key,
  controller: controller,
  initialValue: controller == null ? value : null,
  maxLines: maxLines,
  onChanged: onChanged,
  decoration: InputDecoration(
    labelText: label,
    border: const OutlineInputBorder(),
    suffixIcon: suffixIcon,
  ),
);

Widget _number({
  Key? key,
  required String label,
  required num value,
  required ValueChanged<String> onChanged,
}) => _text(
  key: key,
  label: label,
  value: value.toString(),
  onChanged: onChanged,
);

List<String> _split(String value) => value
    .split(RegExp(r'[,，]'))
    .map((item) => item.trim())
    .where((item) => item.isNotEmpty)
    .toList();

int _minutes(int? seconds) => ((seconds ?? 0) / 60).ceil();
String _decimal(num? value) => (value ?? 0).toStringAsFixed(1);
String _formatDate(String value) =>
    value.replaceFirst('T', ' ').split('.').first;
String _replacementLabel(Object? value) {
  if (value is RecipeReplacement) {
    return '${value.displayName} × ${(value.ratio ?? 1)}';
  }
  if (value is Map) {
    final display = value['display_name'];
    if (display is String && display.isNotEmpty) {
      return '$display × ${value['ratio'] ?? 1}';
    }
  }
  return '';
}

String _message(Object error) =>
    error.toString().replaceFirst('Exception: ', '');
