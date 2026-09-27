import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/tab_page.dart';
import '../tab_paths.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TabPage(
      child: EmptyState(
        icon: Icons.wb_sunny_outlined,
        title: l10n.todayEmptyTitle,
        message: l10n.todayEmptyBody,
        actionLabel: l10n.todayEmptyAction,
        onAction: () => context.go(TabPaths.create),
      ),
    );
  }
}
