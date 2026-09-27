import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/link_opener.dart';
import '../../privacy/documents.dart';
import '../../privacy/policy.dart';
import '../../widgets/page_frame.dart';
import '../onboarding/consent_page.dart';

/// 设置里的隐私文档：隐私政策（摘要 + 全文链接）和两份随 App 发布的清单。
class DocumentPage extends ConsumerWidget {
  const DocumentPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (id == 'privacy' || id == 'terms') {
      final base = ref.watch(appConfigProvider).apiBaseUrl;
      final title = id == 'privacy' ? l10n.privacyTitle : l10n.termsTitle;
      return PageFrame(
        title: title,
        content: [
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
          const LegalLinks(),
        ],
        actions: [
          SecondaryButton(
            label: l10n.openFullText,
            onPressed: () => ref
                .read(linkOpenerProvider)
                .open(Uri.parse(legalUrl(base, id))),
          ),
        ],
      );
    }
    final doc = id == sdkList.id ? sdkList : personalInfoList;
    final theme = Theme.of(context);
    return PageFrame(
      title: doc.title,
      content: [
        BodyText(doc.intro, muted: true),
        for (final item in doc.items)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              BodyText(item.purpose),
              BodyText(item.detail, muted: true),
            ],
          ),
      ],
    );
  }
}
