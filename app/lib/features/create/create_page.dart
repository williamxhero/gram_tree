import 'package:flutter/material.dart';

import '../../features_flags/features.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/tab_page.dart';

class CreatePage extends StatelessWidget {
  const CreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TabPage(
      child: EmptyState(
        icon: Icons.edit_note_outlined,
        title: l10n.createEmptyTitle,
        message: l10n.createEmptyBody,
        footer: FeatureGate(
          feature: Feature.receiptScan,
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: OutlinedButton.icon(
              key: const ValueKey('receipt-scan-entry'),
              icon: const Icon(Icons.receipt_long_outlined),
              label: Text(l10n.featureReceiptScan),
              onPressed: () =>
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l10n.comingSoon))),
            ),
          ),
        ),
      ),
    );
  }
}
