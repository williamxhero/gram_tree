import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../auth/session.dart';
import '../../events/event_recorder.dart';
import '../../storage/secure_store.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';

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

  Future<MonthlyReviewSnapshot> load() async {
    final identity = _session.identity;
    if (identity == null || identity.ownerId != _ownerId) {
      throw StateError('account_unavailable');
    }
    try {
      final api = _ref.read(apiClientProvider);
      final currentResponse = await api
          .getDietaryHistoryApi()
          .getDietaryStatistics(period: 'month', extra: _authExtra(identity));
      if (!_session.matches(identity) || currentResponse.data == null) {
        throw StateError('stale_monthly_review_response');
      }
      final currentMonth = currentResponse.data!;
      final previousMonth = DateTime.utc(
        currentMonth.localStart.year,
        currentMonth.localStart.month - 1,
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
      final current = previousResponse.data!;
      final precedingMonth = DateTime.utc(
        current.localStart.year,
        current.localStart.month - 1,
        15,
      );
      final precedingResponse = await api
          .getDietaryHistoryApi()
          .getDietaryStatistics(
            period: 'month',
            anchor: precedingMonth,
            extra: _authExtra(identity),
          );
      if (!_session.matches(identity) || precedingResponse.data == null) {
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
        previous: precedingResponse.data!,
        changes: changes,
        cachedAt: DateTime.now().toUtc(),
        fromCache: false,
      );
      await _write(identity, snapshot);
      return snapshot;
    } catch (error) {
      if (!isNetworkFailure(error) || !_session.matches(identity)) rethrow;
      final raw = await _ref
          .read(secureStoreProvider)
          .read(_cacheKey(_ownerId));
      if (!_session.matches(identity) || raw == null) rethrow;
      try {
        final box = SecretBox.fromConcatenation(
          base64Url.decode(raw),
          nonceLength: _cipher.nonceLength,
          macLength: _cipher.macAlgorithm.macLength,
        );
        final clear = await _cipher.decrypt(
          box,
          secretKey: await _cacheSecret(create: false),
          aad: utf8.encode(_cacheKey(_ownerId)),
        );
        final json = jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
        return _decode(json);
      } catch (_) {
        final secure = _ref.read(secureStoreProvider);
        await secure.delete(_cacheKey(_ownerId));
        await secure.delete('${_cacheKey(_ownerId)}:key');
        rethrow;
      }
    }
  }

  Future<void> _write(
    SessionIdentity identity,
    MonthlyReviewSnapshot snapshot,
  ) async {
    if (!_session.matches(identity)) return;
    final clear = utf8.encode(jsonEncode(_encode(snapshot)));
    final key = await _cacheSecret();
    if (!_session.matches(identity)) {
      return;
    }
    final box = await _cipher.encrypt(
      clear,
      secretKey: key,
      aad: utf8.encode(_cacheKey(_ownerId)),
    );
    if (!_session.matches(identity)) return;
    await _ref
        .read(secureStoreProvider)
        .write(_cacheKey(_ownerId), base64UrlEncode(box.concatenation()));
  }

  Future<SecretKey> _cacheSecret({bool create = true}) async {
    final secure = _ref.read(secureStoreProvider);
    final keyName = '${_cacheKey(_ownerId)}:key';
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

  static String _cacheKey(String ownerId) => 'monthly_review_v1:$ownerId';

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

final monthlyReviewProvider = FutureProvider.autoDispose<MonthlyReviewSnapshot>(
  (ref) {
    final ownerId = ref.watch(authProvider).value?.id;
    if (ownerId == null) throw StateError('每月回顾需要登录');
    return MonthlyReviewRepository(
      ref,
      ownerId,
      ref.watch(sessionStoreProvider),
    ).load();
  },
);

class MonthlyReviewSection extends ConsumerWidget {
  const MonthlyReviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(monthlyReviewProvider);
    return value.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('上月回顾', style: Theme.of(context).textTheme.titleLarge),
          const Text('回顾暂时无法读取'),
          TextButton(
            onPressed: () => ref.invalidate(monthlyReviewProvider),
            child: const Text('重试'),
          ),
        ],
      ),
      data: (snapshot) => _ReviewBody(snapshot: snapshot),
    );
  }
}

