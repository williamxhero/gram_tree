import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../auth/auth_controller.dart';
import '../../auth/logout_confirmation.dart';
import '../../l10n/app_localizations.dart';
import '../../privacy/consent.dart';
import '../../privacy/documents.dart';
import '../../privacy/policy.dart';
import '../../platform/permissions.dart';
import '../../widgets/permission_request.dart';
import '../records/monthly_review_notifications.dart';
import '../../widgets/page_frame.dart';
import '../../ui_protocol/detail_preference_setting.dart';
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
  static const export = '$path/export';
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
          if (user != null)
            MonthlyReviewNotificationSetting(
              key: ValueKey('monthly-review-notification-${user.id}'),
              ownerId: user.id,
            ),
          const DetailPreferenceSetting(),
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
          item('导出我的数据', onTap: () => context.push(export)),
          item(l10n.settingsWithdraw, onTap: () => context.push(withdraw)),
          const Divider(height: 32),
          item(l10n.signOut, onTap: () => confirmLogout(context, ref)),
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

class MonthlyReviewNotificationSetting extends ConsumerStatefulWidget {
  const MonthlyReviewNotificationSetting({super.key, required this.ownerId});

  final String ownerId;

  @override
  ConsumerState<MonthlyReviewNotificationSetting> createState() =>
      _MonthlyReviewNotificationSettingState();
}

class _MonthlyReviewNotificationSettingState
    extends ConsumerState<MonthlyReviewNotificationSetting> {
  late Future<bool> _enabled;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enabled = ref
        .read(monthlyReviewNotificationControllerProvider)
        .enabled(widget.ownerId);
  }

  Future<void> _change(bool value) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final controller = ref.read(monthlyReviewNotificationControllerProvider);
      final permissionStatus = await ref
          .read(permissionServiceProvider)
          .status(AppPermission.notifications);
      final permissionWasRequested = await controller.permissionRequested(
        widget.ownerId,
      );
      if (value &&
          permissionStatus == PermissionState.denied &&
          !permissionWasRequested) {
        await controller.markPermissionRequested(widget.ownerId);
        if (!mounted) return;
        await requestPermission(context, ref, AppPermission.notifications);
      }
      await controller.setEnabled(widget.ownerId, value);
      if (!mounted) return;
      setState(() => _enabled = Future.value(value));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _enabled,
    builder: (context, snapshot) => SwitchListTile(
      key: const ValueKey('monthly-review-notification-switch'),
      title: const Text('每月回顾提醒'),
      subtitle: const Text('每月初提醒你查看上月回顾'),
      value: snapshot.data ?? true,
      onChanged: snapshot.hasData && !_saving ? _change : null,
    ),
  );
}
