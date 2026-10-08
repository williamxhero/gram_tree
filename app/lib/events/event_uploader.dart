import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../api/api_client.dart';
import '../auth/session.dart';
import '../observability/crash_reporting.dart';
import '../privacy/consent.dart';
import 'event_queue.dart';

final eventUploaderProvider = Provider<EventUploader>((ref) {
  final uploader = EventUploader(ref);
  final session = ref.read(sessionStoreProvider);
  var previousIdentity = session.identity;
  void identityChanged() {
    final next = session.identity;
    final previous = previousIdentity;
    previousIdentity = next;
    if (previous != null && previous.epoch != next?.epoch) {
      unawaited(uploader.pauseOwner(previous));
    }
  }

  session.addListener(identityChanged);
  ref.onDispose(() {
    session.removeListener(identityChanged);
    uploader.dispose();
  });
  return uploader;
});

/// One registered account-scoped drain, extending the existing event uploader.
/// Deferred children do not block later parents. Each attempt and its retry state
/// is durable before HTTP; replay after process death uses the SAME envelope.
class EventUploader {
  EventUploader(
    this._ref, {
    this.initialBackoff = const Duration(seconds: 5),
    this.maxBackoff = const Duration(minutes: 10),
    this.maxAttempts = 20,
    int batchSize = 100,
  });

  final Ref _ref;
  final Duration initialBackoff;
  final Duration maxBackoff;
  final int maxAttempts;
  Timer? _retryTimer;
  bool _uploading = false;
  bool _rerunRequested = false;
  bool _rerunAttemptedOnly = true;
  bool _disposed = false;

  // Compatibility diagnostic thresholds; no content is discarded on backlog.
  static const backlogCountThreshold = 500;
  static const backlogAgeThreshold = Duration(hours: 24);

  SessionStore get _session => _ref.read(sessionStoreProvider);
  EventQueue get _queue => _ref.read(eventQueueProvider);

  Future<void> pauseOwner(SessionIdentity identity) async {
    bool canPause() =>
        !_disposed &&
        _ref.mounted &&
        _session.current?.user.id != identity.ownerId;
    if (!canPause()) return;
    final queue = _queue;
    for (final entry in await queue.entries(ownerId: identity.ownerId)) {
      // A new login of the same owner supersedes this old logout callback.
      if (!canPause()) return;
      if (entry.state == WriteState.pending ||
          entry.state == WriteState.uploading ||
          entry.state == WriteState.deferred) {
        await queue.update(
          entry.change(
            state: WriteState.loginPaused,
            attempts: entry.state == WriteState.uploading
                ? math.max(0, entry.attempts - 1)
                : entry.attempts,
            reasonCode: 'login_required',
          ),
        );
      }
    }
  }

  Future<void> networkRestored() async {
    if (_disposed || !_ref.mounted) return;
    final owner = _session.current?.user.id;
    final epoch = _session.identityEpoch;
    if (owner == null || !_sameAccount(owner, epoch)) return;
    final queue = _queue;
    for (final entry in await queue.entries(ownerId: owner)) {
      if (!_sameAccount(owner, epoch)) return;
      if (entry.state == WriteState.pending ||
          entry.state == WriteState.deferred ||
          entry.state == WriteState.loginPaused ||
          (entry.state == WriteState.uploading && !_uploading)) {
        await queue.update(
          entry.change(state: WriteState.pending, reasonCode: entry.reasonCode),
        );
      }
    }
    if (_sameAccount(owner, epoch)) await triggerUpload();
  }

  Future<void> retryCurrentAccount() async {
    if (_disposed || !_ref.mounted) return;
    final identity = _session.identity;
    if (identity == null || !_sameAccount(identity.ownerId, identity.epoch)) {
      return;
    }
    final queue = _queue;
    await queue.retryAccount(identity.ownerId);
    if (_sameAccount(identity.ownerId, identity.epoch)) await triggerUpload();
  }

  bool _sameAccount(String owner, int epoch) =>
      !_disposed &&
      _ref.mounted &&
      _session.current?.user.id == owner &&
      _session.identityEpoch == epoch &&
      _ref.read(privacyConsentProvider);

  Future<void> triggerUpload() => _triggerUpload();

