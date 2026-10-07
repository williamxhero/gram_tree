import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../recipes/recipe_repository.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import '../../ui_protocol/recipe_safety.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';
import '../recipes/recipe_pages.dart';

/// A thin retrieval/choice surface. Generation, validation and provenance are
/// server-owned; editing uses the existing complete structured recipe editor.
class OneLineRecipePage extends ConsumerStatefulWidget {
  const OneLineRecipePage({super.key});
  static const path = '/recipes/one-line';

  @override
  ConsumerState<OneLineRecipePage> createState() => _OneLineRecipePageState();
}

class _OneLineRecipePageState extends ConsumerState<OneLineRecipePage> {
  final _text = TextEditingController();
  final _servings = TextEditingController();
  final _cookware = TextEditingController();
  AIStatus? _status;
  RetrievalResult? _found;
  GenerationResult? _result;
  String? _error;
  bool _busy = false;
  bool _questions = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadStatus());
  }

  Future<void> _loadStatus() async {
    try {
      final status = await ref.read(recipeRepositoryProvider).aiStatus();
      if (mounted) setState(() => _status = status);
    } catch (_) {
      if (mounted) setState(() => _error = '暂时无法读取 AI 状态，仍可检索或手动新建。');
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = ApiFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _find() => _run(() async {
    if (_text.text.trim().isEmpty) {
      setState(() => _error = '先写下想做的菜和限制。');
      return;
    }
    setState(() {
      _found = null;
      _result = null;
      _questions = false;
    });
    final found = await ref
        .read(recipeRepositoryProvider)
        .findForRequest(_text.text.trim());
    if (!mounted) return;
    setState(() {
      _found = found;
      _status = found.status;
    });
  });

  Future<void> _generate({required bool skip}) => _run(() async {
    final count = skip || _servings.text.trim().isEmpty
        ? null
        : int.tryParse(_servings.text);
    if (!skip &&
        _servings.text.isNotEmpty &&
        (count == null || count < 1 || count > 100)) {
      setState(() => _error = '人数请填写 1 到 100 的整数，或跳过。');
      return;
    }
    final result = await ref
        .read(recipeRepositoryProvider)
        .generate(
          _found!.requestId,
          GenerateInput(
            servings: count,
            cookware: skip || _cookware.text.trim().isEmpty
                ? null
                : _cookware.text.trim(),
          ),
        );
    if (!mounted) return;
    setState(() {
      _result = result;
      _status = result.status;
      _questions = false;
      _error = result.error == null ? null : _reason(result.error);
    });
  });

  Future<void> _existing(SimilarRecipe recipe) => _run(() async {
    final detail = await ref
        .read(recipeRepositoryProvider)
        .chooseExisting(_found!.requestId, recipe.recipeId);
    if (mounted) context.push('/recipes/${detail.id}');
  });

  @override
  void dispose() {
    _text.dispose();
    _servings.dispose();
    _cookware.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final found = _found;
    final result = _result;
    final draft = result?.draft;
    return Scaffold(
      appBar: AppBar(title: const Text('一句话生成菜谱')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text('想做点什么？', style: Theme.of(context).textTheme.headlineSmall),
          const Text('先找你已有的菜谱，再决定是否让 AI 设计。请勿输入个人敏感信息。'),
          const SizedBox(height: 12),
          Text(
            _status == null ? '正在读取今日额度…' : '今日生成剩余 ${_status!.remaining} 次',
            key: const ValueKey('ai-quota'),
            style: const TextStyle(fontFamily: 'DM Mono'),
          ),
          if (_status?.available == false) Text(_reason(_status?.reason)),
          TextField(
            key: const ValueKey('one-line-input'),
            controller: _text,
            enabled: !_busy,
            maxLength: 1000,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '一句话需求',
              hintText: '想做一道小朋友能吃的、不辣的宫保鸡丁',
            ),
            onChanged: (_) => setState(() {
              _found = null;
              _result = null;
              _questions = false;
              _error = null;
            }),
            onSubmitted: (_) => _find(),
          ),
          FilledButton(
            key: const ValueKey('one-line-search'),
            onPressed: _busy ? null : _find,
            child: const Text('先找已有菜谱'),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) Text(_error!, key: const ValueKey('ai-error')),
          if (found != null) ...[
            const SizedBox(height: 16),
            Text(
              '已有菜谱 · ${found.recipes.length} 道',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (found.localFallback == true)
              const Text('模型暂不可用，已用本地关键词检索；原始输入仍保留。'),
            if (found.recipes.isEmpty) const Text('没有找到相似的私有菜谱。'),
            for (final recipe in found.recipes)
              ComponentCard(
                detail: ComponentDescriptorDetailEnum.standard,
                conclusion: Text('${recipe.dishName} · ${recipe.servings} 人份'),
                conclusionSemanticsText: recipe.dishName,
                basisText: recipe.basis,
                primaryActionLabel: '用这道已有菜谱',
                onPrimaryAction: _busy ? null : () => _existing(recipe),
              ),
            OutlinedButton(
              key: const ValueKey('ai-design-new'),
              onPressed: _busy ? null : () => setState(() => _questions = true),
              child: const Text('让 AI 设计新版本'),
            ),
            if (_questions) ...[
              const Text('最多补充两个关键信息；全部可跳过，默认 2 人份和常用锅具。'),
              for (final question in found.questions)
                TextField(
                  key: ValueKey('ai-question-${question.key.value}'),
                  controller: question.key.value == 'servings'
                      ? _servings
                      : _cookware,
                  keyboardType: question.key.value == 'servings'
                      ? TextInputType.number
                      : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: question.text,
                    hintText: question.default_,
                  ),
                ),
              FilledButton(
                key: const ValueKey('ai-generate'),
                onPressed: _busy ? null : () => _generate(skip: false),
                child: const Text('按这些信息生成'),
              ),
              TextButton(
                key: const ValueKey('ai-skip-questions'),
                onPressed: _busy ? null : () => _generate(skip: true),
                child: const Text('跳过，直接生成'),
              ),
            ],
            if (result?.error != null)
              TextButton(
                key: const ValueKey('ai-retry'),
                onPressed: _busy ? null : () => _generate(skip: false),
                child: const Text('保留原话，重试生成'),
              ),
          ],
          if (draft != null) ...[
            ComponentCard(
              detail: ComponentDescriptorDetailEnum.detailed,
              conclusion: Text(
                '${draft.recipe.dishName ?? ''} · AI 辅助 · 尚未做过验证',
              ),
              conclusionSemanticsText: 'AI 辅助菜谱，尚未做过验证',
              basisText: draft.rationale,
              standardExtra: SourceMark(
                sourceType: sourceTypeAiEstimated,
                componentId: 'one-line-draft',
                value: '用量、火候与时长',
                basisText: draft.rationale,
                required: false,
                feedbackEnabled: false,
                onAction: null,
              ),
              detailedExtra: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '菜系：${draft.cuisine} · 菜型：${draft.recipe.snapshot.dishType ?? ''}',
                  ),
                  for (final item
                      in draft.recipe.snapshot.ingredients ??
                          const <RecipeIngredient>[])
                    Text(
                      '${item.displayName} ${item.quantity} ${item.unit} · AI 估算',
                    ),
                  for (final step
                      in draft.recipe.snapshot.steps ?? const <RecipeStep>[])
                    Text(
                      '${step.instruction}\n${step.durationSeconds} 秒 · ${step.heat ?? ''} · ${step.cookware ?? ''}\n原理：${step.why ?? ''}',
                    ),
                ],
              ),
            ),
            FoodSafetyCard(result: result!.safety),
            AllergenCard(result: result.safety),
            for (final warning in [
              ...?result.numericWarnings,
              ...?result.ingredientConfirmations,
            ])
              Text(warning),
            FilledButton(
              key: const ValueKey('ai-edit-draft'),
              onPressed: _busy
                  ? null
                  : () => context.push(RecipeEditorPage.path, extra: result),
              child: const Text('编辑并保存为我的第一版'),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            key: const ValueKey('ai-manual-fallback'),
            onPressed: _busy ? null : () => context.push(RecipeEditorPage.path),
            child: const Text('不用 AI，手动新建'),
          ),
          const Text('模型不可用、额度用完或预算暂停时，查看、编辑和手动保存不受影响。'),
        ],
      ),
    );
  }
}

String _reason(String? reason) => switch (reason) {
  'daily_quota' => '今日生成额度已用完。仍可使用已有菜谱或手动新建。',
  'monthly_budget' => '平台月预算已达到上限，AI 暂停。仍可手动新建。',
  'invalid_output' => 'AI 回答校验未通过，已纠正一次仍失败。原始输入已保留，可重试或手动新建。',
  'configuration' => '模型配置暂不可用。仍可检索已有菜谱或手动新建。',
  _ => '模型暂不可用。原始输入已保留，可重试或手动新建。',
};
