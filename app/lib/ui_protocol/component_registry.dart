import 'package:flutter/widgets.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'components/empty_state_component.dart';
import 'components/hint_bar_component.dart';

/// 组件渲染函数：拿到这个组件实例的描述和触发动作的回调，返回要显示的 widget。
/// 动作怎么处理是 SPEC-009.1 #81（动作即意图）的事，这里先只把回调传下去。
typedef ComponentBuilder = Widget Function(
  BuildContext context,
  ComponentDescriptor component,
  void Function(ActionDescriptor action) onAction,
);

/// 一个登记过的组件类型：类型名、渲染方式。数据格式的 Schema 在
/// `contracts/ui_protocol/schema/<version>/components/<type>.schema.json`
/// （渲染前的校验见 [ProtocolSchemas]，不在这里重复）。
class ComponentSpec {
  const ComponentSpec({
    required this.type,
    required this.builder,
    this.fillsRemainingSpace = false,
  });

  final String type;
  final ComponentBuilder builder;

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

/// #77 只登记两个通用组件；业务组件和其余通用组件（分区标题、文字块、列表容器、
/// 来源标记、为什么面板）由后续票（#80、#82）登记进来。
final defaultComponentRegistry = ComponentRegistry(const [
  ComponentSpec(type: 'hint_bar', builder: buildHintBarComponent),
  ComponentSpec(
    type: 'empty_state',
    builder: buildEmptyStateComponent,
    fillsRemainingSpace: true,
  ),
]);
