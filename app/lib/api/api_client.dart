import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../auth/session.dart';
import 'request_signing.dart';
import 'access_protection.dart';
import '../config/app_config.dart';
import '../privacy/consent.dart';
import '../network/reachability.dart';
import '../network/online_features.dart';
import '../storage/device_id.dart';

/// 由服务端 OpenAPI 描述生成的接口客户端（packages/gramtree_api，不要手改）。
/// 服务端接口变了就运行 tool/gen_api_client.sh 重新生成。
///
/// 这里给它装上几层拦截：
/// 1. 同意隐私政策之前，任何请求都不发出去（[ConsentGate]）。
/// 2. 每个请求带上设备 ID。
/// 3. 登录后带上访问令牌；访问令牌过期时自动续期并重试，续期失败就退出登录。
final apiClientProvider = Provider<GramtreeApi>(
  (ref) => GramtreeApi(dio: ref.watch(dioProvider), interceptors: const []),
);

/// 测试时在拦截链最后加一个假服务端（记录请求、直接返回预设的响应，不走网络层）。
/// null 表示真的发请求。
final fakeServerProvider = Provider<Interceptor?>((ref) => null);

/// Keep the platform implementation in production and live integration tests.
/// Automated widget fixtures can select the package's real Dart algorithms,
/// whose futures do not depend on native browser events outside the fake clock.
final requestSigningCryptographyProvider = Provider<Cryptography>(
  (ref) => Cryptography.instance,
);

/// 端到端测试专用的"飞行模式"开关：默认 false（正常联网），只有测试代码会把它
/// 置成 true。跟 [fakeServerProvider] 不一样——这里仍然是真的服务端，只是本机
/// 暂时不让任何请求发出去，用来在安卓模拟器上模拟断网又不用真的操作系统级飞行模式
/// （集成测试进程没有权限切系统网络设置，见 SPEC-010.1 票 7 的
/// `integration_test/event_offline_replay_test.dart`）。生产代码里没有任何地方
/// 会把它设成 true。
class OfflineSimulation extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool offline) => state = offline;
}

final offlineSimulationProvider = NotifierProvider<OfflineSimulation, bool>(
  OfflineSimulation.new,
);

const deviceIdHeader = 'X-Device-ID';

bool _isPublicShareRequest(RequestOptions options) {
  if (options.extra['public_request'] != true) return false;
  final path = options.uri.path;
  if (options.method == 'GET' &&
      (RegExp(r'^/v1/shares/[^/?#]+$').hasMatch(path) ||
          RegExp(r'^/s/[^/?#]+/image$').hasMatch(path))) {
    return true;
  }
  // Only recovery spawned by an anonymous share request bypasses consent and
  // identity headers. Ordinary authenticated challenges retain their account.
  return options.extra['public_share_captcha'] == true &&
      ((options.method == 'GET' &&
              RegExp(r'^/v1/risk/captcha/[^/?#]+$').hasMatch(path)) ||
          (options.method == 'POST' && path == '/v1/risk/captcha'));
}

Dio _baseDio(Ref ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // The generated Dart client includes nullable optional query fields;
        // omit them so FastAPI does not parse an absent value as an empty one.
        options.queryParameters.removeWhere(
          (key, value) => value == null || value == '',
        );
        if (ref.read(offlineSimulationProvider)) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
              error: 'offline simulation (test only)',
            ),
          );
        } else {
          handler.next(options);
        }
      },
    ),
  );
  dio.interceptors.add(ConsentGate(() => ref.read(privacyConsentProvider)));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final feature =
            options.extra[OnlineFeatures.requestFeatureKey] ??
            OnlineFeatures.forRequest(options.method, options.uri.path);
        if (feature == null) {
          handler.next(options);
          return;
        }
        final monitor = ref.read(apiReachabilityProvider.notifier);
        // Recheck at the execution boundary; no recipe text or conversion input
        // is sent until this small consent-gated health request succeeds.
        if (!await monitor.check()) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
              error: OnlineFeatureUnavailable(
                ref.read(apiReachabilityProvider),
              ),
            ),
          );
          return;
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.error is! OnlineFeatureUnavailable &&
            (error.type == DioExceptionType.connectionError ||
                error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.receiveTimeout ||
                error.type == DioExceptionType.sendTimeout ||
                (error.response?.statusCode ?? 0) >= 500)) {
          ref.read(apiReachabilityProvider.notifier).markUnavailable();
        }
        handler.next(error);
      },
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (!_isPublicShareRequest(options)) {
          options.headers[deviceIdHeader] = ref.read(deviceIdProvider);
        }
        handler.next(options);
      },
    ),
  );
  return dio;
}

