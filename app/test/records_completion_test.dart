import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/features/recipes/cooking_session.dart';
import 'package:gram_tree/features/records/records_repository.dart';
import 'package:gram_tree/recipes/recipe_snapshot.dart';

import 'helpers.dart';
import 'recipe_snapshot_test.dart' show recipeSnapshotFixture;

const completionId = '11111111-1111-4111-8111-111111111111';

CookingSession completedSession({String? ownerId, bool receipt = true}) {
  final detail = recipeSnapshotFixture(
    '22222222-2222-4222-8222-222222222222',
    recipe: '33333333-3333-4333-8333-333333333333',
  );
  return CookingSession(
    id: completionId,
    ownerId: ownerId,
    snapshot: FrozenRecipeSnapshot(
      detail: detail,
      capturedAt: DateTime.utc(2026, 10, 15),
      inputs: {if (receipt) 'execution_token': 'a' * 64},
      render: null,
      dependencies: const {},
    ),
    startedAt: DateTime.utc(2026, 10, 15),
    finishedAt: DateTime.utc(2026, 10, 15, 0, 10),
    status: 'completed',
    reached: const ['boil'],
    completed: const ['boil'],
  );
}

Future<ProviderContainer> setup(TestEnv env) async {
  final container = ProviderContainer(overrides: env.overrides);
  addTearDown(container.dispose);
  await container.read(sessionStoreProvider).load();
  return container;
}

void main() {
  test(
    'completed offline session retains signed evidence and stable delivery ID',
    () async {
      final env = TestEnv.signedIn(offline: true);
      final container = await setup(env);
      final session = completedSession(ownerId: env.server.user.id);
      await container
          .read(recordsRepositoryProvider)
          .saveCompletedSession(session);
      await container
          .read(recordsRepositoryProvider)
          .saveCompletedSession(session);
      final entries = await env.eventQueue.entries(ownerId: env.server.user.id);
      expect(entries, hasLength(1));
      final event = entries.single.write;
      expect(event.id, completionId);
      expect(event.writeType, 'cooking_record.create');
      final record = event.payload['record'] as Map;
      expect(record['verification'], 'unverified');
      expect(record['occurred_at'], '2026-10-15T00:10:00.000Z');
      final completion = record['completion'] as Map;
      expect(completion['status'], 'completed');
      expect(completion['execution_token'], 'a' * 64);
      expect(completion['completed_steps'], ['boil']);
      expect(env.server.calls('POST', '/v1/sync/writes'), isEmpty);
    },
  );

  test(
    'legacy completed session is retained without claiming verification',
    () async {
      final env = TestEnv.signedIn(offline: true);
      final container = await setup(env);
      await container
          .read(recordsRepositoryProvider)
          .saveCompletedSession(completedSession(receipt: false));
      final entries = await env.eventQueue.entries(ownerId: env.server.user.id);
      final record = entries.single.write.payload['record'] as Map;
      expect(record.containsKey('completion'), isFalse);
      expect(record['verification'], 'unverified');
    },
  );

  test(
    'active, missing, duplicate and unknown steps never enter the queue',
    () async {
      final env = TestEnv.signedIn(offline: true);
      final container = await setup(env);
      final good = completedSession();
      for (final invalid in [
        good.copyWith(status: 'active'),
        good.copyWith(completed: const []),
        good.copyWith(completed: const ['boil', 'boil']),
        good.copyWith(completed: const ['boil', 'foreign']),
        good.copyWith(skipped: const ['boil']),
        good.copyWith(reached: const []),
        good.copyWith(finishedAt: DateTime.utc(2026, 10, 14)),
      ]) {
        await expectLater(
          container
              .read(recordsRepositoryProvider)
              .saveCompletedSession(invalid),
          throwsStateError,
        );
      }
      expect(await env.eventQueue.entries(), isEmpty);
      expect(env.server.calls('POST', '/v1/sync/writes'), isEmpty);
    },
  );

  test('another account cannot adopt a completed execution', () async {
    final env = TestEnv.signedIn(offline: true);
    final container = await setup(env);
    await expectLater(
      container
          .read(recordsRepositoryProvider)
          .saveCompletedSession(
            completedSession(ownerId: '44444444-4444-4444-8444-444444444444'),
          ),
      throwsStateError,
    );
    expect(await env.eventQueue.entries(), isEmpty);
  });
}
