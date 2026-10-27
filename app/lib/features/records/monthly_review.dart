import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../auth/session.dart';
import '../../events/event_recorder.dart';
import '../../l10n/app_localizations.dart';
import '../../storage/secure_store.dart';
import '../../ui_protocol/intent_dispatcher.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';

DateTime _accountLocalPreviousMonth(String? timezone) {
  try {
    tzdata.initializeTimeZones();
    final location = tz.getLocation(timezone ?? 'UTC');
    final now = tz.TZDateTime.now(location);
    return DateTime(now.year, now.month - 1);
  } catch (_) {
    final now = DateTime.now().toUtc();
    return DateTime(now.year, now.month - 1);
  }
}

class MonthlyReviewSnapshot {
  const MonthlyReviewSnapshot({
    required this.month,
    required this.current,
    required this.previous,
    required this.changes,
    required this.cachedAt,
    required this.fromCache,
  });

  final DateTime month;
  final DietaryStatisticsOut current;
  final DietaryStatisticsOut previous;
  final List<TasteProfileChangeOut> changes;
  final DateTime cachedAt;
  final bool fromCache;
}

class MonthlyReviewRepository {
  MonthlyReviewRepository(this._ref, this._ownerId, this._session);

  final Ref _ref;
  final String _ownerId;
  final SessionStore _session;
  static final _cipher = AesGcm.with256bits().toSync();

  static String _monthKey(DateTime month) =>
      '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';

  Future<MonthlyReviewSnapshot> load({DateTime? anchor}) async {
    final identity = _session.identity;
    if (identity == null || identity.ownerId != _ownerId) {
      throw StateError('account_unavailable');
    }
    try {
      final api = _ref.read(apiClientProvider);
      final month =
          anchor ?? _accountLocalPreviousMonth(_session.current!.user.timezone);
      final requestedMonth = DateTime.utc(month.year, month.month, 15);
      final currentResponse = await api
          .getDietaryHistoryApi()
          .getDietaryStatistics(
            period: 'month',
            anchor: requestedMonth,
            extra: _authExtra(identity),
          );
      if (!_session.matches(identity) || currentResponse.data == null) {
        throw StateError('stale_monthly_review_response');
      }
      final current = currentResponse.data!;
      final previousMonth = DateTime.utc(
        current.localStart.year,
        current.localStart.month - 1,
        15,
      );
      final previousResponse = await api
          .getDietaryHistoryApi()
          .getDietaryStatistics(
            period: 'month',
            anchor: previousMonth,
            extra: _authExtra(identity),
          );
      if (!_session.matches(identity) || previousResponse.data == null) {
        throw StateError('stale_monthly_review_response');
      }
      final changes = <TasteProfileChangeOut>[];
      final start = DateTime.parse(current.startAt).toUtc();
      final end = DateTime.parse(current.endAt).toUtc();
      String? cursor;
      var hasMore = true;
      while (hasMore) {
        final response = await api.getTasteProfileApi().listTasteProfileChanges(
          cursor: cursor,
          limit: 100,
          extra: _authExtra(identity),
        );
        if (!_session.matches(identity) || response.data == null) {
          throw StateError('stale_monthly_review_response');
        }
        final items = response.data!.items;
        for (final change in items) {
          final created = DateTime.tryParse(change.createdAt)?.toUtc();
          if (created != null &&
              !created.isBefore(start) &&
              created.isBefore(end)) {
            changes.add(change);
          }
        }
        final oldest = items.isEmpty
            ? null
            : DateTime.tryParse(items.last.createdAt)?.toUtc();
        cursor = response.data!.nextCursor;
        hasMore = cursor != null && (oldest == null || !oldest.isBefore(start));
      }
      final snapshot = MonthlyReviewSnapshot(
        month: DateTime(current.localStart.year, current.localStart.month),
        current: current,
        previous: previousResponse.data!,
        changes: changes,
        cachedAt: DateTime.now().toUtc(),
        fromCache: false,
      );
      await _write(identity, snapshot, anchor: anchor);
      return snapshot;
    } catch (error) {
      if (!isNetworkFailure(error) || !_session.matches(identity)) rethrow;
      final raw = await _ref
          .read(secureStoreProvider)
          .read(_cacheKey(_ownerId, anchor));
      if (!_session.matches(identity) || raw == null) rethrow;
      try {
        final box = SecretBox.fromConcatenation(
          base64Url.decode(raw),
          nonceLength: _cipher.nonceLength,
          macLength: _cipher.macAlgorithm.macLength,
        );
        final clear = await _cipher.decrypt(
          box,
          secretKey: await _cacheSecret(create: false, anchor: anchor),
          aad: utf8.encode(_cacheKey(_ownerId, anchor)),
        );
        final json = jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
        if (!_session.matches(identity)) {
          throw StateError('account_changed');
        }
        return _decode(json);
      } catch (_) {
        if (_session.matches(identity)) {
          final secure = _ref.read(secureStoreProvider);
          await secure.delete(_cacheKey(_ownerId, anchor));
          await secure.delete('${_cacheKey(_ownerId, anchor)}:key');
        }
        rethrow;
      }
    }
  }

