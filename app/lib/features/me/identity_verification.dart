import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../auth/session.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/apple_sign_in.dart';
import '../../widgets/page_frame.dart';
import '../auth/code_page.dart';
import 'account_data.dart';

/// Sensitive actions use the account's bound identity, never a new login.
class IdentityVerification extends ConsumerStatefulWidget {
  const IdentityVerification({super.key, required this.onVerified});

  final VoidCallback onVerified;

  @override
  ConsumerState<IdentityVerification> createState() =>
      _IdentityVerificationState();
}

class _IdentityVerificationState extends ConsumerState<IdentityVerification> {
  EmailCodeSent? _sent;
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AppleSignInCancelled {
      // Cancelling the platform identity sheet is not a verification failure.
    } catch (error) {
      if (mounted) setState(() => _error = ApiFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify({String? email, String? code}) async {
    final session = ref.read(sessionStoreProvider);
    final identity = session.identity;
    if (identity == null) return;
    final api = ref.read(apiClientProvider).getAuthApi();
    final extra = <String, dynamic>{
      'auth_owner_id': identity.ownerId,
      'auth_identity_epoch': identity.epoch,
    };
    if (email != null && code != null) {
      await api.reauthEmail(
        emailReauthRequest: EmailReauthRequest(email: email, code: code),
        extra: extra,
      );
    } else {
      final credential = await ref.read(appleSignInProvider).signIn();
      if (!mounted || !session.matches(identity)) return;
      await api.reauthApple(
        appleReauthRequest: AppleReauthRequest(
          identityToken: credential.identityToken,
        ),
        extra: extra,
      );
    }
    if (mounted && session.matches(identity)) widget.onVerified();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final identities = ref.watch(identitiesProvider);
    final ids = identities.value;
    if (ids == null) {
      return Column(
        children: [
          if (!identities.hasError)
            const CircularProgressIndicator()
          else ...[
            ErrorText(ApiFailure.from(identities.error!).message),
            SecondaryButton(
              label: l10n.retry,
              onPressed: () => ref.invalidate(identitiesProvider),
            ),
          ],
        ],
      );
    }
    final email = ids
        .where((i) => i.kind == IdentityOutKindEnum.email)
        .map((i) => i.email)
        .whereType<String>()
        .firstOrNull;
    final apple =
        ids.any((i) => i.kind == IdentityOutKindEnum.apple) &&
        ref.watch(appleSignInProvider).isAvailable;
    final sent = _sent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        PageTitle(l10n.deleteStepVerify),
        if (email != null && sent != null)
          CodeEntry(
            email: email,
            resendAfter: sent.resendAfterSeconds,
            expiresIn: sent.expiresInSeconds,
            purpose: EmailCodeRequestPurposeEnum.reauth,
            onSubmit: (code) => _verify(email: email, code: code),
          )
        else if (email != null) ...[
          BodyText(l10n.deleteVerifyEmail(email)),
          PrimaryButton(
            label: l10n.sendCode,
            busy: _busy,
            onPressed: () => _run(() async {
              final session = ref.read(sessionStoreProvider);
              final identity = session.identity;
              if (identity == null) return;
              final sent = await ref
                  .read(authProvider.notifier)
                  .sendEmailCode(
                    email,
                    purpose: EmailCodeRequestPurposeEnum.reauth,
                  );
              if (mounted && session.matches(identity)) {
                setState(() => _sent = sent);
              }
            }),
          ),
        ],
        if (apple && sent == null)
          SecondaryButton(
            label: l10n.deleteVerifyApple,
            onPressed: _busy ? null : () => _run(() => _verify()),
          ),
        if (email == null && !apple) const BodyText('当前设备无法重新验证，请使用已绑定的登录方式。'),
        if (_error != null) ErrorText(_error!),
      ],
    );
  }
}
