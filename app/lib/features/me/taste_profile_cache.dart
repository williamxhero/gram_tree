import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../storage/secure_store.dart';

/// The private profile cache is deliberately separate from the event queue.
/// It is a last-successful, read-only snapshot; it never contains pending writes.
class TasteProfileCacheSnapshot {
  const TasteProfileCacheSnapshot({
    required this.accountId,
    required this.cachedAt,
    this.profile,
    this.allergies,
    this.constraints,
    this.family,
    this.personalizations = const {},
    this.personalizationAuthorizationFloor = 0,
  });

  final String accountId;
  final DateTime cachedAt;
  final TasteProfileOut? profile;
  final AllergiesOut? allergies;
  final CookingConstraintsOut? constraints;
  final FamilyMembersOut? family;
  final Map<String, dynamic> personalizations;
  // Retain only the revocation boundary, not the withdrawn sensitive values.
  final int personalizationAuthorizationFloor;

  int get nextAuthorizationFloor => math.max(
    personalizationAuthorizationFloor,
    math.max(
          allergies?.authorizationVersion ?? 0,
          family?.authorizationVersion ?? 0,
        ) +
        1,
  );

  factory TasteProfileCacheSnapshot.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final allergies = json['allergies'];
    final constraints = json['constraints'];
    final family = json['family'];
    return TasteProfileCacheSnapshot(
      accountId: json['account_id'] as String,
      personalizationAuthorizationFloor:
          json['personalization_authorization_floor'] as int? ?? 0,
      personalizations: Map<String, dynamic>.from(
        json['personalizations'] as Map? ?? {},
      ),
      cachedAt: DateTime.parse(json['cached_at'] as String).toUtc(),
      profile: profile is Map
          ? TasteProfileOut.fromJson(Map<String, dynamic>.from(profile))
          : null,
      allergies: allergies is Map
          ? AllergiesOut.fromJson(Map<String, dynamic>.from(allergies))
          : null,
      constraints: constraints is Map
          ? CookingConstraintsOut.fromJson(
              Map<String, dynamic>.from(constraints),
            )
          : null,
      family: family is Map
          ? FamilyMembersOut.fromJson(Map<String, dynamic>.from(family))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'account_id': accountId,
    'cached_at': cachedAt.toUtc().toIso8601String(),
    if (profile != null) 'profile': profile!.toJson(),
    if (allergies != null) 'allergies': allergies!.toJson(),
    if (constraints != null) 'constraints': constraints!.toJson(),
    if (family != null) 'family': family!.toJson(),
    'personalizations': personalizations,
    'personalization_authorization_floor': personalizationAuthorizationFloor,
  };

  bool get hasCurrentProfile =>
      profile != null &&
      (allergies == null || allergies!.profileVersion == profile!.version) &&
      (constraints == null ||
          constraints!.profileVersion == profile!.version) &&
      (family == null || family!.profileVersion == profile!.version);

  bool get hasAuthorizedSensitive =>
      allergies?.consentId != null &&
      family?.consentId == allergies?.consentId &&
      family?.authorizationVersion == allergies?.authorizationVersion;

  TasteProfileCacheSnapshot copyWith({
    DateTime? cachedAt,
    TasteProfileOut? profile,
    AllergiesOut? allergies,
    CookingConstraintsOut? constraints,
    FamilyMembersOut? family,
    bool clearAllergies = false,
    bool clearFamily = false,
    Map<String, dynamic>? personalizations,
    int? personalizationAuthorizationFloor,
  }) => TasteProfileCacheSnapshot(
    accountId: accountId,
    cachedAt: cachedAt ?? this.cachedAt,
    profile: profile ?? this.profile,
    allergies: clearAllergies ? null : allergies ?? this.allergies,
    constraints: constraints ?? this.constraints,
    family: clearFamily ? null : family ?? this.family,
    personalizationAuthorizationFloor:
        personalizationAuthorizationFloor ??
        ((clearAllergies || clearFamily) &&
                (this.allergies?.consentId != null ||
                    this.family?.consentId != null)
            ? nextAuthorizationFloor
            : this.personalizationAuthorizationFloor),
    personalizations:
        (profile != null && profile.version != this.profile?.version) ||
            (allergies != null &&
                (allergies.profileVersion != this.allergies?.profileVersion ||
                    allergies.authorizationVersion !=
                        this.allergies?.authorizationVersion)) ||
            (family != null &&
                (family.profileVersion != this.family?.profileVersion ||
                    family.authorizationVersion !=
                        this.family?.authorizationVersion)) ||
            (constraints != null &&
                constraints.profileVersion !=
                    this.constraints?.profileVersion) ||
            ((clearAllergies || clearFamily) &&
                (this.allergies?.consentId != null ||
                    this.family?.consentId != null))
        ? const {}
        : personalizations ?? this.personalizations,
  );
}

