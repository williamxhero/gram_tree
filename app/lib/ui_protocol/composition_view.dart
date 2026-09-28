import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';
import 'package:intl/intl.dart' as intl;

import '../l10n/app_localizations.dart';
import 'component_registry.dart';
import 'composition_provider.dart';
import 'intent_dispatcher.dart';
import 'source_mark.dart' show CompositionIdScope;

/// 渲染服务端下发的一份页面描述：按组件登记表把每个组件类型映射成 widget，按顺序
/// 排列。合法结果和标准布局用同一个入口显示，不合法/请求出错/等待超时时先退回
/// [standardLayoutBuilder]（完整的超时、兜底原因记录见 SPEC-009.1 #79，判断逻辑在
/// `composition_provider.dart` 的 `fetchComposition`）。
///
/// **新页面类型怎么配标准布局（SPEC-009.1 #79 定的统一方式，照抄 `today_page.dart`
/// 就行）**：
/// 1. 页面自己的标准布局写成一个私有 widget（例如 `_StandardXxxLayout`），只调用
///    普通数据接口，不依赖组合服务——这是"出任何问题都不能卡住做饭"的底线，标准布局
///    必须独立于组合服务能不能用。
/// 2. 页面 widget 里用 [CompositionView] 包一层，`pageType` 填这个页面类型的名字，
///    `standardLayoutBuilder` 传一个返回上面那个私有 widget 的 [WidgetBuilder]。
/// 3. 如果这个页面类型有必显组件要求，去 `page_types.dart` 的
///    `defaultRequiredComponentTypes` 里加一项（和服务端 `page_types.py` 的
///    `ITEMS` 对应）；没有就不用加。
///
/// 组件上的动作怎么处理不用页面自己接（SPEC-009.1 #81 起）：每个组件动作都统一
/// 派发给 [IntentDispatcher]（`intentDispatcherProvider`），按钮、整条可点这些不同
/// 入口触发同一个意图时因此总是调用同一个处理器、得到同样的结果，页面 widget 不用
/// 再写自己的 `_handleAction`。
class CompositionView extends ConsumerWidget {
  const CompositionView({
    super.key,
    required this.pageType,
    required this.standardLayoutBuilder,
  });

  final String pageType;

  /// 这个页面类型的标准布局。加载中、请求出错、等待超时、协议或数据不合法、缺必显
  /// 组件时都会显示它——所有这些情况在 App 里看起来完全一样，不区分"为什么"，用户
  /// 只看到"和平时一样能做菜"。
  final WidgetBuilder standardLayoutBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(compositionProvider(pageType));
    final effectiveRegistry = ref.watch(componentRegistryProvider);
    final dispatcher = ref.watch(intentDispatcherProvider);
    return async.when(
      // #77 阶段还没有超时/加载态设计：静态标准布局和默认组合内容一致，加载期间
      // 先显示标准布局，不会出现闪烁或转圈。
      loading: () => standardLayoutBuilder(context),
      error: (_, _) => standardLayoutBuilder(context),
      data: (result) => switch (result) {
        CompositionReady(:final description) => _CompositionBody(
          description: description,
          registry: effectiveRegistry,
          dispatcher: dispatcher,
        ),
        // SPEC-009.1 票 7（#83）：等待超时/离线时用的本机缓存——顶部加一条"上次
        // 更新于 xx:xx"提示，内容渲染和正常成功时完全一样。
        CompositionFromCache(:final description, :final savedAt) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LastUpdatedBanner(savedAt: savedAt),
            Expanded(
              child: _CompositionBody(
                description: description,
                registry: effectiveRegistry,
                dispatcher: dispatcher,
              ),
            ),
          ],
        ),
        CompositionFailed() => standardLayoutBuilder(context),
      },
    );
  }
}

/// "上次更新于 xx:xx"提示条：够用就行，不追求花哨，参考 [Text] 直接用当前主题的
/// 次要文字样式，时间按本机时区、24 小时制显示到分钟。
class _LastUpdatedBanner extends StatelessWidget {
  const _LastUpdatedBanner({required this.savedAt});

  final DateTime savedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final time = intl.DateFormat.Hm().format(savedAt.toLocal());
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Text(
        l10n.compositionLastUpdatedAt(time),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CompositionBody extends StatelessWidget {
  const _CompositionBody({
    required this.description,
    required this.registry,
    required this.dispatcher,
  });

  final PageDescription description;
  final ComponentRegistry registry;
  final IntentDispatcher dispatcher;

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
    final body = hasFiller
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          );
    // SPEC-009.1 #82：把这次组合的 composition_id 挂到组件子树能读到的地方——来源
    // 标记打开"为什么"面板时要用它记事件，见 `source_mark.dart` 顶部的说明。
    return CompositionIdScope(
      compositionId: description.compositionId,
      child: body,
    );
  }

  Widget _build(
    BuildContext context,
    ComponentDescriptor component,
    ComponentSpec spec,
  ) {
    final child = spec.builder(
      context,
      component,
      spec.emptyState,
      (action) => dispatcher.dispatch(
        context,
        compositionId: description.compositionId,
        componentId: component.id,
        action: action,
      ),
    );
    return spec.fillsRemainingSpace ? Expanded(child: child) : child;
  }
}
