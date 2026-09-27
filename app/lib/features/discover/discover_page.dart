import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/tab_page.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TabPage(
      child: EmptyState(
        icon: Icons.explore_outlined,
        title: l10n.discoverEmptyTitle,
        message: l10n.discoverEmptyBody,
      ),
    );
  }
}