/// Secure, account-namespaced storage for the last successful profile reads.
/// The web implementation goes through the same SecureStore boundary, allowing
/// tests and the browser adapter to provide a safe non-platform implementation.
class TasteProfileCache {
  TasteProfileCache(this._secure);

  final SecureStore _secure;
  Future<void> _persistence = Future<void>.value();

  // Keep the implementation identical on VM, mobile, and browser tests. The
  // pure-Dart implementation avoids depending on the browser test runner's
  // Web Crypto context while retaining AES-GCM authenticated encryption.
  static final _encryption = AesGcm.with256bits().toSync();
  static const _encryptedPrefix = 'v2:';
  static const _keyPrefix = 'taste_profile_cache_key_v1:';

  static String keyFor(String accountId) => 'taste_profile_cache_v1:$accountId';

  Future<TasteProfileCacheSnapshot?> read(String accountId) async {
    await _persistence;
    final raw = await _secure.read(keyFor(accountId));
    if (raw == null) return null;
    try {
      return await _decrypt(accountId, raw);
    } catch (_) {
      // A corrupt snapshot is not a reason to block login or leak stale data.
      await clear(accountId);
      return null;
    }
  }

  Future<void> writeProfile(
    String accountId,
    TasteProfileOut profile, {
    required bool Function() stillCurrent,
  }) => _write(
    accountId,
    stillCurrent,
    (old) => (old ?? _empty(accountId)).copyWith(
      cachedAt: DateTime.now().toUtc(),
      profile: profile,
    ),
  );

  Future<void> writeAllergies(
    String accountId,
    AllergiesOut value, {
    required bool Function() stillCurrent,
  }) => _write(
    accountId,
    stillCurrent,
    (old) => value.consentId == null
        ? old?.copyWith(
            cachedAt: DateTime.now().toUtc(),
            clearAllergies: true,
            clearFamily: true,
          )
        : (old ?? _empty(accountId)).copyWith(
            cachedAt: DateTime.now().toUtc(),
            allergies: value,
          ),
  );

  Future<void> writeConstraints(
    String accountId,
    CookingConstraintsOut value, {
    required bool Function() stillCurrent,
  }) => _write(
    accountId,
    stillCurrent,
    (old) => (old ?? _empty(accountId)).copyWith(
      cachedAt: DateTime.now().toUtc(),
      constraints: value,
    ),
  );

  Future<void> writeFamily(
    String accountId,
    FamilyMembersOut value, {
    required bool Function() stillCurrent,
  }) => _write(
    accountId,
    stillCurrent,
    (old) => value.consentId == null
        ? old?.copyWith(
            cachedAt: DateTime.now().toUtc(),
            clearAllergies: true,
            clearFamily: true,
          )
        : (old ?? _empty(accountId)).copyWith(
            cachedAt: DateTime.now().toUtc(),
            family: value,
          ),
  );

  Future<void> removeFamilyMember(
    String accountId,
    String memberId, {
    required bool Function() stillCurrent,
  }) => _write(accountId, stillCurrent, (old) {
    final family = old?.family;
    if (old == null || family == null) return old;
    return old.copyWith(
      cachedAt: DateTime.now().toUtc(),
      family: family.copyWith(
        items: family.items.where((item) => item.id != memberId).toList(),
      ),
    );
  });

  Future<void> writePersonalization(
    String accountId,
    String key,
    Map<String, dynamic> value, {
    required bool Function() stillCurrent,
  }) => _write(accountId, stillCurrent, (old) {
    final current = old ?? _empty(accountId);
    if (!_personalizationMatches(current, value)) return old;
    return current.copyWith(
      cachedAt: DateTime.now().toUtc(),
      personalizations: {...current.personalizations, key: value},
    );
  });

  Future<Map<String, dynamic>?> readPersonalization(
    String accountId,
    String key,
  ) async {
    final current = await read(accountId);
    final value = current?.personalizations[key];
    if (current == null || value is! Map) return null;
    final result = Map<String, dynamic>.from(value);
    return _personalizationMatches(current, result) ? result : null;
  }