void _addFakeServer(Ref ref, Dio dio) {
  final fake = ref.watch(fakeServerProvider);
  if (fake != null) dio.interceptors.add(fake);
}

final dioProvider = Provider<Dio>((ref) {
  final dio = _baseDio(ref);
  // 续期和续期后的重试都用单独的 Dio，不经过下面的续期拦截：
  // 续期拦截是排队执行的，在它里面再走同一条拦截链，重试失败时会互相等待、永远卡住
  final plainDio = _baseDio(ref);
  final signer = RequestSigner(
    ref.watch(sessionStoreProvider),
    cryptography: ref.watch(requestSigningCryptographyProvider),
  );
  final auth = AuthInterceptor(
    retryDio: plainDio,
    session: ref.watch(sessionStoreProvider),
    refresh: (token) async {
      final api = GramtreeApi(dio: plainDio, interceptors: const []);
      final resp = await api.getAuthApi().refreshTokens(
        refreshRequest: RefreshRequest(refreshToken: token),
      );
      return resp.data!;
    },
    canRefresh: () =>
        !ref.read(offlineSimulationProvider) &&
        ref.read(apiReachabilityProvider) != ApiReachability.unavailable,
    onSessionExpired: () =>
        ref.read(sessionStoreProvider).expire(reason: 'refresh_failed'),
  );
  // A clock/captcha replay may encounter token expiry. Apply the same fenced,
  // once-only recovery without entering the queued interceptor recursively.
  // The auth_retried flag prevents a refresh-retry from refreshing again.
  plainDio.interceptors.add(InterceptorsWrapper(onError: auth.onError));
  plainDio.interceptors.add(
    RequestProtectionInterceptor(plainDio, signer, ref),
  );
  _addFakeServer(ref, plainDio);
  dio.interceptors.add(auth);
  dio.interceptors.add(RequestProtectionInterceptor(plainDio, signer, ref));
  _addFakeServer(ref, dio);
  return dio;
});

class RequestProtectionInterceptor extends Interceptor {
  RequestProtectionInterceptor(this._retryDio, this._signer, this._ref);

  final Dio _retryDio;
  final RequestSigner _signer;
  final Ref _ref;
  static const _clockRetried = 'signing_clock_retried';
  static const _captchaRetried = 'captcha_retried';

