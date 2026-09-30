import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features_flags/features.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/tab_page.dart';
import '../recipes/recipe_pages.dart';

class CreatePage extends StatelessWidget {
  const CreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TabPage(
      child: EmptyState(
        icon: Icons.edit_note_outlined,
        title: l10n.createEmptyTitle,
        message: '把菜名、食材和步骤写下来，每次保存都会留下一个新版本。',
        footer: Column(
          children: [
            FilledButton.icon(
              key: const ValueKey('create-recipe-entry'),
              onPressed: () => context.push(RecipeEditorPage.path),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('新建菜谱'),
            ),
            TextButton(
              key: const ValueKey('my-recipes-entry'),
              onPressed: () => context.push(RecipeListPage.path),
              child: const Text('查看我的菜谱'),
            ),
            FeatureGate(
              feature: Feature.receiptScan,
              child: OutlinedButton.icon(
                key: const ValueKey('receipt-scan-entry'),
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(l10n.featureReceiptScan),
                onPressed: () =>
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(l10n.comingSoon))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
