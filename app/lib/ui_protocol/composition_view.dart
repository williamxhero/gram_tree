import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'component_registry.dart';
import 'composition_provider.dart';

/// 渲染服务端下发的一份页面描述：按组件登记表把每个组件类型映射成 widget，按顺序
/// 排列。合法结果和标准布局用同一个入口显示，不合法/请求出错时先退回
/// [standardLayoutBuilder]（完整的超时、兜底原因记录见 SPEC-009.1 #79）。
class CompositionView extends ConsumerWidget {
  const CompositionView({
    super.key,
    required this.pageType,
    required this.standardLayoutBuilder,
    required this.onAction,
  });

  final String pageType;
  final WidgetBuilder standardLayoutBuilder;
  final void Function(ActionDescriptor action) onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(compositionProvider(pageType));
    final effectiveRegistry = ref.watch(componentRegistryProvider);
    return async.when(
      // #77 阶段还没有超时/加载态设计：静态标准布局和默认组合内容一致，加载期间
      // 先显示标准布局，不会出现闪烁或转圈。
      loading: () => standardLayoutBuilder(context),
      error: (_, _) => standardLayoutBuilder(context),
      data: (result) => switch (result) {
        CompositionReady(:final description) => _CompositionBody(
          description: description,
          registry: effectiveRegistry,
          onAction: onAction,
        ),
        CompositionFailed() => standardLayoutBuilder(context),
      },
    );
  }
}

class _CompositionBody extends StatelessWidget {
  const _CompositionBody({
    required this.description,
    required this.registry,
    required this.onAction,
  });

  final PageDescription description;
  final ComponentRegistry registry;
  final void Function(ActionDescriptor action) onAction;

  @override
  Widget build(BuildContext context) {
    final components = description.components ?? const [];
    final hasFiller = components.any(
      (c) => registry[c.type]?.fillsRemainingSpace ?? false,
    );
    final children = [
      for (final component in components)
        _build(context, component, registry[component.type]!),
    ];
    // 撑满剩余空间的组件（比如标准空态）需要有界高度，不能塞进无界高度的滚动视图；
    // 没有这种组件时整体按普通列表滚动（详细的布局规则见 #80）。
    if (hasFiller) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _build(
    BuildContext context,
    ComponentDescriptor component,
    ComponentSpec spec,
  ) {
    final child = spec.builder(context, component, spec.emptyState, onAction);
    return spec.fillsRemainingSpace ? Expanded(child: child) : child;
  }
}
