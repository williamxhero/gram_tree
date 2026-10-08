import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../l10n/app_localizations.dart';
import '../../recipes/recipe_repository.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import '../../ui_protocol/intent_dispatcher.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';
import 'comparison_assistance_cards.dart';
import 'comparison_cards.dart';
import 'comparison_snapshot_details.dart';
import 'recipe_source_badge.dart';

/// Presentation of server-owned alignment and grades; never recalculates either.
class FullComparisonPage extends ConsumerStatefulWidget {
  const FullComparisonPage({
    super.key,
    required this.recipeId,
    required this.fromVersionId,
    required this.toVersionId,
  });

  final String recipeId;
  final String fromVersionId;
  final String toVersionId;

  @override
  ConsumerState<FullComparisonPage> createState() => _FullComparisonPageState();
}

typedef _ComparisonData = ({
  RecipeFullComparison comparison,
  RecipeSnapshot before,
  RecipeSnapshot after,
});

class _FullComparisonPageState extends ConsumerState<FullComparisonPage> {
  late Future<_ComparisonData> _result;
  late Future<RecipeComparisonAssistance?> _assistance;
  int _loadGeneration = 0;
  bool _showAll = false;
  bool _expandDetails = false;
  bool _stacked = false;
  String _grade = 'all';
  String _section = 'all';
  String _kind = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final generation = ++_loadGeneration;
    final recipeId = widget.recipeId;
    final from = widget.fromVersionId;
    final to = widget.toVersionId;
    _result = _fetch();
    // Optional assistance is never awaited by the authoritative comparison.
    // Decode/network/model failures leave the full deterministic page intact.
    _assistance = _result
        .then<RecipeComparisonAssistance?>((_) {
          if (!mounted || generation != _loadGeneration) return null;
          return ref
              .read(recipeRepositoryProvider)
              .compareAssistance(recipeId, from, to);
        })
        .catchError((Object _) => null);
  }

  Future<_ComparisonData> _fetch() async {
    final repository = ref.read(recipeRepositoryProvider);
    final comparison = await repository.compareFull(
      widget.recipeId,
      widget.fromVersionId,
      widget.toVersionId,
    );
    // Comparison rows contain normalized B base quantities. Immutable version
    // snapshots are the only honest source for the original-detail layer.
    final versions = await Future.wait([
      repository.getVersion(
        comparison.fromVersion.recipeId,
        comparison.fromVersion.versionId,
      ),
      repository.getVersion(
        comparison.toVersion.recipeId,
        comparison.toVersion.versionId,
      ),
    ]);
    return (
      comparison: comparison,
      before: versions[0].version.snapshot,
      after: versions[1].version.snapshot,
    );
  }

  @override
  void didUpdateWidget(covariant FullComparisonPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipeId != widget.recipeId ||
        oldWidget.fromVersionId != widget.fromVersionId ||
        oldWidget.toVersionId != widget.toVersionId) {
      _load();
    }
  }

  bool _includes(String section, String? grade, [String? kind]) =>
      (_section == 'all' || _section == section) &&
      (_grade == 'all' || _grade == grade) &&
      (_kind == 'all' || _kind == kind);

  bool _validAssistance(
    RecipeComparisonAssistance assistance,
    _ComparisonData data,
  ) {
    final comparison = data.comparison;
    if (assistance.fromVersionId != comparison.fromVersion.versionId ||
        assistance.toVersionId != comparison.toVersion.versionId ||
        assistance.rulesVersion != comparison.rulesVersion) {
      return false;
    }
    final before = {
      for (final row in comparison.steps)
        if (row.alignment.value == 'uncertain' && row.before != null)
          row.before!.id,
    };
    final after = {
      for (final row in comparison.steps)
        if (row.alignment.value == 'uncertain' && row.after != null)
          row.after!.id,
    };
    final savedBefore = {
      for (final step in (data.before.steps ?? <RecipeStep>[])) step.id,
    };
    final savedAfter = {
      for (final step in (data.after.steps ?? <RecipeStep>[])) step.id,
    };
    final usedBefore = <String>{};
    final usedAfter = <String>{};
    for (final pair in assistance.alignments ?? <AssistedStepPair>[]) {
      // Confidence acceptance belongs to the server. Only reject values outside
      // the wire domain, references outside the authorized uncertain pools, and
      // conflicting display mappings. Do not derive an alignment or a grade.
      if (pair.alignment != AssistedStepPairAlignmentEnum.aiAssisted ||
          pair.sourceType != AssistedStepPairSourceTypeEnum.aiEstimated ||
          !pair.confidence.isFinite ||
          pair.confidence < 0 ||
          pair.confidence > 1 ||
          !before.contains(pair.beforeStepId) ||
          !after.contains(pair.afterStepId) ||
          !savedBefore.contains(pair.beforeStepId) ||
          !savedAfter.contains(pair.afterStepId) ||
          !usedBefore.add(pair.beforeStepId) ||
          !usedAfter.add(pair.afterStepId)) {
        return false;
      }
    }
    final interpretation = assistance.interpretation;
    return interpretation == null ||
        (interpretation.sourceType == SourcedValueSourceTypeEnum.aiEstimated &&
            interpretation.basis.reasonCode == 'general_experience' &&
            interpretation.value.trim().isNotEmpty);
  }

  Widget _assistancePanel(_ComparisonData data, bool sideBySide) {
    final comparison = data.comparison;
    return FutureBuilder<RecipeComparisonAssistance?>(
      key: ValueKey(
        'assistance-${comparison.fromVersion.versionId}-${comparison.toVersion.versionId}-${comparison.rulesVersion}',
      ),
      future: _assistance,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            key: ValueKey('comparison-assistance-loading'),
            padding: EdgeInsets.all(16),
            child: Text('AI 辅助加载中；确定性比较已可使用。'),
          );
        }
        final response = snapshot.data;
        final assistance =
            response != null &&
                response.status == RecipeComparisonAssistanceStatusEnum.ready &&
                _validAssistance(response, data)
            ? response
            : null;
        final pairs = assistance?.alignments ?? <AssistedStepPair>[];
        final beforeSteps = {
          for (final step in (data.before.steps ?? <RecipeStep>[]))
            step.id: step,
        };
        final afterSteps = {
          for (final step in (data.after.steps ?? <RecipeStep>[]))
            step.id: step,
        };
        final beforeNumbers = {
          for (final (index, step)
              in (data.before.steps ?? <RecipeStep>[]).indexed)
            step.id: index + 1,
        };
        final afterNumbers = {
          for (final (index, step)
              in (data.after.steps ?? <RecipeStep>[]).indexed)
            step.id: index + 1,
        };
        return Column(
          key: ValueKey(
            assistance == null
                ? 'comparison-assistance-unavailable'
                : 'comparison-assistance-ready',
          ),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ComparisonInterpretationCard(
              interpretation: assistance?.interpretation,
              rulesVersion: comparison.rulesVersion,
            ),
            if (_includes('steps', null)) ...[
              if (pairs.isEmpty &&
                  comparison.steps.any(
                    (row) => row.alignment.value == 'uncertain',
                  ))
                const Padding(
                  key: ValueKey('comparison-assistance-unaligned'),
                  padding: EdgeInsets.all(16),
                  child: Text('未能对齐 · 双方原文保留；幅度与结论仍由确定规则判定。'),
                ),
              for (final (index, pair) in pairs.indexed)
                ComparisonAssistedStepCard(
                  id: '$index',
                  pair: pair,
                  before: beforeSteps[pair.beforeStepId]!,
                  after: afterSteps[pair.afterStepId]!,
                  beforeIndex: beforeNumbers[pair.beforeStepId]!,
                  afterIndex: afterNumbers[pair.afterStepId]!,
                  rulesVersion: comparison.rulesVersion,
                  sideBySide: sideBySide,
                  expandDetails: _expandDetails,
                  beforeIngredientNames: {
                    for (final item
                        in (data.before.ingredients ?? <RecipeIngredient>[]))
                      item.id: item.displayName,
                  },
                  afterIngredientNames: {
                    for (final item
                        in (data.after.ingredients ?? <RecipeIngredient>[]))
                      item.id: item.displayName,
                  },
                  beforeStepNumbers: beforeNumbers,
                  afterStepNumbers: afterNumbers,
                ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('完整版本对比')),
      body: FutureBuilder<_ComparisonData>(
        key: ValueKey(
          '${widget.recipeId}-${widget.fromVersionId}-${widget.toVersionId}',
        ),
        future: _result,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.recipeComparisonError),
                  TextButton(
                    onPressed: () => setState(_load),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data!.comparison;
          final size = MediaQuery.sizeOf(context);
          final sideBySide =
              !_stacked && (size.width >= 600 || size.width > size.height);
          final cards = _cards(
            result,
            sideBySide,
            snapshot.data!.before,
            snapshot.data!.after,
          );
          return ListView(
            key: const ValueKey('full-comparison-content'),
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: ComparisonPair(
                  before: _version(result.fromVersion, 'A · 从', 'a'),
                  after: _version(result.toVersion, 'B · 到', 'b'),
                  sideBySide: sideBySide,
                ),
              ),
              ComponentCard(
                key: const ValueKey('full-comparison-conclusion'),
                detail: ComponentDescriptorDetailEnum.standard,
                conclusion: Text(
                  comparisonConclusionLabel(result.conclusion.value),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                conclusionSemanticsText: comparisonConclusionLabel(
                  result.conclusion.value,
                ),
                standardExtra: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('确定规则 · 规则版本 ${result.rulesVersion}'),
                    const Text('结论由确定规则计算，不依赖 AI；不影响保存。'),
                    SourceMark(
                      key: const ValueKey('full-comparison-why'),
                      sourceType: sourceTypeAuthorFilled,
                      componentId: 'recipe-comparison-conclusion',
                      value: comparisonConclusionLabel(result.conclusion.value),
                      basisText: result.basis.join('\n'),
                      citation: '规则版本：${result.rulesVersion}',
                      required: false,
                      neutral: true,
                      showWhenAuthorFilled: true,
                      feedbackEnabled: false,
                      labelOverride: '为什么这样判断',
                      whyTitleOverride: '版本变化依据',
                      onAction: null,
                    ),
                  ],
                ),
              ),
              _assistancePanel(snapshot.data!, sideBySide),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.recipeComparisonServings(result.normalizedServings),
                ),
              ),
              if (result.fromVersion.servings != result.toVersion.servings)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SourceMark(
                    sourceType: sourceTypeScenarioAdjusted,
                    componentId: 'full-comparison-servings',
                    value: l10n.recipeComparisonServingValue(
                      result.normalizedServings,
                    ),
                    originalValue: l10n.recipeComparisonServingValue(
                      result.toVersion.servings,
                    ),
                    basisText: l10n.recipeComparisonServingBasis,
                    required: true,
                    feedbackEnabled: false,
                    onAction: null,
                  ),
                ),
              SwitchListTile(
                key: const ValueKey('full-compare-show-all'),
                title: Text(l10n.recipeComparisonShowAll),
                value: _showAll,
                onChanged: (value) => setState(() => _showAll = value),
              ),
              SwitchListTile(
                key: const ValueKey('full-compare-expand-all'),
                title: const Text('展开全部明细'),
                value: _expandDetails,
                onChanged: (value) => setState(() => _expandDetails = value),
              ),
              SwitchListTile(
                key: const ValueKey('full-compare-stacked'),
                title: const Text('上下显示'),
                subtitle: const Text('默认按屏幕采用上下或左右对比'),
                value: _stacked,
                onChanged: (value) => setState(() => _stacked = value),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      key: const ValueKey('full-compare-grade-filter'),
                      initialValue: _grade,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: '幅度筛选'),
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('全部幅度'),
                        ),
                        for (final grade in [
                          'excluded',
                          'minor',
                          'general',
                          'significant',
                        ])
                          DropdownMenuItem(
                            value: grade,
                            child: Text(comparisonGradeLabel(grade)),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _grade = value ?? 'all'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: const ValueKey('full-compare-section-filter'),
                      initialValue: _section,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: '变化筛选'),
                      items: [
                        for (final entry in const {
                          'all': '全部变化',
                          'ingredients': '食材',
                          'steps': '步骤',
                          'method': '烹饪方法',
                          'snapshot': '菜谱字段',
                        }.entries)
                          DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _section = value ?? 'all'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: const ValueKey('full-compare-kind-filter'),
                      initialValue: _kind,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: '变更类型筛选'),
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('全部类型'),
                        ),
                        for (final kind in [
                          ...GradedComparisonChangeKindEnum.values.map(
                            (value) => value.value,
                          ),
                          'order',
                        ])
                          DropdownMenuItem(
                            value: kind,
                            child: Text(_kindLabel(kind)),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _kind = value ?? 'all'),
                    ),
                  ],
                ),
              ),
              if (cards.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('当前筛选下没有变化；可调整筛选或显示全部内容。'),
                ),
              ...cards,
            ],
          );
        },
      ),
    );
  }

  Widget _version(ComparisonVersion version, String label, String side) => Card(
    key: ValueKey('full-compare-version-$side'),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label · ${version.dishName}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            AppLocalizations.of(context).recipeComparisonVersion(
              version.author,
              version.versionNumber,
              version.servings,
            ),
          ),
          TextButton(
            key: ValueKey('full-compare-detail-$side'),
            onPressed: () => ref
                .read(intentDispatcherProvider)
                .dispatch(
                  context,
                  compositionId: CompositionIdScope.of(context),
                  componentId: 'full-compare-detail-$side',
                  action: ActionDescriptor(
                    intent: 'open_page',
                    params: {
                      'page': 'recipe_version',
                      'recipe_id': version.recipeId,
                      'version_id': version.versionId,
                    },
                  ),
                ),
            child: Text(AppLocalizations.of(context).recipeComparisonDetails),
          ),
        ],
      ),
    ),
  );

  List<Widget> _cards(
    RecipeFullComparison result,
    bool sideBySide,
    RecipeSnapshot beforeSnapshot,
    RecipeSnapshot afterSnapshot,
  ) {
    final l10n = AppLocalizations.of(context);
    final originalBefore = {
      for (final item in beforeSnapshot.ingredients ?? <RecipeIngredient>[])
        item.id: item,
    };
    final originalAfter = {
      for (final item in afterSnapshot.ingredients ?? <RecipeIngredient>[])
        item.id: item,
    };
    final cards = <Widget>[];
    for (final kind in [
      'added',
      'removed',
      'quantity',
      'replacement',
      'unit',
      'field',
      'text',
    ]) {
      final changes = <Widget>[];
      for (final row in result.ingredients) {
        for (final change in row.changes ?? <GradedComparisonChange>[]) {
          if (change.kind.value != kind ||
              !_includes(
                'ingredients',
                change.grade.value,
                change.kind.value,
              )) {
            continue;
          }
          final item = row.after ?? row.before;
          changes.add(
            _change(
              id: 'ingredient-${row.before?.id ?? row.after?.id}-${change.field}',
              title: item?.displayName ?? _fieldLabel(change.field),
              kind: '${_kindLabel(kind)} · ${_fieldLabel(change.field)}',
              // Added/removed ingredient payloads may include a signed measure
              // receipt. Summaries and typed original details show the evidence,
              // never the credential-bearing transport field.
              before: kind == 'added' || kind == 'removed'
                  ? (row.before == null ? null : _ingredientSummary(row.before))
                  : change.before,
              after: kind == 'added' || kind == 'removed'
                  ? (row.after == null ? null : _ingredientSummary(row.after))
                  : change.after,
              unit: change.unit,
              relative: change.relativeChange,
              grade: change.grade.value,
              basis: '${change.basis}\n食材配对：${row.pairing.value}',
              ruleId: change.ruleId,
              rulesVersion: change.rulesVersion,
              sideBySide: sideBySide,
              details: _originalPair(
                before: ComparisonIngredientDetails(
                  value: originalBefore[row.before?.id],
                ),
                after: ComparisonIngredientDetails(
                  value: originalAfter[row.after?.id],
                ),
                sideBySide: sideBySide,
              ),
            ),
          );
        }
      }
      if (changes.isNotEmpty) {
        cards.add(_heading('食材 · ${_kindLabel(kind)}'));
        cards.addAll(changes);
      }
    }
    if (_showAll && _includes('ingredients', null)) {
      for (final row in result.ingredients) {
        if (row.changes?.isNotEmpty ?? false) continue;
        cards.add(
          ComparisonRuleCard(
            id: 'ingredient-${row.before?.id ?? row.after?.id}-unchanged',
            title: (row.after ?? row.before)?.displayName ?? '食材',
            kindLabel: '未变化',
            before: _ingredientSummary(row.before),
            after: _ingredientSummary(row.after),
            basis: '配对方式：${row.pairing.value}；原始快照保持不变',
            rulesVersion: result.rulesVersion,
            sideBySide: sideBySide,
            expandDetails: _expandDetails,
            details: _originalPair(
              before: ComparisonIngredientDetails(
                value: originalBefore[row.before?.id],
              ),
              after: ComparisonIngredientDetails(
                value: originalAfter[row.after?.id],
              ),
              sideBySide: sideBySide,
            ),
          ),
        );
      }
    }
    final beforeNames = <String, String>{
      for (final row in result.ingredients)
        if (row.before != null) row.before!.id: row.before!.displayName,
    };
    final afterNames = <String, String>{
      for (final row in result.ingredients)
        if (row.after != null) row.after!.id: row.after!.displayName,
    };
    final beforeNumbers = <String, int>{
      for (final row in result.steps)
        if (row.before != null && row.beforeIndex != null)
          row.before!.id: row.beforeIndex!,
    };
    final afterNumbers = <String, int>{
      for (final row in result.steps)
        if (row.after != null && row.afterIndex != null)
          row.after!.id: row.afterIndex!,
    };
    final stepCards = <Widget>[];
    for (final (index, row) in result.steps.indexed) {
      Widget details() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('对齐：${row.alignment.value}；置信度：${row.confidence}'),
          Text('对齐依据：${row.basis}'),
          _originalPair(
            before: ComparisonStepDetails(
              value: row.before,
              ingredientNames: beforeNames,
              stepNumbers: beforeNumbers,
            ),
            after: ComparisonStepDetails(
              value: row.after,
              ingredientNames: afterNames,
              stepNumbers: afterNumbers,
            ),
            sideBySide: sideBySide,
          ),
        ],
      );
      final alignment = switch (row.alignment.value) {
        'deterministic' => '确定性对齐',
        'uncertain' => '对齐不确定 · 双方原文保留',
        _ => '未能对齐 · 按新增或删除计算',
      };
      final title =
          '步骤 · ${row.beforeIndex == null ? '无' : 'A 第 ${row.beforeIndex} 步'} → ${row.afterIndex == null ? '无' : 'B 第 ${row.afterIndex} 步'}';
      for (final change in row.changes ?? <StepComparisonChange>[]) {
        if (!_includes('steps', change.grade.value, change.kind.value)) {
          continue;
        }
        stepCards.add(
          _change(
            id: 'step-$index-${change.field}',
            title: title,
            kind:
                '${_kindLabel(change.kind.value)} · ${_fieldLabel(change.field)} · $alignment',
            before: change.before,
            after: change.after,
            unit: change.unit,
            relative: change.relativeChange,
            grade: change.grade.value,
            basis: '${row.basis}\n${change.basis}',
            ruleId: change.ruleId,
            rulesVersion: change.rulesVersion,
            sideBySide: sideBySide,
            details: details(),
          ),
        );
      }
      if ((row.changes?.isEmpty ?? true) &&
          (_showAll || row.alignment.value != 'deterministic') &&
          _includes('steps', null)) {
        stepCards.add(
          ComparisonRuleCard(
            id: 'step-$index-unchanged',
            title: title,
            kindLabel: alignment,
            before: row.before?.instruction ?? l10n.recipeComparisonNone,
            after: row.after?.instruction ?? l10n.recipeComparisonNone,
            basis: row.basis,
            rulesVersion: result.rulesVersion,
            sideBySide: sideBySide,
            expandDetails: _expandDetails,
            details: details(),
          ),
        );
      }
    }
    if (stepCards.isNotEmpty) {
      cards.add(_heading('步骤逐行对齐'));
      cards.addAll(stepCards);
    }
    for (final (section, title, changes) in [
      ('method', '烹饪方法变化', result.methodChanges),
      ('snapshot', l10n.recipeComparisonSnapshotFields, result.snapshotFields),
    ]) {
      final selected = [
        for (final change in changes)
          if (_includes(section, change.grade.value, change.kind.value)) change,
      ];
      if (selected.isEmpty) continue;
      cards.add(_heading(title));
      for (final change in selected) {
        cards.add(
          _change(
            id: '$section-${change.field}',
            title: _fieldLabel(change.field),
            kind: _kindLabel(change.kind.value),
            before: change.before,
            after: change.after,
            unit: change.unit,
            relative: change.relativeChange,
            grade: change.grade.value,
            basis: change.basis,
            ruleId: change.ruleId,
            rulesVersion: change.rulesVersion,
            sideBySide: sideBySide,
          ),
        );
      }
    }
    if (_showAll && _includes('snapshot', null)) {
      cards.add(
        ComparisonRuleCard(
          id: 'snapshot-originals',
          title: '双方原始菜谱字段',
          kindLabel: '保存快照 · 不覆盖原始值',
          before: '${beforeSnapshot.servings} 人份',
          after: '${afterSnapshot.servings} 人份',
          sideBySide: sideBySide,
          expandDetails: _expandDetails,
          details: _originalPair(
            before: _snapshotDetails(beforeSnapshot),
            after: _snapshotDetails(afterSnapshot),
            sideBySide: sideBySide,
          ),
        ),
      );
    }
    return cards;
  }

  Widget _snapshotDetails(RecipeSnapshot snapshot) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final entry in {
        '说明': snapshot.description,
        '设计依据': snapshot.designRationale,
        '菜系': snapshot.cuisine,
        '难度': snapshot.difficulty,
        '菜品类型': snapshot.dishType,
        '标签': snapshot.tags,
        '基础模具': snapshot.baseMold?.toJson(),
        '总时长（秒）': snapshot.totalTimeSeconds,
        '主动时长（秒）': snapshot.activeTimeSeconds,
        '快照格式': snapshot.formatVersion.value,
      }.entries)
        Text(
          '${entry.key}：${comparisonValue(AppLocalizations.of(context), entry.value)}',
        ),
      for (final (field, value, source) in [
        ('servings', snapshot.servings, snapshot.servingsSource),
        ('text', snapshot.description, snapshot.textSource),
      ])
        if (source != null)
          SourceMark(
            sourceType: source.source_.value,
            componentId: 'comparison-snapshot-$field',
            value: comparisonValue(AppLocalizations.of(context), value),
            originalValue: source.original,
            basisText: recipeSourceBasis(source),
            neutral: true,
            valueChanged: false,
            required: false,
            showWhenAuthorFilled: true,
            feedbackEnabled: false,
            onAction: null,
          ),
    ],
  );

  Widget _originalPair({
    required Widget before,
    required Widget after,
    required bool sideBySide,
  }) => ComparisonPair(
    before: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [const Text('A · 原始快照'), before],
    ),
    after: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [const Text('B · 原始快照'), after],
    ),
    sideBySide: sideBySide,
  );

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );

  String _ingredientSummary(RecipeIngredient? item) => item == null
      ? AppLocalizations.of(context).recipeComparisonNone
      : '${item.displayName} · 原始保存用量 ${item.quantity} ${item.unit}';

  Widget _change({
    required String id,
    required String title,
    required String kind,
    required Object? before,
    required Object? after,
    String? unit,
    num? relative,
    required String grade,
    required String basis,
    required String ruleId,
    required String rulesVersion,
    required bool sideBySide,
    Widget? details,
  }) {
    final l10n = AppLocalizations.of(context);
    String value(Object? v) =>
        '${comparisonValue(l10n, v)}${unit == null ? '' : ' $unit'}';
    return ComparisonRuleCard(
      id: id,
      title: title,
      kindLabel: kind,
      before: value(before),
      after: value(after),
      grade: grade,
      relativeChange: relative == null
          ? null
          : '${relative < 0 ? '−' : '+'}${(relative.abs() * 100).toStringAsFixed(1)}%',
      basis: basis,
      ruleId: ruleId,
      rulesVersion: rulesVersion,
      sideBySide: sideBySide,
      expandDetails: _expandDetails,
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [if (relative != null) Text('相对变化服务端原值：$relative'), ?details],
      ),
    );
  }
}

