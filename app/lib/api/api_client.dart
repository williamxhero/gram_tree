import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../auth/session.dart';
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
        options.headers[deviceIdHeader] = ref.read(deviceIdProvider);
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
  _addFakeServer(ref, plainDio);
  dio.interceptors.add(
    AuthInterceptor(
      retryDio: plainDio,
      session: ref.watch(sessionStoreProvider),
      refresh: (token) async {
        final api = GramtreeApi(dio: plainDio, interceptors: const []);
        final resp = await api.getAuthApi().refreshTokens(
          refreshRequest: RefreshRequest(refreshToken: token),
        );
        return resp.data!;
      },
      onSessionExpired: () =>
          ref.read(sessionStoreProvider).expire(reason: 'refresh_failed'),
    ),
  );
  _addFakeServer(ref, dio);
  return dio;
});

/// 同意之前拒绝一切请求：请求根本不会交给网络层。
class ConsentGate extends Interceptor {
  ConsentGate(this._consented);

  final bool Function() _consented;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_consented()) {
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
  });

  /// 重试原请求用的 Dio，不能带这个拦截器。
  final Dio retryDio;
  final SessionStore session;
  final Future<TokenPair> Function(String refreshToken) refresh;
  final Future<void> Function() onSessionExpired;

  static const _retried = 'auth_retried';
  static const _originOwner = 'auth_origin_owner';

  bool _sensitiveOriginMatches(RequestOptions options) {
    final owner = options.extra['sensitive_account_id'];
    if (owner == null) return true;
    return session.current?.user.id == owner &&
        identical(options.extra['sensitive_session'], session.current);
  }

  bool _matchesIdentity(RequestOptions options) {
    final owner =
        options.extra['sync_owner_id'] ?? options.extra['auth_owner_id'];
    final epoch =
        options.extra['sync_identity_epoch'] ??
        options.extra['auth_identity_epoch'];
    return (owner == null || owner == session.current?.user.id) &&
        (epoch == null || epoch == session.identityEpoch);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
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
    if (token != null && !options.headers.containsKey('Authorization')) {
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
        final saving = session.save(tokens);
        expected = session.current!;
        await saving;
      }
    } catch (_) {
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
