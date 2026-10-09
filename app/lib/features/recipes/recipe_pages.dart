import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../app/theme.dart';
import '../../auth/auth_controller.dart';
import '../../features_flags/features.dart';
import '../../ingredients/ingredient_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../network/online_features.dart';
import '../../network/reachability.dart';
import '../../recipes/decimal_rounding.dart';
import '../../recipes/measure_display.dart';
import '../../recipes/personal_measure_repository.dart';
import '../../recipes/recipe_draft.dart';
import '../../recipes/recipe_repository.dart';
import '../../recipes/recipe_snapshot.dart';
import '../../recipes/recipe_snapshot_provider.dart';
import '../../recipes/recipe_snapshot_render.dart';
import '../../recipes/mold_conversion.dart';
import '../../recipes/serving_conversion.dart';
import 'batch_advice_section.dart';
import 'personal_measures_page.dart';
import 'recipe_photo_panel.dart';
import 'recipe_answer_section.dart';
import 'reproducibility_card.dart';
import 'quantification_panel.dart';
import 'recipe_source_badge.dart';
import 'text_edit_panel.dart';
import 'change_explanation_panel.dart';
import '../../storage/local_store.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import '../../ui_protocol/intent_dispatcher.dart';
import '../../ui_protocol/recipe_operations.dart';
import '../../ui_protocol/recipe_safety.dart';
import '../../ui_protocol/recipe_safety_protocol.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';
import '../../widgets/empty_state.dart';
import '../../util/ids.dart';

final myRecipesProvider = FutureProvider.autoDispose<RecipeList>((ref) async {
  return ref.watch(recipeRepositoryProvider).listPage();
});

class RecipeListPage extends ConsumerStatefulWidget {
  const RecipeListPage({super.key});

  static const path = '/recipes';

  @override
  ConsumerState<RecipeListPage> createState() => _RecipeListPageState();
}

