import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/tab_page.dart';

class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TabPage(
      child: EmptyState(
        icon: Icons.menu_book_outlined,
        title: l10n.recordsEmptyTitle,
        message: l10n.recordsEmptyBody,
      ),
    );
  }
}
