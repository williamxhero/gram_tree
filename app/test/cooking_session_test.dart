import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/features/recipes/cooking_session.dart';

void main() {
  final started = DateTime.utc(2026, 10, 12, 1, 0, 0);

  group('CookingTimerState', () {
    test('counts elapsed time and clamps at zero', () {
      final timer = CookingTimerState(
        id: 'timer',
        stepId: 'step',
        startedAt: started,
        durationSeconds: 60,
      );

      expect(timer.remainingAt(started), 60);
      expect(timer.remainingAt(started.add(const Duration(seconds: 20))), 40);
      expect(timer.remainingAt(started.add(const Duration(seconds: 90))), 0);
      expect(timer.isDueAt(started.add(const Duration(seconds: 60))), isTrue);
    });

    test('paused time is excluded from elapsed time', () {
      final timer = CookingTimerState(
        id: 'timer',
        stepId: 'step',
        startedAt: started,
        durationSeconds: 60,
        pausedSeconds: 10,
        pausedAt: started.add(const Duration(seconds: 30)),
        status: 'paused',
      );

      expect(timer.remainingAt(started.add(const Duration(seconds: 40))), 40);
      expect(timer.isDueAt(started.add(const Duration(seconds: 100))), isFalse);
    });

    test('round trips persisted state and rejects malformed state', () {
      final timer = CookingTimerState(
        id: 'timer',
        stepId: 'step',
        startedAt: started,
        durationSeconds: 60,
        pausedSeconds: 3,
        status: 'paused',
      );

      final decoded = CookingTimerState.fromJson(timer.toJson());
      expect(decoded?.id, 'timer');
      expect(decoded?.stepId, 'step');
      expect(decoded?.durationSeconds, 60);
      expect(decoded?.pausedSeconds, 3);
      expect(CookingTimerState.fromJson(null), isNull);
      expect(CookingTimerState.fromJson({'id': 'missing'}), isNull);
    });

    test('persists the due-event idempotency marker', () {
      final reportedAt = started.add(const Duration(seconds: 60));
      final timer = CookingTimerState(
        id: 'timer',
        stepId: 'step',
        startedAt: started,
        durationSeconds: 60,
        dueReportedAt: reportedAt,
      );

      final decoded = CookingTimerState.fromJson(timer.toJson());
      expect(decoded?.hasReportedDue, isTrue);
      expect(decoded?.dueReportedAt, reportedAt);
      expect(
        decoded?.isDueAt(started.add(const Duration(seconds: 120))),
        isTrue,
      );
    });
  });
}
