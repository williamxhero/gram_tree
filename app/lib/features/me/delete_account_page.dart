import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/apple_sign_in.dart';
import '../../widgets/page_frame.dart';
import '../auth/code_page.dart';
import 'account_data.dart';

/// 服务端配置项的默认值，只用于说明文字；实际期限以服务端为准。
const _reauthWindowMinutes = 10;
const _deletionBusinessDays = 15;

/// App 内注销账号：重新验证身份 → 看清删什么 → 确认。
class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  bool _verified = false;
  bool _checked = false;
  bool _busy = false;
  EmailCodeSent? _sent;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = ApiFailure.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode(String email) => _run(() async {
    final sent = await ref
        .read(authProvider.notifier)
        .sendEmailCode(email, purpose: EmailCodeRequestPurposeEnum.reauth);
    setState(() => _sent = sent);
  });

  Future<void> _verifyEmail(String email, String code) async {
    await ref
        .read(apiClientProvider)
        .getAuthApi()
        .reauthEmail(
          emailReauthRequest: EmailReauthRequest(email: email, code: code),
        );
    setState(() => _verified = true);
  }

  Future<void> _verifyApple() => _run(() async {
    final AppleCredential c;
    try {
      c = await ref.read(appleSignInProvider).signIn();
    } on AppleSignInCancelled {
      return;
    }
    await ref
        .read(apiClientProvider)
        .getAuthApi()
        .reauthApple(
          appleReauthRequest: AppleReauthRequest(
            identityToken: c.identityToken,
          ),
        );
    setState(() => _verified = true);
  });

  Future<void> _delete() => _run(() async {
    final messenger = ScaffoldMessenger.of(context);
    final done = AppLocalizations.of(context).deleteDone;
    await ref.read(apiClientProvider).getAccountApi().requestDeletion();
    await ref.read(authProvider.notifier).clearLocalSession();
    messenger.showSnackBar(SnackBar(content: Text(done)));
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageFrame(
      title: l10n.deleteAccount,
      content: [
        _Steps(done: _verified ? 3 : 1),
        if (!_verified) ..._verifyStep(l10n) else ..._confirmStep(l10n),
        if (_error != null) ErrorText(_error!),
      ],
      actions: [
        if (_verified)
          FilledButton(
            key: const ValueKey('delete-confirm'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              // 不可撤回的操作用错误色；酱红只留给“系统替你改了”
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: _checked && !_busy ? _delete : null,
            child: Text(l10n.deleteAccount),
          ),
      ],
    );
  }

  List<Widget> _verifyStep(AppLocalizations l10n) {
    final ids = ref.watch(identitiesProvider).value;
    if (ids == null) return const [Center(child: CircularProgressIndicator())];
    final email = ids
        .where((i) => i.kind == IdentityOutKindEnum.email)
        .map((i) => i.email)
        .whereType<String>()
        .firstOrNull;
    final hasApple = ids.any((i) => i.kind == IdentityOutKindEnum.apple);
    final canApple = ref.watch(appleSignInProvider).isAvailable;
    final sent = _sent;
    return [
      PageTitle(l10n.deleteStepVerify),
      if (email != null && sent != null)
        CodeEntry(
          email: email,
          resendAfter: sent.resendAfterSeconds,
          expiresIn: sent.expiresInSeconds,
          purpose: EmailCodeRequestPurposeEnum.reauth,
          onSubmit: (code) => _verifyEmail(email, code),
        )
      else if (email != null) ...[
        BodyText(l10n.deleteVerifyEmail(email)),
        BodyText(l10n.deleteVerifyWindow(_reauthWindowMinutes), muted: true),
        PrimaryButton(
          label: l10n.sendCode,
          busy: _busy,
          onPressed: () => _sendCode(email),
        ),
      ],
      if (hasApple && canApple && sent == null)
        SecondaryButton(
          label: l10n.deleteVerifyApple,
          onPressed: _busy ? null : _verifyApple,
        ),
    ];
  }

  List<Widget> _confirmStep(AppLocalizations l10n) => [
    PageTitle(l10n.deleteWhatTitle),
    InfoCard(lines: [l10n.deleteWhat1, l10n.deleteWhat2, l10n.deleteWhat3]),
    BodyText(l10n.deleteWhatTail(_deletionBusinessDays)),
    CheckboxListTile(
      key: const ValueKey('delete-check'),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: _checked,
      onChanged: (v) => setState(() => _checked = v ?? false),
      title: Text(l10n.deleteCheck),
    ),
  ];
}

/// 三步进度条。
class _Steps extends StatelessWidget {
  const _Steps({required this.done});

  final int done;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: i < done ? colors.primary : colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