  Future<void> _triggerUpload({bool attemptedOnly = false}) async {
    if (_disposed || !_ref.mounted) return;
    if (_uploading) {
      _rerunRequested = true;
      // An explicit enqueue/network trigger may start fresh work even when it
      // coincides with a timer restricted to previously attempted writes.
      _rerunAttemptedOnly = _rerunAttemptedOnly && attemptedOnly;
      return;
    }
    _uploading = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    try {
      do {
        _rerunRequested = false;
        _rerunAttemptedOnly = true;
        await _drain(attemptedOnly: attemptedOnly);
        attemptedOnly = _rerunAttemptedOnly;
      } while (_rerunRequested && !_disposed && _ref.mounted);
      if (!_disposed && _ref.mounted) await _checkBacklog();
    } finally {
      _uploading = false;
    }
    // An overdue retry can fire during the asynchronous backlog read too.
    if (_rerunRequested) {
      unawaited(_triggerUpload(attemptedOnly: _rerunAttemptedOnly));
    }
  }

  Future<void> _drain({required bool attemptedOnly}) async {
    final session = _session.current;
    if (session == null || !_ref.read(privacyConsentProvider)) return;
    final owner = session.user.id;
    final epoch = _session.identityEpoch;
    final queue = _queue;
    var progressed = false;
    var transportUnavailable = false;
    DateTime? earliestRetry;
    do {
      progressed = false;
      final entries = await queue.entries(ownerId: owner);
      if (!_sameAccount(owner, epoch)) return;
      final byId = {for (final entry in entries) entry.write.id: entry};
      Future<void> save(QueueEntry next) async {
        final previous = byId[next.write.id]!;
        await queue.update(next);
        byId[next.write.id] = next;
        // Settled prerequisites wake earlier children too. Updating only the
        // durable queue leaves this pass's dependency lookup stale.
        if ((next.state == WriteState.failed ||
                next.state == WriteState.conflict ||
                next.reasonCode == 'dependency_conflict') &&
            (next.state != previous.state ||
                next.reasonCode != previous.reasonCode)) {
          progressed = true;
        }
      }

      for (var entry in entries) {
        if (!_sameAccount(owner, epoch)) return;
        if (entry.state == WriteState.confirmed ||
            entry.state == WriteState.failed ||
            entry.state == WriteState.conflict ||
            entry.state == WriteState.quarantined ||
            ((attemptedOnly || transportUnavailable) &&
                entry.state == WriteState.loginPaused)) {
          continue;
        }
        if (_hasDependencyCycle(entry.write.id, byId)) {
          await save(
            entry.change(
              state: WriteState.failed,
              reasonCode: 'dependency_cycle',
            ),
          );
          continue;
        }
        final blocked = entry.write.dependencies
            .map((id) => byId[id])
            .whereType<QueueEntry>();
        if (blocked.any((parent) => parent.state == WriteState.failed)) {
          await save(
            entry.change(
              state: WriteState.failed,
              reasonCode: 'dependency_failed',
            ),
          );
          continue;
        }
        if (blocked.any(
          (parent) =>
              parent.state == WriteState.conflict ||
              parent.reasonCode == 'dependency_conflict',
        )) {
          await save(
            entry.change(
              state: WriteState.deferred,
              reasonCode: 'dependency_conflict',
            ),
          );
          continue;
        }
        if (blocked.any((parent) => parent.state != WriteState.confirmed)) {
          // Known local prerequisites can be visited later in this pass. Waiting
          // for them is not an HTTP attempt and must not exhaust the retry cap.
          if (entry.state != WriteState.deferred ||
              entry.reasonCode != 'dependency_not_confirmed') {
            await save(
              entry.change(
                state: WriteState.deferred,
                reasonCode: 'dependency_not_confirmed',
              ),
            );
          }
          continue;
        }
        // Dependency transitions still settle fresh children, but a timer in a
        // transport outage must not spend unrelated writes' first attempts.
        if ((attemptedOnly || transportUnavailable) && entry.attempts == 0) {
          continue;
        }
        // Dependency failure/conflict is actionable even during backoff. It
        // must not wait for, or consume, the child's next HTTP attempt.
        if (entry.nextAttemptAt != null &&
            entry.nextAttemptAt!.isAfter(DateTime.now().toUtc())) {
          if (earliestRetry == null ||
              entry.nextAttemptAt!.isBefore(earliestRetry)) {
            earliestRetry = entry.nextAttemptAt;
          }
          continue;
        }
        if (entry.attempts >= maxAttempts) {
          await save(
            entry.change(
              state: WriteState.failed,
              reasonCode: 'retry_limit_exceeded',
            ),
          );
          continue;
        }
        if (transportUnavailable) continue;
        entry = entry.change(
          state: WriteState.uploading,
          attempts: entry.attempts + 1,
        );
        await save(entry);
        if (!_sameAccount(owner, epoch)) return;
        try {
          final response = await _ref
              .read(apiClientProvider)
              .getSyncApi()
              .uploadWrites(
                writeBatch: WriteBatch(
                  writes: [WriteEnvelope.fromJson(entry.write.toJson())],
                ),
                headers: {
                  'Authorization': 'Bearer ${_session.current!.accessToken}',
                },
                extra: {'sync_owner_id': owner, 'sync_identity_epoch': epoch},
              );
          if (!_sameAccount(owner, epoch)) return;
          final results = response.data?.results;
          if (results == null ||
              results.length != 1 ||
              results.single.writeId != entry.write.id) {
            throw StateError('Incomplete write confirmation');
          }
          // A valid server result proves the transport outage has ended.
          // Ordinary new work can resume, including earlier skipped entries.
          attemptedOnly = false;
          final result = results.single;
          switch (result.status) {
            case WriteResultStatusEnum.confirmed:
            case WriteResultStatusEnum.alreadyProcessed:
              if (result.result == null) {
                throw StateError('Missing resource association');
              }
              await queue.confirm(
                entry.write.id,
                owner,
                result.result!.toJson(),
              );
              byId[entry.write.id] = entry.change(state: WriteState.confirmed);
              progressed = true;
            case WriteResultStatusEnum.deferred_:
              final wait = _retryAt(entry.attempts);
              await save(
                entry.change(
                  state: entry.attempts >= maxAttempts
                      ? WriteState.failed
                      : WriteState.deferred,
                  reasonCode: entry.attempts >= maxAttempts
                      ? 'retry_limit_exceeded:${result.reasonCode}'
                      : result.reasonCode,
                  nextAttemptAt: wait,
                ),
              );
              if (earliestRetry == null || wait.isBefore(earliestRetry)) {
                earliestRetry = wait;
              }
            case WriteResultStatusEnum.conflict:
              await save(
                entry.change(
                  state: WriteState.conflict,
                  reasonCode: result.reasonCode,
                  result: result.conflict == null
                      ? null
                      : Map<String, dynamic>.from(result.conflict! as Map),
                ),
              );
            case WriteResultStatusEnum.failed:
              await save(
                entry.change(
                  state: WriteState.failed,
                  reasonCode: result.reasonCode ?? 'write_rejected',
                ),
              );
              if (_sameAccount(owner, epoch) &&
                  entry.write.writeType == 'experience.event') {
                reportEventRejection(
                  _ref,
                  eventId: entry.write.id,
                  eventType: entry.write.eventType,
                  typeVersion: entry.write.typeVersion,
                  reasonCode: result.reasonCode ?? 'write_rejected',
                );
              }
          }
        } on DioException catch (error) {
          if (!_sameAccount(owner, epoch)) return;
          if (error.response?.statusCode == 401) {
            await queue.update(
              entry.change(
                state: WriteState.loginPaused,
                attempts: entry.attempts - 1,
                reasonCode: 'login_required',
              ),
            );
            return;
          }
          if (error.response != null &&
              error.response!.statusCode! >= 400 &&
              error.response!.statusCode! < 500) {
            attemptedOnly = false;
            await save(
              entry.change(
                state: WriteState.failed,
                reasonCode: ApiFailure.from(error).code,
              ),
            );
          } else {
            final wait = await _retainForRetry(
              entry,
              'network_or_server_failure',
              save,
            );
            if (!_sameAccount(owner, epoch)) return;
            // The outage ends this pass, not the deadlines of writes already
            // attempted in earlier passes. Include unvisited retained retries
            // from the synchronized snapshot, but never start fresh work here.
            earliestRetry = _nextAttemptedRetry(byId);
            // Transport outage affects all entries; don't consume all their
            // attempts while offline. Deferred business results, by contrast,
            // continue to later entries in the same pass.
            if (wait != null) {
              _scheduleRetry(
                earliestRetry,
                owner: owner,
                epoch: epoch,
                attemptedOnly: true,
              );
              return;
            }
            // Exhaustion is terminal: settle dependent children in this drain
            // before returning, without trying other entries during the outage.
            transportUnavailable = true;
          }
        } catch (_) {
          if (!_sameAccount(owner, epoch)) return;
          final wait = await _retainForRetry(
            entry,
            'invalid_or_lost_response',
            save,
          );
          if (wait != null &&
              (earliestRetry == null || wait.isBefore(earliestRetry))) {
            earliestRetry = wait;
          }
        }
      }
      if (!_sameAccount(owner, epoch)) return;
      if (progressed) {
        // A newly confirmed prerequisite wakes deferred dependents immediately,
        // in original sequence, rather than waiting behind a retry deadline.
        final refreshed = await queue.entries(ownerId: owner);
        final confirmedIds = refreshed
            .where((e) => e.state == WriteState.confirmed)
            .map((e) => e.write.id)
            .toSet();
        for (final entry in refreshed) {
          if (!_sameAccount(owner, epoch)) return;
          if (entry.state == WriteState.deferred &&
              entry.write.dependencies.isNotEmpty &&
              entry.write.dependencies.every(confirmedIds.contains)) {
            await queue.update(
              entry.change(
                state: WriteState.deferred,
                reasonCode: entry.reasonCode,
              ),
            );
          }
        }
      }
    } while (progressed && _sameAccount(owner, epoch));
    _scheduleRetry(
      earliestRetry,
      owner: owner,
      epoch: epoch,
      attemptedOnly: attemptedOnly || transportUnavailable,
    );
  }

