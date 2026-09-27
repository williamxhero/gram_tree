import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/tab_page.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TabPage(
      child: EmptyState(
        icon: Icons.person_outline,
        title: l10n.meEmptyTitle,
        message: l10n.meEmptyBody,
      ),
    );
  }
}
