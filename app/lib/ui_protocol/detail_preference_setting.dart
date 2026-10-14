import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../auth/session.dart';
import 'composition_provider.dart';

class DetailPreferenceSetting extends ConsumerStatefulWidget {
  const DetailPreferenceSetting({super.key});

  @override
  ConsumerState<DetailPreferenceSetting> createState() =>
      _DetailPreferenceSettingState();
}

class _DetailPreferenceSettingState
    extends ConsumerState<DetailPreferenceSetting> {
  bool _saving = false;

  Future<void> _save(String value) async {
    final session = ref.read(sessionStoreProvider);
    final identity = session.identity;
    if (identity == null || _saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(dioProvider)
          .put<Map<String, dynamic>>(
            '/v1/ui/preferences',
            data: {'detail': value},
            options: Options(
              extra: {
                'auth_owner_id': identity.ownerId,
                'auth_identity_epoch': identity.epoch,
              },
            ),
          );
      if (!mounted || !session.matches(identity)) return;
      ref.invalidate(detailPreferenceProvider);
      ref.invalidate(scenarioCompositionProvider);
    } catch (_) {
      if (mounted && session.matches(identity)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('默认详略未保存，请联网后重试。')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preference = ref.watch(detailPreferenceProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('页面默认详略'),
          const SizedBox(height: 8),
          preference.when(
            loading: () => const Text('正在读取默认设置…'),
            error: (_, _) => TextButton(
              onPressed: () => ref.invalidate(detailPreferenceProvider),
              child: const Text('无法读取，重试'),
            ),
            data: (value) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in const {
                  'auto': '按经验自动',
                  'brief': '固定简洁',
                  'detailed': '固定详细',
                }.entries)
                  ChoiceChip(
                    key: ValueKey('detail-preference-${entry.key}'),
                    label: Text(entry.value),
                    selected: value == entry.key,
                    onSelected: _saving ? null : (_) => _save(entry.key),
                  ),
              ],
            ),
          ),
          const Text('页面内切换只影响本次查看，不改变这里的默认设置。'),
        ],
      ),
    );
  }
}
