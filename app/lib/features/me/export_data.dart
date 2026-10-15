import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../auth/session.dart';
import '../../platform/export_file_share.dart';

final exportJobsProvider =
    AsyncNotifierProvider<ExportJobs, List<ExportJobView>>(ExportJobs.new);

/// Job status is durable on the server. Polling survives leaving the export page,
/// but never carries one account's jobs into another account's session.
class ExportJobs extends AsyncNotifier<List<ExportJobView>> {
  @override
  Future<List<ExportJobView>> build() async {
    ref.watch(exportShareSessionFenceProvider);
    final auth = ref.watch(authProvider);
    if (auth.value == null) return const [];
    final identity = ref.read(sessionStoreProvider).identity;
    if (identity == null) return const [];
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    return await _fetch(identity) ?? const [];
  }

  Map<String, dynamic> _extra(SessionIdentity identity) => {
    'auth_owner_id': identity.ownerId,
    'auth_identity_epoch': identity.epoch,
  };

  int _requestGeneration = 0;

  Future<List<ExportJobView>?> _fetch(SessionIdentity identity) async {
    final generation = ++_requestGeneration;
    final result = await ref
        .read(apiClientProvider)
        .getExportsApi()
        .listExports(extra: _extra(identity));
    if (!ref.mounted ||
        generation != _requestGeneration ||
        !ref.read(sessionStoreProvider).matches(identity)) {
      return null;
    }
    final jobs = result.data!.items;
    final pending = jobs.any(
      (job) =>
          job.status.value == 'pending' || job.status.value == 'processing',
    );
    if (pending) {
      _timer ??= Timer.periodic(const Duration(seconds: 5), (_) {
        if (ref.mounted && ref.read(sessionStoreProvider).matches(identity)) {
          unawaited(_poll(identity));
        }
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
    return jobs;
  }

  Timer? _timer;
  bool _polling = false;

  Future<void> _poll(SessionIdentity identity) async {
    if (_polling) return;
    _polling = true;
    try {
      final generation = _requestGeneration + 1;
      final jobs = await _fetch(identity);
      if (jobs != null &&
          generation == _requestGeneration &&
          ref.mounted &&
          ref.read(sessionStoreProvider).matches(identity)) {
        state = AsyncData(jobs);
      }
    } catch (_) {
      // A transient outage does not erase a completed job or its expiry display.
    } finally {
      _polling = false;
    }
  }

  Future<void> refresh() async {
    final identity = ref.read(sessionStoreProvider).identity;
    if (identity == null) return;
    final generation = _requestGeneration + 1;
    final jobs = await _fetch(identity);
    if (jobs != null &&
        generation == _requestGeneration &&
        ref.mounted &&
        ref.read(sessionStoreProvider).matches(identity)) {
      state = AsyncData(jobs);
    }
  }

  Future<void> start() async {
    final identity = ref.read(sessionStoreProvider).identity;
    if (identity == null) return;
    await ref
        .read(apiClientProvider)
        .getExportsApi()
        .startExport(extra: _extra(identity));
    if (ref.mounted && ref.read(sessionStoreProvider).matches(identity)) {
      await refresh();
    }
  }

  Future<void> retry(String id) async {
    final identity = ref.read(sessionStoreProvider).identity;
    if (identity == null) return;
    await ref
        .read(apiClientProvider)
        .getExportsApi()
        .retryExport(jobId: id, extra: _extra(identity));
    if (ref.mounted && ref.read(sessionStoreProvider).matches(identity)) {
      await refresh();
    }
  }

  Future<bool> download(ExportJobView job) async {
    final session = ref.read(sessionStoreProvider);
    final identity = session.identity;
    if (identity == null || !session.canUpload(identity)) return false;
    final url = Uri.tryParse(job.downloadUrl ?? '');
    if (url == null ||
        url.hasScheme ||
        url.hasAuthority ||
        url.path != '/v1/me/exports/${job.id}/download' ||
        url.fragment.isNotEmpty) {
      throw StateError('Invalid export download URL');
    }
    final share = ref.read(exportFileShareProvider);
    // Binary transfer uses the same consent/auth chain, not an external link
    // opener. The generated JSON client remains the source for job operations.
    final result = await ref
        .read(dioProvider)
        .get<List<int>>(
          url.toString(),
          options: Options(
            responseType: ResponseType.bytes,
            extra: _extra(identity),
          ),
        );
    if (!ref.mounted || !session.canUpload(identity)) return false;
    final bytes = result.data;
    if (bytes == null || bytes.isEmpty) throw StateError('Empty export');
    await share.share(
      Uint8List.fromList(bytes),
      filename: 'gramtree-${job.id}.zip',
    );
    return ref.mounted && session.canUpload(identity);
  }
}