  DateTime? _nextAttemptedRetry(Map<String, QueueEntry> entries) {
    DateTime? earliest;
    for (final entry in entries.values) {
      final at = entry.nextAttemptAt;
      if (entry.attempts == 0 ||
          at == null ||
          (entry.state != WriteState.pending &&
              entry.state != WriteState.deferred &&
              entry.state != WriteState.uploading) ||
          entry.reasonCode == 'dependency_conflict') {
        continue;
      }
      if (entry.write.dependencies.any((id) {
        final parent = entries[id];
        return parent != null &&
            (parent.state != WriteState.confirmed ||
                parent.reasonCode == 'dependency_conflict');
      })) {
        continue;
      }
      if (earliest == null || at.isBefore(earliest)) earliest = at;
    }
    return earliest;
  }

  bool _hasDependencyCycle(String start, Map<String, QueueEntry> entries) {
    final visiting = <String>{};
    final visited = <String>{};
    final stack = <(String, bool)>[(start, false)];
    while (stack.isNotEmpty) {
      final (id, exiting) = stack.removeLast();
      if (exiting) {
        visiting.remove(id);
        visited.add(id);
        continue;
      }
      if (visiting.contains(id)) return true;
      if (visited.contains(id) || entries[id] == null) continue;
      visiting.add(id);
      stack.add((id, true));
      for (final dependency in entries[id]!.write.dependencies) {
        stack.add((dependency, false));
      }
    }
    return false;
  }

