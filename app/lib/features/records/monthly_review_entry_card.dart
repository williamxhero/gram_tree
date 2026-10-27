import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../auth/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import 'monthly_review.dart';

/// Compact first-of-month entry point; the full review remains below history.
final monthlyReviewClockProvider = Provider<DateTime>((ref) => DateTime.now());

bool isAccountLocalMonthStart(DateTime now, String timezone) {
  try {
    tzdata.initializeTimeZones();
    return tz.TZDateTime.from(now, tz.getLocation(timezone)).day == 1;
  } catch (_) {
    return now.toUtc().day == 1;
  }
}

class MonthlyReviewEntryCard extends ConsumerWidget {
  const MonthlyReviewEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timezone = ref.watch(authProvider).value?.timezone ?? 'UTC';
    if (!isAccountLocalMonthStart(
      ref.watch(monthlyReviewClockProvider),
      timezone,
    )) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        key: const ValueKey('monthly-review-entry-card'),
        leading: const Icon(Icons.calendar_month_outlined),
        title: Text(l10n.monthlyReviewTitle),
        subtitle: const Text('上个月的做菜回顾已准备好'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: const MonthlyReviewSection(),
            ),
          ),
        ),
      ),
    );
  }
}
