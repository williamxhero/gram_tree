import 'dart:async';
import 'dart:convert';

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
  });

  final String accountId;
  final DateTime cachedAt;
  final TasteProfileOut? profile;
  final AllergiesOut? allergies;
  final CookingConstraintsOut? constraints;
  final FamilyMembersOut? family;

  factory TasteProfileCacheSnapshot.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final allergies = json['allergies'];
    final constraints = json['constraints'];
    final family = json['family'];
    return TasteProfileCacheSnapshot(
      accountId: json['account_id'] as String,
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
  }) => TasteProfileCacheSnapshot(
    accountId: accountId,
    cachedAt: cachedAt ?? this.cachedAt,
    profile: profile ?? this.profile,
    allergies: clearAllergies ? null : allergies ?? this.allergies,
    constraints: constraints ?? this.constraints,
    family: clearFamily ? null : family ?? this.family,
  );
}

/// Secure, account-namespaced storage for the last successful profile reads.
/// The web implementation goes through the same SecureStore boundary, allowing
/// tests and the browser adapter to provide a safe non-platform implementation.
class TasteProfileCache {
  TasteProfileCache(this._secure);

  final SecureStore _secure;
  Future<void> _persistence = Future<void>.value();

  static String keyFor(String accountId) => 'taste_profile_cache_v1:$accountId';

  Future<TasteProfileCacheSnapshot?> read(String accountId) async {
    await _persistence;
    final raw = await _secure.read(keyFor(accountId));
    if (raw == null) return null;
    try {
      final value = TasteProfileCacheSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return value.accountId == accountId ? value : null;
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
        ? old?.copyWith(cachedAt: DateTime.now().toUtc(), clearFamily: true)
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

  Future<void> clearSensitive(
    String accountId, {
    required bool Function() stillCurrent,
  }) => _write(
    accountId,
    stillCurrent,
    (old) => old?.copyWith(
      cachedAt: DateTime.now().toUtc(),
      clearAllergies: true,
      clearFamily: true,
    ),
  );

  Future<void> clear(String accountId) {
    final operation = _persistence.then(
      (_) => _secure.delete(keyFor(accountId)),
    );
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
        await _secure.write(keyFor(accountId), jsonEncode(value.toJson()));
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
      final value = TasteProfileCacheSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return value.accountId == accountId ? value : null;
    } catch (_) {
      return null;
    }
  }

  static TasteProfileCacheSnapshot _empty(String accountId) =>
      TasteProfileCacheSnapshot(
        accountId: accountId,
        cachedAt: DateTime.now().toUtc(),
      );
}

final tasteProfileCacheProvider = Provider<TasteProfileCache>(
  (ref) => TasteProfileCache(ref.watch(secureStoreProvider)),
);
