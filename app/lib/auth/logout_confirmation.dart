import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../events/event_queue.dart';
import '../l10n/app_localizations.dart';
import 'auth_controller.dart';
import 'session.dart';

/// Ordinary logout keeps owner-bound data; privacy withdrawal/deletion does not
/// use this dialog. Capture the login generation before reading private counts.
Future<void> confirmLogout(BuildContext context, WidgetRef ref) async {
  final session = ref.read(sessionStoreProvider);
  final identity = session.identity;
  if (identity == null) return;
  final auth = ref.read(authProvider.notifier);
  final entries = await ref
      .read(eventQueueProvider)
      .entries(ownerId: identity.ownerId);
  if (!context.mounted || !session.matches(identity)) return;
  final count = entries.where((entry) => entry.needsSync).length;
  final l10n = AppLocalizations.of(context);
  final action = await showDialog<String>(
    context: context,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        ref.watch(authProvider);
        if (!session.matches(identity)) {
          // A switch while the dialog is open must hide the old owner's count
          // immediately and must never turn confirmation into the new logout.
          return AlertDialog(
            content: Text(l10n.logoutIdentityChanged),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
            ],
          );
        }
        return AlertDialog(
          title: count == 0 ? null : Text(l10n.logoutUnfinishedCount(count)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.signOutConfirm),
                if (count != 0) ...[
                  const SizedBox(height: 12),
                  Text(l10n.logoutRetainedExplanation),
                ],
              ],
            ),
          ),
          actions: [
            if (count != 0)
              TextButton(
                onPressed: () => Navigator.of(context).pop('sync'),
                child: Text(l10n.logoutViewSync),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('logout'),
              child: Text(l10n.signOut),
            ),
          ],
        );
      },
    ),
  );
  if (!context.mounted || !session.matches(identity)) return;
  if (action == 'sync') {
    context.push('/me/sync');
  } else if (action == 'logout') {
    await auth.signOut(identity: identity);
  }
}