  bool _rebindRetryBearer(RequestOptions options) {
    final revocation = options.extra['auth_revocation_session'];
    if (options.extra['auth_revocation'] == true &&
        options.method == 'POST' &&
        options.uri.path == '/v1/auth/logout' &&
        revocation is AuthSession &&
        options.headers['Authorization'] ==
            'Bearer ${revocation.accessToken}') {
      // Revocation is explicitly authorized for this captured, already-logged-out
      // session; never replace its bearer with the next account's credential.
      return true;
    }
    final session = _ref.read(sessionStoreProvider);
    if (options.extra['auth_identity_epoch'] != session.identityEpoch ||
        options.extra['auth_owner_id'] != session.current?.user.id) {
      return false;
    }
    // Security subrequests can rotate credentials while the original operation
    // waits for a challenge. Rebind only its already-captured login generation.
    if (options.headers['Authorization'] != null &&
        session.current != null &&
        options.extra['auth_revocation'] != true) {
      options.headers['Authorization'] =
          'Bearer ${session.current!.accessToken}';
    }
    return true;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      await _signer.sign(options, transformer: _retryDio.transformer);
      handler.next(options);
    } catch (error) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          error: error,
        ),
      );
    }
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (response.headers.value('x-pagination-limit-reached') == 'true') {
      _ref.read(accessProtectionProvider.notifier).paginationLimit(true);
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final data = err.response?.data;
    final body = data is Map ? data['error'] : null;
    final headers = err.response?.headers;
    if (body is Map && body['code'] == 'pagination_limit_reached') {
      _ref.read(accessProtectionProvider.notifier).paginationLimit(true);
    }
    final retrySeconds = int.tryParse(headers?.value('retry-after') ?? '');
    if (err.response?.statusCode == 429 && retrySeconds != null) {
      _ref.read(accessProtectionProvider.notifier).rateLimited(retrySeconds);
    }
    if (body is Map &&
        body['code'] == 'risk_captcha_required' &&
        options.extra[_captchaRetried] != true &&
        !options.uri.path.startsWith('/v1/risk/captcha')) {
      final challengeId = headers?.value('x-risk-challenge');
      if (challengeId != null && _rebindRetryBearer(options)) {
        options.extra[_captchaRetried] = true;
        try {
          final riskApi = GramtreeApi(
            dio: _retryDio,
            interceptors: const [],
          ).getRiskApi();
          final recoveryExtra = {
            ...options.extra,
            if (_isPublicShareRequest(options)) 'public_share_captcha': true,
          };
          final response = await riskApi.getCaptchaChallenge(
            challengeId: Uri.encodeComponent(challengeId),
            headers: {'Authorization': options.headers['Authorization']},
            extra: recoveryExtra,
          );
          final challenge = response.data;
          final imageUri = challenge?.imageDataUri;
          if (challenge?.challengeId != challengeId ||
              imageUri == null ||
              !imageUri.startsWith('data:image/png;base64,') ||
              imageUri.length > 1024 * 1024) {
            handler.next(err);
            return;
          }
          if (!_rebindRetryBearer(options)) {
            handler.next(err);
            return;
          }
          final answer = await _ref
              .read(captchaAdapterProvider)
              .solve(
                CaptchaChallenge(
                  id: challengeId,
                  prompt: challenge!.prompt,
                  image: base64Decode(
                    imageUri.substring('data:image/png;base64,'.length),
                  ),
                ),
              );
          if (answer != null &&
              answer.isNotEmpty &&
              _rebindRetryBearer(options)) {
            // Preserve the original account fence through challenge, verification and replay.
            final verification = await riskApi.verifyCaptcha(
              captchaVerification: CaptchaVerification(
                challengeId: challengeId,
                response: answer,
              ),
              headers: {'Authorization': options.headers['Authorization']},
              extra: {...recoveryExtra, _captchaRetried: true},
            );
            if (verification.data?.accepted != true ||
                verification.data?.accessRestored != true ||
                !_rebindRetryBearer(options)) {
              handler.next(err);
              return;
            }
            handler.resolve(await _retryDio.fetch<dynamic>(options));
            return;
          }
        } on DioException catch (retryError) {
          handler.next(retryError);
          return;
        } on FormatException {
          handler.next(err);
          return;
        }
      }
    }
    if (body is! Map ||
        body['code'] != 'signature_clock_skew' ||
        options.extra[_clockRetried] == true ||
        !_rebindRetryBearer(options) ||
        !_signer.correctServerTime(body['server_time'])) {
      handler.next(err);
      return;
    }
    options.extra[_clockRetried] = true;
    try {
      handler.resolve(await _retryDio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}

/// 同意之前拒绝一切请求：请求根本不会交给网络层。
class ConsentGate extends Interceptor {
  ConsentGate(this._consented);

  final bool Function() _consented;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_consented() || _isPublicShareRequest(options)) {
      handler.next(options);
    } else {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          error: const ConsentRequired(),
        ),
      );
    }
  }
}

class ConsentRequired implements Exception {
  const ConsentRequired();

  @override
  String toString() => '需要先同意隐私政策';
}

