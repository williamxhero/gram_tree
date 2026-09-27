import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../platform/permissions.dart';
import '../privacy/consent.dart';

/// 统一的权限申请方式：先说用途，用户点“继续”才调用系统申请。
///
/// 返回最终状态。已被永久拒绝时不再弹系统申请，直接返回 [PermissionState.permanentlyDenied]，
/// 由功能显示 [PermissionDeniedNotice]。同意隐私政策前不申请任何权限。
///
/// 用法（以后接入相机时）：
/// ```dart
/// final state = await requestPermission(context, ref, AppPermission.camera);
/// if (state == PermissionState.granted) { ... } else { 显示 PermissionDeniedNotice }
/// ```
Future<PermissionState> requestPermission(
  BuildContext context,
  WidgetRef ref,
  AppPermission permission,
) async {
  if (!ref.read(privacyConsentProvider)) return PermissionState.denied;
  final service = ref.read(permissionServiceProvider);
  final current = await service.status(permission);
  if (current != PermissionState.denied) return current;
  if (!context.mounted) return current;
  final go = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) => _Rationale(permission: permission),
  );
  if (go != true) return PermissionState.denied;
  return service.request(permission);
}

class _Rationale extends StatelessWidget {
  const _Rationale({required this.permission});

  final AppPermission permission;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.permissionNeeded(permission.label),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(permission.rationale, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.permissionContinue),
            ),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.permissionNotNow),
            ),
          ],
        ),
      ),
    );
  }
}

/// 权限被拒绝后，只在这个功能的位置显示：不可用 + 去系统设置打开。其余功能照常。
class PermissionDeniedNotice extends ConsumerWidget {
  const PermissionDeniedNotice({super.key, required this.permission});

  final AppPermission permission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.permissionUnavailableTitle(permission.feature),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.permissionUnavailableBody(permission.label),
            style: theme.textTheme.bodyMedium,
          ),
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () =>
                ref.read(permissionServiceProvider).openSystemSettings(),
            child: Text(l10n.permissionOpenSettings),
          ),
        ],
      ),
    );
  }
}
