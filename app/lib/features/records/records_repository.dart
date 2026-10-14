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
    final auth = _ref.read(sessionStoreProvider).current;
    if (auth == null) return;
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
