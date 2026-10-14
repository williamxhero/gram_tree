import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../auth/session.dart';
import '../features/me/taste_profile_data.dart';
import 'composition_provider.dart';
import 'scenario_detail_scope.dart';

Future<Object?> handleScenarioFeedback(
  BuildContext context,
  Ref ref,
  Map<String, dynamic> params,
) async {
  final session = ref.read(sessionStoreProvider);
  final identity = session.identity;
  try {
    await ref
        .read(dioProvider)
        .post<void>(
          '/v1/ui/scenario-feedback',
          data: {
            'component_id': params['component_id'],
            'source_type': params['source_type'],
          },
          options: Options(
            extra: {
              if (identity != null) 'auth_owner_id': identity.ownerId,
              if (identity != null) 'auth_identity_epoch': identity.epoch,
            },
          ),
        );
    if (identity != null && !session.matches(identity)) return null;
    ref.invalidate(scenarioCompositionProvider);
  } on DioException {
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(const SnackBar(content: Text('反馈未保存，请联网后重试。')));
    }
  }
  return null;
}

Future<Object?> handleBeforeTasteChange(
  BuildContext context,
  Ref ref,
  Map<String, dynamic> params,
) async {
  await ScenarioDetailScope.of(context)?.onBeforeTaste
      ?.call(params['change_id'] as String);
  return null;
}

/// Reuses the existing learning/change history and revert operation. Opening
/// evidence does not revoke the profile until the user confirms the change.
Future<Object?> handleOpenTasteChange(
  BuildContext context,
  Ref ref,
  Map<String, dynamic> params,
) async {
  final scope = ScenarioDetailScope.of(context);
  final repository = ref.read(tasteProfileRepositoryProvider);
  final session = ref.read(sessionStoreProvider);
  final identity = session.identity;
  bool current() => identity != null && session.matches(identity);
  try {
    final changes = await repository.changes();
    final change = changes
        .where((row) => row.id == params['change_id'])
        .firstOrNull;
    if (change == null || !context.mounted || !current()) return null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('撤销这个口味变化'),
        content: Text(
          '${change.reason}\n${change.createdAt}\n撤销后将沿用已有口味变更恢复规则，不影响其他无关改动。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const ValueKey('scenario-confirm-revert'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确认撤销'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted || !current()) return null;
    await repository.revertChange(change.id);
    if (!context.mounted || !current()) return null;
    ref.invalidate(tasteProfileSnapshotProvider);
    ref.invalidate(tasteProfileProvider);
    ref.invalidate(tasteProfileChangesProvider);
    ref.invalidate(scenarioCompositionProvider);
    scope?.onTasteReverted?.call();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(const SnackBar(content: Text('口味变化暂时不可用，请联网后重试。')));
    }
  }
  return null;
}