class _ReviewBody extends ConsumerStatefulWidget {
  const _ReviewBody({required this.snapshot});
  final MonthlyReviewSnapshot snapshot;

  @override
  ConsumerState<_ReviewBody> createState() => _ReviewBodyState();
}

class _ReviewBodyState extends ConsumerState<_ReviewBody> {
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
      final api = ref.read(apiClientProvider).getTasteProfileApi();
      if (confirm) {
        await api.confirmChange(
          changeId: change.id,
          source_: 'monthly_review',
          extra: {
            'auth_owner_id': identity.ownerId,
            'auth_identity_epoch': identity.epoch,
          },
        );
      } else {
        await api.revertChange(
          changeId: change.id,
          source_: 'monthly_review',
          extra: {
            'auth_owner_id': identity.ownerId,
            'auth_identity_epoch': identity.epoch,
          },
        );
      }
      if (!mounted || !session.matches(identity)) return;
      ref.invalidate(monthlyReviewProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(confirm ? '已确认口味变化' : '已撤销口味变化')));
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
        Text('上月回顾', style: Theme.of(context).textTheme.titleLarge),
        Text(monthLabel, style: Theme.of(context).textTheme.titleMedium),
        if (widget.snapshot.fromCache)
          Text('离线回顾 · 更新于 ${widget.snapshot.cachedAt.toLocal()}'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('做菜次数'),
          subtitle: Text(
            '较再上月 ${_difference(stats.cookingCount - previous.cookingCount)}',
          ),
          trailing: Text('${stats.cookingCount}'),
        ),
        if (stats.frequentDishes.isNotEmpty)
          _ReviewList(
            title: '常做',
            names: stats.frequentDishes
                .map((item) => '${item.name} · ${item.count} 次')
                .toList(),
          ),
        if (stats.newDishes.isNotEmpty)
          _ReviewList(
            title: '新尝试',
            names: stats.newDishes
                .map((item) => '${item.name} · ${item.count} 次')
                .toList(),
          ),
        if (stats.ingredientDistribution.isNotEmpty)
          _ReviewList(
            title: '主料摘要',
            names: stats.ingredientDistribution
                .map((item) => '${item.key} · ${item.count} 次')
                .toList(),
          ),
        if (stats.cookingCount == 0 && widget.snapshot.changes.isEmpty)
          const Text('上月没有做菜记录或口味变化。'),
        if (automatic.isNotEmpty) ...[
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('自动学习的口味变化'),
          ),
          if (widget.snapshot.fromCache) const Text('离线时不能确认或撤销，联网后重试。'),
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
            title: '手动修改',
            names: manual
                .map((change) => '${change.field} · ${change.reason}')
                .toList(),
          ),
      ],
    );
  }

  String _difference(int value) => value == 0
      ? '无变化'
      : value > 0
      ? '增加 $value 次'
      : '减少 ${-value} 次';
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
  Widget build(BuildContext context) => ListTile(
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
              : '手动修改',
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
          title: const Text('变化明细'),
          children: [
            ListTile(dense: true, title: Text('变更前：${change.oldValue}')),
            ListTile(dense: true, title: Text('变更后：${change.newValue}')),
          ],
        ),
      ],
    ),
    trailing: Wrap(
      spacing: 4,
      children: [
        if (change.status == TasteProfileChangeOutStatusEnum.pending)
          IconButton(
            tooltip: '确认',
            onPressed: offline || busy ? null : onConfirm,
            icon: const Icon(Icons.check),
          ),
        if (change.status == TasteProfileChangeOutStatusEnum.active ||
            change.status == TasteProfileChangeOutStatusEnum.confirmed)
          IconButton(
            tooltip: '撤销',
            onPressed: offline || busy ? null : onRevert,
            icon: const Icon(Icons.undo),
          ),
      ],
    ),
  );
}
