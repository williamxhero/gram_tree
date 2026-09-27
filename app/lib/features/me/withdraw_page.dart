import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../privacy/consent.dart';
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
    await ref
        .read(consentProvider.notifier)
        .withdraw(
          beforeEffective: (records) async {
            final uploaded = await auth.uploadConsentRecords(records);
            await auth.signOutOnServer();
            return uploaded;
          },
        );
    await auth.clearLocalSession();
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
