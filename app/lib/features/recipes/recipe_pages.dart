import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../ingredients/ingredient_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/permissions.dart';
import '../../storage/local_store.dart';
import '../../widgets/empty_state.dart';
import '../../recipes/recipe_draft.dart';
import '../../recipes/recipe_repository.dart';

final myRecipesProvider = FutureProvider.autoDispose<RecipeList>((ref) async {
  final userId = ref.watch(apiClientProvider);
  // AuthInterceptor supplies the current account; this provider is invalidated
  // by route changes and after save/delete from the pages below.
  return RecipeRepository(userId).list();
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
                footer: FilledButton.icon(
                  key: const ValueKey('new-recipe-button'),
                  onPressed: () => context.push(RecipeEditorPage.path),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.newRecipe),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(myRecipesProvider),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('new-recipe-button'),
                      onPressed: () => context.push(RecipeEditorPage.path),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.newRecipe),
                    ),
                    const SizedBox(height: 12),
                    for (final item in page.items)
                      Card(
                        child: ListTile(
                          key: ValueKey('recipe-card-${item.id}'),
                          title: Text(item.dish.name),
                          subtitle: Text(
                            '第 ${item.versionNumber} 版 · ${item.servings} 份 · ${_minutes(item.totalTimeSeconds)} 分钟',
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

class RecipeEditorPage extends ConsumerStatefulWidget {
  const RecipeEditorPage({super.key, this.recipeId, this.versionId});

  static const path = '/recipes/new';
  final String? recipeId;
  final String? versionId;

  @override
  ConsumerState<RecipeEditorPage> createState() => _RecipeEditorPageState();
}

class _RecipeEditorPageState extends ConsumerState<RecipeEditorPage> {
  late final TextEditingController _dish;
  late final TextEditingController _ingredient;
  late final TextEditingController _quantity;
  late final TextEditingController _unit;
  late final TextEditingController _preparation;
  late final TextEditingController _step;
  late final TextEditingController _why;
  late final TextEditingController _note;
  late RecipeForm _form;
  RecipeDetail? _loaded;
  RecipeDraft? _draft;
  String? _error;
  bool _loading = true;
  bool _saving = false;
  Timer? _draftTimer;
  List<IngredientDetail> _ingredientResults = const [];

  String get _recipeKey => widget.recipeId ?? 'new';

  @override
  void initState() {
    super.initState();
    _form = RecipeForm(dishName: '');
    _dish = TextEditingController();
    _ingredient = TextEditingController();
    _quantity = TextEditingController(text: '0');
    _unit = TextEditingController(text: 'g');
    _preparation = TextEditingController();
    _step = TextEditingController();
    _why = TextEditingController();
    _note = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.recipeId != null) {
        _loaded = await ref
            .read(recipeRepositoryProvider)
            .get(widget.recipeId!);
        _form = _formFromSnapshot(
          _loaded!.version.snapshot,
          _loaded!.dish.name,
        );
      }
      _draft = RecipeDraftStore(ref.read(localStoreProvider))
          .read(recipeKey: _recipeKey, baselineVersionId: _loaded?.version.id);
      if (_draft != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _askRestore());
      }
      _syncControllers();
    } catch (error) {
      _error = '菜谱加载失败';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  RecipeForm _formFromSnapshot(RecipeSnapshot snapshot, String name) {
    final ingredient = snapshot.ingredients?.firstOrNull;
    final step = snapshot.steps?.firstOrNull;
    return RecipeForm(
      dishName: name,
      servings: snapshot.servings,
      difficulty: snapshot.difficulty,
      dishType: snapshot.dishType,
      ingredientName: ingredient?.displayName ?? '',
      ingredientQuantity: ingredient?.quantity.toDouble() ?? 0,
      ingredientUnit: ingredient?.unit ?? 'g',
      preparation: ingredient?.preparation ?? '',
      ingredientGroup: ingredient?.group ?? '主料',
      stepInstruction: step?.instruction ?? '',
      stepDurationSeconds: step?.durationSeconds ?? 0,
      stepAction: step?.action ?? '炒',
      stepWhy: step?.why ?? '',
    );
  }

  void _syncControllers() {
    _dish.text = _form.dishName;
    _ingredient.text = _form.ingredientName;
    _quantity.text = _form.ingredientQuantity == 0
        ? ''
        : _form.ingredientQuantity.toString();
    _unit.text = _form.ingredientUnit;
    _preparation.text = _form.preparation;
    _step.text = _form.stepInstruction;
    _why.text = _form.stepWhy;
    _note.text = _form.changeNote;
  }

  Future<void> _askRestore() async {
    final l10n = AppLocalizations.of(context);
    if (!mounted || _draft == null) return;
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
      _form = RecipeForm.fromDraft(_draft!.payload);
      _syncControllers();
    } else {
      await RecipeDraftStore(ref.read(localStoreProvider)).discard(_recipeKey);
    }
  }

  void _changed() {
    _form
      ..dishName = _dish.text.trim()
      ..ingredientName = _ingredient.text.trim()
      ..ingredientQuantity = double.tryParse(_quantity.text) ?? 0
      ..ingredientUnit = _unit.text.trim().isEmpty ? 'g' : _unit.text.trim()
      ..preparation = _preparation.text.trim()
      ..stepInstruction = _step.text.trim()
      ..stepWhy = _why.text.trim()
      ..changeNote = _note.text.trim();
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 250), () {
      unawaited(
        RecipeDraftStore(ref.read(localStoreProvider)).save(
          RecipeDraft(
            recipeKey: _recipeKey,
            baselineVersionId: _loaded?.version.id,
            payload: _form.toDraft(),
          ),
        ),
      );
    });
    setState(() {});
  }

  Future<void> _searchIngredients() async {
    final query = _ingredient.text.trim();
    if (query.isEmpty) return;
    final results = await ref.read(ingredientRepositoryProvider).search(query);
    if (mounted) setState(() => _ingredientResults = results);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    _changed();
    if (_form.dishName.isEmpty) {
      setState(() => _error = l10n.recipeDishRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(recipeRepositoryProvider);
      final detail = _loaded == null
          ? await repo.create(_form)
          : await repo.saveVersion(
              widget.recipeId!,
              _form,
              baseVersionId: widget.versionId,
            );
      await RecipeDraftStore(ref.read(localStoreProvider)).discard(_recipeKey);
      if (!mounted) return;
      context.go('/recipes/${detail.id}');
    } catch (error) {
      if (mounted) {
        setState(() => _error = l10n.recipeSaveFailed(_message(error)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    for (final controller in [
      _dish,
      _ingredient,
      _quantity,
      _unit,
      _preparation,
      _step,
      _why,
      _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_loaded == null ? l10n.newRecipe : l10n.recipeContinueEdit),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          TextField(
            key: const ValueKey('recipe-dish-name'),
            controller: _dish,
            onChanged: (_) => _changed(),
            decoration: InputDecoration(
              labelText: l10n.recipeName,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.recipeFood, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('recipe-ingredient-search'),
            controller: _ingredient,
            onChanged: (_) => _changed(),
            decoration: InputDecoration(
              labelText: l10n.recipeSearchOrFill,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                key: const ValueKey('recipe-search-ingredient'),
                onPressed: _searchIngredients,
                icon: const Icon(Icons.search),
              ),
            ),
          ),
          for (final result in _ingredientResults)
            ListTile(
              key: ValueKey('ingredient-result-${result.id}'),
              title: Text(result.standardName),
              subtitle: Text(result.aliases.join('、')),
              onTap: () {
                _ingredient.text = result.standardName;
                _changed();
                setState(() => _ingredientResults = const []);
              },
            ),
          TextField(
            key: const ValueKey('recipe-ingredient-quantity'),
            controller: _quantity,
            keyboardType: TextInputType.number,
            onChanged: (_) => _changed(),
            decoration: InputDecoration(
              labelText: l10n.recipeQuantity,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('recipe-ingredient-unit'),
            controller: _unit,
            onChanged: (_) => _changed(),
            decoration: InputDecoration(
              labelText: l10n.recipeUnit,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('recipe-ingredient-preparation'),
            controller: _preparation,
            onChanged: (_) => _changed(),
            decoration: InputDecoration(
              labelText: l10n.recipePreparationGroup,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.recipeSteps, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('recipe-step-instruction'),
            controller: _step,
            maxLines: 3,
            onChanged: (_) => _changed(),
            decoration: InputDecoration(
              labelText: l10n.recipeInstruction,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('recipe-step-why'),
            controller: _why,
            maxLines: 2,
            onChanged: (_) => _changed(),
            decoration: InputDecoration(
              labelText: l10n.recipeWhy,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('recipe-change-note'),
            controller: _note,
            onChanged: (_) => _changed(),
            decoration: InputDecoration(
              labelText: l10n.recipeChangeNote,
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              key: const ValueKey('recipe-save-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            key: const ValueKey('save-recipe-button'),
            onPressed: _saving ? null : _save,
            child: Text(_saving ? l10n.recipeSaving : l10n.recipeSaveVersion),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const ValueKey('discard-recipe-draft'),
            onPressed: () async {
              final router = GoRouter.of(context);
              await RecipeDraftStore(ref.read(localStoreProvider))
                  .discard(_recipeKey);
              if (!mounted) return;
              router.pop();
            },
            child: Text(l10n.recipeDiscardDraftAction),
          ),
        ],
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
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(recipeRepositoryProvider);
      _detail = await repo.get(widget.recipeId);
      if (widget.versionId != null) {
        _detail = await repo.getVersion(widget.recipeId, widget.versionId!);
      }
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) setState(() => _error = '菜谱不存在或你没有权限查看');
    }
  }

  Future<void> _delete() async {
    await ref.read(recipeRepositoryProvider).delete(widget.recipeId);
    if (!mounted) return;
    context.go(RecipeListPage.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = _detail;
    if (_error != null) {
      return Scaffold(body: Center(child: Text(l10n.recipeNotFound)));
    }
    if (detail == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final snapshot = detail.version.snapshot;
    final derived = detail.version.derived;
    return Scaffold(
      appBar: AppBar(
        title: Text(detail.dish.name),
        actions: [
          if (widget.versionId == null)
            IconButton(
              key: const ValueKey('edit-recipe-button'),
              tooltip: l10n.recipeEditAction,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/recipes/${widget.recipeId}/edit'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            detail.author.nickname,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.recipeAuthorVersion(
              detail.version.versionNumber,
              snapshot.servings,
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            l10n.recipeDuration(
              _minutes(derived.totalTimeSeconds),
              _minutes(derived.activeTimeSeconds),
            ),
          ),
          if ((derived.allergens ?? const []).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.recipeAllergens(
                (derived.allergens ?? const []).join('、'),
                derived.allergensIncomplete == true
                    ? l10n.recipeIncomplete
                    : '',
              ),
            ),
          ],
          if (derived.nutritionPerServing != null)
            Text(
              l10n.recipeNutrition(
                detail.version.derived.nutritionPerServing!.incomplete == true
                    ? l10n.recipeIncomplete
                    : '',
              ),
            ),
          const SizedBox(height: 20),
          Text(l10n.recipeFood, style: Theme.of(context).textTheme.titleLarge),
          for (final ingredient in snapshot.ingredients ?? const [])
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(ingredient.displayName),
              subtitle: Text(
                '${ingredient.quantity} ${ingredient.unit}${ingredient.preparation.isEmpty ? '' : ' · ${ingredient.preparation}'}',
              ),
              trailing: ingredient.optional == true
                  ? Text(l10n.recipeOptional)
                  : null,
            ),
          Text(l10n.recipeSteps, style: Theme.of(context).textTheme.titleLarge),
          for (final (index, step) in (snapshot.steps ?? const []).indexed)
            ExpansionTile(
              key: ValueKey('recipe-step-$index'),
              title: Text('${index + 1}. ${step.instruction}'),
              subtitle: Text(
                '${step.action} · ${l10n.recipeSeconds(step.durationSeconds ?? 0)}',
              ),
              children: [
                if (step.why.isNotEmpty)
                  _RationalePanel(why: step.why, title: l10n.recipeRationale),
                if (step.notes.isNotEmpty)
                  ListTile(
                    title: Text(l10n.recipeKeyPoint),
                    subtitle: Text(step.notes),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('recipe-image-permission'),
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(l10n.recipeAddPhoto),
            onPressed: () => _requestPhotoPermission(context),
          ),
          OutlinedButton.icon(
            key: const ValueKey('recipe-camera-permission'),
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(l10n.recipeTakePhoto),
            onPressed: () => _requestCameraPermission(context),
          ),
          TextButton(
            key: const ValueKey('recipe-history-button'),
            onPressed: () =>
                context.push('/recipes/${widget.recipeId}/history'),
            child: Text(l10n.recipeHistory),
          ),
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

  Future<void> _requestCameraPermission(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final state = await ref
        .read(permissionServiceProvider)
        .request(AppPermission.camera);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          state == PermissionState.granted
              ? l10n.recipeCameraAvailable
              : l10n.recipeCameraDenied,
        ),
      ),
    );
  }

  Future<void> _requestPhotoPermission(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final state = await ref
        .read(permissionServiceProvider)
        .request(AppPermission.photos);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          state == PermissionState.granted
              ? l10n.recipePhotoAvailable
              : l10n.recipePhotoDenied,
        ),
      ),
    );
  }
}

class RecipeHistoryPage extends ConsumerWidget {
  const RecipeHistoryPage({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recipeHistory)),
      body: FutureBuilder<RecipeVersionHistory>(
        future: ref.read(recipeRepositoryProvider).history(recipeId),
        builder: (context, snapshot) {
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
                    item.aiAssisted == true ? l10n.recipeAi : '',
                  ),
                ),
                subtitle: Text(
                  item.changeNote.isEmpty
                      ? l10n.recipeNoChangeNote
                      : item.changeNote,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push('/recipes/$recipeId/versions/${item.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _RationalePanel extends StatelessWidget {
  const _RationalePanel({required this.why, required this.title});
  final String why;
  final String title;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title),
    subtitle: Text(why),
    leading: const Icon(Icons.lightbulb_outline),
  );
}

class _RecipeError extends StatelessWidget {
  const _RecipeError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          TextButton(onPressed: onRetry, child: Text(l10n.recipeRetry)),
        ],
      ),
    );
  }
}

int _minutes(int? seconds) => ((seconds ?? 0) / 60).ceil();
String _message(Object error) =>
    error.toString().replaceFirst('Exception: ', '');
