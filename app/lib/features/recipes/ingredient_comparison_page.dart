import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../app/theme.dart';
import '../../recipes/recipe_repository.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import '../../ui_protocol/source_mark.dart';

/// Ingredient-only comparison. No client-side pairing, arithmetic or severity.
class IngredientComparisonPage extends ConsumerStatefulWidget {
  const IngredientComparisonPage({
    super.key,
    required this.recipeId,
    required this.fromVersionId,
    required this.toVersionId,
  });
  final String recipeId;
  final String fromVersionId;
  final String toVersionId;

  @override
  ConsumerState<IngredientComparisonPage> createState() =>
      _IngredientComparisonPageState();
}

class _IngredientComparisonPageState
    extends ConsumerState<IngredientComparisonPage> {
  late Future<RecipeIngredientComparison> _result;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _result = ref
        .read(recipeRepositoryProvider)
        .compareIngredients(
          widget.recipeId,
          widget.fromVersionId,
          widget.toVersionId,
        );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('食材版本对比')),
    body: FutureBuilder<RecipeIngredientComparison>(
      future: _result,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('无法比较这些版本，请确认两版仍可查看'),
                TextButton(
                  onPressed: () => setState(_load),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final result = snapshot.data!;
        final media = MediaQuery.sizeOf(context);
        final sideBySide = media.width >= 600 || media.width > media.height;
        final headers = [
          _version(result.fromVersion, '从 A', 'a'),
          _version(result.toVersion, '到 B', 'b'),
        ];
        return ListView(
          key: const ValueKey('ingredient-comparison-content'),
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('仅比较食材，尚未比较步骤'),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: sideBySide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: headers[0]),
                        const SizedBox(width: 12),
                        Expanded(child: headers[1]),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        headers[0],
                        const SizedBox(height: 12),
                        headers[1],
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('已按 ${result.normalizedServings} 人份对比'),
            ),
            if (result.fromVersion.servings != result.toVersion.servings)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SourceMark(
                  sourceType: 'scenario_adjusted',
                  componentId: 'ingredient-comparison-servings',
                  value: '${result.normalizedServings} 人份',
                  originalValue: '${result.toVersion.servings} 人份',
                  basisText: 'B 的基础量按线性、固定或阶梯规则归一到 A 的份数；原版本未修改。',
                  required: true,
                  feedbackEnabled: false,
                  onAction: null,
                ),
              ),
            SwitchListTile(
              key: const ValueKey('compare-show-all'),
              title: const Text('展开全部食材'),
              value: _showAll,
              onChanged: (value) => setState(() => _showAll = value),
            ),
            if (result.ingredients.every((row) => row.changes?.isEmpty ?? true))
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('没有食材配方变化'),
              ),
            for (final kind in ComparisonChangeKindEnum.values) ...[
              if (result.ingredients.any(
                (row) => row.changes?.any((c) => c.kind == kind) ?? false,
              ))
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _kindLabel(kind),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              for (final row in result.ingredients)
                for (final change in row.changes ?? <ComparisonChange>[])
                  if (change.kind == kind)
                    _DiffCard(row: row, change: change, sideBySide: sideBySide),
            ],
            if (_showAll)
              for (final row in result.ingredients)
                if (row.changes?.isEmpty ?? true)
                  _DiffCard(row: row, sideBySide: sideBySide),
            if (result.snapshotFields?.isNotEmpty ?? false) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '菜谱字段变化',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final change in result.snapshotFields!)
                _DiffCard(change: change, sideBySide: sideBySide),
            ],
          ],
        );
      },
    ),
  );

  Widget _version(ComparisonVersion version, String label, String key) => Card(
    key: ValueKey('compare-version-$key'),
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
            '${version.author} · 第 ${version.versionNumber} 版 · ${version.servings} 人份',
          ),
          TextButton(
            key: ValueKey('compare-detail-$key'),
            onPressed: () => context.push(
              '/recipes/${version.recipeId}/versions/${version.versionId}',
            ),
            child: const Text('查看版本详情'),
          ),
        ],
      ),
    ),
  );
}

class _DiffCard extends StatelessWidget {
  const _DiffCard({this.row, this.change, required this.sideBySide});
  final IngredientComparisonRow? row;
  final ComparisonChange? change;
  final bool sideBySide;

