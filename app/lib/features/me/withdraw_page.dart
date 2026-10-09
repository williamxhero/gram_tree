import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_controller.dart';
import '../../auth/session.dart';
import '../../l10n/app_localizations.dart';
import '../../privacy/consent.dart';
import '../../recipes/recipe_snapshot_provider.dart';
import '../../recipes/personal_measure_repository.dart';
import '../../widgets/page_frame.dart';

/// 撤回同意：说明已存数据怎么处理 → 确认后停止采集、退出登录、回到同意页。
class WithdrawConsentPage extends ConsumerStatefulWidget {
  const WithdrawConsentPage({super.key});

  @override
  ConsumerState<WithdrawConsentPage> createState() =>
      _WithdrawConsentPageState();
}

class _WithdrawConsentPageState extends ConsumerState<WithdrawConsentPage> {
  bool _busy = false;

  Future<void> _withdraw() async {
    setState(() => _busy = true);
    final auth = ref.read(authProvider.notifier);
    final session = ref.read(sessionStoreProvider);
    final identity = session.identity;
    final pausing = identity == null
        ? null
        : session.pauseAccountUploads(identity);
    // Consent removal makes the provider nullable; retain the current-owner
    // handle so cleanup is awaited, not only a best-effort provider listener.
    final snapshots = ref.read(recipeSnapshotStoreProvider);
    final measures = identity == null
        ? null
        : ref.read(personalMeasureRepositoryProvider);
    await pausing;
    await ref
        .read(consentProvider.notifier)
        .withdraw(
          beforeEffective: (records) async {
            final uploaded = identity == null
                ? false
                : await auth.uploadConsentRecords(records, identity: identity);
            if (identity != null) {
              await auth.signOutOnServer(identity: identity);
            }
            return uploaded;
          },
        );
    await snapshots?.clear();
    await measures?.clearAccount();
    if (identity != null) await auth.clearLocalSession(identity: identity);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageFrame(
      title: l10n.settingsWithdraw,
      content: [
        BodyText(l10n.withdrawBody),
        InfoCard(label: l10n.withdrawDataLabel, lines: [l10n.withdrawDataBody]),
      ],
      actions: [
        PrimaryButton(
          label: l10n.withdrawConfirm,
          busy: _busy,
          onPressed: _withdraw,
        ),
        SecondaryButton(
          label: l10n.cancel,
          quiet: true,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
