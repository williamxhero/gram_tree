import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../ingredients/ingredient_provider.dart';
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
    final recipes = ref.watch(myRecipesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('我的菜谱')),
      body: recipes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _RecipeError(
          message: '菜谱暂时加载不了',
          onRetry: () => ref.invalidate(myRecipesProvider),
        ),
        data: (page) => page.items.isEmpty
            ? EmptyState(
                icon: Icons.menu_book_outlined,
                title: '还没有菜谱',
                message: '把常做的一道菜写下来，之后可以继续改良。',
                footer: FilledButton.icon(
                  key: const ValueKey('new-recipe-button'),
                  onPressed: () => context.push(RecipeEditorPage.path),
                  icon: const Icon(Icons.add),
                  label: const Text('新建菜谱'),
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
                      label: const Text('新建菜谱'),
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
    if (!mounted || _draft == null) return;
    final restore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复未保存修改？'),
        content: const Text('上次编辑还有未保存内容。要恢复这份草稿吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('放弃草稿'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('恢复'),
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
    _changed();
    if (_form.dishName.isEmpty) {
      setState(() => _error = '请先填写菜名');
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
          : await repo.saveVersion(widget.recipeId!, _form);
      await RecipeDraftStore(ref.read(localStoreProvider)).discard(_recipeKey);
      if (!mounted) return;
      context.go('/recipes/${detail.id}');
    } catch (error) {
      if (mounted) setState(() => _error = '保存失败：${_message(error)}');
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
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(_loaded == null ? '新建菜谱' : '继续编辑菜谱')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          TextField(
            key: const ValueKey('recipe-dish-name'),
            controller: _dish,
            onChanged: (_) => _changed(),
            decoration: const InputDecoration(
              labelText: '菜名',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('食材', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('recipe-ingredient-search'),
            controller: _ingredient,
            onChanged: (_) => _changed(),
            decoration: InputDecoration(
              labelText: '搜索或填写食材',
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
            decoration: const InputDecoration(
              labelText: '用量',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('recipe-ingredient-unit'),
            controller: _unit,
            onChanged: (_) => _changed(),
            decoration: const InputDecoration(
              labelText: '单位（克、毫升、个、勺）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('recipe-ingredient-preparation'),
            controller: _preparation,
            onChanged: (_) => _changed(),
            decoration: const InputDecoration(
              labelText: '处理方式和分组',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Text('步骤', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('recipe-step-instruction'),
            controller: _step,
            maxLines: 3,
            onChanged: (_) => _changed(),
            decoration: const InputDecoration(
              labelText: '步骤说明',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('recipe-step-why'),
            controller: _why,
            maxLines: 2,
            onChanged: (_) => _changed(),
            decoration: const InputDecoration(
              labelText: '为什么这样做（可选）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('recipe-change-note'),
            controller: _note,
            onChanged: (_) => _changed(),
            decoration: const InputDecoration(
              labelText: '这次改了什么',
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
            child: Text(_saving ? '保存中…' : '保存为新版本'),
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
            child: const Text('放弃草稿'),
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
    final detail = _detail;
    if (_error != null) return Scaffold(body: Center(child: Text(_error!)));
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
              tooltip: '我来改一版',
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
            '第 ${detail.version.versionNumber} 版 · ${snapshot.servings} 份',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            '总时长 ${_minutes(derived.totalTimeSeconds)} 分钟 · 动手 ${_minutes(derived.activeTimeSeconds)} 分钟',
          ),
          if ((derived.allergens ?? const []).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '过敏原：${(derived.allergens ?? const []).join('、')}${derived.allergensIncomplete == true ? '（可能不完整）' : ''}',
            ),
          ],
          if (derived.nutritionPerServing != null)
            Text(
              '每份营养：估算值${detail.version.derived.nutritionPerServing!.incomplete == true ? '（可能不完整）' : ''}',
            ),
          const SizedBox(height: 20),
          Text('食材', style: Theme.of(context).textTheme.titleLarge),
          for (final ingredient in snapshot.ingredients ?? const [])
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(ingredient.displayName),
              subtitle: Text(
                '${ingredient.quantity} ${ingredient.unit}${ingredient.preparation.isEmpty ? '' : ' · ${ingredient.preparation}'}',
              ),
              trailing: ingredient.optional == true ? const Text('可选') : null,
            ),
          Text('步骤', style: Theme.of(context).textTheme.titleLarge),
          for (final (index, step) in (snapshot.steps ?? const []).indexed)
            ExpansionTile(
              key: ValueKey('recipe-step-$index'),
              title: Text('${index + 1}. ${step.instruction}'),
              subtitle: Text('${step.action} · ${step.durationSeconds ?? 0} 秒'),
              children: [
                if (step.why.isNotEmpty) _RationalePanel(why: step.why),
                if (step.notes.isNotEmpty)
                  ListTile(title: const Text('要点'), subtitle: Text(step.notes)),
              ],
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('recipe-image-permission'),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('添加成品图'),
            onPressed: () => _requestPhotoPermission(context),
          ),
          OutlinedButton.icon(
            key: const ValueKey('recipe-camera-permission'),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('拍一张成品图'),
            onPressed: () => _requestCameraPermission(context),
          ),
          TextButton(
            key: const ValueKey('recipe-history-button'),
            onPressed: () =>
                context.push('/recipes/${widget.recipeId}/history'),
            child: const Text('查看版本历史'),
          ),
          if (widget.versionId == null)
            TextButton(
              key: const ValueKey('delete-recipe-button'),
              onPressed: _delete,
              child: const Text('删除这份私有菜谱'),
            ),
        ],
      ),
    );
  }

  Future<void> _requestCameraPermission(BuildContext context) async {
    final state = await ref
        .read(permissionServiceProvider)
        .request(AppPermission.camera);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          state == PermissionState.granted ? '可以拍摄成品图' : '相机权限未开启，菜谱编辑不受影响',
        ),
      ),
    );
  }

  Future<void> _requestPhotoPermission(BuildContext context) async {
    final state = await ref
        .read(permissionServiceProvider)
        .request(AppPermission.photos);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          state == PermissionState.granted ? '可以从相册选择成品图' : '相册权限未开启，菜谱编辑不受影响',
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
    return Scaffold(
      appBar: AppBar(title: const Text('版本历史')),
      body: FutureBuilder<RecipeVersionHistory>(
        future: ref.read(recipeRepositoryProvider).history(recipeId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!.items;
          if (items.isEmpty) return const Center(child: Text('还没有版本历史'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                key: ValueKey('recipe-version-${item.versionNumber}'),
                title: Text(
                  '第 ${item.versionNumber} 版${item.aiAssisted == true ? ' · AI 协助' : ''}',
                ),
                subtitle: Text(
                  item.changeNote.isEmpty ? '未填写修改说明' : item.changeNote,
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
  const _RationalePanel({required this.why});
  final String why;

  @override
  Widget build(BuildContext context) => ListTile(
    title: const Text('为什么这样做'),
    subtitle: Text(why),
    leading: const Icon(Icons.lightbulb_outline),
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
        TextButton(onPressed: onRetry, child: const Text('重试')),
      ],
    ),
  );
}

String _minutes(int? seconds) => ((seconds ?? 0) / 60).ceil().toString();
String _message(Object error) =>
    error.toString().replaceFirst('Exception: ', '');
