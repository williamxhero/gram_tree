import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/features/records/monthly_review_notifications.dart';

void main() {
  group('monthly review reminder date', () {
    test('uses the account timezone month boundary', () {
      final dueAt = nextMonthlyReviewReminderAt(
        DateTime.utc(2026, 10, 15),
        'Asia/Shanghai',
      );

      expect(dueAt.toUtc(), DateTime.utc(2026, 11, 1, 1));
    });

    test('resolves the month start using daylight-saving rules', () {
      final dueAt = nextMonthlyReviewReminderAt(
        DateTime.utc(2026, 10, 15),
        'America/New_York',
      );

      expect(dueAt.toUtc(), DateTime.utc(2026, 11, 1, 14));
    });

    test('when local month start has passed, selects next month', () {
      final dueAt = nextMonthlyReviewReminderAt(
        DateTime.utc(2026, 10, 1, 1),
        'Asia/Shanghai',
      );

      expect(dueAt.toUtc(), DateTime.utc(2026, 11, 1, 1));
    });
  });
}