  Future<void> _write(
    SessionIdentity identity,
    MonthlyReviewSnapshot snapshot, {
    DateTime? anchor,
  }) async {
    if (!_session.matches(identity)) return;
    final clear = utf8.encode(jsonEncode(_encode(snapshot)));
    final cacheKey = _cacheKey(_ownerId, anchor);
    final key = await _cacheSecret(anchor: anchor);
    if (!_session.matches(identity)) {
      return;
    }
    final box = await _cipher.encrypt(
      clear,
      secretKey: key,
      aad: utf8.encode(cacheKey),
    );
    if (!_session.matches(identity)) return;
    await _ref
        .read(secureStoreProvider)
        .write(cacheKey, base64UrlEncode(box.concatenation()));
  }

  Future<SecretKey> _cacheSecret({bool create = true, DateTime? anchor}) async {
    final secure = _ref.read(secureStoreProvider);
    final keyName = '${_cacheKey(_ownerId, anchor)}:key';
    final existing = await secure.read(keyName);
    if (existing != null) {
      return SecretKey(base64Url.decode(existing));
    }
    if (!create) {
      throw const FormatException('missing monthly review cache key');
    }
    final key = await _cipher.newSecretKey();
    await secure.write(keyName, base64UrlEncode(await key.extractBytes()));
    return key;
  }

  static Map<String, dynamic> _authExtra(SessionIdentity identity) => {
    'auth_owner_id': identity.ownerId,
    'auth_identity_epoch': identity.epoch,
  };

  static String _cacheKey(String ownerId, DateTime? month) =>
      'monthly_review_v2:$ownerId:${month == null ? 'latest' : _monthKey(month)}';

  static Map<String, dynamic> _encode(MonthlyReviewSnapshot value) => {
    'month': value.month.toIso8601String(),
    'current': value.current.toJson(),
    'previous': value.previous.toJson(),
    'changes': value.changes.map((item) => item.toJson()).toList(),
    'cached_at': value.cachedAt.toIso8601String(),
  };

  static MonthlyReviewSnapshot _decode(Map<String, dynamic> json) =>
      MonthlyReviewSnapshot(
        month: DateTime.parse(json['month'] as String),
        current: DietaryStatisticsOut.fromJson(
          Map<String, dynamic>.from(json['current'] as Map),
        ),
        previous: DietaryStatisticsOut.fromJson(
          Map<String, dynamic>.from(json['previous'] as Map),
        ),
        changes: (json['changes'] as List)
            .map(
              (item) => TasteProfileChangeOut.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(growable: false),
        cachedAt: DateTime.parse(json['cached_at'] as String).toUtc(),
        fromCache: true,
      );
}

final monthlyReviewProvider = FutureProvider.autoDispose
    .family<MonthlyReviewSnapshot, DateTime>((ref, month) {
      final ownerId = ref.watch(authProvider).value?.id;
      if (ownerId == null) throw StateError('每月回顾需要登录');
      return MonthlyReviewRepository(
        ref,
        ownerId,
        ref.watch(sessionStoreProvider),
      ).load(anchor: month);
    });

class MonthlyReviewSection extends ConsumerWidget {
  const MonthlyReviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _MonthlyReviewContent();
  }
}

class _MonthlyReviewContent extends ConsumerStatefulWidget {
  const _MonthlyReviewContent();

