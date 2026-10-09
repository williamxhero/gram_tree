import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../api/api_client.dart';
import '../events/event_queue.dart';
import '../events/event_uploader.dart';
import '../platform/apple_sign_in.dart';
import '../platform/timezone_source.dart';
import '../privacy/consent.dart';
import 'session.dart';

/// 当前登录的账号；null 表示未登录。加载本机保存的登录状态时是 loading。
final authProvider = AsyncNotifierProvider<AuthController, UserOut?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<UserOut?> {
  SessionStore get _session => ref.read(sessionStoreProvider);
  GramtreeApi get _api => ref.read(apiClientProvider);

  @override
  Future<UserOut?> build() async {
    final store = ref.watch(sessionStoreProvider);
    final session = await store.load();
    void onChange() => state = AsyncData(store.current?.user);
    store.addListener(onChange);
    ref.onDispose(() => store.removeListener(onChange));
    // 已登录时重新同意（例如隐私政策改版），把新的同意记录传上去
    ref.listen(privacyConsentProvider, (before, now) {
      if (now && before == false) unawaited(uploadPendingConsents());
    });
    if (session != null) unawaited(_afterSignIn());
    return session?.user;
  }

  Future<EmailCodeSent> sendEmailCode(
    String email, {
    EmailCodeRequestPurposeEnum purpose = EmailCodeRequestPurposeEnum.login,
  }) async {
    final resp = await _api.getAuthApi().sendEmailCode(
      emailCodeRequest: EmailCodeRequest(email: email, purpose: purpose),
    );
    return resp.data!;
  }

  Future<void> signInWithEmail(String email, String code) async {
    final resp = await _api.getAuthApi().emailLogin(
      emailLoginRequest: EmailLoginRequest(email: email, code: code),
    );
    await _signedIn(resp.data!);
  }

  /// 返回 false 表示用户取消了。
  Future<bool> signInWithApple() async {
    final AppleCredential c;
    try {
      c = await ref.read(appleSignInProvider).signIn();
    } on AppleSignInCancelled {
      return false;
    }
    final resp = await _api.getAuthApi().appleLogin(
      appleLoginRequest: AppleLoginRequest(
        identityToken: c.identityToken,
        authorizationCode: c.authorizationCode,
        givenName: c.givenName,
        familyName: c.familyName,
      ),
    );
    await _signedIn(resp.data!);
    return true;
  }

  Future<void> _signedIn(TokenPair tokens) async {
    await _session.save(tokens);
    await _afterSignIn();
  }

  /// 登录后：补传登录前存在本机的同意记录，同步手机的时区，试着传一次本机队列里
  /// 积压的事件（登录前记的事件留在队列里，登录后才有 token 可以传）。三者互不依赖，
  /// 并发执行；失败不影响使用，下次再试。
  Future<void> _afterSignIn() async {
    await Future.wait([
      uploadPendingConsents(),
      _syncTimezone(),
      ref.read(eventUploaderProvider).networkRestored(),
    ]);
  }

  Future<void> uploadPendingConsents() async {
    final pending = ref.read(consentProvider).pendingUpload;
    if (pending.isEmpty || _session.current == null) return;
    if (await uploadConsentRecords(pending)) {
      await ref
          .read(consentProvider.notifier)
          .markUploaded(pending.map((e) => e.id));
    }
  }

  /// 把同意记录传到账号。返回是否成功；失败的下次启动或登录时再传。
  Future<bool> uploadConsentRecords(
    List<ConsentEntry> records, {
    SessionIdentity? identity,
  }) async {
    final captured = identity ?? _session.identity;
    if (records.isEmpty || captured == null || !_session.matches(captured)) {
      return false;
    }
    try {
      await _api.getAccountApi().uploadConsents(
        extra: {
          'auth_owner_id': captured.ownerId,
          'auth_identity_epoch': captured.epoch,
        },
        consentUpload: ConsentUpload(
          records: [
            for (final e in records)
              ConsentRecordInput(
                id: e.id,
                kind: ConsentRecordInputKindEnum.values.firstWhere(
                  (k) => k.value == e.kind.value,
                ),
                version: e.version,
                action: e.agree
                    ? ConsentRecordInputActionEnum.agree
                    : ConsentRecordInputActionEnum.withdraw,
                occurredAt: e.occurredAt.toUtc(),
                deviceId: e.deviceId,
              ),
          ],
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _syncTimezone() async {
    final session = _session;
    final identity = session.identity;
    final user = session.current?.user;
    if (identity == null || user == null) return;
    final tz = await ref.read(timezoneSourceProvider).current();
    if (!ref.mounted ||
        !session.matches(identity) ||
        tz == null ||
        tz == user.timezone) {
      return;
    }
    try {
      await updateProfile(timezone: tz);
    } catch (_) {}
  }

  Future<UserOut> updateProfile({String? nickname, String? timezone}) async {
    final session = _session;
    final identity = session.identity;
    if (identity == null) throw StateError('Login required');
    final resp = await _api.getAccountApi().updateMe(
      extra: {
        'auth_owner_id': identity.ownerId,
        'auth_identity_epoch': identity.epoch,
      },
      profileUpdate: ProfileUpdate(nickname: nickname, timezone: timezone),
    );
    if (ref.mounted &&
        session.matches(identity) &&
        resp.data!.id == identity.ownerId) {
      await session.updateUser(resp.data!);
    }
    return resp.data!;
  }

  /// 退出当前设备的登录。服务端没连上也照样清掉本机的登录状态。
  Future<void> signOut() async {
    // 普通登出保留账号绑定的内容。下一个账号的上传器只取自己的队列；
    // 完整待同步提醒由同步状态界面提供，绝不能以清空代替隔离。
    final identity = _session.identity;
    if (identity == null) return;
    await ref.read(eventUploaderProvider).triggerUpload();
    if (!ref.mounted || !_session.matches(identity)) return;
    await signOutOnServer(identity: identity);
    if (ref.mounted && _session.matches(identity)) await _session.clear();
  }

  /// 只通知服务端吊销这台设备的令牌，本机状态留给调用方清。
  Future<void> signOutOnServer({SessionIdentity? identity}) async {
    final captured = identity ?? _session.identity;
    if (captured == null || !_session.matches(captured)) return;
    try {
      await _api.getAuthApi().logout(
        extra: {
          'auth_owner_id': captured.ownerId,
          'auth_identity_epoch': captured.epoch,
        },
      );
    } catch (_) {}
  }

  /// 清掉本机的登录状态（注销账号后服务端已经吊销了令牌）。
  Future<void> clearLocalSession({
    bool deleteAccountData = false,
    SessionIdentity? identity,
  }) async {
    final session = _session;
    final captured = identity ?? session.identity;
    if (captured == null) return;
    final queue = ref.read(eventQueueProvider);
    // Capture dependencies before awaiting; provider disposal must not silently
    // skip a confirmed deletion, nor turn Alice's cleanup into Bob's cleanup.
    if (session.matches(captured)) await session.clear();
    await queue.clearAccount(
      captured.ownerId,
      experienceOnly: !deleteAccountData,
    );
  }
}
