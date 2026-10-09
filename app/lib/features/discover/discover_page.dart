import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/reachability.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/tab_page.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(apiReachabilityProvider);
    return TabPage(
      child: EmptyState(
        icon: Icons.explore_outlined,
        title: l10n.discoverEmptyTitle,
        message: l10n.discoverEmptyBody,
        footer: status.canRequest ? null : Text(status.message),
      ),
    );
  }
}
