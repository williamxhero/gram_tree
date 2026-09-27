import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/apple_sign_in.dart';
import '../../widgets/page_frame.dart';
import '../auth/code_page.dart';
import 'account_data.dart';
import 'settings_page.dart';

/// 登录方式：列出已绑定的，可以再绑一种。身份已属于别的账号时提示不能绑定，不做合并。
class IdentitiesPage extends ConsumerStatefulWidget {
  const IdentitiesPage({super.key});

  @override
  ConsumerState<IdentitiesPage> createState() => _IdentitiesPageState();
}

class _IdentitiesPageState extends ConsumerState<IdentitiesPage> {
  String? _error;
  bool _busy = false;

  Future<void> _bindApple() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final AppleCredential c;
      try {
        c = await ref.read(appleSignInProvider).signIn();
      } on AppleSignInCancelled {
        return;
      }
      await ref
          .read(apiClientProvider)
          .getAccountApi()
          .bindApple(
            bindAppleRequest: BindAppleRequest(
              identityToken: c.identityToken,
              authorizationCode: c.authorizationCode,
            ),
          );
      ref.invalidate(identitiesProvider);
    } catch (e) {
      if (mounted) setState(() => _error = ApiFailure.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final list = ref.watch(identitiesProvider);
    final ids = list.value ?? const <IdentityOut>[];
    String? find(IdentityOutKindEnum kind) =>
        ids.where((i) => i.kind == kind).map((i) => i.email ?? '').firstOrNull;
    final email = find(IdentityOutKindEnum.email);
    final apple = find(IdentityOutKindEnum.apple);
    final canApple = ref.watch(appleSignInProvider).isAvailable;
    return PageFrame(
      title: l10n.settingsIdentities,
      content: [
        if (list.isLoading && ids.isEmpty)
          const Center(child: CircularProgressIndicator())
        else
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            child: Column(
              children: [
                ValueTile(
                  title: l10n.identityEmail,
                  value: email ?? l10n.identityNotBound,
                ),
                ValueTile(
                  title: l10n.identityApple,
                  value: apple == null
                      ? l10n.identityNotBound
                      : (apple.isEmpty ? l10n.bindDone : apple),
                ),
              ],
            ),
          ),
        BodyText(l10n.identitiesHint, muted: true),
        if (_error != null) ErrorText(_error!),
      ],
      actions: [
        if (list.hasValue && email == null)
          SecondaryButton(
            label: l10n.bindEmail,
            onPressed: () => context.push(SettingsPage.bindEmail),
          ),
        if (list.hasValue && apple == null && canApple)
          SecondaryButton(
            label: l10n.bindApple,
            onPressed: _busy ? null : _bindApple,
          ),
      ],
    );
  }
}

/// 绑定邮箱：输邮箱 → 收码 → 输码。
class BindEmailPage extends ConsumerStatefulWidget {
  const BindEmailPage({super.key});

  @override
  ConsumerState<BindEmailPage> createState() => _BindEmailPageState();
}

class _BindEmailPageState extends ConsumerState<BindEmailPage> {
  final _email = TextEditingController();
  EmailCodeSent? _sent;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final sent = await ref
          .read(authProvider.notifier)
          .sendEmailCode(
            _email.text.trim(),
            purpose: EmailCodeRequestPurposeEnum.bind,
          );
      setState(() => _sent = sent);
    } catch (e) {
      setState(() => _error = ApiFailure.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _bind(String code) async {
    await ref
        .read(apiClientProvider)
        .getAccountApi()
        .bindEmail(
          bindEmailRequest: BindEmailRequest(
            email: _email.text.trim(),
            code: code,
          ),
        );
    ref.invalidate(identitiesProvider);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sent = _sent;
    return PageFrame(
      title: l10n.bindEmail,
      content: [
        if (sent == null) ...[
          TextField(
            key: const ValueKey('bind-email'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.emailLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_error != null) ErrorText(_error!),
          PrimaryButton(label: l10n.sendCode, busy: _busy, onPressed: _send),
        ] else
          CodeEntry(
            email: _email.text.trim(),
            resendAfter: sent.resendAfterSeconds,
            expiresIn: sent.expiresInSeconds,
            purpose: EmailCodeRequestPurposeEnum.bind,
            onSubmit: _bind,
          ),
      ],
    );
  }
}