  @override
  ConsumerState<_MonthlyReviewContent> createState() =>
      _MonthlyReviewContentState();
}

class _MonthlyReviewContentState extends ConsumerState<_MonthlyReviewContent> {
  DateTime? _month;

  @override
  void initState() {
    super.initState();
    _month = _latestReviewMonth;
  }

  DateTime get _latestReviewMonth =>
      _accountLocalPreviousMonth(ref.read(authProvider).value?.timezone);

  @override
  Widget build(BuildContext context) {
    final month = _month!;
    final value = ref.watch(monthlyReviewProvider(month));
    return value.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).monthlyReviewTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(AppLocalizations.of(context).monthlyReviewUnavailable),
          TextButton(
            onPressed: () => ref.invalidate(monthlyReviewProvider(month)),
            child: Text(AppLocalizations.of(context).monthlyReviewRetry),
          ),
        ],
      ),
      data: (snapshot) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: AppLocalizations.of(context)
                    .monthlyReviewPreviousMonth,
                onPressed: () => setState(
                  () => _month = DateTime(month.year, month.month - 1),
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${snapshot.month.year} 年 ${snapshot.month.month} 月',
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context).monthlyReviewNextMonth,
                onPressed:
                    month.year == _latestReviewMonth.year &&
                        month.month == _latestReviewMonth.month
                    ? null
                    : () => setState(
                        () => _month = DateTime(month.year, month.month + 1),
                      ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          _ReviewBody(
            key: ValueKey('${snapshot.month.year}-${snapshot.month.month}'),
            snapshot: snapshot,
          ),
        ],
      ),
    );
  }
}

class _ReviewBody extends ConsumerStatefulWidget {
  const _ReviewBody({super.key, required this.snapshot});
  final MonthlyReviewSnapshot snapshot;

  @override
  ConsumerState<_ReviewBody> createState() => _ReviewBodyState();
}

class _ReviewBodyState extends ConsumerState<_ReviewBody> {
  AppLocalizations get _l10n => AppLocalizations.of(context);
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(eventRecorderProvider)
          .record(
            eventType: 'records.monthly_review_opened',
            typeVersion: 1,
            content: {
              'month':
                  '${widget.snapshot.month.year.toString().padLeft(4, '0')}-${widget.snapshot.month.month.toString().padLeft(2, '0')}',
            },
          );
    });
  }

  Future<void> _change(TasteProfileChangeOut change, bool confirm) async {
    if (widget.snapshot.fromCache || _busy.contains(change.id)) return;
    final session = ref.read(sessionStoreProvider);
    final identity = session.identity;
    if (identity == null) return;
    setState(() => _busy.add(change.id));
    try {
      final changed = await ref
          .read(intentDispatcherProvider)
          .dispatch(
            context,
            componentId: 'monthly-review-${change.id}',
            action: ActionDescriptor(
              intent: 'monthly_review_change',
              params: {
                'change_id': change.id,
                'decision': confirm ? 'confirm' : 'revert',
                'year': widget.snapshot.month.year,
                'month': widget.snapshot.month.month,
              },
            ),
          );
      if (changed != true || !mounted || !session.matches(identity)) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            confirm
                ? _l10n.monthlyReviewConfirmed
                : _l10n.monthlyReviewReverted,
          ),
        ),
      );
    } catch (error) {
      if (mounted && session.matches(identity)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiFailure.from(error).message)));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(change.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.snapshot.current;
    final previous = widget.snapshot.previous;
    final automatic = widget.snapshot.changes
        .where(
          (change) => change.origin == TasteProfileChangeOutOriginEnum.auto,
        )
        .toList();
    final manual = widget.snapshot.changes
        .where(
          (change) => change.origin != TasteProfileChangeOutOriginEnum.auto,
        )
        .toList();
    final monthLabel =
        '${widget.snapshot.month.year} 年 ${widget.snapshot.month.month} 月';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _l10n.monthlyReviewTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(monthLabel, style: Theme.of(context).textTheme.titleMedium),
        if (widget.snapshot.fromCache)
          Text(
            _l10n.monthlyReviewOffline(
              widget.snapshot.cachedAt.toLocal().toString(),
            ),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_l10n.monthlyReviewCount),
          subtitle: Text(
            _l10n.monthlyReviewCompared(
              _difference(stats.cookingCount - previous.cookingCount),
            ),
          ),
          trailing: Text('${stats.cookingCount}'),
        ),
        if (stats.frequentDishes.isNotEmpty)
          _ReviewList(
            title: _l10n.monthlyReviewFrequent,
            names: stats.frequentDishes
                .map((item) => '${item.name} · ${item.count} 次')
                .toList(),
          ),
        if (stats.newDishes.isNotEmpty)
          _ReviewList(
            title: _l10n.monthlyReviewNewDishes,
            names: stats.newDishes
                .map((item) => '${item.name} · ${item.count} 次')
                .toList(),
          ),
        if (stats.ingredientDistribution.isNotEmpty)
          _ReviewList(
            title: _l10n.monthlyReviewMainIngredients,
            names: stats.ingredientDistribution
                .map((item) => '${item.key} · ${item.count} 次')
                .toList(),
          ),
        if (stats.cookingCount == 0 && widget.snapshot.changes.isEmpty)
          Text(_l10n.monthlyReviewEmpty),
        if (automatic.isNotEmpty) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_l10n.monthlyReviewAutomaticChanges),
          ),
          if (widget.snapshot.fromCache)
            Text(_l10n.monthlyReviewOfflineActions),
          for (final change in automatic)
            _TasteChangeTile(
              change: change,
              offline: widget.snapshot.fromCache,
              busy: _busy.contains(change.id),
              onConfirm: () => _change(change, true),
              onRevert: () => _change(change, false),
            ),
        ],
        if (manual.isNotEmpty)
          _ReviewList(
            title: _l10n.monthlyReviewManualChanges,
            names: manual
                .map((change) => '${change.field} · ${change.reason}')
                .toList(),
          ),
      ],
    );
  }

  String _difference(int value) => value == 0
      ? _l10n.monthlyReviewNoChange
      : value > 0
      ? _l10n.monthlyReviewIncrease(value)
      : _l10n.monthlyReviewDecrease(-value);
}

