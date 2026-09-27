import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/app_exit.dart';
import '../../platform/link_opener.dart';
import '../../privacy/consent.dart';
import '../../privacy/policy.dart';
import '../../widgets/page_frame.dart';

const goodbyePath = '/goodbye';

/// 首次启动（或协议改版、撤回同意之后）的同意页。同意之前 App 不联网、不启动第三方 SDK。
///
/// 不同意时再说明一次为什么需要；仍不同意就退出，下次打开再问，不反复弹窗。
class ConsentPage extends ConsumerStatefulWidget {
  const ConsentPage({super.key});

  @override
  ConsumerState<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends ConsumerState<ConsentPage> {
  bool _explaining = false;
  bool _saving = false;

  Future<void> _agree() async {
    setState(() => _saving = true);
    await ref.read(consentProvider.notifier).agree();
    // 路由会在同意后自动跳到登录页
  }

  Future<void> _quit() async {
    final exited = await ref.read(appExitProvider).exit();
    if (!exited && mounted) context.go(goodbyePath);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final outdated = ref.watch(
      consentProvider.select((s) => s.outdatedPrivacyVersion),
    );
    if (_explaining) {
      return PageFrame(
        content: [
          PageTitle(l10n.consentExplainTitle),
          BodyText(l10n.consentExplainLead),
          InfoCard(
            lines: [
              l10n.consentExplain1,
              l10n.consentExplain2,
              l10n.consentExplain3,
            ],
          ),
          BodyText(l10n.consentExplainTail),
        ],
        actions: [
          PrimaryButton(
            label: l10n.consentAgree,
            busy: _saving,
            onPressed: _agree,
          ),
          SecondaryButton(label: l10n.consentExplainQuit, onPressed: _quit),
        ],
      );
    }
    final changes = outdated == null ? null : privacyChangeLog[privacyVersion];
    return PageFrame(
      content: [
        if (outdated != null) ...[
          PageTitle(
            l10n.consentUpdatedTitle,
            eyebrow: l10n.consentUpdatedEyebrow,
          ),
          InfoCard(
            label: l10n.consentUpdatedVersion(outdated, privacyVersion),
            lines: changes ?? const [],
          ),
          BodyText(l10n.consentUpdatedTail),
        ] else ...[
          PageTitle(l10n.consentTitle, eyebrow: l10n.consentEyebrow),
          InfoCard(
            label: l10n.consentCollectLabel,
            lines: [
              l10n.consentCollect1,
              l10n.consentCollect2,
              l10n.consentCollect3,
            ],
          ),
          InfoCard(
            label: l10n.consentNotLabel,
            lines: [l10n.consentNot1, l10n.consentNot2],
          ),
        ],
        const LegalLinks(),
      ],
      actions: [
        PrimaryButton(
          key: const ValueKey('consent-agree'),
          label: outdated != null
              ? l10n.consentUpdatedAgree
              : l10n.consentAgree,
          busy: _saving,
          onPressed: _agree,
        ),
        SecondaryButton(
          label: l10n.consentDecline,
          quiet: true,
          onPressed: () => setState(() => _explaining = true),
        ),
      ],
    );
  }
}

/// “完整内容见 用户协议 和 隐私政策”，点开用浏览器打开静态网页。
class LegalLinks extends ConsumerWidget {
  const LegalLinks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final base = ref.watch(appConfigProvider).apiBaseUrl;
    TextSpan link(String label, String doc) => TextSpan(
      text: label,
      style: TextStyle(
        decoration: TextDecoration.underline,
        color: theme.colorScheme.primary,
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () =>
            ref.read(linkOpenerProvider).open(Uri.parse(legalUrl(base, doc))),
    );
    return Text.rich(
      TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
        children: [
          TextSpan(text: '${l10n.consentLinksPrefix} '),
          link(l10n.termsTitle, 'terms'),
          const TextSpan(text: ' 和 '),
          link(l10n.privacyTitle, 'privacy'),
          const TextSpan(text: '。'),
        ],
      ),
    );
  }
}

/// 不同意且 App 不能自己退出时（iOS、网页版）显示的替身页。
class GoodbyePage extends StatelessWidget {
  const GoodbyePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageFrame(
      content: [PageTitle(l10n.goodbyeTitle), BodyText(l10n.goodbyeBody)],
      actions: [
        SecondaryButton(
          label: l10n.goodbyeReconsider,
          onPressed: () => context.go('/consent'),
        ),
      ],
    );
  }
}
