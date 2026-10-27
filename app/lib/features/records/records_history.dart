import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../api/api_client.dart';
import '../../auth/session.dart';
import '../../events/event_queue.dart';
import '../../storage/local_store.dart';

class RecordCalendarDay {
  const RecordCalendarDay({
    required this.date,
    required this.start,
    required this.end,
  });
  final String date;
  final DateTime start;
  final DateTime end;

  factory RecordCalendarDay.fromJson(Map<String, dynamic> json) =>
      RecordCalendarDay(
        date: json['date'] as String,
        start: DateTime.parse(json['start'] as String).toUtc(),
        end: DateTime.parse(json['end'] as String).toUtc(),
      );

  Map<String, dynamic> toJson() => {
    'date': date,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
  };
}

class RecordCalendarContext {
  const RecordCalendarContext({
    required this.timezone,
    required this.year,
    required this.month,
    required this.days,
  });
  final String timezone;
  final int year;
  final int month;
  final List<RecordCalendarDay> days;

  factory RecordCalendarContext.fromJson(Map<String, dynamic> json) =>
      RecordCalendarContext(
        timezone: json['timezone'] as String,
        year: json['year'] as int,
        month: json['month'] as int,
        days: [
          for (final day in (json['days'] as List? ?? const []))
            RecordCalendarDay.fromJson(Map<String, dynamic>.from(day as Map)),
        ],
      );

  Map<String, dynamic> toJson() => {
    'timezone': timezone,
    'year': year,
    'month': month,
    'days': [for (final day in days) day.toJson()],
  };

  RecordCalendarDay? dayFor(DateTime occurredAt) {
    final at = occurredAt.toUtc();
    for (final day in days) {
      if (!at.isBefore(day.start) && at.isBefore(day.end)) return day;
    }
    return null;
  }
}

class RecordHistorySnapshot {
  const RecordHistorySnapshot({
    required this.accountId,
    required this.timezone,
    required this.cachedAt,
    required this.items,
    required this.contexts,
  });
  final String accountId;
  final String timezone;
  final DateTime cachedAt;
  final List<Map<String, dynamic>> items;
  final Map<String, RecordCalendarContext> contexts;

  factory RecordHistorySnapshot.fromJson(Map<String, dynamic> json) =>
      RecordHistorySnapshot(
        accountId: json['account_id'] as String,
        timezone: json['timezone'] as String,
        cachedAt: DateTime.parse(json['cached_at'] as String).toUtc(),
        items: [
          for (final item in (json['items'] as List? ?? const []))
            Map<String, dynamic>.from(item as Map),
        ],
        contexts: {
          for (final raw in (json['contexts'] as Map? ?? const {}).entries)
            raw.key as String: RecordCalendarContext.fromJson(
              Map<String, dynamic>.from(raw.value as Map),
            ),
        },
      );

  Map<String, dynamic> toJson() => {
    'account_id': accountId,
    'timezone': timezone,
    'cached_at': cachedAt.toIso8601String(),
    'items': items,
    'contexts': {
      for (final entry in contexts.entries) entry.key: entry.value.toJson(),
    },
  };
}

class RecordsHistory {
  RecordsHistory(this._ref);
  final Ref _ref;
  static bool _timeZonesInitialized = false;
  static String keyFor(String accountId) => 'records_history:v1:$accountId';

  RecordCalendarContext localContext(String timezone, int year, int month) {
    if (!_timeZonesInitialized) {
      tzdata.initializeTimeZones();
      _timeZonesInitialized = true;
    }
    final location = tz.getLocation(timezone);
    final days = <RecordCalendarDay>[];
    var day = 1;
    while (true) {
      final start = tz.TZDateTime(location, year, month, day);
      if (start.month != month) break;
      final end = tz.TZDateTime(location, year, month, day + 1);
      days.add(
        RecordCalendarDay(
          date:
              '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
          start: start.toUtc(),
          end: end.toUtc(),
        ),
      );
      day++;
    }
    return RecordCalendarContext(
      timezone: timezone,
      year: year,
      month: month,
      days: days,
    );
  }