String _kindLabel(String kind) =>
    const {
      'added': '新增',
      'removed': '删除',
      'quantity': '用量变化',
      'replacement': '替换',
      'unit': '单位不同',
      'field': '字段变化',
      'text': '文字修改',
      'order': '顺序变化',
    }[kind] ??
    kind;

String _fieldLabel(String field) =>
    const {
      'base_quantity': '基础量',
      'base_unit': '基础单位',
      'ingredient_id': '标准食材',
      'display_name': '显示名',
      'preparation': '处理方式',
      'group': '分组',
      'optional': '可选',
      'scaling_mode': '缩放方式',
      'replacement': '替代关系',
      'functional': '功能性用料',
      'flavor_contribution': '味型贡献',
      'action': '动作',
      'ingredient_ids': '引用食材',
      'instruction': '说明',
      'duration_seconds': '时长',
      'unattended': '是否需要守着',
      'heat': '火候',
      'temperature_celsius': '温度',
      'cookware': '厨具',
      'doneness': '成熟判断',
      'depends_on': '前置依赖',
      'notes': '要点',
      'why': '原因',
      'order': '步骤顺序',
      'heating_actions': '主料加热方法',
      'description': '菜谱说明',
      'difficulty': '难度',
      'dish_type': '菜品类型',
      'tags': '标签',
      'base_mold': '基础模具',
      'cuisine': '菜系',
      'design_rationale': '设计依据',
      'total_time_seconds': '总时长',
      'active_time_seconds': '主动时长',
    }[field] ??
    field;