class _RecipeListPageState extends ConsumerState<RecipeListPage> {
  RecipeList? _sourcePage;
  List<RecipeListItem> _items = const [];
  String? _nextCursor;
  bool _loadingMore = false;
  Object? _loadMoreError;

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (_loadingMore || cursor == null) return;
    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });
    try {
      final page = await ref
          .read(recipeRepositoryProvider)
          .listPage(cursor: cursor);
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...page.items];
        _nextCursor = page.nextCursor;
      });
    } catch (error) {
      if (mounted) setState(() => _loadMoreError = error);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        data: (page) {
          if (!identical(_sourcePage, page)) {
            _sourcePage = page;
            _items = [...page.items];
            _nextCursor = page.nextCursor;
            _loadMoreError = null;
          }
          if (_items.isEmpty) {
            return EmptyState(
              icon: Icons.menu_book_outlined,
              title: l10n.recipeEmptyTitle,
              message: l10n.recipeEmptyBody,
              footer: _NewRecipeButton(),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myRecipesProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _NewRecipeButton(),
                const SizedBox(height: 12),
                for (final item in _items)
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
                if (_nextCursor != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const ValueKey('recipe-load-more'),
                    onPressed: _loadingMore ? null : _loadMore,
                    icon: _loadingMore
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more),
                    label: Text(
                      _loadMoreError == null
                          ? l10n.recipeLoadMore
                          : l10n.recipeLoadMoreRetry,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
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
  const RecipeEditorPage({
    super.key,
    this.recipeId,
    this.versionId,
    this.generation,
  });

  static const path = '/recipes/new';
  final String? recipeId;
  final String? versionId;
  final GenerationResult? generation;

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
  bool _hasManualEdits = false;
  ChangeExplanationSuggestion? _manualExplanationResult;
  RecipeQuantificationOut? _quantification;
  RecipeReproducibilityResult? _reproducibility;
  String? _reproducibilityError;
  bool _checkingReproducibility = false;
  int _reproducibilityRevision = 0;
  int _nextProblem = 0;
  ReproducibilityProblem? _locatedProblem;
  final _problemTargets = <String, GlobalKey>{};
  final _editorScroll = ScrollController();
  final _operationCompositionId = newUuidV4();
  RecipeSafetyResult? _safetyResult;
  String? _safetyError;
  bool _safetyLoading = false;
  bool _safetyAwaitingCheck = true;
  int _safetyRevision = 0;
  int _editorRevision = 0;
  int _textEditEpoch = 0;
  Timer? _draftTimer;
  Future<void>? _draftWrite;
  int _draftGeneration = 0;
  final Map<String, List<IngredientDetail>> _ingredientResults = {};
  // Library scaling default of the standard ingredient picked for each draft
  // row, shown when the author has not chosen a mode explicitly.
  final Map<String, String?> _libraryScaling = {};
  final Map<String, List<IngredientDetail>> _replacementResults = {};
  final Map<String, bool> _searching = {};

  String get _recipeKey =>
      widget.recipeId ??
      (widget.generation == null
          ? 'new'
          : 'ai-${widget.generation!.requestId}');
  String get _accountId => ref.read(authProvider).value?.id ?? 'anonymous';

  @override
  void initState() {
    super.initState();
    _draftStore = RecipeDraftStore(ref.read(localStoreProvider));
    final generated = widget.generation?.draft?.recipe;
    _form = RecipeForm(dishName: '');
    if (generated != null) {
      _form =
          RecipeForm.fromSnapshot(
              generated.snapshot,
              generated.dishName ?? '',
              aliases: generated.dishAliases,
            )
            ..aiAssisted = true
            ..changeNote = generated.changeNote ?? '';
    }
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      if (widget.recipeId != null) {
        final repo = ref.read(recipeRepositoryProvider);
        _loaded = widget.versionId == null
            ? await repo.get(widget.recipeId!)
            : await repo.getVersion(widget.recipeId!, widget.versionId!);
        _form = RecipeForm.fromSnapshot(
          _loaded!.version.snapshot,
          _loaded!.dish.name,
          aliases: _loaded!.dish.aliases,
        )..aiAssisted = _loaded!.version.aiAssisted;
        _reproducibility = _loaded!.version.reproducibility;
      }
      _draft = _draftStore.read(
        recipeKey: _recipeKey,
        accountId: _accountId,
        baselineVersionId: _loaded?.version.id,
      );
      if (_draft != null && !RecipeForm.isDraftPayloadValid(_draft!.payload)) {
        await _discardDraft();
      }
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
      _hasManualEdits = true;
      _reproducibility = null;
      _editorRevision++;
      setState(() {});
    } else {
      await _discardDraft();
      if (mounted) setState(() => _textEditEpoch++);
    }
  }

  void _changed() {
    if (!mounted) return;
    _form.explanationFingerprint = null;
    setState(() {
      _hasManualEdits = true;
      _quantification = null;
      _reproducibility = null;
      _reproducibilityError = null;
      _locatedProblem = null;
      _checkingReproducibility = false;
      _reproducibilityRevision++;
      _safetyResult = null;
      _safetyError = null;
      _safetyLoading = false;
      _safetyAwaitingCheck = true;
      _safetyRevision++;
    });
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

  Future<void> _discardDraft() => _discardDraftForScope(
    accountId: _accountId,
    recipeKey: _recipeKey,
    baselineVersionId: _loaded?.version.id,
    generationRequestId: widget.generation?.requestId,
  );

  Future<void> _discardDraftForScope({
    required String accountId,
    required String recipeKey,
    required String? baselineVersionId,
    required String? generationRequestId,
    bool preserveNewerForm = false,
    RecipeDraft? expectedFormDraft,
  }) async {
    ++_draftGeneration;
    _draftTimer?.cancel();
    _draftTimer = null;
    try {
      await _draftWrite;
    } catch (_) {
      // A failed local write must not prevent leaving the editor.
    }
    if (preserveNewerForm) {
      await _draftStore.discardMatching(expectedFormDraft);
    } else {
      await _draftStore.discard(recipeKey, accountId: accountId);
    }
    await _draftStore.discardModification(
      recipeKey: recipeKey,
      accountId: accountId,
      baselineVersionId: baselineVersionId,
    );
    if (generationRequestId != null) {
      await _draftStore.discardGeneratedResult(
        generationRequestId,
        accountId: accountId,
      );
    }
    _draftWrite = null;
    _draft = null;
  }

  Future<void> _checkReproducibility() async {
    final revision = _reproducibilityRevision;
    setState(() {
      _checkingReproducibility = true;
      _reproducibilityError = null;
    });
    try {
      final result = await ref
          .read(recipeRepositoryProvider)
          .checkReproducibility(_form);
      if (!mounted || revision != _reproducibilityRevision) return;
      setState(() {
        _reproducibility = result;
        _nextProblem = 0;
        _locatedProblem = null;
      });
    } catch (_) {
      if (mounted && revision == _reproducibilityRevision) {
        setState(() => _reproducibilityError = '检查失败，请重试。仍可保存私有版本。');
      }
    } finally {
      if (mounted && revision == _reproducibilityRevision) {
        setState(() => _checkingReproducibility = false);
      }
    }
  }

  Future<void> _locateProblem() async {
    final problems =
        _reproducibility?.problems
            ?.where(
              (problem) =>
                  problem.status != ReproducibilityProblemStatusEnum.resolved,
            )
            .toList() ??
        const <ReproducibilityProblem>[];
    if (problems.isEmpty || !_editorScroll.hasClients) return;
    final problem = problems[_nextProblem++ % problems.length];
    final revision = _reproducibilityRevision;
    setState(() => _locatedProblem = problem);
    final target =
        _problemTargets['${problem.position.collection.value}:${problem.position.itemId}'];
    if (target == null) return;
    // ListView builds rows lazily. Reveal the target before asking Flutter to
    // align it; a far-away step must work just like an already mounted row.
    await _editorScroll.animateTo(
      0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
    while (mounted &&
        revision == _reproducibilityRevision &&
        target.currentContext == null &&
        _editorScroll.offset < _editorScroll.position.maxScrollExtent) {
      await _editorScroll.animateTo(
        (_editorScroll.offset + 500).clamp(
          0,
          _editorScroll.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
    if (!mounted || revision != _reproducibilityRevision) return;
    final targetContext = target.currentContext;
    if (targetContext != null && targetContext.mounted) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 150),
        alignment: 0,
      );
    }
  }

  Widget _problemRow(String collection, String id, Widget child) {
    final problem = _locatedProblem;
    final selected =
        problem?.position.collection.value == collection &&
        problem?.position.itemId == id;
    return Column(
      key: _problemTargets.putIfAbsent('$collection:$id', GlobalKey.new),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selected)
          Semantics(liveRegion: true, child: Text('当前定位：${problem!.message}')),
        if (collection == 'ingredients') ...[
          RecipeSourceBadge(
            key: ValueKey('editor-source-$id-quantity'),
            source: _form.ingredients
                .firstWhere((i) => i.id == id)
                .quantitySource,
            value:
                '${_form.ingredients.firstWhere((i) => i.id == id).quantity} ${_form.ingredients.firstWhere((i) => i.id == id).unit}',
            fieldId: 'editor-$id-quantity',
          ),
          RecipeSourceBadge(
            key: ValueKey('editor-source-$id-preparation'),
            source: _form.ingredients
                .firstWhere((i) => i.id == id)
                .preparationSource,
            value: _form.ingredients.firstWhere((i) => i.id == id).preparation,
            fieldId: 'editor-$id-preparation',
          ),
        ],
        if (collection == 'steps')
          Wrap(
            spacing: 8,
            children: [
              for (final pair in <(String, String, ValueSource?)>[
                (
                  'instruction',
                  _form.steps.firstWhere((s) => s.id == id).instruction,
                  _form.steps.firstWhere((s) => s.id == id).instructionSource,
                ),
                (
                  'duration',
                  '${_form.steps.firstWhere((s) => s.id == id).durationSeconds} 秒',
                  _form.steps.firstWhere((s) => s.id == id).durationSource,
                ),
                (
                  'heat',
                  _form.steps.firstWhere((s) => s.id == id).heat,
                  _form.steps.firstWhere((s) => s.id == id).heatSource,
                ),
                (
                  'temperature',
                  '${_form.steps.firstWhere((s) => s.id == id).temperatureCelsius} ℃',
                  _form.steps.firstWhere((s) => s.id == id).temperatureSource,
                ),
                (
                  'doneness',
                  _form.steps.firstWhere((s) => s.id == id).doneness,
                  _form.steps.firstWhere((s) => s.id == id).donenessSource,
                ),
              ])
                RecipeSourceBadge(
                  key: ValueKey('editor-source-$id-${pair.$1}'),
                  source: pair.$3,
                  value: pair.$2,
                  fieldId: 'editor-$id-${pair.$1}',
                ),
            ],
          ),
        child,
      ],
    );
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _editorScroll.dispose();
    super.dispose();
  }

  Future<void> _checkSafety() async {
    final revision = _safetyRevision;
    setState(() {
      _safetyLoading = true;
      _safetyError = null;
      _safetyAwaitingCheck = false;
    });
    try {
      final result = await ref
          .read(recipeRepositoryProvider)
          .checkSafety(_form);
      if (!mounted || revision != _safetyRevision) return;
      setState(() {
        _safetyResult = result;
        _safetyAwaitingCheck = false;
      });
    } catch (error) {
      if (!mounted || revision != _safetyRevision) return;
      setState(() {
        _safetyError = ApiFailure.from(error).message;
        _safetyAwaitingCheck = true;
      });
    } finally {
      if (mounted && revision == _safetyRevision) {
        setState(() => _safetyLoading = false);
      }
    }
  }

  void _showSavedVersion(RecipeDetail detail) {
    _hasManualEdits = false;
    _loaded = detail;
    _form = RecipeForm.fromSnapshot(
      detail.version.snapshot,
      detail.dish.name,
      aliases: detail.dish.aliases,
    )..aiAssisted = detail.version.aiAssisted;
    _reproducibility = detail.version.reproducibility;
    _editorRevision++;
    _safetyResult = detail.version.safety;
    _safetyAwaitingCheck = false;
    _quantification = null;
  }

  void _showEditorError(String message) {
    if (!mounted) return;
    setState(() => _error = message);
    // Errors are at the top of a lazy list; make them visible after an action
    // taken farther down, including long proposal panels and large text.
    if (_editorScroll.hasClients) _editorScroll.jumpTo(0);
  }

  Future<void> _quantify() async {
    if (!_validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _flushDraft();
      final repo = ref.read(recipeRepositoryProvider);
      // Save the visible draft before asking for owned proposals. A later
      // decision never applies to unsaved client edits or an historical base.
      final detail = _loaded == null
          ? widget.generation == null
                ? await repo.create(_form)
                : await repo.saveGenerated(widget.generation!.requestId, _form)
          : await repo.saveVersion(
              _loaded!.id,
              _form,
              baseVersionId: _loaded!.version.id,
              expectedCurrentVersionId: _loaded!.version.id,
            );
      await _discardDraft();
      if (!mounted) return;
      setState(() => _showSavedVersion(detail));
      final proposal = await repo.quantify(detail.id, detail.version.id);
      if (mounted) setState(() => _quantification = proposal);
    } catch (error) {
      _showEditorError(ApiFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _decideQuantification(
    List<QuantificationDecision> decisions,
    bool acceptAll,
  ) async {
    final proposal = _quantification;
    if (proposal == null || _loaded == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final detail = await ref
          .read(recipeRepositoryProvider)
          .decideQuantification(
            _loaded!.id,
            proposal.id,
            decisions: decisions,
            acceptAll: acceptAll,
          );
      await _discardDraft();
      if (mounted) setState(() => _showSavedVersion(detail));
    } catch (error) {
      _showEditorError(ApiFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
      // Always re-check immediately before saving. A result obtained while the
      // form was unchanged is valid; a failed/stale check must never become a
      // way around the server's immutable safety gate.
      final safety = await repo.checkSafety(_form);
      if (!mounted) return;
      setState(() {
        _safetyResult = safety;
        _safetyAwaitingCheck = false;
        _safetyError = null;
      });
      if (safety.canSave != true) {
        final claims = safety.prohibitedClaims ?? const <String>[];
        final message = claims.isEmpty
            ? l10n.recipeSafetySaveBlocked
            : '${l10n.recipeSafetyClaims(claims.join('、'), safety.claimBasis ?? '')} '
                  '${l10n.recipeSafetyClaimRewrite}';
        _showEditorError(message);
        return;
      }
      final detail = _loaded == null
          ? widget.generation == null
                ? await repo.create(_form)
                : await repo.saveGenerated(widget.generation!.requestId, _form)
          : await repo.saveVersion(
              _loaded!.id,
              _form,
              baseVersionId: _loaded!.version.id,
            );
      await _discardDraft();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.recipeSaveSuccess)));
      // Replace the editor route so saving a new version cannot reuse a stale
      // RecipeDetailPage state when the destination path is unchanged.
      context.pushReplacement('/recipes/${detail.id}');
    } catch (error) {
      if (mounted) {
        final failure = ApiFailure.from(error);
        final message = failure.code == 'prohibited_health_claim'
            ? '${failure.message} ${l10n.recipeSafetyClaimRewrite}'
            : l10n.recipeSaveFailed(failure.message);
        _showEditorError(message);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _validate() {
    final l10n = AppLocalizations.of(context);
    if (_form.dishName.trim().isEmpty) {
      _showEditorError(l10n.recipeDishRequired);
      return false;
    }
    if (_form.ingredients.any((item) => item.displayName.trim().isEmpty)) {
      _showEditorError(l10n.recipeIngredientRequired);
      return false;
    }
    if (_form.servings < 1 ||
        _form.ingredients.any(
          (item) => item.quantity < 0 || item.baseQuantity < 0,
        ) ||
        _form.steps.any((item) => item.durationSeconds < 0)) {
      _showEditorError(l10n.recipeInvalidNumber);
      return false;
    }
    final ingredientIds = _form.ingredients.map((item) => item.id).toSet();
    final stepIds = _form.steps.map((item) => item.id).toSet();
    if (_form.steps.any(
      (item) =>
          item.ingredientIds.any((id) => !ingredientIds.contains(id)) ||
          item.dependsOn.any((id) => !stepIds.contains(id)),
    )) {
      _showEditorError(l10n.recipeInvalidStepReference);
      return false;
    }
    final visiting = <String>{};
    final visited = <String>{};
    bool hasCycle(String stepId) {
      if (stepId.isEmpty || visited.contains(stepId)) return false;
      if (!visiting.add(stepId)) return true;
      final step = _form.steps.firstWhere((item) => item.id == stepId);
      for (final dependency in step.dependsOn) {
        if (hasCycle(dependency)) return true;
      }
      visiting.remove(stepId);
      visited.add(stepId);
      return false;
    }

    if (_form.steps.any((step) => hasCycle(step.id))) {
      _showEditorError(l10n.recipeInvalidStepReference);
      return false;
    }
    if (_form.steps.any(
      (item) => item.temperatureCelsius < -50 || item.temperatureCelsius > 1000,
    )) {
      _showEditorError(l10n.recipeInvalidNumber);
      return false;
    }
    if (_form.baseMold != null && !_validMold(_form.baseMold!)) {
      _showEditorError(l10n.recipeInvalidNumber);
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
    _libraryScaling[id] = scalingRuleForLibraryAttribute(
      value.attributes.scaling?.value,
    );
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

  bool get _canExplainChanges => _loaded != null || widget.generation != null;

  String get _explanationBinding {
    final snapshot = _form.snapshot.toJson()..remove('tags');
    return jsonEncode([
      _accountId,
      _loaded?.id,
      _loaded?.version.id,
      widget.generation?.requestId,
      snapshot,
    ]);
  }

  Future<ChangeExplanationSuggestion> _dispatchExplanation(
    BuildContext context,
  ) async {
    _manualExplanationResult = null;
    await ref
        .read(intentDispatcherProvider)
        .dispatch(
          context,
          compositionId: _operationCompositionId,
          componentId: 'recipe-change-explanation',
          action: ActionDescriptor(
            intent: 'recipe_operation',
            params: {'operation': 'explain_changes'},
          ),
        );
    return _manualExplanationResult ??
        const ChangeExplanationSuggestion(available: false);
  }

  Future<ChangeExplanationSuggestion> _explainChanges() async {
    final result = await ref
        .read(recipeRepositoryProvider)
        .explainChanges(
          ChangeExplanationInput(
            recipeId: _loaded?.id,
            baseVersionId: _loaded?.version.id,
            generationRequestId: _loaded == null
                ? widget.generation?.requestId
                : null,
            snapshot: _form.snapshot,
          ),
        );
    return ChangeExplanationSuggestion.fromResult(result);
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
    // Cleanup can finish after this page is disposed or another account signs
    // in. Bind storage work now; only navigation consults the live account.
    final accountId = ref.watch(authProvider).value?.id ?? 'anonymous';
    final recipeKey = _recipeKey;
    final baselineVersionId = _loaded?.version.id;
    final generationRequestId = widget.generation?.requestId;
    final expectedFormDraft = _draftStore.read(
      recipeKey: recipeKey,
      accountId: accountId,
      baselineVersionId: baselineVersionId,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(_loaded == null ? l10n.newRecipe : l10n.recipeContinueEdit),
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          key: const ValueKey('recipe-editor-content'),
          controller: _editorScroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            if (_loaded != null && _loaded!.author.id == accountId)
              TextEditPanel(
                key: ValueKey(
                  'text-edit-recipe-$accountId-${_loaded!.version.id}-$_textEditEpoch',
                ),
                recipeId: _loaded!.id,
                baseVersionId: _loaded!.version.id,
                manualEdits: _hasManualEdits,
                onSavingChanged: (saving) {
                  if (mounted) setState(() => _saving = saving);
                },
                onSaved: (detail) async {
                  await _discardDraftForScope(
                    accountId: accountId,
                    recipeKey: recipeKey,
                    baselineVersionId: baselineVersionId,
                    generationRequestId: generationRequestId,
                    preserveNewerForm: true,
                    expectedFormDraft: expectedFormDraft,
                  );
                  if (context.mounted && accountId == _accountId) {
                    context.pushReplacement('/recipes/${detail.id}');
                  }
                },
              ),
            if (_error != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  key: const ValueKey('recipe-save-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            RecipeOperationScope(
              key: const ValueKey('recipe-reproducibility-operations'),
              handlers: {
                'check': (_) => _checkingReproducibility || _saving
                    ? null
                    : _checkReproducibility(),
                'quantify': (_) => _saving ? null : _quantify(),
                'locate': (_) => _locateProblem(),
                'cancel': (_) => setState(() => _quantification = null),
                'decide': (params) => _saving
                    ? null
                    : _decideQuantification(
                        recipeDecisions(params),
                        params['accept_all'] == true,
                      ),
              },
              child: CompositionIdScope(
                compositionId: _operationCompositionId,
                child: Builder(
                  builder: (context) {
                    Future<void> dispatch(ActionDescriptor action) => ref
                        .read(intentDispatcherProvider)
                        .dispatch(
                          context,
                          compositionId: _operationCompositionId,
                          componentId: 'recipe-reproducibility',
                          action: action,
                        );
                    Future<void> operation(String name) => dispatch(
                      ActionDescriptor(
                        intent: 'recipe_operation',
                        params: {'operation': name},
                      ),
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton(
                          key: const ValueKey('recipe-reproducibility-check'),
                          onPressed: _checkingReproducibility
                              ? null
                              : () => operation('check'),
                          child: Text(
                            _checkingReproducibility ? '正在检查可复刻性…' : '检查可复刻性',
                          ),
                        ),
                        ReproducibilityCard(
                          result: _reproducibility,
                          onLocate: () => operation('locate'),
                        ),
                        if (_reproducibilityError != null)
                          Text(_reproducibilityError!),
                        const Text('请求量化前会先保存当前私有版本，处理建议后再保存新版本。'),
                        OutlinedButton(
                          key: const ValueKey('recipe-quantify'),
                          onPressed: _saving
                              ? null
                              : () => operation('quantify'),
                          child: Text(_saving ? '正在保存或量化…' : '保存并请求 AI 量化'),
                        ),
                        TextField(
                          key: const ValueKey('recipe-operation-command'),
                          decoration: const InputDecoration(
                            labelText: '一句话操作',
                            hintText: '检查可复刻性 / 请求量化 / 定位下一处 / 全部接受 / 暂不处理',
                          ),
                          onSubmitted: (text) {
                            final action = recipeCommand(text);
                            if (action != null) {
                              unawaited(dispatch(action));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('请输入提示中的菜谱操作')),
                              );
                            }
                          },
                        ),
                        if (_quantification != null)
                          QuantificationPanel(
                            key: ValueKey(_quantification!.id),
                            proposal: _quantification!,
                            onDecide: _decideQuantification,
                            onCancel: () =>
                                setState(() => _quantification = null),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (_form.aiAssisted) ...[
              const Text('AI 辅助 · 尚未做过验证'),
              SourceMark(
                sourceType: sourceTypeAiEstimated,
                componentId: 'recipe-ai-editor',
                value: '菜谱设计',
                basisText: _form.designRationale ?? '一般经验；尚未做过验证',
                required: false,
                feedbackEnabled: false,
                onAction: null,
              ),
            ],
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
            const SizedBox(height: 12),
            KeyedSubtree(
              key: ValueKey('recipe-info-$_editorRevision'),
              child: _RecipeInfoFields(
                form: _form,
                onChanged: _changed,
                showExplanationFields: !_canExplainChanges || !_hasManualEdits,
                explanationPanel: _canExplainChanges && _hasManualEdits
                    ? RecipeOperationScope(
                        handlers: {
                          'explain_changes': (_) async {
                            _manualExplanationResult = await _explainChanges();
                          },
                        },
                        child: Builder(
                          builder: (context) => ChangeExplanationPanel(
                            bindingKey: _explanationBinding,
                            changeNote: _form.changeNote,
                            tags: _form.tags,
                            noteAuthored: _form.explanationNoteAuthored,
                            tagsAuthored: _form.explanationTagsAuthored,
                            changesFingerprint: _form.explanationFingerprint,
                            explain: () => _dispatchExplanation(context),
                            onChanged: (draft) {
                              _form.changeNote = draft.changeNote;
                              _form.tags = draft.tags;
                              _form.explanationNoteAuthored =
                                  draft.noteAuthored;
                              _form.explanationTagsAuthored =
                                  draft.tagsAuthored;
                              _changed();
                              _form.explanationFingerprint =
                                  draft.changesFingerprint;
                            },
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const ValueKey('recipe-safety-check'),
              onPressed: _safetyLoading ? null : _checkSafety,
              icon: _safetyLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.health_and_safety_outlined),
              label: Text(
                _safetyLoading
                    ? l10n.recipeSafetyChecking
                    : l10n.recipeSafetyCheck,
              ),
            ),
            FoodSafetyCard(
              result: _safetyResult,
              loading: _safetyLoading,
              awaitingCheck: _safetyAwaitingCheck,
              errorMessage: _safetyError,
            ),
            AllergenCard(
              result: _safetyResult,
              loading: _safetyLoading,
              awaitingCheck: _safetyAwaitingCheck,
              errorMessage: _safetyError,
            ),
            const SizedBox(height: 20),
            RecipePhotoPanel(
              // Editors stage a new image; the immutable version save attaches it
              // together with the structured snapshot. Viewing a saved recipe may
              // still upload directly in the detail page below.
              recipeId: null,
              onUploaded: (result) {
                _form.imageIds.add(result.id);
                _changed();
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
              _problemRow(
                'ingredients',
                entry.$2.id,
                _IngredientEditorCard(
                  key: ValueKey(
                    'recipe-ingredient-${entry.$2.id}-$_editorRevision',
                  ),
                  item: entry.$2,
                  index: entry.$1,
                  count: _form.ingredients.length,
                  results: _ingredientResults[entry.$2.id] ?? const [],
                  replacementResults:
                      _replacementResults[entry.$2.id] ?? const [],
                  searching: _searching['ingredient:${entry.$2.id}'] == true,
                  replacementSearching:
                      _searching['replacement:${entry.$2.id}'] == true,
                  onChanged: _changed,
                  onSearch: () =>
                      _searchIngredient(entry.$2.id, replacement: false),
                  onReplacementSearch: () =>
                      _searchIngredient(entry.$2.id, replacement: true),
                  libraryScaling: _libraryScaling[entry.$2.id],
                  onSelect: (value) => _selectIngredient(entry.$2.id, value),
                  onSelectReplacement: (value) =>
                      _selectReplacement(entry.$2.id, value),
                  onDelete: () => _deleteIngredient(entry.$1),
                  onMoveUp: () => _moveIngredient(entry.$1, -1),
                  onMoveDown: () => _moveIngredient(entry.$1, 1),
                ),
              ),
            OutlinedButton.icon(
              key: const ValueKey('recipe-add-ingredient'),
              onPressed: _addIngredient,
              icon: const Icon(Icons.add),
              label: Text(l10n.recipeIngredientAdd),
            ),
            const SizedBox(height: 20),
            for (final entry in _form.steps.indexed)
              _problemRow(
                'steps',
                entry.$2.id,
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
      ),
    );
  }
}

class _RecipeInfoFields extends StatelessWidget {
  const _RecipeInfoFields({
    required this.form,
    required this.onChanged,
    this.showExplanationFields = true,
    this.explanationPanel,
  });
  final RecipeForm form;
  final VoidCallback onChanged;
  final bool showExplanationFields;
  final Widget? explanationPanel;

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
        _BaseMoldEditor(form: form, onChanged: onChanged),
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
        if (showExplanationFields)
          _text(
            label: l10n.recipeTags,
            value: form.tags.join('，'),
            onChanged: (value) {
              form.tags = _split(value);
              form.explanationTagsAuthored = true;
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
        if (showExplanationFields)
          _text(
            label: l10n.recipeChangeNote,
            value: form.changeNote,
            onChanged: (value) {
              form.changeNote = value.trim();
              form.explanationNoteAuthored = true;
              onChanged();
            },
          ),
        ?explanationPanel,
      ],
    );
  }
}

class _BaseMoldEditor extends StatelessWidget {
  const _BaseMoldEditor({required this.form, required this.onChanged});

  final RecipeForm form;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mold = form.baseMold;
    if (mold == null) {
      return OutlinedButton.icon(
        key: const ValueKey('base-mold-enable'),
        onPressed: () {
          form.baseMold = MoldSpec(
            shape: MoldSpecShapeEnum.round,
            unit: MoldSpecUnitEnum.in_,
            diameter: 6,
          );
          onChanged();
        },
        icon: const Icon(Icons.cake_outlined),
        label: Text(l10n.recipeMoldConversion),
      );
    }
    final shape = mold.shape;
    final round = shape == MoldSpecShapeEnum.round;
    final square = shape == MoldSpecShapeEnum.square;
    return ComponentCard(
      key: const ValueKey('base-mold-editor'),
      detail: ComponentDescriptorDetailEnum.standard,
      conclusion: Text(l10n.recipeMoldConversion),
      conclusionSemanticsText: l10n.recipeMoldConversion,
      standardExtra: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            DropdownButtonFormField<MoldSpecShapeEnum>(
              key: const ValueKey('base-mold-shape'),
              initialValue: shape,
              decoration: InputDecoration(
                labelText: l10n.recipeMoldTargetShape,
              ),
              items: [
                DropdownMenuItem(
                  value: MoldSpecShapeEnum.round,
                  child: Text(l10n.recipeMoldRound),
                ),
                DropdownMenuItem(
                  value: MoldSpecShapeEnum.square,
                  child: Text(l10n.recipeMoldSquare),
                ),
                DropdownMenuItem(
                  value: MoldSpecShapeEnum.rectangular,
                  child: Text(l10n.recipeMoldRectangular),
                ),
                DropdownMenuItem(
                  value: MoldSpecShapeEnum.custom,
                  child: Text(l10n.recipeMoldCustom),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                form.baseMold = _moldForShape(mold, value);
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            if (round)
              Row(
                children: [
                  Expanded(
                    child: _number(
                      key: const ValueKey('base-mold-diameter'),
                      label: l10n.recipeMoldDiameter,
                      value: mold.diameter ?? 0,
                      onChanged: (value) {
                        form.baseMold = _moldWith(
                          mold,
                          diameter: double.tryParse(value),
                        );
                        onChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<MoldSpecUnitEnum>(
                      key: const ValueKey('base-mold-unit'),
                      initialValue: mold.unit ?? MoldSpecUnitEnum.cm,
                      decoration: InputDecoration(
                        labelText: l10n.recipeMoldUnit,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: MoldSpecUnitEnum.in_,
                          child: Text(l10n.recipeMoldInch),
                        ),
                        DropdownMenuItem(
                          value: MoldSpecUnitEnum.cm,
                          child: Text(l10n.recipeMoldCm),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        form.baseMold = _moldWith(mold, unit: value);
                        onChanged();
                      },
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _number(
                      key: const ValueKey('base-mold-width'),
                      label: square
                          ? l10n.recipeMoldSide
                          : l10n.recipeMoldWidth,
                      value: mold.side ?? mold.width ?? 0,
                      onChanged: (value) {
                        final parsed = double.tryParse(value);
                        form.baseMold = _moldWith(
                          mold,
                          side: square ? parsed : null,
                          width: parsed,
                        );
                        onChanged();
                      },
                    ),
                  ),
                  if (!square) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _number(
                        key: const ValueKey('base-mold-length'),
                        label: l10n.recipeMoldLength,
                        value: mold.length ?? 0,
                        onChanged: (value) {
                          form.baseMold = _moldWith(
                            mold,
                            length: double.tryParse(value),
                          );
                          onChanged();
                        },
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

MoldSpec _moldForShape(MoldSpec value, MoldSpecShapeEnum shape) {
  final round = shape == MoldSpecShapeEnum.round;
  final square = shape == MoldSpecShapeEnum.square;
  return MoldSpec(
    shape: shape,
    unit: round ? value.unit ?? MoldSpecUnitEnum.cm : MoldSpecUnitEnum.cm,
    diameter: round ? value.diameter ?? 6 : null,
    side: square ? value.side ?? value.width ?? 15 : null,
    width: round || square ? null : value.width ?? 15,
    length: round || square ? null : value.length ?? 15,
  );
}

MoldSpec _moldWith(
  MoldSpec value, {
  MoldSpecShapeEnum? shape,
  MoldSpecUnitEnum? unit,
  double? diameter,
  double? side,
  double? width,
  double? length,
}) => MoldSpec(
  shape: shape ?? value.shape,
  unit: unit ?? value.unit,
  diameter: diameter ?? value.diameter,
  side: side ?? value.side,
  width: width ?? value.width,
  length: length ?? value.length,
);

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
    this.libraryScaling,
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
  final String? libraryScaling;
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
                item.displayName = value;
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
                      // A typed amount is the author's own value, whatever
                      // estimated or verified it before.
                      item.quantitySource = null;
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
                      item.quantitySource = null;
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
                item.preparationSource = null;
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
                          item.quantitySource = null;
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
                          item.quantitySource = null;
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
                DropdownButtonFormField<String>(
                  key: ValueKey('recipe-ingredient-scaling-$id'),
                  initialValue:
                      item.scalingMode?.value ?? _scalingLibraryDefaultValue,
                  decoration: InputDecoration(
                    labelText: l10n.recipeScalingMode,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: _scalingLibraryDefaultValue,
                      child: Text(
                        widget.libraryScaling == null
                            ? l10n.recipeScalingLibraryDefaultUnknown
                            : l10n.recipeScalingLibraryDefault(
                                _scalingModeLabel(widget.libraryScaling!, l10n),
                              ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: RecipeIngredientScalingModeEnum.proportional.value,
                      child: Text(l10n.recipeScalingProportional),
                    ),
                    DropdownMenuItem(
                      value: RecipeIngredientScalingModeEnum.unchanged.value,
                      child: Text(l10n.recipeScalingUnchanged),
                    ),
                    DropdownMenuItem(
                      value: RecipeIngredientScalingModeEnum.round.value,
                      child: Text(l10n.recipeScalingRound),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    // Leaving the mode unset lets the server apply the
                    // ingredient library default when the version is saved.
                    item.scalingMode = RecipeIngredientScalingModeEnum.values
                        .where((mode) => mode.value == value)
                        .firstOrNull;
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
              ingredientId: null,
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
                item.instructionSource = null;
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
                      item.durationSource = null;
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
                      item.temperatureSource = null;
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
                item.heatSource = null;
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
                item.donenessSource = null;
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

enum _RecipeScaleMode { servings, mold }

class _RecipeDetailPageState extends ConsumerState<RecipeDetailPage> {
  RecipeDetail? _detail;
  String? _error;
  int? _targetServings;
  _RecipeScaleMode _scaleMode = _RecipeScaleMode.servings;
  MoldSpec? _targetMold;
  MeasureDisplayMode _displayMode = MeasureDisplayMode.base;
  List<PersonalMeasureOut> _measures = const [];
  Map<String, double> _densities = const {};
  String? _selectedMeasureId;
  RecipeIngredientDisplayOut? _displayContract;
  String? _displayContractKey;
  RecipeSnapshotStore? _snapshotStore;
  RecipeSnapshotRender? _frozenRender;
  FrozenRecipeSnapshot? _frozenSnapshot;
  String? _loadedAccountId;
  String? _catalogueVersion;
  String? _lastCapture;
  String? _capacityMessage;
  bool _offline = false;
  int _loadGeneration = 0;
  String? _viewAccountId;

  @override
  void initState() {
    super.initState();
    _viewAccountId = ref.read(authProvider).value?.id;
    ref.listenManual(authProvider, (_, next) {
      if (next.isLoading) return;
      final accountId = next.value?.id;
      if (accountId == _viewAccountId) return;
      _viewAccountId = accountId;
      _loadGeneration++;
      setState(() {
        _detail = null;
        _error = null;
        _snapshotStore = null;
        _loadedAccountId = null;
        _frozenRender = null;
        _frozenSnapshot = null;
        _lastCapture = null;
        _capacityMessage = null;
        _offline = false;
        _targetServings = null;
        _targetMold = null;
        _measures = const [];
        _densities = const {};
        _selectedMeasureId = null;
        _displayContract = null;
        _displayContractKey = null;
        _scaleMode = _RecipeScaleMode.servings;
        _displayMode = MeasureDisplayMode.base;
      });
      if (accountId != null) unawaited(_load());
    });
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant RecipeDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipeId != widget.recipeId ||
        oldWidget.versionId != widget.versionId) {
      _detail = null;
      _displayContract = null;
      _displayContractKey = null;
      _scaleMode = _RecipeScaleMode.servings;
      _targetServings = null;
      _targetMold = null;
      unawaited(_load());
    }
  }

  bool get _networkUnavailable =>
      _offline ||
      ref.read(offlineSimulationProvider) ||
      ref.read(apiReachabilityProvider) == ApiReachability.unavailable;

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final accountId = ref.read(authProvider).value?.id;
    final cache = ref.read(recipeSnapshotStoreProvider);
    _snapshotStore = cache;
    bool current() =>
        mounted &&
        generation == _loadGeneration &&
        accountId == ref.read(authProvider).value?.id;
    if (mounted) {
      setState(() {
        _error = null;
        _detail = null;
        _lastCapture = null;
        _displayContract = null;
        _displayContractKey = null;
        _frozenRender = null;
        _frozenSnapshot = null;
        _offline = false;
        _capacityMessage = null;
        _measures = const [];
        _densities = const {};
        _selectedMeasureId = null;
        _displayMode = MeasureDisplayMode.base;
        _scaleMode = _RecipeScaleMode.servings;
        _catalogueVersion = null;
      });
    }
    try {
      if (ref.read(apiReachabilityProvider) == ApiReachability.unavailable &&
          !await ref.read(apiReachabilityProvider.notifier).check()) {
        throw const OnlineFeatureUnavailable(ApiReachability.unavailable);
      }
      if (!current()) return;
      final repo = ref.read(recipeRepositoryProvider);
      final detail = widget.versionId == null
          ? await repo.get(widget.recipeId)
          : await repo.getVersion(widget.recipeId, widget.versionId!);
      if (!current()) return;
      setState(() {
        _detail = detail;
        _loadedAccountId = accountId;
        // Personal defaults initialize a new view only. Explicit choices (and
        // resetting to author servings) survive recipe/measure refreshes.
        _targetServings ??=
            detail.defaultServings ?? detail.version.snapshot.servings;
        _targetMold ??= detail.version.snapshot.baseMold;
      });
      unawaited(_loadDisplayMetadata(detail));
    } catch (error, stack) {
      developer.log(
        'recipe detail load failed',
        name: 'recipe_detail',
        error: error,
        stackTrace: stack,
      );
      if (!current()) return;
      final code = ApiFailure.from(error).code;
      // A denied/deleted version must not be resurrected from a local cache.
      if (code != 'network') {
        if (code == 'not_found' || code == 'forbidden') {
          await cache?.removeRecipe(widget.recipeId);
        }
        if (current()) {
          setState(
            () => _error = code == 'not_found' ? 'not_found' : 'load_error',
          );
        }
        return;
      }
      final frozen = await cache?.read(
        widget.recipeId,
        versionId: widget.versionId,
      );
      if (!current()) return;
      if (frozen == null) {
        setState(() => _error = 'offline_uncached');
        return;
      }
      setState(() {
        _offline = true;
        _loadedAccountId = accountId;
        _detail = frozen.detail;
        _frozenSnapshot = frozen;
        _frozenRender = RecipeSnapshotRender.fromJson(frozen.render);
        _targetServings = frozen.inputs['target_servings'] as int?;
        _targetMold = frozen.inputs['target_mold'] == null
            ? null
            : MoldSpec.fromJson(frozen.inputs['target_mold']);
        _scaleMode = frozen.inputs['scale_mode'] == 'mold'
            ? _RecipeScaleMode.mold
            : _RecipeScaleMode.servings;
        _displayMode =
            MeasureDisplayMode.values
                .where((mode) => mode.name == frozen.inputs['display_mode'])
                .firstOrNull ??
            MeasureDisplayMode.base;
        _displayContract = _frozenRender?.contract;
        final measure = frozen.inputs['personal_measure'];
        _measures = measure == null
            ? const []
            : [PersonalMeasureOut.fromJson(measure)];
        _selectedMeasureId = _measures.firstOrNull?.id;
      });
    }
  }

  Future<void> _persistDisplayed(
    RecipeDetail detail,
    RecipeSnapshotRender render,
    PersonalMeasureOut? measure,
    RecipeConversionConfig config,
  ) async {
    final cache = _snapshotStore;
    if (cache == null || _networkUnavailable) {
      return;
    }
    final inputs = <String, dynamic>{
      'scale_mode': _scaleMode.name,
      'target_servings': _targetServings,
      'target_mold': _targetMold?.toJson(),
      'display_mode': _displayMode.name,
      'personal_measure': measure?.toJson(),
    };
    final dependencies = <String, String?>{
      'recipe_version': detail.version.id,
      'ingredient_catalogue': _catalogueVersion,
      'serving_rules': 'v1',
      'mold_rules': detail.version.snapshot.baseMold == null ? null : 'v1',
      'measure_rules': 'v1',
      'personal_measure_version': measure?.updatedAt,
      'rule_parameters': jsonEncode({
        'min_servings': config.minServings,
        'max_servings': config.maxServings,
        'round_deviation_threshold': config.roundDeviationThreshold,
        'batch_multiplier': config.batchMultiplier,
      }),
      'taste_profile': null,
      'taste_rules': null,
      'safety_rules':
          (detail.version.safety ?? detail.version.safetyAtSave)?.rulesVersion,
    };
    final complete =
        render.serving.ingredients.length ==
            (detail.version.snapshot.ingredients?.length ?? 0) &&
        (_scaleMode != _RecipeScaleMode.mold || render.mold != null);
    final encodedRender = complete ? render.toJson() : null;
    final fingerprint = jsonEncode([
      detail.toJson(),
      inputs,
      encodedRender,
      dependencies,
    ]);
    if (fingerprint == _lastCapture) return;
    _lastCapture = fingerprint;
    final frozen = FrozenRecipeSnapshot(
      detail: detail,
      capturedAt: DateTime.now(),
      inputs: inputs,
      render: encodedRender,
      dependencies: dependencies,
    );
    // This exact render is also kept while a currently visible page loses network.
    _frozenSnapshot = frozen;
    _frozenRender = complete ? render : null;
    try {
      final capacity = await cache.save(frozen);
      if (mounted &&
          cache == _snapshotStore &&
          _capacityMessage != capacity.message) {
        setState(() => _capacityMessage = capacity.message);
      }
    } catch (_) {
      if (mounted && cache == _snapshotStore) {
        setState(() => _capacityMessage = '本机快照保存失败，此版本可能无法离线查看。');
      }
    }
  }

  Future<void> _loadDisplayMetadata(RecipeDetail detail) async {
    final accountId = _viewAccountId;
    final List<String> ids = [
      for (final item in detail.version.snapshot.ingredients ?? const [])
        if (item.ingredientId?.isNotEmpty == true) item.ingredientId!,
    ];
    final densities = <String, double>{};
    try {
      final ingredientRepository = ref.read(ingredientRepositoryProvider);
      await ingredientRepository.sync();
      final ingredients = await ingredientRepository.getMany(ids);
      if (!mounted ||
          !identical(_detail, detail) ||
          _loadedAccountId != ref.read(authProvider).value?.id) {
        return;
      }
      _catalogueVersion = ingredientRepository.version;
      densities.addAll({
        for (final item in ingredients)
          if (item.attributes.density != null)
            item.id: item.attributes.density!.value.toDouble(),
      });
    } catch (_) {
      // Density is optional; a missing catalogue must not hide cached measures.
    }
    List<PersonalMeasureOut> measures = const [];
    try {
      measures = await ref.read(personalMeasureRepositoryProvider).list();
    } catch (_) {
      // Detail pages remain useful offline with base g/ml values and cached data.
    }
    if (!mounted ||
        !identical(_detail, detail) ||
        _networkUnavailable ||
        accountId != _viewAccountId ||
        _loadedAccountId != ref.read(authProvider).value?.id) {
      return;
    }
    setState(() {
      _densities = densities;
      _measures = measures;
      // Selecting the home-measure mode must not silently choose an arbitrary
      // measure; the user explicitly picks which registered utensil to use.
      _selectedMeasureId = measures.any((item) => item.id == _selectedMeasureId)
          ? _selectedMeasureId
          : null;
    });
  }

  Future<void> _refreshDisplayMetadata() async {
    final detail = _detail;
    if (detail == null) return;
    if (mounted) {
      setState(() {
        _displayContractKey = null;
        _displayContract = null;
      });
    }
    await _loadDisplayMetadata(detail);
  }

  void _scheduleDisplayContract({
    required RecipeSnapshot snapshot,
    required int targetServings,
    required MoldSpec? targetMold,
    required MeasureDisplayMode displayMode,
    required String? measureId,
    required String? measureFingerprint,
  }) {
    if (_networkUnavailable) return;
    final activeMold = _scaleMode == _RecipeScaleMode.mold ? targetMold : null;
    final activeServings = _scaleMode == _RecipeScaleMode.servings
        ? targetServings
        : null;
    final key = [
      _loadedAccountId,
      _loadGeneration,
      widget.recipeId,
      _detail?.version.id ?? widget.versionId,
      displayMode.name,
      measureId,
      measureFingerprint,
      activeServings,
      activeMold?.toJson(),
    ].toString();
    if (_displayContractKey == key) return;
    _displayContractKey = key;
    _displayContract = null;
    unawaited(
      _fetchDisplayContract(
        key: key,
        mode: displayMode.name,
        measureId: measureId,
        targetServings: activeServings,
        targetMold: activeMold,
      ),
    );
  }

  Future<void> _fetchDisplayContract({
    required String key,
    required String mode,
    required String? measureId,
    required int? targetServings,
    required MoldSpec? targetMold,
  }) async {
    try {
      final result = await ref
          .read(recipeRepositoryProvider)
          .displayIngredients(
            widget.recipeId,
            mode: mode,
            measureId: measureId,
            targetServings: targetServings,
            targetMold: targetMold,
            // Pin the request to the version on screen: the current-recipe
            // endpoint could already serve a newer version saved elsewhere.
            versionId: _detail?.version.id ?? widget.versionId,
          );
      if (!mounted || _displayContractKey != key || _networkUnavailable) return;
      setState(() => _displayContract = result);
    } catch (_) {
      // The local kernel remains the offline and transient-error fallback.
      if (mounted && _displayContractKey == key) {
        setState(() => _displayContract = null);
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
    final accountId = ref.watch(authProvider).value?.id;
    final offline =
        _offline ||
        ref.watch(offlineSimulationProvider) ||
        ref.watch(apiReachabilityProvider) == ApiReachability.unavailable;
    if (_error != null) {
      final notFound = _error == 'not_found';
      return Scaffold(
        body: _RecipeError(
          message: _error == 'offline_uncached'
              ? '此菜谱版本尚未缓存，需要联网后打开。'
              : notFound
              ? l10n.recipeNotFound
              : l10n.recipeLoadError,
          onRetry: notFound ? null : _load,
        ),
      );
    }
    final detail = _detail;
    if (detail == null || accountId != _loadedAccountId) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final snapshot = detail.version.snapshot;
    if (offline && _frozenRender == null) {
      return Scaffold(
        appBar: AppBar(title: Text(detail.dish.name)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('此版本缺少已保存的换算结果，需要联网查看用量。'),
            ReproducibilityCard(result: detail.version.reproducibility),
            RecipeSafetyProtocolSection(
              result: detail.version.safety ?? detail.version.safetyAtSave,
              legacyDerived: detail.version.derived,
              dishName: detail.dish.name,
              snapshot: snapshot,
              recipeId: widget.recipeId,
              versionId: detail.version.id,
              authoring: false,
              loading: false,
            ),
            for (final step in snapshot.steps ?? const <RecipeStep>[])
              Text(step.instruction),
          ],
        ),
      );
    }
    final derived = detail.version.derived;
    final conversionConfig = ref.watch(recipeConversionConfigProvider);
    final groups = <String, List<RecipeIngredient>>{};
    for (final ingredient in snapshot.ingredients ?? const []) {
      groups
          .putIfAbsent(ingredient.group ?? l10n.recipeIngredientGroup, () => [])
          .add(ingredient);
    }
    final Map<String, String> ingredientNames = {
      for (final ingredient
          in snapshot.ingredients ?? const <RecipeIngredient>[])
        ingredient.id: ingredient.displayName,
    };
    final Map<String, String> stepLabels = {
      for (final (index, step) in (snapshot.steps ?? const []).indexed)
        step.id: '${index + 1}. ${step.instruction}',
    };
    final targetServings = _targetServings ?? snapshot.servings;
    late final ServingConversionResult servingConversion;
    try {
      servingConversion = offline
          ? _frozenRender!.serving
          : _recipeServingConversion(
              snapshot,
              derived,
              targetServings,
              config: conversionConfig,
            );
    } catch (error, stack) {
      developer.log(
        'recipe serving conversion failed',
        name: 'recipe_detail',
        error: error,
        stackTrace: stack,
      );
      servingConversion = ServingConversionResult(
        originalServings: snapshot.servings,
        targetServings: targetServings,
        minServings: conversionConfig.minServings,
        maxServings: conversionConfig.maxServings,
        ingredients: const [],
        steps: const [],
        warnings: const [],
        totalTimeSeconds: derived.totalTimeSeconds,
        activeTimeSeconds: derived.activeTimeSeconds,
      );
    }
    MoldConversionResult? moldConversion;
    String? moldConversionError;
    if (offline) {
      moldConversion = _frozenRender!.mold;
      moldConversionError = _frozenRender!.moldError;
    } else if (snapshot.baseMold != null && _targetMold != null) {
      try {
        moldConversion = _recipeMoldConversion(
          snapshot,
          _targetMold!,
          config: conversionConfig,
        );
      } on MoldConversionError {
        // Keep the target controls visible, but never present an invalid
        // request as a fabricated zero-ratio conversion.
        moldConversionError = l10n.recipeMoldInvalid;
      } catch (_) {
        // A malformed legacy mold must remain visible and actionable without
        // inventing conversion output.
        moldConversionError = l10n.recipeMoldInvalid;
      }
    }
    final convertedServingById = {
      for (final item in servingConversion.ingredients) item.id: item,
    };
    final convertedMoldById = {
      for (final item in moldConversion?.ingredients ?? const []) item.id: item,
    };
    final convertedServingStepsById = {
      for (final item in servingConversion.steps) item.id: item,
    };
    final convertedMoldStepsById = {
      for (final item in moldConversion?.steps ?? const []) item.id: item,
    };
    final servingTargetChanged =
        _scaleMode == _RecipeScaleMode.servings &&
        targetServings != snapshot.servings;
    final moldTargetChanged =
        _scaleMode == _RecipeScaleMode.mold &&
        moldConversion != null &&
        snapshot.baseMold != _targetMold;
    // Times are re-estimated with the conversion rules: step durations and
    // heat never scale, and mold changes never stretch baking time.
    final totalTimeSeconds = _scaleMode == _RecipeScaleMode.servings
        ? servingConversion.totalTimeSeconds
        : derived.totalTimeSeconds;
    final activeTimeSeconds = _scaleMode == _RecipeScaleMode.servings
        ? servingConversion.activeTimeSeconds
        : derived.activeTimeSeconds;
    final String? durationNote;
    if (servingTargetChanged) {
      final largeBatch = servingConversion.steps.any(
        (step) => step.batchWarning,
      );
      durationNote = [
        l10n.recipeDurationServingNote(targetServings),
        if (largeBatch) l10n.recipeDurationBatchNote,
      ].join('');
    } else if (moldTargetChanged) {
      durationNote = l10n.recipeDurationMoldNote;
    } else {
      durationNote = null;
    }
    final selectedMeasure = _measures
        .where((item) => item.id == _selectedMeasureId)
        .firstOrNull;
    // Nested edit routes retain this detail page underneath them. Do not start
    // hidden display requests while the user is editing or restoring drafts.
    if (ModalRoute.of(context)?.isCurrent == true) {
      _scheduleDisplayContract(
        snapshot: snapshot,
        targetServings: targetServings,
        targetMold: _targetMold,
        displayMode: _displayMode,
        measureId: selectedMeasure?.id,
        measureFingerprint: selectedMeasure == null
            ? null
            : '${selectedMeasure.id}:${selectedMeasure.name}:${selectedMeasure.capacityMl}:${selectedMeasure.updatedAt}',
      );
    }
    // Only a contract computed from the version on screen may replace the
    // local kernel's values.
    final displayedContract = offline
        ? _frozenRender!.contract
        : _displayContract;
    final contract = displayedContract?.display.versionId == detail.version.id
        ? displayedContract
        : null;
    final contractById = {
      for (final item in contract?.display.ingredients ?? const [])
        item.id: item,
    };
    final displayedById = offline
        ? _frozenRender!.amounts
        : <String, DisplayedAmount?>{
            for (final ingredient in snapshot.ingredients ?? const [])
              ingredient.id: _displayedAmount(
                ingredient,
                _scaleMode == _RecipeScaleMode.servings
                    ? convertedServingById[ingredient.id]
                    : null,
                convertedMold: _scaleMode == _RecipeScaleMode.mold
                    ? convertedMoldById[ingredient.id]
                    : null,
                contract: contractById[ingredient.id],
                displayMode: _displayMode,
                densities: _densities,
                measure: selectedMeasure,
                // Scale in decimal form, like the server's exact Decimal product;
                // a binary product such as 0.024999999999999997 * 0.2 is already
                // 0.005 and would show a tiny amount as 0.01.
                scaleExactly: _scaleMode == _RecipeScaleMode.servings
                    ? (quantity) => scaleByIntegerRatio(
                        quantity,
                        targetServings,
                        snapshot.servings,
                        fractionDigits: _exactScaleDigits,
                      )
                    : moldConversion == null
                    ? null
                    : (quantity) => moldConversion!.scaleQuantity(
                        quantity,
                        fractionDigits: _exactScaleDigits,
                      ),
              ),
          };
    if (!offline) {
      unawaited(
        _persistDisplayed(
          detail,
          RecipeSnapshotRender(
            serving: servingConversion,
            mold: moldConversion,
            moldError: moldConversionError,
            amounts: displayedById,
            contract: contract,
          ),
          selectedMeasure,
          conversionConfig,
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(detail.dish.name),
        leading: IconButton(
          key: const ValueKey('recipe-list-button'),
          tooltip: l10n.myRecipes,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RecipeListPage.path),
        ),
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
        key: const ValueKey('recipe-detail-content'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (offline)
            _SmallHint(
              text:
                  '离线快照 · 第 ${detail.version.versionNumber} 版 · ${_frozenSnapshot?.capturedAt.toLocal().toIso8601String() ?? ''}',
            ),
          if (_capacityMessage != null) _SmallHint(text: _capacityMessage!),
          if (detail.version.aiAssisted) ...[
            const Text('AI 辅助 · 尚未做过验证'),
            SourceMark(
              sourceType: sourceTypeAiEstimated,
              componentId: 'recipe-ai-design',
              value: '菜谱设计',
              basisText: snapshot.designRationale ?? '一般经验；尚未做过验证',
              required: false,
              feedbackEnabled: false,
              onAction: null,
            ),
          ],
          // Saved explanation and tags belong with the source conclusion, not
          // below long checks where a lazy phone list may not build them yet.
          if (detail.version.changeNote.trim().isNotEmpty)
            Text(
              '${l10n.recipeChangeNote}：${detail.version.changeNote}',
              key: const ValueKey('recipe-change-note'),
            ),
          if (snapshot.tags?.isNotEmpty == true)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in snapshot.tags!) Chip(label: Text(tag)),
              ],
            ),
          ReproducibilityCard(result: detail.version.reproducibility),
          RecipeSafetyProtocolSection(
            result: detail.version.safety ?? detail.version.safetyAtSave,
            legacyDerived: derived,
            dishName: detail.dish.name,
            snapshot: snapshot,
            recipeId: widget.recipeId,
            versionId: detail.version.id,
            authoring: false,
            loading: false,
          ),
          _RecipePhotoDisplay(images: detail.version.images),
          if (widget.versionId == null && !offline)
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
                key: const ValueKey('recipe-duration'),
                label: Text(
                  l10n.recipeDuration(
                    _minutes(totalTimeSeconds),
                    _minutes(activeTimeSeconds),
                  ),
                ),
              ),
              if (snapshot.difficulty?.isNotEmpty == true)
                Chip(
                  label: Text(l10n.recipeDifficultyValue(snapshot.difficulty!)),
                ),
              if (snapshot.dishType?.isNotEmpty == true)
                Chip(label: Text(l10n.recipeDishTypeValue(snapshot.dishType!))),
            ],
          ),
          if (durationNote != null)
            _SmallHint(
              key: const ValueKey('recipe-duration-note'),
              text: durationNote,
            ),
          const SizedBox(height: 12),
          if (!offline) ...[
            if (snapshot.baseMold != null) ...[
              _ScaleModeControl(
                mode: _scaleMode,
                onServing: () => setState(() {
                  _scaleMode = _RecipeScaleMode.servings;
                  _targetServings = snapshot.servings;
                }),
                onMold: () => setState(() {
                  _scaleMode = _RecipeScaleMode.mold;
                  _targetMold ??= snapshot.baseMold;
                }),
              ),
              const SizedBox(height: 8),
            ] else
              _SmallHint(
                key: const ValueKey('recipe-mold-unavailable'),
                text: l10n.recipeMoldUnavailable,
              ),
            if (_scaleMode == _RecipeScaleMode.servings) ...[
              _ServingControl(
                conversion: servingConversion,
                ingredientNames: ingredientNames,
                onChanged: (value) => setState(() => _targetServings = value),
                onReset: () =>
                    setState(() => _targetServings = snapshot.servings),
              ),
              const SizedBox(height: 8),
            ] else
              _MoldControl(
                original: snapshot.baseMold!,
                target: _targetMold!,
                conversion: moldConversion,
                errorText: moldConversionError,
                ingredientNames: ingredientNames,
                onTargetChanged: (value) => setState(() => _targetMold = value),
                onReset: () => setState(() => _targetMold = snapshot.baseMold),
              ),
            if (_scaleMode == _RecipeScaleMode.servings &&
                targetServings >=
                    snapshot.servings * conversionConfig.batchMultiplier)
              BatchAdviceSection(
                key: ValueKey('batch-${detail.version.id}-$targetServings'),
                recipeId: widget.recipeId,
                versionId: detail.version.id,
                targetServings: targetServings,
                snapshot: snapshot,
              ),
            const SizedBox(height: 8),
            _DisplayModeControl(
              mode: _displayMode,
              hasHomeMeasures: _measures.isNotEmpty,
              measures: _measures,
              selectedMeasureId: _selectedMeasureId,
              onMeasureChanged: (id) => setState(() => _selectedMeasureId = id),
              onReload: () => unawaited(_refreshDisplayMetadata()),
              onManageMeasures: () => context.push(PersonalMeasuresPage.path),
              onChanged: (mode) => setState(() => _displayMode = mode),
            ),
          ] else
            _SmallHint(text: '已保存 $targetServings 份的用量与换算结果；离线只读，修改换算需要联网。'),
          const SizedBox(height: 16),
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
              _IngredientDetailRow(
                ingredient: ingredient,
                converted: _scaleMode == _RecipeScaleMode.servings
                    ? convertedServingById[ingredient.id]
                    : null,
                moldConverted: _scaleMode == _RecipeScaleMode.mold
                    ? convertedMoldById[ingredient.id]
                    : null,
                conversionTargetChanged: _scaleMode == _RecipeScaleMode.servings
                    ? targetServings != snapshot.servings
                    : snapshot.baseMold != _targetMold,
                displayed: displayedById[ingredient.id],
                contract: contractById[ingredient.id],
              ),
          ],
          const SizedBox(height: 16),
          // Preserve ordinary serving/ingredient visibility and trailing steps.
          RecipeAnswerSection(
            key: ValueKey(
              'answer-${ref.watch(authProvider).value?.id}-${detail.version.id}',
            ),
            detail: detail,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.recipeStepsTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if ((snapshot.steps ?? const []).isEmpty) Text(l10n.recipeNoSteps),
          for (final (index, step) in (snapshot.steps ?? const []).indexed)
            _StepDetailTile(
              // Lazy scrolling recreates tiles; retain expanded requirements
              // only for this immutable version and stable step identity.
              key: PageStorageKey('step-${detail.version.id}-${step.id}'),
              index: index,
              step: step,
              converted: _scaleMode == _RecipeScaleMode.servings
                  ? convertedServingStepsById[step.id]
                  : null,
              moldConverted: _scaleMode == _RecipeScaleMode.mold
                  ? convertedMoldStepsById[step.id]
                  : null,
              ingredientNames: ingredientNames,
              stepLabels: stepLabels,
              safetyFindings:
                  (detail.version.safety ?? detail.version.safetyAtSave)
                      ?.findings ??
                  const [],
              l10n: l10n,
            ),
          const SizedBox(height: 16),
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

class _ScaleModeControl extends StatelessWidget {
  const _ScaleModeControl({
    required this.mode,
    required this.onServing,
    required this.onMold,
  });

  final _RecipeScaleMode mode;
  final VoidCallback onServing;
  final VoidCallback onMold;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _modeButton(
            context,
            key: const ValueKey('recipe-mode-serving'),
            selected: mode == _RecipeScaleMode.servings,
            icon: Icons.people_outline,
            label: l10n.recipeModeServing,
            onPressed: onServing,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _modeButton(
            context,
            key: const ValueKey('recipe-mode-mold'),
            selected: mode == _RecipeScaleMode.mold,
            icon: Icons.cake_outlined,
            label: l10n.recipeModeMold,
            onPressed: onMold,
          ),
        ),
      ],
    );
  }

  // The selected mode is announced as selected and shows a check icon, so the
  // choice never depends on the background colour alone.
  Widget _modeButton(
    BuildContext context, {
    required Key key,
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) => MergeSemantics(
    child: Semantics(
      selected: selected,
      child: OutlinedButton.icon(
        key: key,
        onPressed: onPressed,
        icon: Icon(selected ? Icons.check : icon),
        label: Text(label),
        style: selected
            ? OutlinedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              )
            : null,
      ),
    ),
  );
}

class _MoldControl extends StatelessWidget {
  const _MoldControl({
    required this.original,
    required this.target,
    required this.conversion,
    required this.errorText,
    required this.ingredientNames,
    required this.onTargetChanged,
    required this.onReset,
  });

  final MoldSpec original;
  final MoldSpec target;
  final MoldConversionResult? conversion;
  final String? errorText;
  final Map<String, String> ingredientNames;
  final ValueChanged<MoldSpec> onTargetChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = GramTreeColors.of(context);
    final warningColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final changed = target != original;
    final round = target.shape == MoldSpecShapeEnum.round;
    final square = target.shape == MoldSpecShapeEnum.square;
    return ComponentCard(
      key: const ValueKey('recipe-mold-control'),
      detail: ComponentDescriptorDetailEnum.standard,
      conclusion: Text(l10n.recipeMoldConversion),
      conclusionSemanticsText: l10n.recipeMoldConversion,
      standardExtra: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const ValueKey('recipe-mold-reset'),
                  onPressed: changed ? onReset : null,
                  child: Text(l10n.recipeMoldReset),
                ),
              ],
            ),
            if (conversion != null)
              Text(
                l10n.recipeMoldOriginal(
                  _moldLabel(original, l10n),
                  conversion!.areaRatio.toStringAsFixed(2),
                ),
                key: const ValueKey('recipe-mold-ratio'),
                style: colors.numberStyle(
                  Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                ),
              )
            else
              _SmallHint(
                key: const ValueKey('recipe-mold-error'),
                text: errorText ?? l10n.recipeMoldInvalid,
              ),
            const SizedBox(height: 8),
            DropdownButtonFormField<MoldSpecShapeEnum>(
              key: const ValueKey('target-mold-shape'),
              initialValue: target.shape,
              decoration: InputDecoration(
                labelText: l10n.recipeMoldTargetShape,
              ),
              items: [
                DropdownMenuItem(
                  value: MoldSpecShapeEnum.round,
                  child: Text(l10n.recipeMoldRound),
                ),
                DropdownMenuItem(
                  value: MoldSpecShapeEnum.square,
                  child: Text(l10n.recipeMoldSquare),
                ),
                DropdownMenuItem(
                  value: MoldSpecShapeEnum.rectangular,
                  child: Text(l10n.recipeMoldRectangular),
                ),
                DropdownMenuItem(
                  value: MoldSpecShapeEnum.custom,
                  child: Text(l10n.recipeMoldCustom),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                onTargetChanged(_moldForShape(target, value));
              },
            ),
            const SizedBox(height: 8),
            if (round)
              Row(
                children: [
                  Expanded(
                    child: _number(
                      key: const ValueKey('target-mold-diameter'),
                      label: l10n.recipeMoldTargetDiameter,
                      value: target.diameter ?? 0,
                      onChanged: (value) => onTargetChanged(
                        _moldWith(target, diameter: double.tryParse(value)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<MoldSpecUnitEnum>(
                      key: const ValueKey('target-mold-unit'),
                      initialValue: target.unit ?? MoldSpecUnitEnum.cm,
                      decoration: InputDecoration(
                        labelText: l10n.recipeMoldUnit,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: MoldSpecUnitEnum.in_,
                          child: Text(l10n.recipeMoldInch),
                        ),
                        DropdownMenuItem(
                          value: MoldSpecUnitEnum.cm,
                          child: Text(l10n.recipeMoldCm),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          onTargetChanged(_moldWith(target, unit: value));
                        }
                      },
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: KeyedSubtree(
                      // A square's side controller must not survive a switch
                      // to a rectangle with a different default width.
                      key: ValueKey('target-mold-width-${target.shape}'),
                      child: _number(
                        key: const ValueKey('target-mold-width'),
                        label: square
                            ? l10n.recipeMoldTargetSide
                            : l10n.recipeMoldTargetWidth,
                        value: target.side ?? target.width ?? 0,
                        onChanged: (value) {
                          final parsed = double.tryParse(value);
                          onTargetChanged(
                            _moldWith(
                              target,
                              side: square ? parsed : null,
                              width: parsed,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (!square) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _number(
                        key: const ValueKey('target-mold-length'),
                        label: l10n.recipeMoldTargetLength,
                        value: target.length ?? 0,
                        onChanged: (value) => onTargetChanged(
                          _moldWith(target, length: double.tryParse(value)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 8),
            Text(l10n.recipeMoldBakingNote),
            for (final warning in conversion?.warnings ?? const [])
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      size: 18,
                      color: warningColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        warning.code == 'round_deviation'
                            ? l10n.recipeMoldRoundWarning(
                                ingredientNames[warning.ingredientId] ??
                                    l10n.recipeIngredients,
                              )
                            : l10n.recipeMoldTimeAdvisory,
                        key: ValueKey(
                          'recipe-mold-warning-${warning.ingredientId}',
                        ),
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: warningColor),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

bool _validMold(MoldSpec mold) {
  if (mold.shape == MoldSpecShapeEnum.round) {
    return mold.diameter != null && mold.diameter! > 0;
  }
  if (mold.unit != null && mold.unit != MoldSpecUnitEnum.cm) return false;
  if (mold.shape == MoldSpecShapeEnum.square) {
    final side = mold.side ?? mold.width;
    return side != null && side > 0;
  }
  return mold.width != null &&
      mold.width! > 0 &&
      mold.length != null &&
      mold.length! > 0;
}

String _moldLabel(MoldSpec mold, AppLocalizations l10n) {
  final unit = mold.unit == MoldSpecUnitEnum.in_
      ? l10n.recipeMoldInch
      : l10n.recipeMoldCm;
  return switch (mold.shape) {
    MoldSpecShapeEnum.round => '${mold.diameter} $unit ${l10n.recipeMoldRound}',
    MoldSpecShapeEnum.square =>
      '${mold.side ?? mold.width} ${l10n.recipeMoldCm} ${l10n.recipeMoldSquare}',
    MoldSpecShapeEnum.rectangular =>
      '${mold.width} × ${mold.length} ${l10n.recipeMoldCm} ${l10n.recipeMoldRectangular}',
    _ =>
      '${mold.width} × ${mold.length} ${l10n.recipeMoldCm} ${l10n.recipeMoldCustom}',
  };
}

class _ServingControl extends StatelessWidget {
  const _ServingControl({
    required this.conversion,
    required this.ingredientNames,
    required this.onChanged,
    required this.onReset,
  });

  final ServingConversionResult conversion;
  final Map<String, String> ingredientNames;
  final ValueChanged<int> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = GramTreeColors.of(context);
    final warningColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final changed = conversion.targetServings != conversion.originalServings;
    return ComponentCard(
      key: const ValueKey('recipe-serving-control'),
      detail: ComponentDescriptorDetailEnum.standard,
      conclusion: Text(l10n.recipeServingsAdjust),
      conclusionSemanticsText: l10n.recipeServingsAdjust,
      standardExtra: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  key: const ValueKey('recipe-serving-decrease'),
                  tooltip: l10n.recipeServingsDecrease,
                  onPressed: conversion.targetServings <= conversion.minServings
                      ? null
                      : () => onChanged(conversion.targetServings - 1),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Semantics(
                  label: l10n.recipeServings,
                  value: '${conversion.targetServings}',
                  child: Text(
                    '${conversion.targetServings}',
                    key: const ValueKey('recipe-serving-value'),
                    style: colors.numberStyle(
                      Theme.of(context).textTheme.titleMedium ??
                          const TextStyle(),
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('recipe-serving-increase'),
                  tooltip: l10n.recipeServingsIncrease,
                  onPressed: conversion.targetServings >= conversion.maxServings
                      ? null
                      : () => onChanged(conversion.targetServings + 1),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                Text(l10n.recipeServingsUnit),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.recipeServingsRange(
                      conversion.minServings,
                      conversion.maxServings,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  key: const ValueKey('recipe-serving-reset'),
                  onPressed: changed ? onReset : null,
                  child: Text(l10n.recipeServingsReset),
                ),
              ],
            ),
            for (final warning in conversion.warnings)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      size: 18,
                      color: warningColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        warning.code == 'round_deviation'
                            ? l10n.recipeServingRoundWarning(
                                ingredientNames[warning.ingredientId] ??
                                    l10n.recipeIngredients,
                              )
                            : warning.message,
                        key: ValueKey(
                          'recipe-serving-warning-${warning.ingredientId}',
                        ),
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: warningColor),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
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

class _DisplayModeControl extends StatelessWidget {
  const _DisplayModeControl({
    required this.mode,
    required this.hasHomeMeasures,
    required this.measures,
    required this.selectedMeasureId,
    required this.onMeasureChanged,
    required this.onReload,
    required this.onManageMeasures,
    required this.onChanged,
  });

  final MeasureDisplayMode mode;
  final bool hasHomeMeasures;
  final List<PersonalMeasureOut> measures;
  final String? selectedMeasureId;
  final ValueChanged<String?> onMeasureChanged;
  final VoidCallback onReload;
  final VoidCallback onManageMeasures;
  final ValueChanged<MeasureDisplayMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = GramTreeColors.of(context);
    return ComponentCard(
      key: const ValueKey('recipe-measure-mode'),
      detail: ComponentDescriptorDetailEnum.standard,
      conclusion: Text(l10n.recipeMeasureModeTitle),
      conclusionSemanticsText: l10n.recipeMeasureModeTitle,
      standardExtra: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  key: const ValueKey('recipe-measure-refresh'),
                  onPressed: onReload,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.recipeMeasureRefresh),
                ),
                if (!hasHomeMeasures)
                  TextButton(
                    key: const ValueKey('recipe-measure-manage'),
                    onPressed: onManageMeasures,
                    child: Text(l10n.recipeMeasureManage),
                  ),
              ],
            ),
            SegmentedButton<MeasureDisplayMode>(
              key: const ValueKey('recipe-display-mode-selector'),
              // Keep selection visible even when colour is unavailable; the
              // segmented control also exposes selected semantics.
              showSelectedIcon: true,
              segments: [
                ButtonSegment(
                  value: MeasureDisplayMode.base,
                  label: Semantics(
                    key: const ValueKey('recipe-display-mode-base'),
                    selected: mode == MeasureDisplayMode.base,
                    child: Text(l10n.recipeMeasureModeBase),
                  ),
                ),
                ButtonSegment(
                  value: MeasureDisplayMode.standard,
                  label: Semantics(
                    key: const ValueKey('recipe-display-mode-standard'),
                    selected: mode == MeasureDisplayMode.standard,
                    child: Text(l10n.recipeMeasureModeStandard),
                  ),
                ),
                ButtonSegment(
                  value: MeasureDisplayMode.home,
                  label: Semantics(
                    key: const ValueKey('recipe-display-mode-home'),
                    selected: mode == MeasureDisplayMode.home,
                    child: Text(l10n.recipeMeasureModeHome),
                  ),
                  enabled: hasHomeMeasures,
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selected) {
                final value = selected.first;
                if (value == MeasureDisplayMode.home && !hasHomeMeasures) {
                  return;
                }
                onChanged(value);
              },
            ),
            if (mode == MeasureDisplayMode.home && hasHomeMeasures)
              DropdownButtonFormField<String>(
                key: const ValueKey('recipe-measure-picker'),
                isExpanded: true,
                initialValue: selectedMeasureId,
                decoration: InputDecoration(
                  labelText: l10n.recipeMeasureChoose,
                ),
                items: [
                  for (final measure in measures)
                    DropdownMenuItem(
                      value: measure.id,
                      child: Text(
                        '${measure.name} · ${l10n.personalMeasuresCapacityValue(measure.capacityMl.toString())}',
                        style: colors.numberStyle(
                          Theme.of(context).textTheme.bodyMedium ??
                              const TextStyle(),
                        ),
                      ),
                    ),
                ],
                onChanged: onMeasureChanged,
              ),
            if (!hasHomeMeasures)
              Padding(
                key: const ValueKey('recipe-measure-empty-hint'),
                padding: const EdgeInsets.only(top: 8),
                child: Text(l10n.recipeMeasureModeNoHome),
              ),
          ],
        ),
      ),
    );
  }
}

class _IngredientDetailRow extends StatelessWidget {
  const _IngredientDetailRow({
    required this.ingredient,
    this.converted,
    this.moldConverted,
    required this.conversionTargetChanged,
    this.displayed,
    this.contract,
  });
  final RecipeIngredient ingredient;
  final ConvertedServingIngredient? converted;
  final ConvertedMoldIngredient? moldConverted;
  final bool conversionTargetChanged;
  final DisplayedAmount? displayed;
  final RecipeDisplayedIngredient? contract;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contractQuantity = contract?.convertedQuantity?.toDouble();
    final convertedQuantity =
        contractQuantity ??
        (converted?.displayQuantity ?? moldConverted?.displayQuantity);
    final convertedUnit =
        contract?.convertedUnit ?? (converted?.unit ?? moldConverted?.unit);
    final convertedRule =
        contract?.conversionRule.value ??
        (converted?.rule ?? moldConverted?.rule);
    final adjusted =
        convertedQuantity != null && convertedQuantity != ingredient.quantity;
    final servingQuantity = adjusted && convertedUnit != null
        ? '${_quantityText(convertedQuantity)} $convertedUnit'
        : '${_quantityText(ingredient.quantity)} ${ingredient.unit}';
    final quantity =
        contract?.text ??
        (displayed == null
            ? servingQuantity
            : localizedDisplayedAmount(displayed!, l10n));
    final noDensity = displayed?.rule == 'no_density';
    final noDensityBasis = l10n.recipeMeasureNoDensity(
      displayed?.baseUnit == 'ml'
          ? l10n.recipeMeasureMillilitre
          : l10n.recipeMeasureGram,
    );
    final systemDisplayChanged =
        displayed != null && displayed!.rule != 'base' && !noDensity;
    final displayChanged = systemDisplayChanged || noDensity;
    final conversionRule = contract?.conversionRule.value;
    // A serving/mold target is active, but this value may still equal the
    // original (an `unchanged` rule, or rounding back to the same count).
    final conversionActive = conversionTargetChanged && convertedRule != null;
    final conversionPresent = conversionActive || adjusted;
    // A measure conversion changes only the expression, not the recipe
    // quantity. Accent and scene provenance are reserved for real serving/mold
    // quantity changes; display-only provenance remains neutral.
    final systemChanged = adjusted;
    final valueChanged = systemChanged;
    final originalQuantity =
        '${_quantityText(ingredient.quantity)} ${ingredient.unit}';
    final source = ingredient.quantitySource;
    final serverSource = contract?.source_;
    final displayOnly = systemDisplayChanged && !conversionActive && !adjusted;
    final sourceType =
        conversionActive &&
            serverSource?.sourceType.value == sourceTypeAuthorFilled
        ? sourceTypeScenarioAdjusted
        : serverSource?.sourceType.value ??
              (conversionActive || systemChanged
                  ? sourceTypeScenarioAdjusted
                  : source?.source_.value ?? sourceTypeAuthorFilled);
    final displayNeutralLabel =
        displayOnly &&
        (sourceType == sourceTypeAuthorFilled ||
            sourceType == sourceTypeScenarioAdjusted);
    final showSource =
        displayOnly ||
        (serverSource != null
            ? serverSource.sourceType.value != sourceTypeAuthorFilled ||
                  conversionActive ||
                  systemDisplayChanged
            : systemChanged ||
                  conversionActive ||
                  systemDisplayChanged ||
                  (source != null &&
                      source.source_.value != sourceTypeAuthorFilled));
    final conversionBasis = conversionPresent
        ? (moldConverted != null || conversionRule == 'mold_ratio'
              ? _conversionRuleLabel(convertedRule ?? '', l10n)
              : _servingRuleLabel(convertedRule ?? '', l10n))
        : null;
    final String sourceBasis;
    if (serverSource != null) {
      sourceBasis = serverSource.basis.text;
    } else if (systemDisplayChanged && conversionBasis != null) {
      sourceBasis =
          '$conversionBasis；${displayed!.rule == 'personal_measure' ? l10n.recipeMeasureDisplayOnly : l10n.recipeMeasureStandardDisplayOnly}';
    } else if (systemDisplayChanged) {
      sourceBasis = displayed!.rule == 'personal_measure'
          ? l10n.recipeMeasureDisplayOnly
          : l10n.recipeMeasureStandardDisplayOnly;
    } else if (noDensity && conversionBasis != null) {
      sourceBasis = '$conversionBasis；$noDensityBasis';
    } else if (noDensity) {
      sourceBasis = noDensityBasis;
    } else if (conversionBasis != null) {
      sourceBasis = conversionBasis;
    } else if (source?.basis?.isNotEmpty == true) {
      sourceBasis = source!.basis!;
    } else {
      sourceBasis = l10n.recipeSourceAuthorFilled;
    }
    final originalSourceValue = serverSource?.originalValue ?? source?.original;
    final subtitleDetails = [
      if (noDensity) noDensityBasis,
      // Unchanged conversion results keep the author's value, so they get
      // no adjustment mark; the applied rule stays visible as text.
      if (conversionActive && !systemChanged && conversionBasis != null)
        l10n.recipeConversionRuleDetail(originalQuantity, conversionBasis),
      if (ingredient.preparation?.isNotEmpty == true) ingredient.preparation!,
      if (ingredient.optional == true) l10n.recipeOptional,
      if (ingredient.functional == true) l10n.recipeFunctionalToggle,
      if (_replacementLabel(ingredient.replacement).isNotEmpty)
        '${l10n.recipeReplacement}：${_replacementLabel(ingredient.replacement)}',
    ];
    final subtitleStyle = GramTreeColors.of(
      context,
    ).numberStyle(Theme.of(context).textTheme.bodyMedium ?? const TextStyle());
    return ListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(
              ingredient.displayName.isEmpty
                  ? l10n.recipeUnknownIngredient
                  : ingredient.displayName,
            ),
          ),
          RecipeSourceBadge(
            key: ValueKey('recipe-source-preparation-${ingredient.id}'),
            source: ingredient.preparationSource,
            value: ingredient.preparation ?? '',
            fieldId: 'recipe-${ingredient.id}-preparation',
          ),
          if (showSource)
            SourceMark(
              key: ValueKey('recipe-source-mark-${ingredient.id}'),
              sourceType: sourceType,
              componentId: displayChanged
                  ? 'recipe-ingredient-${ingredient.id}-measure'
                  : conversionPresent
                  ? 'recipe-ingredient-${ingredient.id}-conversion'
                  : 'recipe-ingredient-${ingredient.id}-quantity',
              value: serverSource?.value ?? quantity,
              originalValue:
                  serverSource?.originalValue ??
                  (systemDisplayChanged || conversionPresent
                      ? originalQuantity
                      : originalSourceValue),
              basisText: {
                sourceBasis,
                if (source?.source_.value == sourceTypeAiEstimated)
                  recipeSourceBasis(source),
              }.join('\n'),
              citation: serverSource?.basis.citation,
              required: false,
              neutral:
                  (displayNeutralLabel && !systemChanged) ||
                  (sourceType == sourceTypeScenarioAdjusted && !systemChanged),
              valueChanged: valueChanged,
              showWhenAuthorFilled:
                  displayNeutralLabel && sourceType == sourceTypeAuthorFilled,
              labelOverride: displayNeutralLabel
                  ? l10n.recipeMeasureDisplaySource
                  : null,
              whyTitleOverride: displayNeutralLabel
                  ? l10n.recipeMeasureDisplaySource
                  : null,
              // SPEC-002.3 only provides deterministic provenance; adjustment
              // feedback belongs to a later recipe-adjustment contract.
              feedbackEnabled: false,
              onAction: null,
            ),
        ],
      ),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: quantity,
              style: valueChanged
                  ? TextStyle(color: GramTreeColors.of(context).accent)
                  : null,
            ),
            for (final detail in subtitleDetails) TextSpan(text: ' · $detail'),
          ],
        ),
        key: ValueKey('recipe-ingredient-amount-${ingredient.id}'),
        style: subtitleStyle,
      ),
    );
  }
}

class _StepDetailTile extends StatelessWidget {
  const _StepDetailTile({
    super.key,
    required this.index,
    required this.step,
    this.converted,
    this.moldConverted,
    required this.ingredientNames,
    required this.stepLabels,
    required this.safetyFindings,
    required this.l10n,
  });

  final int index;
  final RecipeStep step;
  final ConvertedServingStep? converted;
  final ConvertedMoldStep? moldConverted;
  final Map<String, String> ingredientNames;
  final Map<String, String> stepLabels;
  final List<RecipeSafetyFinding> safetyFindings;
  final AppLocalizations l10n;

  Widget _sourceMark(
    BuildContext context, {
    required String field,
    required String value,
    required ValueSource? source,
  }) {
    if (source == null) return const SizedBox.shrink();
    return SourceMark(
      sourceType: source.source_.value,
      componentId: 'recipe-step-${step.id}-$field',
      value: value,
      originalValue: source.original,
      basisText: recipeSourceBasis(source),
      required: false,
      feedbackEnabled: false,
      onAction: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final warningColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final references = (step.ingredientIds ?? const [])
        .map((id) => ingredientNames[id])
        .whereType<String>()
        .join('、');
    final dependencies = (step.dependsOn ?? const [])
        .map((id) => stepLabels[id] ?? id)
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
      if (dependencies.isNotEmpty) '${l10n.recipeStepDepends}：$dependencies',
    ].join(' · ');
    final stepFindings = safetyFindings
        .where(
          (finding) => (finding.stepIds ?? const <String>[]).contains(step.id),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExpansionTile(
          key: ValueKey('recipe-step-$index'),
          title: Text('${index + 1}. ${step.instruction}'),
          subtitle: Text(
            details.isEmpty
                ? (step.action ?? '')
                : '${step.action ?? ''} · $details',
            style: GramTreeColors.of(context).numberStyle(
              Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            ),
          ),
          children: [
            if (converted?.batchWarning == true)
              Container(
                key: ValueKey('recipe-step-batch-warning-${step.id}'),
                margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: warningColor),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l10n.recipeBatchWarning)),
                  ],
                ),
              ),
            if (moldConverted?.donenessWarning == true)
              Container(
                key: ValueKey('recipe-step-doneness-warning-${step.id}'),
                margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                padding: const EdgeInsets.all(10),
                color: Theme.of(context).colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      size: 18,
                      color: warningColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${l10n.recipeMoldTimeAdvisory} ${l10n.recipeMoldDonenessWarning}',
                        style: TextStyle(color: warningColor),
                      ),
                    ),
                  ],
                ),
              ),
            if (step.durationSource != null ||
                step.instructionSource != null ||
                step.donenessSource != null ||
                step.heatSource != null ||
                step.temperatureSource != null)
              Wrap(
                spacing: 8,
                children: [
                  _sourceMark(
                    context,
                    field: 'instruction',
                    value: step.instruction,
                    source: step.instructionSource,
                  ),
                  _sourceMark(
                    context,
                    field: 'doneness',
                    value: step.doneness ?? '',
                    source: step.donenessSource,
                  ),
                  _sourceMark(
                    context,
                    field: 'duration',
                    value: l10n.recipeSeconds(step.durationSeconds ?? 0),
                    source: step.durationSource,
                  ),
                  _sourceMark(
                    context,
                    field: 'heat',
                    value: step.heat ?? '',
                    source: step.heatSource,
                  ),
                  _sourceMark(
                    context,
                    field: 'temperature',
                    value: '${step.temperatureCelsius ?? 0}',
                    source: step.temperatureSource,
                  ),
                ],
              ),
            if (step.notes?.isNotEmpty == true)
              ListTile(
                title: Text(l10n.recipeStepNotes),
                subtitle: Text(step.notes!),
              ),
            if (step.why?.isNotEmpty == true)
              Padding(
                // The nested WhyPanel scroll offset must not read the tile's
                // boolean expansion receipt from the same PageStorage entry.
                key: PageStorageKey('step-why-${step.id}'),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: WhyPanel(
                  sourceType: sourceTypeAuthorFilled,
                  value: step.why!,
                  basisText: l10n.recipeStepWhy,
                  required: true,
                ),
              ),
          ],
        ),
        for (final finding in stepFindings)
          _StepSafetyFinding(finding: finding),
      ],
    );
  }
}

class _StepSafetyFinding extends StatelessWidget {
  const _StepSafetyFinding({required this.finding});

  final RecipeSafetyFinding finding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final highRisk = finding.severity.toString() == 'high_risk';
    final color = highRisk
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.tertiary;
    final details = [
      if (finding.thresholdCelsius != null)
        l10n.recipeSafetyThreshold(finding.thresholdCelsius!.toString()),
      if (finding.restMinutes != null)
        l10n.recipeSafetyRest(finding.restMinutes!),
    ];
    return Container(
      key: ValueKey('recipe-step-safety-finding-${finding.ruleId}'),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Semantics(
        container: true,
        label: [finding.message, finding.basis, ...details].join('，'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              highRisk ? Icons.warning_amber_rounded : Icons.health_and_safety,
              color: color,
              semanticLabel: highRisk
                  ? l10n.recipeSafetyHighRisk
                  : l10n.recipeSafetyWarning,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    finding.message,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (finding.basis.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(finding.basis),
                  ],
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(details.join(' · ')),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
        style: GramTreeColors.of(context).numberStyle(
          Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        ),
      ),
    );
  }
}

class RecipeHistoryPage extends ConsumerStatefulWidget {
  const RecipeHistoryPage({super.key, required this.recipeId});
  final String recipeId;

  @override
  ConsumerState<RecipeHistoryPage> createState() => _RecipeHistoryPageState();
}

class _RecipeHistoryPageState extends ConsumerState<RecipeHistoryPage> {
  List<RecipeVersionSummary> _items = const [];
  String? _nextCursor;
  Object? _error;
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadFirst());
  }

  Future<void> _loadFirst() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(recipeRepositoryProvider)
          .historyPage(widget.recipeId);
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _nextCursor = page.nextCursor;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (_loadingMore || cursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(recipeRepositoryProvider)
          .historyPage(widget.recipeId, cursor: cursor);
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...page.items];
        _nextCursor = page.nextCursor;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null && _items.isEmpty) {
      body = _RecipeError(message: l10n.recipeLoadError, onRetry: _loadFirst);
    } else if (_items.isEmpty) {
      body = Center(child: Text(l10n.recipeNoHistory));
    } else {
      body = ListView(
        children: [
          for (final item in _items)
            ListTile(
              key: ValueKey('recipe-version-${item.versionNumber}'),
              title: Text(
                l10n.recipeVersionTitle(
                  item.versionNumber,
                  item.aiAssisted ? l10n.recipeAiAssisted : '',
                ),
              ),
              subtitle: Text(
                '${item.changeNote.isEmpty ? l10n.recipeNoChangeNote : item.changeNote}\n${l10n.recipeVersionDate(_formatDate(context, item.createdAt))}',
                style: GramTreeColors.of(context).numberStyle(
                  Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                ),
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(
                '/recipes/${widget.recipeId}/versions/${item.id}',
              ),
            ),
          if (_nextCursor != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                key: const ValueKey('recipe-history-load-more'),
                onPressed: _loadingMore ? null : _loadMore,
                icon: _loadingMore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more),
                label: Text(
                  _error == null
                      ? l10n.recipeLoadMore
                      : l10n.recipeLoadMoreRetry,
                ),
              ),
            ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recipeHistory)),
      body: body,
    );
  }
}

class _SmallHint extends StatelessWidget {
  const _SmallHint({super.key, required this.text});
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
  const _RecipeError({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        if (onRetry != null)
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
  TextStyle? style,
  int maxLines = 1,
}) => TextFormField(
  key: key,
  controller: controller,
  initialValue: controller == null ? value : null,
  maxLines: maxLines,
  style: style,
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
  style: const TextStyle(fontFamily: numberFont),
  onChanged: onChanged,
);

List<String> _split(String value) => value
    .split(RegExp(r'[,，]'))
    .map((item) => item.trim())
    .where((item) => item.isNotEmpty)
    .toList();

int _minutes(int? seconds) => ((seconds ?? 0) / 60).ceil();
String _decimal(num? value) => value == null ? '—' : value.toStringAsFixed(1);
String _formatDate(BuildContext context, String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  final local = parsed.toLocal();
  return '${MaterialLocalizations.of(context).formatMediumDate(local)} '
      '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

// Exact scaled amounts keep enough decimals that a product just below the
// 0.005 display threshold cannot be rounded up to it before formatting.
const _exactScaleDigits = 20;

String _quantityText(num value) {
  final number = value.toDouble();
  if (number > 0 && number < 0.005) return '<0.01';
  if (number == number.roundToDouble()) return number.toInt().toString();
  final rounded = roundHalfUp(number, fractionDigits: 2);
  return rounded
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

const _countDisplayUnits = {
  '个',
  '只',
  '颗',
  '粒',
  '瓣',
  '头',
  '根',
  '条',
  '片',
  '块',
  '张',
  '棵',
  '朵',
  '枚',
};

const _scalingLibraryDefaultValue = 'library_default';

String _scalingModeLabel(String rule, AppLocalizations l10n) => switch (rule) {
  'unchanged' => l10n.recipeScalingUnchanged,
  'round' => l10n.recipeScalingRound,
  _ => l10n.recipeScalingProportional,
};

String _servingRuleLabel(String rule, AppLocalizations l10n) => switch (rule) {
  'proportional' => l10n.recipeRuleProportional,
  'unchanged' => l10n.recipeRuleUnchanged,
  'round' => l10n.recipeRuleRound,
  _ => l10n.recipeRuleUnknown,
};

DisplayedAmount? _displayedAmount(
  RecipeIngredient ingredient,
  ConvertedServingIngredient? converted, {
  ConvertedMoldIngredient? convertedMold,
  RecipeDisplayedIngredient? contract,
  required MeasureDisplayMode displayMode,
  required Map<String, double> densities,
  required PersonalMeasureOut? measure,
  double Function(double quantity)? scaleExactly,
}) {
  // A positive proportional amount that rounds to `0` keeps its exact scaled
  // value, so it is shown as "<0.01" instead of disappearing. Every other
  // amount uses the kernel's decimal half-up result.
  final roundedQuantity =
      contract?.convertedQuantity?.toDouble() ??
      convertedMold?.displayQuantity ??
      converted?.displayQuantity;
  final proportional =
      scaleExactly != null &&
      {'proportional', 'mold_ratio'}.contains(
        contract?.conversionRule.value ??
            convertedMold?.rule ??
            converted?.rule,
      );
  final tinyProportional =
      proportional &&
      roundedQuantity == 0 &&
      ingredient.quantity != 0 &&
      {'proportional', 'mold_ratio'}.contains(
        contract?.conversionRule.value ??
            convertedMold?.rule ??
            converted?.rule,
      );
  if (contract != null) {
    final contractBaseUnit =
        ingredient.baseUnit?.value ?? _displayBaseUnit(ingredient.unit);
    var contractBaseQuantity =
        ingredient.baseQuantity?.toDouble() ?? ingredient.quantity.toDouble();
    final contractQuantity = contract.convertedQuantity?.toDouble();
    if (contractBaseUnit != 'count' && proportional) {
      contractBaseQuantity = scaleExactly(contractBaseQuantity);
    } else if (contractBaseUnit != 'count' &&
        contractQuantity != null &&
        ingredient.quantity != 0) {
      contractBaseQuantity *= contractQuantity / ingredient.quantity;
    }
    final baseRule =
        contract.rule.value == 'base' || contract.rule.value == 'no_density';
    return DisplayedAmount(
      text: contract.text,
      displayQuantity: baseRule && tinyProportional
          ? contractBaseQuantity
          : contract.displayQuantity.toDouble(),
      displayUnit: contract.displayUnit,
      grams: contract.grams?.toDouble(),
      rule: contract.rule.value,
      baseQuantity: contractBaseQuantity,
      baseUnit: contractBaseUnit,
    );
  }
  final convertedQuantity =
      convertedMold?.displayQuantity ??
      converted?.displayQuantity ??
      ingredient.quantity.toDouble();
  final originalQuantity =
      convertedMold?.originalQuantity ??
      converted?.originalQuantity ??
      ingredient.quantity.toDouble();
  if (_countDisplayUnits.contains(ingredient.unit.trim().toLowerCase())) {
    final shownQuantity = tinyProportional
        ? scaleExactly(ingredient.quantity.toDouble())
        : convertedQuantity;
    return DisplayedAmount(
      text: '${_quantityText(shownQuantity)} ${ingredient.unit}',
      displayQuantity: shownQuantity,
      displayUnit: ingredient.unit,
      grams: null,
      rule: 'base',
    );
  }
  final baseUnit =
      ingredient.baseUnit?.value ?? _displayBaseUnit(ingredient.unit);
  if (baseUnit == null) return null;
  if (baseUnit == 'count') {
    final shownQuantity = tinyProportional
        ? scaleExactly(ingredient.quantity.toDouble())
        : convertedQuantity;
    return DisplayedAmount(
      text: '${_quantityText(shownQuantity)} ${ingredient.unit}',
      displayQuantity: shownQuantity,
      displayUnit: ingredient.unit,
      grams: null,
      rule: 'base',
    );
  }
  var baseQuantity =
      ingredient.baseQuantity?.toDouble() ?? ingredient.quantity.toDouble();
  if (tinyProportional) {
    baseQuantity = scaleExactly(baseQuantity);
  } else if (originalQuantity != 0) {
    baseQuantity *= convertedQuantity / originalQuantity;
  }
  final density = densities[ingredient.ingredientId];
  // Home-measure mode is a deliberate choice, but the utensil itself is also
  // a deliberate choice. Until the picker has a selection, keep the page
  // usable by showing the base quantity rather than silently choosing one or
  // throwing from the display formatter.
  final effectiveMode =
      displayMode == MeasureDisplayMode.home && measure == null
      ? MeasureDisplayMode.base
      : displayMode;
  return displayAmount(
    DisplayMeasureInput(
      baseQuantity: baseQuantity,
      baseUnit: baseUnit,
      density: density,
      mode: effectiveMode,
      measure: measure,
    ),
  );
}

String? _displayBaseUnit(String unit) {
  final normalized = unit.trim().toLowerCase();
  if ({'g', '克', 'kg', '千克', '公斤'}.contains(normalized)) return 'g';
  if ({
    'ml',
    '毫升',
    'l',
    '升',
    '勺',
    '大勺',
    '汤匙',
    'tbsp',
    '小勺',
    '茶匙',
    'tsp',
  }.contains(normalized)) {
    return 'ml';
  }
  return null;
}

// The pure row helper receives immutable snapshots from the page state.
String _conversionRuleLabel(String rule, AppLocalizations l10n) =>
    switch (rule) {
      'proportional' || 'mold_ratio' =>
        rule == 'mold_ratio'
            ? l10n.recipeRuleMoldRatio
            : l10n.recipeRuleProportional,
      'unchanged' => l10n.recipeRuleUnchanged,
      'round' => l10n.recipeRuleRound,
      _ => l10n.recipeRuleUnknown,
    };

/// A saved recipe version owns its scaling mode. Legacy snapshots with a null
/// mode use the immutable proportional fallback rather than today's library.
String _scalingRule(RecipeIngredient item) =>
    item.scalingMode?.value ?? 'proportional';

ServingConversionResult _recipeServingConversion(
  RecipeSnapshot snapshot,
  RecipeDerived derived,
  int targetServings, {
  required RecipeConversionConfig config,
}) => convertServings(
  originalServings: snapshot.servings,
  targetServings: targetServings,
  ingredients: [
    for (final item in snapshot.ingredients ?? const [])
      ServingIngredientInput(
        id: item.id,
        displayName: item.displayName,
        quantity: item.quantity.toDouble(),
        unit: item.unit,
        scalingMode: _scalingRule(item),
      ),
  ],
  steps: [
    for (final item in snapshot.steps ?? const [])
      ServingStepInput(
        id: item.id,
        instruction: item.instruction,
        ingredientIds: [...?item.ingredientIds],
        durationSeconds: item.durationSeconds ?? 0,
        temperatureCelsius: item.temperatureCelsius?.toDouble(),
        heat: item.heat,
        unattended: item.unattended == true,
        dependsOn: [...?item.dependsOn],
      ),
  ],
  minServings: config.minServings,
  maxServings: config.maxServings,
  roundDeviationThreshold: config.roundDeviationThreshold,
  batchMultiplier: config.batchMultiplier,
  totalTimeSeconds: derived.totalTimeSeconds,
  activeTimeSeconds: derived.activeTimeSeconds,
);

MoldConversionResult _recipeMoldConversion(
  RecipeSnapshot snapshot,
  MoldSpec target, {
  required RecipeConversionConfig config,
}) => convertMold(
  originalMold: snapshot.baseMold!,
  targetMold: target,
  ingredients: [
    for (final item in snapshot.ingredients ?? const [])
      MoldIngredientInput(
        id: item.id,
        displayName: item.displayName,
        quantity: item.quantity.toDouble(),
        unit: item.unit,
        scalingMode: _scalingRule(item),
      ),
  ],
  steps: [
    for (final item in snapshot.steps ?? const [])
      MoldStepInput(
        id: item.id,
        instruction: item.instruction,
        durationSeconds: item.durationSeconds ?? 0,
        temperatureCelsius: item.temperatureCelsius?.toDouble(),
        heat: item.heat,
        action: item.action,
        cookware: item.cookware,
      ),
  ],
  roundDeviationThreshold: config.roundDeviationThreshold,
);

String _replacementLabel(Object? value) {
  if (value is String) return value;
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
