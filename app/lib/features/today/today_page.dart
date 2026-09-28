import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../l10n/app_localizations.dart';
import '../../ui_protocol/composition_view.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/tab_page.dart';
import '../tab_paths.dart';

/// “今天”页由服务端的默认组合下发（SPEC-009.1 #77），标准布局
/// （[_StandardTodayLayout]）在组合不合法、请求出错、等待超时或还没返回时顶上，两者
/// 看起来一样（完整的兜底原因记录、超时时限见 #79，机制说明见
/// `composition_view.dart` 的 `CompositionView` 文档注释——这是"新页面类型怎么配
/// 标准布局"的样板，以后加页面类型照这个写）。
class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TabPage(
      child: CompositionView(
        pageType: 'today',
        onAction: (action) => _handleAction(context, action),
        standardLayoutBuilder: (context) => const _StandardTodayLayout(),
      ),
    );
  }
}

/// 组件上的动作只能是 App 已登记的意图；完整的意图登记表和统一派发入口在
/// SPEC-009.1 #81，这里先只处理“今天”页目前唯一用得到的 open_page。
void _handleAction(BuildContext context, ActionDescriptor action) {
  if (action.intent != 'open_page') return;
  final params = action.params;
  final page = params is Map ? params['page'] as String? : null;
  if (page == 'create') context.go(TabPaths.create);
}

class _StandardTodayLayout extends StatelessWidget {
  const _StandardTodayLayout();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.wb_sunny_outlined,
      title: l10n.todayEmptyTitle,
      message: l10n.todayEmptyBody,
      actionLabel: l10n.todayEmptyAction,
      onAction: () => context.go(TabPaths.create),
    );
  }
}
