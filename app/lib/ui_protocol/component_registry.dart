import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'components/empty_state_component.dart';
import 'components/hint_bar_component.dart';
import 'components/list_component.dart';
import 'components/section_title_component.dart';
import 'components/source_demo_component.dart';
import 'components/scenario_summary_component.dart';
import 'components/scenario_notice_component.dart';
import 'components/component_scaffold.dart';
import 'source_mark.dart';
import 'source_types.dart';
import 'components/records_calendar_component.dart';
import 'components/text_block_component.dart';
import 'recipe_components.dart';
import 'source_attribution.dart';
import 'recipe_safety_protocol.dart';
import 'dietary_statistics_protocol.dart';

Widget buildMonthlyReviewComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
) {
  final data = component.data is Map
      ? Map<String, dynamic>.from(component.data as Map)
      : const <String, dynamic>{};
  final conclusion = data['conclusion'] as String?;
  final changes = (data['taste_changes'] as List? ?? const [])
      .whereType<Map>()
      .toList();
  if (conclusion == null || conclusion.isEmpty) {
    return ComponentEmptyCard(emptyState: emptyState);
  }
  final detailed = component.detail == ComponentDescriptorDetailEnum.detailed;
  final source = data['source'];
  final sourceData = source is Map ? Map<String, dynamic>.from(source) : null;
  final basis =
      parseBasisText(data) ??
      (sourceData == null ? null : parseBasisText(sourceData));
  Widget changeList({required bool detailed}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final change in changes)
        Semantics(
          container: true,
          label:
              '${change['field'] ?? '口味变化'}${detailed ? '，变更前 ${change['old_value'] ?? ''}，变更后 ${change['new_value'] ?? ''}，${change['reason'] ?? ''}' : ''}',
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.tune),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    change['conclusion'] as String? ??
                        change['field'] as String? ??
                        '口味变化',
                  ),
                ),
                if (change['source'] is Map)
                  SourceMark(
                    sourceType:
                        (change['source'] as Map)['source_type'] as String? ??
                        sourceTypeVerified,
                    componentId: 'monthly-review-${change['field']}',
                    value:
                        (change['source'] as Map)['value'] as String? ?? '已登记',
                    basisText:
                        parseBasisText(
                          Map<String, dynamic>.from(change['source'] as Map),
                        ) ??
                        '已登记的月度回顾依据',
                    required: false,
                    showWhenAuthorFilled: true,
                    onAction: onAction,
                  ),
              ],
            ),
            subtitle: detailed
                ? Text(
                    '${change['old_value'] ?? ''} → ${change['new_value'] ?? ''}\n${change['reason'] ?? ''}',
                  )
                : null,
          ),
        ),
    ],
  );
  return ComponentCard(
    detail: component.detail,
    conclusion: Text(conclusion),
    conclusionSemanticsText: conclusion,
    basisText: basis,
    standardExtra: switch (component.detail) {
      ComponentDescriptorDetailEnum.standard => changeList(detailed: false),
      _ => null,
    },
    detailedExtra: detailed ? changeList(detailed: true) : null,
  );
}

/// 组件登记时要给的标准空态文案：结论层（各组件类型自己的必填字段，比如
/// `hint_bar`/`text_block`/`section_title` 的 `conclusion`，`list` 的 `items`）
/// 拿不到内容时显示什么。标题必填，一句说明可选。
///
/// 这是给"组件本身没内容"兜底用的，和"服务端没下发这个组件"（不出现在
/// components 数组里）、"整页退回标准布局"（SPEC-009.1 #79）是三件不同的事。
class ComponentEmptyState {
  const ComponentEmptyState({required this.title, this.message});

  final String title;
  final String? message;
}

/// 组件渲染函数：拿到这个组件实例的描述、登记的标准空态文案、触发动作的回调，
/// 返回要显示的 widget。组件自己决定什么时候用 [emptyState]（比如结论缺失、
/// 列表一项都没有）。动作怎么处理是 SPEC-009.1 #81（动作即意图）的事，这里先只把
/// 回调传下去。
typedef ComponentBuilder = Widget Function(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
);

/// 一个登记过的组件类型：类型名、渲染方式、标准空态文案。数据格式的 Schema 在
/// `contracts/ui_protocol/schema/<version>/components/<type>.schema.json`
/// （渲染前的校验见 [ProtocolSchemas]，不在这里重复；无障碍标注是每个组件
/// [builder] 自己的职责，按 SPEC-009.1 #80 的约定把整个组件包一层 `Semantics`，
/// 读出结论、当前档位下显示的依据和动作文案，参考
/// `components/component_scaffold.dart` 的 `ComponentCard`）。
///
/// 新增一个业务组件只需要登记这几样：类型名、Schema 文件、[builder]、
/// [emptyState]。
class ComponentSpec {
  const ComponentSpec({
    required this.type,
    required this.builder,
    required this.emptyState,
    this.fillsRemainingSpace = false,
  });

  final String type;
  final ComponentBuilder builder;
  final ComponentEmptyState emptyState;

  /// 是否要撑满页面剩余空间（例如标准空态）。布局细节由 #80 的设计系统定稿，
  /// 这里先给渲染器一个信号，避免把撑满整页的组件塞进无界高度的滚动视图里崩溃。
  final bool fillsRemainingSpace;
}

