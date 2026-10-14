import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/session.dart';
import 'export_data.dart';

final exportMessengerKeyProvider = Provider(
  (ref) => GlobalKey<ScaffoldMessengerState>(),
);

void listenForExportCompletion(WidgetRef ref) {
  ref.listen(exportJobsProvider, (previous, next) {
    final jobs = next.value;
    if (next.isLoading || jobs == null) return;
    final before = {
      for (final job in previous?.value ?? []) job.id: job.status.value,
    };
    final identity = ref.read(sessionStoreProvider).identity;
    if (identity == null) return;
    final key = ref.read(exportMessengerKeyProvider);
    for (final job in jobs) {
      if (job.status.value != 'completed' || before[job.id] == 'completed') {
        continue;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!ref.context.mounted ||
            !ref.read(sessionStoreProvider).matches(identity)) {
          return;
        }
        key.currentState?.showSnackBar(
          const SnackBar(content: Text('导出已完成，可在设置 → 导出我的数据中下载')),
        );
      });
    }
  });
}