  Future<RecordHistorySnapshot?> read(String accountId) async {
    try {
      final raw = _ref.read(localStoreProvider).getString(keyFor(accountId));
      if (raw == null) return null;
      final value = RecordHistorySnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return value.accountId == accountId ? value : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    RecordHistorySnapshot value, {
    required SessionIdentity identity,
  }) async {
    final session = _ref.read(sessionStoreProvider);
    if (!session.matches(identity)) return;
    await _ref
        .read(localStoreProvider)
        .setString(keyFor(value.accountId), jsonEncode(value.toJson()));
  }

  Future<RecordCalendarContext> fetchContext(
    SessionIdentity identity,
    int year,
    int month,
  ) async {
    final api = _ref.read(apiClientProvider);
    final response = await api.dio.get<Map<String, dynamic>>(
      '/v1/records/calendar-context',
      queryParameters: {'year': year, 'month': month},
      options: Options(
        extra: {
          'auth_owner_id': identity.ownerId,
          'auth_identity_epoch': identity.epoch,
        },
      ),
    );
    if (!_ref.read(sessionStoreProvider).matches(identity)) {
      throw StateError('account_changed');
    }
    return RecordCalendarContext.fromJson(response.data!);
  }

  Future<List<Map<String, dynamic>>> fetchAll(SessionIdentity identity) async {
    final result = <Map<String, dynamic>>[];
    String? cursor;
    do {
      final response = await _ref
          .read(apiClientProvider)
          .getRecordsApi()
          .listRecords(
            cursor: cursor,
            limit: 100,
            extra: {
              'auth_owner_id': identity.ownerId,
              'auth_identity_epoch': identity.epoch,
            },
          );
      if (!_ref.read(sessionStoreProvider).matches(identity)) {
        throw StateError('account_changed');
      }
      final page = response.data;
      if (page == null) break;
      result.addAll([for (final item in page.items) item.toJson()]);
      cursor = page.nextCursor;
    } while (cursor != null);
    return result;
  }

  Future<RecordHistorySnapshot> loadCurrent(SessionIdentity identity) async {
    final now = DateTime.now().toUtc();
    final old = await read(identity.ownerId);
    var fetched = const <Map<String, dynamic>>[];
    try {
      final items = await fetchAll(identity);
      fetched = items;
      final contexts = <String, RecordCalendarContext>{...?(old?.contexts)};
      for (var delta = -1; delta <= 1; delta++) {
        final monthDate = DateTime.utc(now.year, now.month + delta, 1);
        try {
          final context = await fetchContext(
            identity,
            monthDate.year,
            monthDate.month,
          );
          contexts['${context.year}-${context.month}'] = context;
        } catch (_) {
          contexts['${monthDate.year}-${monthDate.month}'] = localContext(
            identityTimezone(identity),
            monthDate.year,
            monthDate.month,
          );
        }
      }
      final value = RecordHistorySnapshot(
        accountId: identity.ownerId,
        timezone: identityTimezone(identity),
        cachedAt: DateTime.now().toUtc(),
        items: fetched,
        contexts: contexts,
      );
      await write(value, identity: identity);
      return value;
    } catch (_) {
      if (old != null && old.timezone == identityTimezone(identity)) return old;
      final queued = withPending(
        RecordHistorySnapshot(
          accountId: identity.ownerId,
          timezone: identityTimezone(identity),
          cachedAt: DateTime.now().toUtc(),
          items: fetched,
          contexts: const {},
        ),
        await _ref.read(eventQueueProvider).entries(ownerId: identity.ownerId),
      );
      if (queued.isNotEmpty) {
        final month = DateTime.now().toUtc();
        return RecordHistorySnapshot(
          accountId: identity.ownerId,
          timezone: identityTimezone(identity),
          cachedAt: DateTime.now().toUtc(),
          items: queued,
          contexts: {
            '${month.year}-${month.month}': localContext(
              identityTimezone(identity),
              month.year,
              month.month,
            ),
          },
        );
      }
      if (fetched.isNotEmpty) {
        final occurrence =
            DateTime.tryParse(fetched.first['occurred_at'] as String? ?? '') ??
            DateTime.now().toUtc();
        final month = occurrence.toUtc();
        return RecordHistorySnapshot(
          accountId: identity.ownerId,
          timezone: identityTimezone(identity),
          cachedAt: DateTime.now().toUtc(),
          items: fetched,
          contexts: {
            '${month.year}-${month.month}': localContext(
              identityTimezone(identity),
              month.year,
              month.month,
            ),
          },
        );
      }
      rethrow;
    }
  }

  String identityTimezone(SessionIdentity identity) =>
      _ref.read(sessionStoreProvider).current!.user.timezone;

  Future<RecordHistorySnapshot> load(
    SessionIdentity identity, {
    required int year,
    required int month,
  }) async {
    final old = await read(identity.ownerId);
    final contextKey = '$year-$month';
    try {
      final items = await fetchAll(identity);
      final context = await fetchContext(identity, year, month);
      final contexts = {...?old?.contexts, contextKey: context};
      final value = RecordHistorySnapshot(
        accountId: identity.ownerId,
        timezone: context.timezone,
        cachedAt: DateTime.now().toUtc(),
        items: items,
        contexts: contexts,
      );
      await write(value, identity: identity);
      return value;
    } catch (_) {
      if (old != null &&
          old.timezone ==
              _ref.read(sessionStoreProvider).current?.user.timezone) {
        return old;
      }
      rethrow;
    }
  }

  List<Map<String, dynamic>> withPending(
    RecordHistorySnapshot snapshot,
    List<QueueEntry> entries,
  ) {
    final byClient = <String, Map<String, dynamic>>{
      for (final item in snapshot.items)
        if (item['client_id'] is String)
          (item['id'] as String? ?? item['client_id'] as String): item,
    };
    for (final entry in entries.where(
      (entry) => entry.write.writeType == 'cooking_record.create',
    )) {
      final raw = entry.write.payload['record'];
      if (raw is! Map || raw['client_id'] is! String) continue;
      if (entry.state == WriteState.confirmed) continue;
      byClient[raw['client_id'] as String] = {
        ...Map<String, dynamic>.from(raw),
        'id': raw['client_id'],
        'created_at': entry.write.deviceTime.toIso8601String(),
        'occurred_at':
            raw['occurred_at'] ?? entry.write.deviceTime.toIso8601String(),
        'verification': raw['verification'] ?? 'unverified',
        'counts_as_cooked': raw['source'] != 'dining',
        'meal': raw['meal'],
        'taste_summary': <String, dynamic>{},
      };
    }
    return byClient.values.toList();
  }
}

final recordsHistoryProvider = Provider<RecordsHistory>(RecordsHistory.new);
