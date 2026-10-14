import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/session.dart';
import '../../events/event_queue.dart';
import '../../events/event_uploader.dart';
import '../recipes/cooking_session.dart';

/// Persists a completed cooking session in the existing account-scoped offline
/// write queue. No completion is lost when the device is offline.
class RecordsRepository {
  RecordsRepository(this._ref);
  final Ref _ref;

  Future<void> saveCompletedSession(
    CookingSession session, {
    List<String> coDinerIds = const [],
  }) async {
    if (!session.isComplete ||
        session.finishedAt == null ||
        session.finishedAt!.isBefore(session.startedAt) ||
        session.steps.isEmpty ||
        session.completed.isEmpty ||
        session.completed.toSet().length != session.completed.length ||
        session.skipped.toSet().length != session.skipped.length ||
        session.completed.any(session.skipped.contains) ||
        !session.steps.every(
          (step) =>
              session.completed.contains(step.id) ||
              session.skipped.contains(step.id),
        ) ||
        session.completed.any((id) => !session.reached.contains(id)) ||
        [
          ...session.reached,
          ...session.completed,
          ...session.skipped,
        ].any((id) => !session.steps.any((step) => step.id == id))) {
      throw StateError('只有完整走完做菜模式的会话才能保存完成记录');
    }
    final auth = _ref.read(sessionStoreProvider).current;
    if (auth == null) return;
    if (session.ownerId != null && session.ownerId != auth.user.id) {
      throw StateError('不能把另一账号的做菜会话保存到当前账号');
    }
    final snapshot = session.snapshot.toJson();
    final record = <String, dynamic>{
      'client_id': session.id,
      'recipe_id': session.snapshot.recipeId,
      'recipe_version_id': session.snapshot.versionId,
      'dish_name': session.snapshot.detail.dish.name,
      'source': 'cooking_session',
      'verification': 'unverified',
      'occurred_at': (session.finishedAt ?? DateTime.now().toUtc())
          .toUtc()
          .toIso8601String(),
      'snapshot': snapshot,
      'adjustments': session.adjustments,
      if (session.snapshot.inputs['execution_token'] case final String token)
        'completion': {
          'session_id': session.id,
          'execution_token': token,
          'status': session.status,
          'started_at': session.startedAt.toUtc().toIso8601String(),
          'finished_at': session.finishedAt!.toUtc().toIso8601String(),
          'reached_steps': session.reached,
          'completed_steps': session.completed,
          'skipped_steps': session.skipped,
        },
      'source_context': {
        'session_id': session.id,
        'completed_steps': session.completed,
        'skipped_steps': session.skipped,
        'questions': session.questions,
      },
      'co_diner_ids': coDinerIds,
    };
    await _ref
        .read(eventQueueProvider)
        .enqueue(
          QueuedEvent.write(
            // The cooking-session UUID is also the stable delivery UUID. If the
            // process dies after the session is marked complete but before the
            // queue write finishes, retrying cannot create a second record.
            id: session.id,
            ownerId: auth.user.id,
            deviceTime: session.finishedAt ?? DateTime.now().toUtc(),
            writeType: 'cooking_record.create',
            payload: {'record': record},
          ),
        );
    await _ref.read(eventUploaderProvider).triggerUpload();
  }
}

final recordsRepositoryProvider = Provider<RecordsRepository>(
  RecordsRepository.new,
);
