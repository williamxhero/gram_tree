import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
///
/// 组件上的动作（比如提示条点整条跳到新建页）统一派发给意图登记表
/// （SPEC-009.1 #81，见 `composition_view.dart`/`intent_dispatcher.dart`），页面
/// 自己不用再写 `_handleAction`。
class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TabPage(
      child: CompositionView(
        pageType: 'today',
        standardLayoutBuilder: (context) => const _StandardTodayLayout(),
      ),
    );
  }
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
