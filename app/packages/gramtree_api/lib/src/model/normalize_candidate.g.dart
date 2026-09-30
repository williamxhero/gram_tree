// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'normalize_candidate.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NormalizeCandidateCWProxy {
  NormalizeCandidate ingredientId(String ingredientId);

  NormalizeCandidate standardName(String standardName);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NormalizeCandidate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NormalizeCandidate(...).copyWith(id: 12, name: "My name")
  /// ````
  NormalizeCandidate call({String ingredientId, String standardName});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfNormalizeCandidate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfNormalizeCandidate.copyWith.fieldName(...)`
class _$NormalizeCandidateCWProxyImpl implements _$NormalizeCandidateCWProxy {
  const _$NormalizeCandidateCWProxyImpl(this._value);

  final NormalizeCandidate _value;

  @override
  NormalizeCandidate ingredientId(String ingredientId) =>
      this(ingredientId: ingredientId);

  @override
  NormalizeCandidate standardName(String standardName) =>
      this(standardName: standardName);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NormalizeCandidate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NormalizeCandidate(...).copyWith(id: 12, name: "My name")
  /// ````
  NormalizeCandidate call({
    Object? ingredientId = const $CopyWithPlaceholder(),
    Object? standardName = const $CopyWithPlaceholder(),
  }) {
    return NormalizeCandidate(
      ingredientId: ingredientId == const $CopyWithPlaceholder()
          ? _value.ingredientId
          // ignore: cast_nullable_to_non_nullable
          : ingredientId as String,
      standardName: standardName == const $CopyWithPlaceholder()
          ? _value.standardName
          // ignore: cast_nullable_to_non_nullable
          : standardName as String,
    );
  }
}

extension $NormalizeCandidateCopyWith on NormalizeCandidate {
  /// Returns a callable class that can be used as follows: `instanceOfNormalizeCandidate.copyWith(...)` or like so:`instanceOfNormalizeCandidate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NormalizeCandidateCWProxy get copyWith =>
      _$NormalizeCandidateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NormalizeCandidate _$NormalizeCandidateFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'NormalizeCandidate',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['ingredient_id', 'standard_name'],
        );
        final val = NormalizeCandidate(
          ingredientId: $checkedConvert('ingredient_id', (v) => v as String),
          standardName: $checkedConvert('standard_name', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'ingredientId': 'ingredient_id',
        'standardName': 'standard_name',
      },
    );

Map<String, dynamic> _$NormalizeCandidateToJson(NormalizeCandidate instance) =>
    <String, dynamic>{
      'ingredient_id': instance.ingredientId,
      'standard_name': instance.standardName,
    };