  Future<void> _checkBacklog() async {
    final owner = _session.current?.user.id;
    final epoch = _session.identityEpoch;
    if (owner == null || !_sameAccount(owner, epoch)) return;
    final entries = (await _queue.entries(ownerId: owner))
        .where(
          (entry) =>
              entry.needsSync &&
              entry.state != WriteState.failed &&
              entry.write.writeType == 'experience.event',
        )
        .toList();
    if (!_sameAccount(owner, epoch) || entries.isEmpty) return;
    final oldest = entries
        .map((e) => e.write.deviceTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final age = DateTime.now().toUtc().difference(oldest);
    if (entries.length > backlogCountThreshold || age > backlogAgeThreshold) {
      reportEventBacklogAlert(_ref, count: entries.length, oldestAge: age);
    }
  }

  DateTime _retryAt(int attempts) {
    final multiplier = math.pow(2, math.min(attempts - 1, 20)).toInt();
    final milliseconds = math.min(
      initialBackoff.inMilliseconds * multiplier,
      maxBackoff.inMilliseconds,
    );
    return DateTime.now().toUtc().add(Duration(milliseconds: milliseconds));
  }

  Future<DateTime?> _retainForRetry(
    QueueEntry entry,
    String reason,
    Future<void> Function(QueueEntry) save,
  ) async {
    final failed = entry.attempts >= maxAttempts;
    final next = failed ? null : _retryAt(entry.attempts);
    await save(
      entry.change(
        state: failed ? WriteState.failed : WriteState.pending,
        reasonCode: failed ? 'retry_limit_exceeded:$reason' : reason,
        nextAttemptAt: next,
      ),
    );
    return next;
  }

  void _scheduleRetry(
    DateTime? at, {
    required String owner,
    required int epoch,
    bool attemptedOnly = false,
  }) {
    if (at == null || !_sameAccount(owner, epoch)) return;
    _retryTimer?.cancel();
    final wait = at.difference(DateTime.now().toUtc());
    _retryTimer = Timer(wait.isNegative ? Duration.zero : wait, () {
      if (_sameAccount(owner, epoch)) {
        unawaited(_triggerUpload(attemptedOnly: attemptedOnly));
      }
    });
  }

  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
  }
}
