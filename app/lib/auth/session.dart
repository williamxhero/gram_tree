import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../storage/secure_store.dart';

/// 当前设备的登录状态：访问令牌、刷新令牌和账号资料，存在系统安全存储里。
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthSession.fromTokens(TokenPair t) => AuthSession(
    accessToken: t.accessToken,
    refreshToken: t.refreshToken,
    user: t.user,
  );

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    user: UserOut.fromJson(json['user'] as Map<String, dynamic>),
  );

  final String accessToken;
  final String refreshToken;
  final UserOut user;

  AuthSession withUser(UserOut user) => AuthSession(
    accessToken: accessToken,
    refreshToken: refreshToken,
    user: user,
  );

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'user': user.toJson(),
  };
}

const sessionStorageKey = 'auth_session';

/// Owner + login generation captured before any async account operation.
class SessionIdentity {
  const SessionIdentity({required this.ownerId, required this.epoch});
  final String ownerId;
  final int epoch;
}

/// 持有当前登录状态。拦截器同步读取令牌；登录、续期、退出时通知界面。
class SessionStore extends ChangeNotifier {
  SessionStore(this._secure);

  final SecureStore _secure;
  AuthSession? _current;
  bool _loaded = false;
  int _identityEpoch = 0;
  Future<void> _persistence = Future<void>.value();

  Future<void> _persist(Future<void> Function() operation) {
    // Keep writes/deletes in invocation order. A slow old refresh write must
    // never finish after logout deletion or a subsequent account's write.
    final pending = _persistence.then((_) => operation());
    _persistence = pending.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return pending;
  }

  /// Changes on account switch/logout, not same-account token refresh.
  int get identityEpoch => _identityEpoch;
  SessionIdentity? get identity => _current == null
      ? null
      : SessionIdentity(ownerId: _current!.user.id, epoch: _identityEpoch);
  bool matches(SessionIdentity identity) =>
      _current?.user.id == identity.ownerId && _identityEpoch == identity.epoch;

  /// 为什么变成了未登录（续期失败、撤回同意等），给登录页显示提示用。
  String? lastExpiryReason;

  AuthSession? get current => _current;
  bool get isLoaded => _loaded;

  Future<AuthSession?> load() async {
    if (_loaded) return _current;
    final epoch = _identityEpoch;
    final raw = await _secure.read(sessionStorageKey);
    if (_loaded || epoch != _identityEpoch) return _current;
    if (raw != null) {
      try {
        _current = AuthSession.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        await _persist(() => _secure.delete(sessionStorageKey));
        if (_loaded || epoch != _identityEpoch) return _current;
      }
    }
    _loaded = true;
    notifyListeners();
    return _current;
  }

  Future<void> save(TokenPair tokens) => _set(AuthSession.fromTokens(tokens));

  Future<void> updateUser(UserOut user) async {
    final s = _current;
    if (s != null && s.user.id == user.id) await _set(s.withUser(user));
  }

  Future<void> _set(AuthSession session) async {
    if (_current?.user.id != session.user.id) _identityEpoch++;
    _current = session;
    _loaded = true;
    lastExpiryReason = null;
    final value = jsonEncode(session.toJson());
    // Fence old account work immediately; ordered persistence may still be slow.
    notifyListeners();
    await _persist(() => _secure.write(sessionStorageKey, value));
  }

  /// 清掉本机的登录状态。
  Future<void> clear() async {
    _identityEpoch++;
    _current = null;
    _loaded = true;
    // Hide account-private UI immediately, even while older storage IO drains.
    notifyListeners();
    await _persist(() => _secure.delete(sessionStorageKey));
  }

  Future<void> expire({required String reason}) async {
    if (_current == null) return;
    lastExpiryReason = reason;
    await clear();
  }
}

final sessionStoreProvider = Provider<SessionStore>((ref) {
  final store = SessionStore(ref.watch(secureStoreProvider));
  ref.onDispose(store.dispose);
  return store;
});