class _ReviewList extends StatelessWidget {
  const _ReviewList({required this.title, required this.names});
  final String title;
  final List<String> names;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: Text(title),
    children: [
      for (final name in names) ListTile(dense: true, title: Text(name)),
    ],
  );
}

class _TasteChangeTile extends StatelessWidget {
  const _TasteChangeTile({
    required this.change,
    required this.offline,
    required this.busy,
    required this.onConfirm,
    required this.onRevert,
  });
  final TasteProfileChangeOut change;
  final bool offline;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onRevert;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Text(change.field),
          SourceMark(
            sourceType: change.origin == TasteProfileChangeOutOriginEnum.auto
                ? sourceTypeTasteAdjusted
                : sourceTypeAuthorFilled,
            componentId: 'monthly-review-${change.id}',
            value: change.newValue.toString(),
            originalValue: change.oldValue.toString(),
            basisText: change.reason,
            required: false,
            showWhenAuthorFilled: true,
            labelOverride: change.origin == TasteProfileChangeOutOriginEnum.auto
                ? null
                : l10n.monthlyReviewManualSource,
            onAction: null,
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(change.reason),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(l10n.monthlyReviewChangeDetails),
            children: [
              ListTile(
                dense: true,
                title: Text(
                  l10n.monthlyReviewBefore(change.oldValue.toString()),
                ),
              ),
              ListTile(
                dense: true,
                title: Text(
                  l10n.monthlyReviewAfter(change.newValue.toString()),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Wrap(
        spacing: 4,
        children: [
          if (change.status == TasteProfileChangeOutStatusEnum.pending ||
              change.status == TasteProfileChangeOutStatusEnum.active)
            IconButton(
              tooltip: l10n.monthlyReviewConfirm,
              onPressed: offline || busy ? null : onConfirm,
              icon: const Icon(Icons.check),
            ),
          if (change.status == TasteProfileChangeOutStatusEnum.active ||
              change.status == TasteProfileChangeOutStatusEnum.confirmed)
            IconButton(
              tooltip: l10n.monthlyReviewRevert,
              onPressed: offline || busy ? null : onRevert,
              icon: const Icon(Icons.undo),
            ),
        ],
      ),
    );
  }
}
