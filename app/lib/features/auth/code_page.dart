import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../app/theme.dart';
import '../../auth/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/page_frame.dart';

/// 输入验证码。输满 6 位自动提交；有重新发送倒计时。
///
/// 登录、绑定邮箱、注销前重新验证都用它，区别只在 [onSubmit] 和发码用途。
class CodeEntry extends ConsumerStatefulWidget {
  const CodeEntry({
    super.key,
    required this.email,
    required this.resendAfter,
    required this.expiresIn,
    required this.purpose,
    required this.onSubmit,
  });

  final String email;
  final int resendAfter;
  final int expiresIn;
  final EmailCodeRequestPurposeEnum purpose;

  /// 提交验证码；抛出的接口错误会显示在输入框下面。
  final Future<void> Function(String code) onSubmit;

  @override
  ConsumerState<CodeEntry> createState() => _CodeEntryState();
}

class _CodeEntryState extends ConsumerState<CodeEntry> {
  final _code = TextEditingController();
  Timer? _timer;
  late int _wait = widget.resendAfter;
  late int _expiresIn = widget.expiresIn;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _wait = _wait > 0 ? _wait - 1 : 0);
      if (_wait == 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code.text.trim();
    if (code.length != 6 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(code);
    } catch (e) {
      if (mounted) {
        setState(() => _error = ApiFailure.from(e).message);
        _code.clear();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _error = null);
    try {
      final sent = await ref
          .read(authProvider.notifier)
          .sendEmailCode(widget.email, purpose: widget.purpose);
      setState(() {
        _wait = sent.resendAfterSeconds;
        _expiresIn = sent.expiresInSeconds;
      });
      _startTimer();
    } catch (e) {
      setState(() => _error = ApiFailure.from(e).message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = GramTreeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BodyText(l10n.codeSentTo(widget.email, _expiresIn ~/ 60)),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('code-input'),
          controller: _code,
          autofocus: true,
          enabled: !_busy,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onChanged: (v) {
            if (v.length == 6) _submit();
          },
          textAlign: TextAlign.center,
          style: colors.numberStyle(
            theme.textTheme.headlineSmall!.copyWith(letterSpacing: 12),
          ),
          decoration: InputDecoration(
            labelText: l10n.codeFieldLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        if (_error != null) ...[const SizedBox(height: 8), ErrorText(_error!)],
        const SizedBox(height: 12),
        if (_wait > 0)
          BodyText(l10n.resendIn(_wait), muted: true)
        else
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: _resend, child: Text(l10n.resend)),
          ),
        const SizedBox(height: 12),
        BodyText(l10n.codeHelp, muted: true),
      ],
    );
  }
}

/// 登录的验证码页。
class CodePage extends ConsumerWidget {
  const CodePage({
    super.key,
    required this.email,
    required this.resendAfter,
    required this.expiresIn,
  });

  static const path = '/login/code';

  static String location({
    required String email,
    required int resendAfter,
    required int expiresIn,
  }) => Uri(
    path: path,
    queryParameters: {
      'email': email,
      'resend': '$resendAfter',
      'expires': '$expiresIn',
    },
  ).toString();

  final String email;
  final int resendAfter;
  final int expiresIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PageFrame(
      showBack: true,
      content: [
        PageTitle(l10n.codeTitle),
        CodeEntry(
          email: email,
          resendAfter: resendAfter,
          expiresIn: expiresIn,
          purpose: EmailCodeRequestPurposeEnum.login,
          // 登录成功后路由自动进入主界面
          onSubmit: (code) =>
              ref.read(authProvider.notifier).signInWithEmail(email, code),
        ),
      ],
    );
  }
}
