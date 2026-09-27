import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../auth/session.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/apple_sign_in.dart';
import '../../widgets/page_frame.dart';
import 'code_page.dart';

const loginPath = '/login';

/// 登录页：邮箱验证码，iPhone 上另有“通过 Apple 登录”。首次登录即创建账号。
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (ref.read(sessionStoreProvider).lastExpiryReason != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).sessionExpired)),
        );
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final sent = await ref.read(authProvider.notifier).sendEmailCode(email);
      if (!mounted) return;
      context.push(
        CodePage.location(
          email: email,
          resendAfter: sent.resendAfterSeconds,
          expiresIn: sent.expiresInSeconds,
        ),
      );
    } catch (e) {
      setState(() => _error = ApiFailure.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apple() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).signInWithApple();
    } catch (e) {
      if (mounted) setState(() => _error = ApiFailure.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final apple = ref.watch(appleSignInProvider).isAvailable;
    return PageFrame(
      content: [
        PageTitle(l10n.loginTitle),
        BodyText(l10n.loginSubtitle),
        TextField(
          key: const ValueKey('login-email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _send(),
          decoration: InputDecoration(
            labelText: l10n.emailLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        if (_error != null) ErrorText(_error!),
        PrimaryButton(label: l10n.sendCode, busy: _busy, onPressed: _send),
        if (apple) ...[
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(l10n.or),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          // Apple 规定的黑底按钮样式
          FilledButton.icon(
            key: const ValueKey('apple-sign-in'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: _busy ? null : _apple,
            icon: const Icon(Icons.apple),
            label: Text(l10n.appleSignIn),
          ),
        ],
        BodyText(l10n.loginFooter, muted: true),
      ],
    );
  }
}
