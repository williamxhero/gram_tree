import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/storage/device_id.dart';
import 'package:gram_tree/storage/secure_store.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'signed_probe_support.dart' as support;
import 'helpers.dart' show testUser;

/// Verifies the independent observer's outgoing bytes, without using RequestSigner.
class _SignedCountAdapter implements HttpClientAdapter {
  final credentials = <String, String>{};
  final received = <String>[];
  final nonces = <String>{};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bearer = options.headers['Authorization'] as String;
    final key = credentials[bearer];
    expect(key, isNotNull);
    expect(options.headers['X-Device-ID'], 'probe-device');
    final timestamp = options.headers['X-Request-Timestamp'] as String;
    expect(int.tryParse(timestamp), isNotNull);
    final nonce = options.headers['X-Request-Nonce'] as String;
    expect(nonces.add(nonce), isTrue);
    final crypto = DartCryptography.defaultInstance;
    final hash = (await crypto.sha256().hash(const [])).bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    String quote(String field) =>
        Uri.encodeComponent(field)
            .replaceAll('%2F', '/')
            .replaceAll('%3D', '=')
            .replaceAll('%26', '&');
    final mac = await crypto
        .hmac(crypto.sha256())
        .calculateMac(
          utf8.encode(
            [
              options.method,
              options.uri.path,
              options.uri.query,
              timestamp,
              nonce,
              hash,
            ].map(quote).join('\n'),
          ),
          secretKey: SecretKey(utf8.encode(key!)),
        );
    expect(
      options.headers['X-Request-Signature'],
      mac.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    );
    received.add(bearer);
    return ResponseBody.fromString(
      '{"count":2}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

TokenPair _login(String owner, String generation) => TokenPair(
  accessExpiresIn: 3600,
  accessToken: 'probe-$generation',
  refreshToken: 'refresh-$generation',
  requestSigningKey: 'key-$generation',
  user: UserOut.fromJson({...testUser().toJson(), 'id': owner}),
);

Future<int> _recipeSavedFactCount(Dio server, String token) async =>
    (await server.get<Map<String, dynamic>>(
          '/v1/dev/events/count',
          queryParameters: {'event_type': 'recipe.version_saved'},
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        )).data!['count']
        as int;

void main() {
  test(
    'business count observer follows persisted restore and A/B/A relogin',
    () async {
      final secure = MemorySecureStore();
      final seed = SessionStore(secure);
      await seed.save(_login('owner-a', 'a1'));
      seed.dispose();
      final restored = SessionStore(secure);
      addTearDown(restored.dispose);
      await restored.load();
      final container = ProviderContainer(
        overrides: [
          sessionStoreProvider.overrideWithValue(restored),
          deviceIdProvider.overrideWithValue('probe-device'),
        ],
      );
      addTearDown(container.dispose);
      final adapter = _SignedCountAdapter()
        ..credentials.addAll({
          'Bearer probe-a1': 'key-a1',
          'Bearer probe-b': 'key-b',
          'Bearer probe-a2': 'key-a2',
        });
      final server = Dio(BaseOptions(baseUrl: 'http://observer.test'))
        ..httpClientAdapter = adapter;
      addTearDown(() => server.close(force: true));
      support.registerProbeSession(
        server,
        restored.current!,
        deviceId: 'probe-device',
      );
      expect(await _recipeSavedFactCount(server, 'probe-a1'), 2);
      for (final login in [_login('owner-b', 'b'), _login('owner-a', 'a2')]) {
        await restored.clear();
        await restored.save(login);
        final token = support.accessTokenOf(container, server: server);
        expect(await _recipeSavedFactCount(server, token), 2);
      }
      expect(adapter.received, [
        'Bearer probe-a1',
        'Bearer probe-b',
        'Bearer probe-a2',
      ]);
      // Selecting a new account must not replace an explicitly captured bearer.
      expect(await _recipeSavedFactCount(server, 'probe-a1'), 2);
      expect(adapter.received.last, 'Bearer probe-a1');
    },
  );

  test('default event observer still registers its selected login', () async {
    final store = SessionStore(MemorySecureStore());
    addTearDown(store.dispose);
    await store.save(_login('owner-a', 'default'));
    final container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(store),
        deviceIdProvider.overrideWithValue('probe-device'),
      ],
    );
    addTearDown(container.dispose);
    final original = support.devServer.httpClientAdapter;
    final adapter = _SignedCountAdapter()
      ..credentials['Bearer probe-default'] = 'key-default';
    support.devServer.httpClientAdapter = adapter;
    addTearDown(() => support.devServer.httpClientAdapter = original);
    final token = support.accessTokenOf(container);
    expect(await _recipeSavedFactCount(support.devServer, token), 2);
    expect(adapter.received, ['Bearer probe-default']);
  });
}
