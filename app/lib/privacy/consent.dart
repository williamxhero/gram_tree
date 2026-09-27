import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/device_id.dart';
import '../storage/local_store.dart';
import '../util/ids.dart';
import 'policy.dart';

/// 一条同意或撤回记录。登录前先存在本机，登录后上传到账号（[uploaded] 标记是否已上传）。
class ConsentEntry {
  const ConsentEntry({
    required this.id,
    required this.kind,
    required this.version,
    required this.agree,
    required this.occurredAt,
    required this.deviceId,
    this.uploaded = false,
  });

  factory ConsentEntry.fromJson(Map<String, dynamic> json) => ConsentEntry(
    id: json['id'] as String,
    kind: ConsentKind.parse(json['kind'] as String),
    version: json['version'] as String,
    agree: json['agree'] as bool,
    occurredAt: DateTime.parse(json['occurred_at'] as String),
    deviceId: json['device_id'] as String,
    uploaded: json['uploaded'] as bool? ?? false,
  );

  final String id;
  final ConsentKind kind;
  final String version;
  final bool agree;
  final DateTime occurredAt;
  final String deviceId;
  final bool uploaded;

  ConsentEntry markUploaded() => ConsentEntry(
    id: id,
    kind: kind,
    version: version,
    agree: agree,
    occurredAt: occurredAt,
    deviceId: deviceId,
    uploaded: true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.value,
    'version': version,
    'agree': agree,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'device_id': deviceId,
    'uploaded': uploaded,
  };
}

class ConsentState {
  const ConsentState(this.entries);

  final List<ConsentEntry> entries;

  ConsentEntry? _latest(ConsentKind kind) {
    for (final e in entries.reversed) {
      if (e.kind == kind) return e;
    }
    return null;
  }

  bool _agreedTo(ConsentKind kind, String version) {
    final latest = _latest(kind);
    return latest != null && latest.agree && latest.version == version;
  }

  /// 已同意当前版本的用户协议和隐私政策。
  bool get agreedToCurrent =>
      _agreedTo(ConsentKind.terms, termsVersion) &&
      _agreedTo(ConsentKind.privacy, privacyVersion);

  /// 同意过旧版本隐私政策（且没撤回），现在需要看变更摘要重新同意。
  String? get outdatedPrivacyVersion {
    final latest = _latest(ConsentKind.privacy);
    if (latest == null || !latest.agree || latest.version == privacyVersion) {
      return null;
    }
    return latest.version;
  }

  List<ConsentEntry> get pendingUpload =>
      entries.where((e) => !e.uploaded).toList();
}

const _storeKey = 'consent_records';

/// 同意状态。首次启动、改版、撤回都由它决定是否显示同意页。
final consentProvider = NotifierProvider<ConsentController, ConsentState>(
  ConsentController.new,
);

class ConsentController extends Notifier<ConsentState> {
  LocalStore get _store => ref.read(localStoreProvider);

  @override
  ConsentState build() {
    final raw = ref.watch(localStoreProvider).getString(_storeKey);
    if (raw == null) return const ConsentState([]);
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return ConsentState(list.map(ConsentEntry.fromJson).toList());
  }

  Future<void> _save(List<ConsentEntry> entries) async {
    state = ConsentState(entries);
    await _store.setString(
      _storeKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  List<ConsentEntry> _records(bool agree) {
    final now = DateTime.now();
    final device = ref.read(deviceIdProvider);
    return [
      for (final (kind, version) in [
        (ConsentKind.terms, termsVersion),
        (ConsentKind.privacy, privacyVersion),
      ])
        ConsentEntry(
          id: newUuidV4(),
          kind: kind,
          version: version,
          agree: agree,
          occurredAt: now,
          deviceId: device,
        ),
    ];
  }

  /// 同意当前版本的用户协议和隐私政策。
  Future<void> agree() => _save([...state.entries, ..._records(true)]);

  /// 撤回同意。之后 App 回到首次启动的同意页。
  ///
  /// 撤回一生效网络层就不再放行请求，所以要传给服务端的（撤回记录、退出登录）
  /// 放在 [beforeEffective] 里先做；它返回撤回记录是否已上传。
  Future<List<ConsentEntry>> withdraw({
    Future<bool> Function(List<ConsentEntry> records)? beforeEffective,
  }) async {
    final records = _records(false);
    var uploaded = false;
    if (beforeEffective != null) {
      try {
        uploaded = await beforeEffective(records);
      } catch (_) {}
    }
    await _save([
      ...state.entries,
      for (final r in records) uploaded ? r.markUploaded() : r,
    ]);
    return records;
  }

  Future<void> markUploaded(Iterable<String> ids) {
    final done = ids.toSet();
    return _save([
      for (final e in state.entries) done.contains(e.id) ? e.markUploaded() : e,
    ]);
  }
}

/// 用户是否已同意当前版本的隐私政策。同意前不联网、不初始化第三方 SDK、不申请权限。
final privacyConsentProvider = Provider<bool>(
  (ref) => ref.watch(consentProvider).agreedToCurrent,
);
