import 'package:flutter/widgets.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'components/empty_state_component.dart';
import 'components/hint_bar_component.dart';
import 'components/list_component.dart';
import 'components/section_title_component.dart';
import 'components/source_demo_component.dart';
import 'components/text_block_component.dart';
import 'recipe_components.dart';

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
]);
