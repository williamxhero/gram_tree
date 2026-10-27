import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/features/records/monthly_review_entry_card.dart';

void main() {
  test(
    'monthly entry begins on the account-local first day, including offset',
    () {
      expect(
        isAccountLocalMonthStart(
          DateTime.utc(2026, 10, 31, 16),
          'Asia/Shanghai',
        ),
        isTrue,
      );
      expect(
        isAccountLocalMonthStart(
          DateTime.utc(2026, 10, 31, 16),
          'America/New_York',
        ),
        isFalse,
      );
    },
  );
}
