import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../auth/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../privacy/consent.dart';
import '../../privacy/documents.dart';
import '../../privacy/policy.dart';
import '../../widgets/page_frame.dart';
import 'account_data.dart';
import 'allergies_section.dart';

/// 我的 → 设置：账号、隐私、退出登录、注销账号。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const path = '/me/settings';
  static const identities = '$path/identities';
  static const bindEmail = '$path/identities/email';
  static const withdraw = '$path/withdraw';
  static const delete = '$path/delete';
  static String document(String id) => '$path/doc/$id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).value;
    final kinds = ref
        .watch(identitiesProvider)
        .value
        ?.map(
          (i) => i.kind == IdentityOutKindEnum.apple
              ? l10n.identityApple
              : l10n.identityEmail,
        )
        .join('、');
    Widget group(String label) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
    Widget item(
      String title, {
      String? value,
      VoidCallback? onTap,
      Color? color,
    }) => ValueTile(title: title, value: value, onTap: onTap, color: color);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          group(l10n.settingsAccount),
          item(
            l10n.settingsIdentities,
            value: kinds,
            onTap: () => context.push(identities),
          ),
          // 时区跟随手机自动更新，只展示
          item(l10n.settingsTimezone, value: user?.timezone),
          group(l10n.settingsPrivacy),
          item(
            l10n.privacyTitle,
            value: privacyVersion,
            onTap: () => context.push(document('privacy')),
          ),
          item(
            personalInfoList.title,
            onTap: () => context.push(document(personalInfoList.id)),
          ),
          item(sdkList.title, onTap: () => context.push(document(sdkList.id))),
          SwitchListTile(
            key: const ValueKey('product-analytics-switch'),
            title: Text(l10n.settingsProductAnalytics),
            subtitle: Text(
              l10n.settingsProductAnalyticsDetail,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            value: ref.watch(consentProvider).productAnalyticsEnabled,
            onChanged: (enabled) => _setProductAnalytics(ref, enabled),
          ),
          if (user != null)
            SensitiveWithdrawalTile(
              key: ValueKey('sensitive-withdraw-${user.id}'),
            ),
          item(l10n.settingsWithdraw, onTap: () => context.push(withdraw)),
          const Divider(height: 32),
          item(l10n.signOut, onTap: () => _signOut(context, ref)),
          item(
            l10n.deleteAccount,
            // 不可撤回的操作用错误色；酱红只留给“系统替你改了”
            color: theme.colorScheme.error,
            onTap: () => context.push(delete),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(authProvider.notifier).signOut();
  }

  /// 开关变化都记一条 `product_analytics` 同意记录，登录状态下立刻尝试上传。
  Future<void> _setProductAnalytics(WidgetRef ref, bool enabled) async {
    final entry = await ref
        .read(consentProvider.notifier)
        .setProductAnalytics(enabled);
    final uploaded = await ref.read(authProvider.notifier).uploadConsentRecords(
      [entry],
    );
    if (uploaded) {
      await ref.read(consentProvider.notifier).markUploaded([entry.id]);
    }
  }
}
