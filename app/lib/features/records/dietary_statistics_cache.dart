import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../../storage/secure_store.dart';

/// Last successful owner-scoped dietary result. Pending writes never enter this cache.
class DietaryStatisticsCache {
  DietaryStatisticsCache(this._secure);
  final SecureStore _secure;
  Future<void> _persistence = Future<void>.value();
  static final _encryption = AesGcm.with256bits().toSync();
  static const _prefix = 'v1:';

  static String keyFor(String ownerId, String period) =>
      'dietary_statistics_cache_v1:$ownerId:$period';

  Future<Map<String, dynamic>?> read(String ownerId, String period) async {
    await _persistence;
    final raw = await _secure.read(keyFor(ownerId, period));
    if (raw == null) return null;
    try {
      final box = SecretBox.fromConcatenation(
        base64Url.decode(raw.substring(_prefix.length)),
        nonceLength: _encryption.nonceLength,
        macLength: _encryption.macAlgorithm.macLength,
      );
      final clear = await _encryption.decrypt(
        box,
        secretKey: await _key(ownerId, period, create: false),
        aad: utf8.encode('$ownerId:$period'),
      );
      final value = jsonDecode(utf8.decode(clear));
      return value is Map ? Map<String, dynamic>.from(value) : null;
    } catch (_) {
      await clear(ownerId, period);
      return null;
    }
  }

  Future<void> write(
    String ownerId,
    String period,
    Map<String, dynamic> value, {
    required bool Function() stillCurrent,
  }) {
    final operation = _persistence.then((_) async {
      if (!stillCurrent()) return;
      final box = await _encryption.encrypt(
        utf8.encode(jsonEncode(value)),
        secretKey: await _key(ownerId, period),
        aad: utf8.encode('$ownerId:$period'),
      );
      if (stillCurrent()) {
        await _secure.write(
          keyFor(ownerId, period),
          '$_prefix${base64UrlEncode(box.concatenation())}',
        );
      }
    });
    _persistence = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> clear(String ownerId, String period) {
    final operation = _persistence.then((_) async {
      await _secure.delete(keyFor(ownerId, period));
      await _secure.delete('${keyFor(ownerId, period)}:key');
    });
    _persistence = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> clearOwner(String ownerId) async {
    for (final period in ['week', 'month', 'year']) {
      await clear(ownerId, period);
    }
  }

  Future<SecretKey> _key(
    String ownerId,
    String period, {
    bool create = true,
  }) async {
    final keyName = '${keyFor(ownerId, period)}:key';
    final existing = await _secure.read(keyName);
    if (existing != null) return SecretKey(base64Url.decode(existing));
    if (!create) throw const FormatException('missing cache key');
    final key = await _encryption.newSecretKey();
    await _secure.write(keyName, base64UrlEncode(await key.extractBytes()));
    return key;
  }
}