  bool _personalizationMatches(
    TasteProfileCacheSnapshot current,
    Map<String, dynamic> value,
  ) {
    final profileVersions = [
      current.profile?.version,
      current.allergies?.profileVersion,
      current.constraints?.profileVersion,
      current.family?.profileVersion,
    ].whereType<int>();
    final authorizationVersions = [
      current.allergies?.authorizationVersion,
      current.family?.authorizationVersion,
    ].whereType<int>();
    final authorization = value['authorization_version'];
    return authorization is int &&
        authorization >= current.personalizationAuthorizationFloor &&
        (profileVersions.isEmpty ||
            value['profile_version'] == profileVersions.reduce(math.max)) &&
        (authorizationVersions.isEmpty ||
            authorization == authorizationVersions.reduce(math.max));
  }

  Future<void> clearSensitive(
    String accountId, {
    required bool Function() stillCurrent,
  }) => _write(
    accountId,
    stillCurrent,
    (old) => (old ?? _empty(accountId)).copyWith(
      cachedAt: DateTime.now().toUtc(),
      clearAllergies: true,
      clearFamily: true,
      personalizations: const {},
      personalizationAuthorizationFloor:
          (old ?? _empty(accountId)).nextAuthorizationFloor,
    ),
  );

  Future<void> clear(String accountId) {
    final operation = _persistence.then((_) async {
      await _secure.delete(keyFor(accountId));
      await _secure.delete(_keyFor(accountId));
    });
    _persistence = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> _write(
    String accountId,
    bool Function() stillCurrent,
    TasteProfileCacheSnapshot? Function(TasteProfileCacheSnapshot?) update,
  ) {
    final operation = _persistence.then((_) async {
      if (!stillCurrent()) return;
      final old = await _readUnlocked(accountId);
      final value = update(old);
      if (!stillCurrent()) return;
      if (value == null) {
        await _secure.delete(keyFor(accountId));
      } else {
        await _secure.write(
          keyFor(accountId),
          await _encrypt(value, accountId),
        );
      }
    });
    _persistence = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<TasteProfileCacheSnapshot?> _readUnlocked(String accountId) async {
    final raw = await _secure.read(keyFor(accountId));
    if (raw == null) return null;
    try {
      return await _decrypt(accountId, raw);
    } catch (_) {
      return null;
    }
  }

  Future<String> _encrypt(
    TasteProfileCacheSnapshot value,
    String accountId,
  ) async {
    final key = await _secretKey(accountId);
    final box = await _encryption.encrypt(
      utf8.encode(jsonEncode(value.toJson())),
      secretKey: key,
      aad: utf8.encode(accountId),
    );
    return '$_encryptedPrefix${base64UrlEncode(box.concatenation())}';
  }

  Future<TasteProfileCacheSnapshot> _decrypt(
    String accountId,
    String raw,
  ) async {
    if (!raw.startsWith(_encryptedPrefix)) {
      throw const FormatException('Unsupported cache format');
    }
    final box = SecretBox.fromConcatenation(
      base64Url.decode(raw.substring(_encryptedPrefix.length)),
      nonceLength: _encryption.nonceLength,
      macLength: _encryption.macAlgorithm.macLength,
    );
    final clearText = await _encryption.decrypt(
      box,
      secretKey: await _secretKey(accountId, create: false),
      aad: utf8.encode(accountId),
    );
    final value = TasteProfileCacheSnapshot.fromJson(
      jsonDecode(utf8.decode(clearText)) as Map<String, dynamic>,
    );
    if (value.accountId != accountId) {
      throw const FormatException('Mismatched cache account');
    }
    return value;
  }

  Future<SecretKey> _secretKey(String accountId, {bool create = true}) async {
    final stored = await _secure.read(_keyFor(accountId));
    if (stored != null) {
      final bytes = base64Url.decode(stored);
      if (bytes.length != _encryption.secretKeyLength) {
        throw const FormatException('Invalid cache key');
      }
      return SecretKey(bytes);
    }
    if (!create) throw const FormatException('Missing cache key');

    final key = await _encryption.newSecretKey();
    final bytes = await key.extractBytes();
    await _secure.write(_keyFor(accountId), base64UrlEncode(bytes));
    return key;
  }

  static String _keyFor(String accountId) => '$_keyPrefix$accountId';

  static TasteProfileCacheSnapshot _empty(String accountId) =>
      TasteProfileCacheSnapshot(
        accountId: accountId,
        cachedAt: DateTime.now().toUtc(),
      );
}

final tasteProfileCacheProvider = Provider<TasteProfileCache>(
  (ref) => TasteProfileCache(ref.watch(secureStoreProvider)),
);
