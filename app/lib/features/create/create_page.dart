import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/reachability.dart';

import '../../features_flags/features.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/tab_page.dart';
import '../recipes/recipe_pages.dart';

class CreatePage extends ConsumerWidget {
  const CreatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final connectivity = ref.watch(apiReachabilityProvider);
    return TabPage(
      child: EmptyState(
        icon: Icons.edit_note_outlined,
        title: l10n.createEmptyTitle,
        message: l10n.createEmptyBody,
        footer: Column(
          children: [
            FilledButton.icon(
              key: const ValueKey('create-recipe-entry'),
              onPressed: () => context.push(RecipeEditorPage.path),
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(l10n.newRecipe),
            ),
            OutlinedButton.icon(
              key: const ValueKey('one-line-recipe-entry'),
              onPressed: connectivity.canRequest
                  ? () => context.push('/recipes/one-line')
                  : null,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('一句话生成菜谱'),
            ),
            if (!connectivity.canRequest) Text(connectivity.message),
            TextButton(
              key: const ValueKey('my-recipes-entry'),
              onPressed: () => context.push(RecipeListPage.path),
              child: Text(l10n.viewMyRecipes),
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