  @override
  Widget build(BuildContext context) {
    final item = row?.after ?? row?.before;
    final title = item?.displayName ?? _fieldLabel(change!.field);
    final basis = change?.basis ?? '基础量按相同份数比较，食材与执行字段均未改变';
    final before = _value(false);
    final after = _value(true);
    final values = [Text('A：$before'), Text('B：$after')];
    final relative = change?.relativeChange;
    final percent = relative == null
        ? null
        : '${relative < 0 ? '−' : '+'}${(relative.abs() * 100).toStringAsFixed(1)}%';
    return ComponentCard(
      detail: ComponentDescriptorDetailEnum.detailed,
      conclusion: Text(title, style: Theme.of(context).textTheme.titleMedium),
      conclusionSemanticsText: title,
      standardExtra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (change == null) const Text('无食材变化'),
          if (change != null) Text(_fieldLabel(change!.field)),
          DefaultTextStyle(
            style: GramTreeColors.of(context)
                .numberStyle(Theme.of(context).textTheme.bodyMedium!),
            child: sideBySide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: values[0]),
                      const SizedBox(width: 12),
                      Expanded(child: values[1]),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: values,
                  ),
          ),
          if (percent != null) Text(percent),
          SourceMark(
            sourceType: 'author_filled',
            componentId:
                'ingredient-diff-${row?.before?.id ?? row?.after?.id ?? 'snapshot'}-${change?.field ?? 'unchanged'}',
            value: after,
            originalValue: before,
            basisText: basis,
            required: true,
            feedbackEnabled: false,
            neutral: true,
            showWhenAuthorFilled: true,
            labelOverride: '为什么',
            onAction: null,
          ),
        ],
      ),
      basisText: basis,
      detailedExtra: row == null
          ? null
          : Material(
              color: GramTreeColors.of(context).card,
              child: ExpansionTile(
                title: const Text('食材明细'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'A：${_ingredientDetails(row!.before)}\nB：${_ingredientDetails(row!.after)}',
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _value(bool after) {
    final ingredient = after ? row?.after : row?.before;
    if (change == null ||
        change!.kind == ComparisonChangeKindEnum.added ||
        change!.kind == ComparisonChangeKindEnum.removed) {
      return ingredient == null
          ? '无'
          : '${ingredient.displayName} ${_render(ingredient.baseQuantity)} ${ingredient.baseUnit?.value ?? ingredient.unit}';
    }
    final value = after ? change!.after : change!.before;
    return '${_render(value)}${change!.unit == null ? '' : ' ${change!.unit}'}';
  }
}

String _ingredientDetails(RecipeIngredient? value) => value == null
    ? '无'
    : [
        '${value.displayName} ${_render(value.baseQuantity)} ${value.baseUnit?.value ?? value.unit}',
        '处理：${value.preparation ?? '无'}',
        '分组：${value.group ?? '无'}',
        '可选：${value.optional == true ? '是' : '否'}',
        '功能性用料：${value.functional == true ? '是' : '否'}',
        '缩放：${value.scalingMode?.value ?? 'proportional'}',
        '替代品：${_render(value.replacement)}',
      ].join('；');

String _render(Object? value) => switch (value) {
  null => '无',
  bool b => b ? '是' : '否',
  num n => n == n.roundToDouble() ? n.toInt().toString() : n.toString(),
  Map() || List() => jsonEncode(value),
  _ => value.toString(),
};

String _kindLabel(ComparisonChangeKindEnum kind) => switch (kind) {
  ComparisonChangeKindEnum.added => '新增',
  ComparisonChangeKindEnum.removed => '删除',
  ComparisonChangeKindEnum.replacement => '替换',
  ComparisonChangeKindEnum.quantity => '用量变化',
  ComparisonChangeKindEnum.unit => '单位不同',
  ComparisonChangeKindEnum.field => '执行字段变化',
  ComparisonChangeKindEnum.text => '文字修改',
};

String _fieldLabel(String field) =>
    const {
      'base_quantity': '基础量',
      'base_unit': '基础单位',
      'ingredient_id': '食材',
      'display_name': '显示名',
      'preparation': '处理方式',
      'group': '分组',
      'optional': '可选性',
      'scaling_mode': '缩放方式',
      'replacement': '替代品',
      'functional': '功能性用料',
      'flavor_contribution': '味型贡献',
      'description': '说明',
      'difficulty': '难度',
      'dish_type': '菜型',
      'tags': '标签',
      'base_mold': '基准模具',
      'cuisine': '菜系',
      'design_rationale': '设计原理',
      'total_time_seconds': '总时长',
      'active_time_seconds': '需守着的时长',
    }[field] ??
    field;