/// 带上访问令牌；收到 token_expired 时用刷新令牌续期（同一时间只续一次）并重试原请求。
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.retryDio,
    required this.session,
    required this.refresh,
    required this.onSessionExpired,
    this.canRefresh,
  });

  /// 重试原请求用的 Dio，不能带这个拦截器。
  final Dio retryDio;
  final SessionStore session;
  final Future<TokenPair> Function(String refreshToken) refresh;
  final Future<void> Function() onSessionExpired;
  final bool Function()? canRefresh;

  static const _retried = 'auth_retried';
  static const _originOwner = 'auth_origin_owner';

  bool _sensitiveOriginMatches(RequestOptions options) {
    final owner = options.extra['sensitive_account_id'];
    if (owner == null) return true;
    final epoch = options.extra['sensitive_identity_epoch'];
    return session.current?.user.id == owner &&
        (epoch != null
            ? epoch == session.identityEpoch
            : identical(options.extra['sensitive_session'], session.current));
  }

  bool _matchesIdentity(RequestOptions options) {
    final owner =
        options.extra['sync_owner_id'] ?? options.extra['auth_owner_id'];
    final epoch =
        options.extra['sync_identity_epoch'] ??
        options.extra['auth_identity_epoch'];
    final identity = session.identity;
    return (owner == null || owner == session.current?.user.id) &&
        (epoch == null || epoch == session.identityEpoch) &&
        (options.extra['sync_owner_id'] == null ||
            (identity != null && session.canUpload(identity)));
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublicShareRequest(options)) {
      options.headers.remove('Authorization');
      // Anonymous recovery still belongs to the login generation that opened
      // the link; never replay it across a login/logout or account switch.
      options.extra['auth_owner_id'] = session.current?.user.id;
      options.extra['auth_identity_epoch'] = session.identityEpoch;
      handler.next(options);
      return;
    }
    // Upgrade an older saved login before dispatching any protected request.
    // The refresh endpoint is token-authenticated and does not need a bearer MAC.
    final legacy = session.current;
    if (legacy != null &&
        legacy.requestSigningKey == null &&
        options.extra['auth_revocation'] != true &&
        _matchesIdentity(options) &&
        _sensitiveOriginMatches(options)) {
      final identity = session.identity!;
      try {
        if (canRefresh?.call() == false) {
          throw StateError('refresh_waiting_for_network');
        }
        final tokens = await refresh(legacy.refreshToken);
        if (!session.matches(identity) || !identical(session.current, legacy)) {
          throw StateError('account_changed');
        }
        if (tokens.user.id != legacy.user.id) {
          throw StateError('account_changed');
        }
        await session.saveRefreshed(tokens, identity: identity);
        if (!session.matches(identity)) throw StateError('account_changed');
        // Only this verified same-login rotation may update a sensitive capture.
        if (identical(options.extra['sensitive_session'], legacy)) {
          options.extra['sensitive_session'] = session.current;
        }
        if (options.headers['Authorization'] ==
            'Bearer ${legacy.accessToken}') {
          options.headers['Authorization'] =
              'Bearer ${session.current!.accessToken}';
        }
      } catch (error) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: error,
          ),
        );
        return;
      }
    }
    // Confirmed local logout fences the session before HTTP dispatch. Allow
    // only this captured-token revocation, never inject a new account's token.
    if (options.extra['auth_revocation'] == true &&
        options.method == 'POST' &&
        options.uri.path == '/v1/auth/logout' &&
        options.headers['Authorization'] != null) {
      handler.next(options);
      return;
    }
    if (!_matchesIdentity(options) || !_sensitiveOriginMatches(options)) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          error: !_matchesIdentity(options)
              ? 'account_changed'
              : 'account_unavailable',
        ),
      );
      return;
    }
    options.extra['auth_owner_id'] = session.current?.user.id;
    options.extra['auth_identity_epoch'] = session.identityEpoch;
    final token = session.current?.accessToken;
    if (token != null &&
        (!options.headers.containsKey('Authorization') ||
            options.extra['sensitive_identity_epoch'] ==
                session.identityEpoch)) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    if (token != null) {
      options.extra[_originOwner] = session.current!.user.id;
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final code = ApiFailure.from(err).code;
    final current = session.current;
    final epoch = session.identityEpoch;
    if (!_matchesIdentity(err.requestOptions) ||
        code != 'token_expired' ||
        current == null ||
        err.requestOptions.extra[_retried] == true ||
        err.requestOptions.extra[_originOwner] != current.user.id ||
        !_sensitiveOriginMatches(err.requestOptions)) {
      handler.next(err);
      return;
    }
    if (canRefresh?.call() == false) {
      handler.next(
        DioException(
          requestOptions: err.requestOptions,
          type: DioExceptionType.connectionError,
          error: 'refresh_waiting_for_network',
        ),
      );
      return;
    }
    var expected = current;
    try {
      // 排队期间可能已经有别的请求续期成功了，直接用新的。
      final sentWith = err.requestOptions.headers['Authorization'];
      if (sentWith == 'Bearer ${current.accessToken}') {
        final tokens = await refresh(current.refreshToken);
        // A stale refresh must neither replace a new login nor replay an old
        // owner-private mutation under that login (sensitive or ordinary).
        if (!_matchesIdentity(err.requestOptions) ||
            session.identityEpoch != epoch ||
            !identical(session.current, current) ||
            tokens.user.id != current.user.id) {
          handler.next(err);
          return;
        }
        final saving = session.saveRefreshed(
          tokens,
          identity: SessionIdentity(ownerId: current.user.id, epoch: epoch),
        );
        expected = session.current!;
        await saving;
        if (identical(err.requestOptions.extra['sensitive_session'], current) &&
            _matchesIdentity(err.requestOptions) &&
            identical(session.current, expected)) {
          err.requestOptions.extra['sensitive_session'] = expected;
        }
      }
    } catch (error) {
      // A transport outage is not a revoked login. Return the transport error
      // so account queues retain their writes for network recovery, not logout.
      if (error is DioException &&
          (error.response == null ||
              (error.response?.statusCode ?? 0) >= 500)) {
        handler.next(error);
        return;
      }
      // A failed old refresh must not sign out a newly selected account.
      if (_matchesIdentity(err.requestOptions) &&
          session.identityEpoch == epoch &&
          identical(session.current, expected)) {
        await onSessionExpired();
      }
      handler.next(err);
      return;
    }
    if (!_matchesIdentity(err.requestOptions) ||
        session.identityEpoch != epoch ||
        !identical(session.current, expected)) {
      handler.next(err);
      return;
    }
    final retry = err.requestOptions
      ..extra[_retried] = true
      ..headers['Authorization'] = 'Bearer ${expected.accessToken}';
    try {
      handler.resolve(await retryDio.fetch<dynamic>(retry));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

/// 从接口错误里取出统一错误格式的 code 和给用户看的 message。
bool isNetworkFailure(Object error) {
  if (error is! DioException || error.response != null) return false;
  return switch (error.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => true,
    _ => false,
  };
}

class ApiFailure {
  const ApiFailure(this.code, this.message);

  factory ApiFailure.from(Object error) {
    if (error is OnlineFeatureUnavailable) {
      return ApiFailure('network', error.toString());
    }
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] is Map) {
        final e = data['error'] as Map;
        return ApiFailure(
          e['code'] as String? ?? 'error',
          e['message'] as String? ?? _fallback,
        );
      }
      if (error.error is ConsentRequired) {
        return const ApiFailure('consent_required', '需要先同意隐私政策');
      }
      if (error.error is OnlineFeatureUnavailable) {
        return ApiFailure('network', error.error.toString());
      }
      if (isNetworkFailure(error)) {
        return const ApiFailure('network', '网络连接不上，请检查网络后再试');
      }
    }
    return const ApiFailure('error', _fallback);
  }

  static const _fallback = '出了点问题，请稍后再试';

  final String code;
  final String message;
}
