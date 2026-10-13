import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/api/request_signing.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/storage/secure_store.dart';

import 'helpers.dart';

void main() {
  test('canonical bytes keep raw query and match server field escaping', () {
    final bytes = RequestSigner.canonicalMessage(
      'get',
      '/v1/菜谱',
      'q=a%20b&x=1',
      1700000000,
      'nonce 1',
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );

    expect(
      utf8.decode(bytes),
      'GET\n/v1/%E8%8F%9C%E8%B0%B1\nq=a%2520b&x=1\n1700000000\nnonce%201\n'
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );
  });

  test(
    'canonical fields percent-encode literal percent to avoid collisions',
    () {
      final a = utf8.decode(
        RequestSigner.canonicalMessage('GET', '/v1/x', 'q=a+b', 1, 'n', 'h'),
      );
      final b = utf8.decode(
        RequestSigner.canonicalMessage('GET', '/v1/x', 'q=a%2Bb', 1, 'n', 'h'),
      );
      expect(a, contains('q=a%2Bb'));
      expect(b, contains('q=a%252Bb'));
      expect(a, isNot(b));
    },
  );

  test(
    'signing adds a fresh nonce and an HMAC over the exact request body',
    () async {
      final secure = MemorySecureStore({
        sessionStorageKey: jsonEncode({
          'access_token': 'access',
          'refresh_token': 'refresh',
          'request_signing_key': 'opaque-hex-key',
          'user': testUser().toJson(),
        }),
      });
      final session = SessionStore(secure);
      await session.load();
      var calls = 0;
      final signer = RequestSigner(
        session,
        now: () => DateTime.utc(2026, 1, 2, 3, 4, 5 + calls++),
      );

      RequestOptions request() => RequestOptions(
        path: '/v1/me',
        baseUrl: 'https://api.example.test',
        method: 'POST',
        data: '{"value":1}',
        headers: {'Authorization': 'Bearer access'},
      );

      final first = request();
      await signer.sign(first);
      final second = request();
      await signer.sign(second);

      expect(first.headers[signingTimestampHeader], '1767323045');
      expect(
        first.headers[signingNonceHeader],
        isNot(second.headers[signingNonceHeader]),
      );
      expect(
        first.headers[signingSignatureHeader],
        matches(RegExp(r'^[0-9a-f]{64}$')),
      );
      expect(
        second.headers[signingSignatureHeader],
        matches(RegExp(r'^[0-9a-f]{64}$')),
      );
      await session.clear();
    },
  );
}
