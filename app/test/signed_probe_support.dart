import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gram_tree/api/request_signing.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/config/app_config.dart';
import 'package:gram_tree/storage/device_id.dart';
import 'package:gram_tree/storage/secure_store.dart';

/// Independent acceptance observer, not the App's consent/offline transport.
final devServer = Dio(
  BaseOptions(baseUrl: AppConfig.fromEnvironment().apiBaseUrl),
);

/// Register the selected login on the observer that will actually send it.
/// A standalone restart uses its own Dio; ordinary event tests use [devServer].
String accessTokenOf(ProviderContainer container, {Dio? server}) {
  final session = container.read(sessionStoreProvider).current!;
  registerProbeSession(
    server ?? devServer,
    session,
    deviceId: container.read(deviceIdProvider),
  );
  return session.accessToken;
}

Future<int> recipeSavedFactCount(Dio server, String token) async =>
    (await server.get<Map<String, dynamic>>(
          '/v1/dev/events/count',
          queryParameters: {'event_type': 'recipe.version_saved'},
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        )).data!['count']
        as int;

/// Independent HTTP observers retain each login's full credential. Selecting a
/// bearer never substitutes the App's current account or its offline transport.
Map<String, dynamic> registerProbeSession(
  Dio server,
  AuthSession session, {
  required String deviceId,
}) {
  final existing = server.interceptors.whereType<_ProbeSigningInterceptor>();
  final interceptor = existing.isEmpty
      ? (_ProbeSigningInterceptor()..install(server))
      : existing.single;
  interceptor.sessions['Bearer ${session.accessToken}'] = (
    session: session,
    deviceId: deviceId,
  );
  return {'Authorization': 'Bearer ${session.accessToken}'};
}

class _ProbeSigningInterceptor extends Interceptor {
  final sessions = <String, ({AuthSession session, String deviceId})>{};
  late final Dio _server;

  void install(Dio server) {
    _server = server;
    server.interceptors.add(this);
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Generated optional query values must be omitted, just as in the App's
    // base transport; an empty cursor is a different, invalid server input.
    options.queryParameters.removeWhere(
      (key, value) => value == null || value == '',
    );
    final authorization = options.headers['Authorization'];
    if (authorization == null) {
      handler.next(options);
      return;
    }
    final credential = sessions[authorization];
    if (credential == null) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'probe_credential_missing',
        ),
      );
      return;
    }
    final store = SessionStore(
      MemorySecureStore({
        sessionStorageKey: jsonEncode(credential.session.toJson()),
      }),
    );
    try {
      await store.load();
      options.headers['X-Device-ID'] = credential.deviceId;
      await RequestSigner(store)
          .sign(options, transformer: _server.transformer);
      handler.next(options);
    } catch (error, stack) {
      handler.reject(
        DioException(requestOptions: options, error: error, stackTrace: stack),
      );
    } finally {
      store.dispose();
    }
  }
}