/// App 内置组件登记表。服务端请求时会带上这里的类型名清单，服务端只会下发
/// App 声明认识的组件（SPEC-009.1 #77）。
class ComponentRegistry {
  ComponentRegistry(Iterable<ComponentSpec> specs)
    : _byType = {for (final s in specs) s.type: s};

  final Map<String, ComponentSpec> _byType;

  bool isRegistered(String type) => _byType.containsKey(type);

  Set<String> get supportedTypes => _byType.keys.toSet();

  ComponentSpec? operator [](String type) => _byType[type];
}

/// #80 登记齐 SPEC-009.1 #18 要求的五个通用组件：提示条、分区标题、文字块、
/// 列表容器、标准空态。来源标记（`SourceMark`）和"为什么"面板（`WhyPanel`）是
/// #82 加的通用组件，但它们不是独立的"组件类型"——协议里没有单独的 `source_mark`/
/// `why_panel` type，它们是任何组件在渲染自己的 `data` 时可以内嵌使用的展示单元
/// （见 `source_mark.dart`）。`source_demo` 是 #82 新登记的组件类型，
/// 仅测试用，专门用来驱动"来源标记 -> 为什么面板 -> 反馈"这条链路，不是真实业务
/// 组件（真实的换算内容留给以后的子 SPEC）。
final defaultComponentRegistry = ComponentRegistry(const [
  ComponentSpec(
    type: 'source_attribution',
    builder: buildSourceAttributionComponent,
    emptyState: ComponentEmptyState(title: '来源署名暂不可用 · 来源关系仍永久保留'),
  ),
  ComponentSpec(
    type: 'scenario_difference',
    builder: buildScenarioNoticeComponent,
    emptyState: ComponentEmptyState(title: '和上次的差别'),
  ),
  ComponentSpec(
    type: 'failure_reminder',
    builder: buildScenarioNoticeComponent,
    emptyState: ComponentEmptyState(title: '这一步留意'),
  ),
  ComponentSpec(
    type: 'taste_change_notice',
    builder: buildScenarioNoticeComponent,
    emptyState: ComponentEmptyState(title: '已按你最近的口味调整'),
  ),
  ComponentSpec(
    type: 'scenario_summary',
    builder: buildScenarioSummaryComponent,
    emptyState: ComponentEmptyState(title: '标准步骤'),
  ),
  ComponentSpec(
    type: 'hint_bar',
    builder: buildHintBarComponent,
    emptyState: ComponentEmptyState(title: '没有可显示的提示'),
  ),
  ComponentSpec(
    type: 'section_title',
    builder: buildSectionTitleComponent,
    emptyState: ComponentEmptyState(title: '没有标题'),
  ),
  ComponentSpec(
    type: 'text_block',
    builder: buildTextBlockComponent,
    emptyState: ComponentEmptyState(title: '没有可显示的说明'),
  ),
  ComponentSpec(
    type: 'list',
    builder: buildListComponent,
    emptyState: ComponentEmptyState(title: '还没有记录', message: '这里会显示内容'),
  ),
  ComponentSpec(
    type: 'empty_state',
    builder: buildEmptyStateComponent,
    emptyState: ComponentEmptyState(title: '没有内容'),
    fillsRemainingSpace: true,
  ),
  ComponentSpec(
    type: 'recipe_header',
    builder: buildRecipeHeaderComponent,
    emptyState: ComponentEmptyState(title: ''),
  ),
  ComponentSpec(
    type: 'recipe_ingredients',
    builder: buildRecipeIngredientsComponent,
    emptyState: ComponentEmptyState(title: ''),
  ),
  ComponentSpec(
    type: 'recipe_steps',
    builder: buildRecipeStepsComponent,
    emptyState: ComponentEmptyState(title: ''),
  ),
  ComponentSpec(
    type: 'recipe_card',
    builder: buildRecipeCardComponent,
    emptyState: ComponentEmptyState(title: ''),
  ),
  ComponentSpec(
    type: 'source_demo',
    builder: buildSourceDemoComponent,
    emptyState: ComponentEmptyState(title: '没有可显示的示例'),
  ),
  ComponentSpec(
    type: 'food_safety',
    builder: buildFoodSafetyProtocolComponent,
    emptyState: ComponentEmptyState(title: '暂时无法确认食品安全信息'),
  ),
  ComponentSpec(
    type: 'records_calendar',
    builder: buildRecordsCalendarComponent,
    emptyState: ComponentEmptyState(
      title: '还没有记录',
      message: '做完菜点做好了，这里就会出现你的记录。',
    ),
  ),
  ComponentSpec(
    type: 'allergen_notice',
    builder: buildAllergenNoticeProtocolComponent,
    emptyState: ComponentEmptyState(title: '暂时无法确认过敏原信息'),
  ),
  ComponentSpec(
    type: 'monthly_review',
    builder: buildMonthlyReviewComponent,
    emptyState: ComponentEmptyState(
      title: '这个月还没有回顾内容',
      message: '有做菜记录或口味变化后，这里会显示月度回顾。',
    ),
  ),
  ComponentSpec(
    type: 'dietary_statistics',
    builder: buildDietaryStatisticsComponent,
    emptyState: ComponentEmptyState(title: '统计暂时不可用'),
  ),
  ComponentSpec(
    type: 'dietary_distribution',
    builder: buildDietaryDistributionComponent,
    emptyState: ComponentEmptyState(title: '分布暂时不可用'),
  ),
]);
