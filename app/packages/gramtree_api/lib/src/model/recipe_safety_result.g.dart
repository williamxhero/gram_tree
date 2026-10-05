// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_safety_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeSafetyResultCWProxy {
  RecipeSafetyResult allergens(List<String>? allergens);

  RecipeSafetyResult allergensIncomplete(bool? allergensIncomplete);

  RecipeSafetyResult canSave(bool? canSave);

  RecipeSafetyResult checkedAt(String checkedAt);

  RecipeSafetyResult claimBasis(String? claimBasis);

  RecipeSafetyResult findings(List<RecipeSafetyFinding>? findings);

  RecipeSafetyResult highRisk(bool? highRisk);

  RecipeSafetyResult prohibitedClaims(List<String>? prohibitedClaims);

  RecipeSafetyResult replacementAllergens(
    List<RecipeReplacementAllergens>? replacementAllergens,
  );

  RecipeSafetyResult rulesVersion(String rulesVersion);

  RecipeSafetyResult stale(bool? stale);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeSafetyResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeSafetyResult(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeSafetyResult call({
    List<String>? allergens,
    bool? allergensIncomplete,
    bool? canSave,
    String checkedAt,
    String? claimBasis,
    List<RecipeSafetyFinding>? findings,
    bool? highRisk,
    List<String>? prohibitedClaims,
    List<RecipeReplacementAllergens>? replacementAllergens,
    String rulesVersion,
    bool? stale,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeSafetyResult.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeSafetyResult.copyWith.fieldName(...)`
class _$RecipeSafetyResultCWProxyImpl implements _$RecipeSafetyResultCWProxy {
  const _$RecipeSafetyResultCWProxyImpl(this._value);

  final RecipeSafetyResult _value;

  @override
  RecipeSafetyResult allergens(List<String>? allergens) =>
      this(allergens: allergens);

  @override
  RecipeSafetyResult allergensIncomplete(bool? allergensIncomplete) =>
      this(allergensIncomplete: allergensIncomplete);

  @override
  RecipeSafetyResult canSave(bool? canSave) => this(canSave: canSave);

  @override
  RecipeSafetyResult checkedAt(String checkedAt) => this(checkedAt: checkedAt);

  @override
  RecipeSafetyResult claimBasis(String? claimBasis) =>
      this(claimBasis: claimBasis);

  @override
  RecipeSafetyResult findings(List<RecipeSafetyFinding>? findings) =>
      this(findings: findings);

  @override
  RecipeSafetyResult highRisk(bool? highRisk) => this(highRisk: highRisk);

  @override
  RecipeSafetyResult prohibitedClaims(List<String>? prohibitedClaims) =>
      this(prohibitedClaims: prohibitedClaims);

  @override
  RecipeSafetyResult replacementAllergens(
    List<RecipeReplacementAllergens>? replacementAllergens,
  ) => this(replacementAllergens: replacementAllergens);

  @override
  RecipeSafetyResult rulesVersion(String rulesVersion) =>
      this(rulesVersion: rulesVersion);

  @override
  RecipeSafetyResult stale(bool? stale) => this(stale: stale);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeSafetyResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeSafetyResult(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeSafetyResult call({
    Object? allergens = const $CopyWithPlaceholder(),
    Object? allergensIncomplete = const $CopyWithPlaceholder(),
    Object? canSave = const $CopyWithPlaceholder(),
    Object? checkedAt = const $CopyWithPlaceholder(),
    Object? claimBasis = const $CopyWithPlaceholder(),
    Object? findings = const $CopyWithPlaceholder(),
    Object? highRisk = const $CopyWithPlaceholder(),
    Object? prohibitedClaims = const $CopyWithPlaceholder(),
    Object? replacementAllergens = const $CopyWithPlaceholder(),
    Object? rulesVersion = const $CopyWithPlaceholder(),
    Object? stale = const $CopyWithPlaceholder(),
  }) {
    return RecipeSafetyResult(
      allergens: allergens == const $CopyWithPlaceholder()
          ? _value.allergens
          // ignore: cast_nullable_to_non_nullable
          : allergens as List<String>?,
      allergensIncomplete: allergensIncomplete == const $CopyWithPlaceholder()
          ? _value.allergensIncomplete
          // ignore: cast_nullable_to_non_nullable
          : allergensIncomplete as bool?,
      canSave: canSave == const $CopyWithPlaceholder()
          ? _value.canSave
          // ignore: cast_nullable_to_non_nullable
          : canSave as bool?,
      checkedAt: checkedAt == const $CopyWithPlaceholder()
          ? _value.checkedAt
          // ignore: cast_nullable_to_non_nullable
          : checkedAt as String,
      claimBasis: claimBasis == const $CopyWithPlaceholder()
          ? _value.claimBasis
          // ignore: cast_nullable_to_non_nullable
          : claimBasis as String?,
      findings: findings == const $CopyWithPlaceholder()
          ? _value.findings
          // ignore: cast_nullable_to_non_nullable
          : findings as List<RecipeSafetyFinding>?,
      highRisk: highRisk == const $CopyWithPlaceholder()
          ? _value.highRisk
          // ignore: cast_nullable_to_non_nullable
          : highRisk as bool?,
      prohibitedClaims: prohibitedClaims == const $CopyWithPlaceholder()
          ? _value.prohibitedClaims
          // ignore: cast_nullable_to_non_nullable
          : prohibitedClaims as List<String>?,
      replacementAllergens: replacementAllergens == const $CopyWithPlaceholder()
          ? _value.replacementAllergens
          // ignore: cast_nullable_to_non_nullable
          : replacementAllergens as List<RecipeReplacementAllergens>?,
      rulesVersion: rulesVersion == const $CopyWithPlaceholder()
          ? _value.rulesVersion
          // ignore: cast_nullable_to_non_nullable
          : rulesVersion as String,
      stale: stale == const $CopyWithPlaceholder()
          ? _value.stale
          // ignore: cast_nullable_to_non_nullable
          : stale as bool?,
    );
  }
}

extension $RecipeSafetyResultCopyWith on RecipeSafetyResult {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeSafetyResult.copyWith(...)` or like so:`instanceOfRecipeSafetyResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeSafetyResultCWProxy get copyWith =>
      _$RecipeSafetyResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeSafetyResult _$RecipeSafetyResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RecipeSafetyResult',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['checked_at', 'rules_version']);
        final val = RecipeSafetyResult(
          allergens: $checkedConvert(
            'allergens',
            (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
          ),
          allergensIncomplete: $checkedConvert(
            'allergens_incomplete',
            (v) => v as bool? ?? false,
          ),
          canSave: $checkedConvert('can_save', (v) => v as bool? ?? true),
          checkedAt: $checkedConvert('checked_at', (v) => v as String),
          claimBasis: $checkedConvert('claim_basis', (v) => v as String?),
          findings: $checkedConvert(
            'findings',
            (v) => (v as List<dynamic>?)
                ?.map(
                  (e) =>
                      RecipeSafetyFinding.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
          ),
          highRisk: $checkedConvert('high_risk', (v) => v as bool? ?? false),
          prohibitedClaims: $checkedConvert(
            'prohibited_claims',
            (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
          ),
          replacementAllergens: $checkedConvert(
            'replacement_allergens',
            (v) => (v as List<dynamic>?)
                ?.map(
                  (e) => RecipeReplacementAllergens.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList(),
          ),
          rulesVersion: $checkedConvert('rules_version', (v) => v as String),
          stale: $checkedConvert('stale', (v) => v as bool? ?? false),
        );
        return val;
      },
      fieldKeyMap: const {
        'allergensIncomplete': 'allergens_incomplete',
        'canSave': 'can_save',
        'checkedAt': 'checked_at',
        'claimBasis': 'claim_basis',
        'highRisk': 'high_risk',
        'prohibitedClaims': 'prohibited_claims',
        'replacementAllergens': 'replacement_allergens',
        'rulesVersion': 'rules_version',
      },
    );

Map<String, dynamic> _$RecipeSafetyResultToJson(RecipeSafetyResult instance) =>
    <String, dynamic>{
      'allergens': ?instance.allergens,
      'allergens_incomplete': ?instance.allergensIncomplete,
      'can_save': ?instance.canSave,
      'checked_at': instance.checkedAt,
      'claim_basis': ?instance.claimBasis,
      'findings': ?instance.findings?.map((e) => e.toJson()).toList(),
      'high_risk': ?instance.highRisk,
      'prohibited_claims': ?instance.prohibitedClaims,
      'replacement_allergens': ?instance.replacementAllergens
          ?.map((e) => e.toJson())
          .toList(),
      'rules_version': instance.rulesVersion,
      'stale': ?instance.stale,
    };
