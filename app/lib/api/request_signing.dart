import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';

import '../auth/session.dart';

const signingTimestampHeader = 'X-Request-Timestamp';
const signingNonceHeader = 'X-Request-Nonce';
const signingSignatureHeader = 'X-Request-Signature';

class RequestSigner {
  RequestSigner(
    this._session, {
    DateTime Function()? now,
    Cryptography? cryptography,
  }) : _now = now ?? DateTime.now,
       _cryptography = cryptography ?? Cryptography.instance;

  final SessionStore _session;
  final DateTime Function() _now;
  final Cryptography _cryptography;
  final Random _random = Random.secure();
  Duration _serverOffset = Duration.zero;

  Duration get serverOffset => _serverOffset;

  Future<void> sign(RequestOptions options, {Transformer? transformer}) async {
    final captured = _session.current;
    final revocation = options.extra['auth_revocation_session'];
    final credential =
        options.extra['auth_revocation'] == true &&
            options.method == 'POST' &&
            options.uri.path == '/v1/auth/logout' &&
            revocation is AuthSession
        ? revocation
        : captured;
    if (options.headers['Authorization'] == null) return;
    final owner =
        options.extra['sync_owner_id'] ?? options.extra['auth_owner_id'];
    final epoch =
        options.extra['sync_identity_epoch'] ??
        options.extra['auth_identity_epoch'];
    final revoking =
        identical(credential, revocation) && revocation is AuthSession;
    final sensitiveOwner = options.extra['sensitive_account_id'];
    final identity = _session.identity;
    if (!revoking &&
        ((owner != null && owner != captured?.user.id) ||
            (epoch != null && epoch != _session.identityEpoch) ||
            (sensitiveOwner != null &&
                (sensitiveOwner != captured?.user.id ||
                    (options.extra['sensitive_identity_epoch'] != null
                        ? options.extra['sensitive_identity_epoch'] !=
                              _session.identityEpoch
                        : !identical(
                            options.extra['sensitive_session'],
                            captured,
                          )))) ||
            (options.extra['sync_owner_id'] != null &&
                (identity == null || !_session.canUpload(identity))))) {
      throw StateError('account_changed');
    }
    if (credential == null ||
        options.headers['Authorization'] !=
            'Bearer ${credential.accessToken}') {
      throw StateError('account_changed');
    }
    final key = credential.requestSigningKey;
    // Older saved sessions have no credential until their next refresh. Never
    // manufacture a key or silently sign a different account's bearer token.
    if (key == null || key.isEmpty) throw StateError('signing_key_missing');
    final identityEpoch = _session.identityEpoch;
    options.extra.putIfAbsent('auth_owner_id', () => credential.user.id);
    options.extra.putIfAbsent('auth_identity_epoch', () => identityEpoch);
    // Materialize exactly the bytes Dio would send, including multipart boundary
    // and custom encoders. Uint8List bypasses a second transform and permits
    // bounded security/auth retries without consuming an upload stream twice.
    if (options.data != null && options.data is! Uint8List) {
      final data = options.data;
      final List<int> bytes;
      if (data is FormData) {
        options.contentType =
            '${Headers.multipartFormDataContentType}; boundary=${data.boundary}';
        bytes = await data.readAsBytes();
      } else if (data is Stream<List<int>>) {
        bytes = await data.fold<List<int>>(
          <int>[],
          (buffer, chunk) => buffer..addAll(chunk),
        );
      } else {
        if (data is Map || data is List) {
          options.contentType ??= Headers.jsonContentType;
        }
        final transformed = transformer != null
            ? await transformer.transformRequest(options)
            : await Transformer.defaultTransformRequest(options, jsonEncode);
        bytes = options.requestEncoder == null
            ? utf8.encode(transformed)
            : await options.requestEncoder!(transformed, options);
      }
      options.data = Uint8List.fromList(bytes);
      options.requestEncoder = null;
    }
    final timestamp =
        (_now().toUtc().add(_serverOffset).millisecondsSinceEpoch ~/ 1000);
    final nonce = base64Url
        .encode(List<int>.generate(24, (_) => _random.nextInt(256)))
        .replaceAll('=', '');
    final body = _bodyBytes(options.data);
    final message = canonicalMessage(
      options.method,
      options.uri.path,
      options.uri.hasQuery ? options.uri.query : '',
      timestamp,
      nonce,
      (await _cryptography.sha256().hash(body)).bytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join(),
    );
    final hmac = _cryptography.hmac(_cryptography.sha256());
    final mac = await hmac.calculateMac(
      message,
      secretKey: SecretKey(utf8.encode(key)),
    );
    // Crypto may yield to a logout, account switch, or credential rotation.
    // Never dispatch work signed for a stale login after that boundary.
    if (!revoking &&
        (_session.identityEpoch != identityEpoch ||
            !identical(_session.current, captured) ||
            (options.extra['sync_owner_id'] != null &&
                (identity == null || !_session.canUpload(identity))))) {
      throw StateError('account_changed');
    }
    options.headers[signingTimestampHeader] = '$timestamp';
    options.headers[signingNonceHeader] = nonce;
    options.headers[signingSignatureHeader] = mac.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  bool correctServerTime(Object? raw) {
    if (raw is! String) return false;
    final serverTime = DateTime.tryParse(raw)?.toUtc();
    if (serverTime == null) return false;
    _serverOffset = serverTime.difference(_now().toUtc());
    return true;
  }

  static List<int> _bodyBytes(Object? body) {
    if (body == null) return const [];
    if (body is List<int>) return body;
    if (body is String) return utf8.encode(body);
    return utf8.encode(jsonEncode(body));
  }

  static List<int> canonicalMessage(
    String method,
    String path,
    String query,
    int timestamp,
    String nonce,
    String bodyHash,
  ) => utf8.encode(
    [
      method.toUpperCase(),
      path,
      query,
      '$timestamp',
      nonce,
      bodyHash,
    ].map(_quoteField).join('\n'),
  );

  static String _quoteField(String value) {
    final bytes = utf8.encode(value);
    final out = StringBuffer();
    for (final byte in bytes) {
      final safe =
          (byte >= 0x41 && byte <= 0x5a) ||
          (byte >= 0x61 && byte <= 0x7a) ||
          (byte >= 0x30 && byte <= 0x39) ||
          '-_.~/=&'.codeUnits.contains(byte);
      if (safe) {
        out.writeCharCode(byte);
      } else {
        out.write('%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      }
    }
    return out.toString();
  }
}
