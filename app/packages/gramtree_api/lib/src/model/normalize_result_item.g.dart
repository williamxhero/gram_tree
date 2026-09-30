// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'normalize_result_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NormalizeResultItemCWProxy {
  NormalizeResultItem candidates(List<NormalizeCandidate> candidates);

  NormalizeResultItem confidence(NormalizeResultItemConfidenceEnum confidence);

  NormalizeResultItem ingredientId(String? ingredientId);

  NormalizeResultItem name(String name);

  NormalizeResultItem standardName(String? standardName);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NormalizeResultItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NormalizeResultItem(...).copyWith(id: 12, name: "My name")
  /// ````
  NormalizeResultItem call({
    List<NormalizeCandidate> candidates,
    NormalizeResultItemConfidenceEnum confidence,
    String? ingredientId,
    String name,
    String? standardName,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfNormalizeResultItem.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfNormalizeResultItem.copyWith.fieldName(...)`
class _$NormalizeResultItemCWProxyImpl implements _$NormalizeResultItemCWProxy {
  const _$NormalizeResultItemCWProxyImpl(this._value);

  final NormalizeResultItem _value;

  @override
  NormalizeResultItem candidates(List<NormalizeCandidate> candidates) =>
      this(candidates: candidates);

  @override
  NormalizeResultItem confidence(
    NormalizeResultItemConfidenceEnum confidence,
  ) => this(confidence: confidence);

  @override
  NormalizeResultItem ingredientId(String? ingredientId) =>
      this(ingredientId: ingredientId);

  @override
  NormalizeResultItem name(String name) => this(name: name);

  @override
  NormalizeResultItem standardName(String? standardName) =>
      this(standardName: standardName);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NormalizeResultItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NormalizeResultItem(...).copyWith(id: 12, name: "My name")
  /// ````
  NormalizeResultItem call({
    Object? candidates = const $CopyWithPlaceholder(),
    Object? confidence = const $CopyWithPlaceholder(),
    Object? ingredientId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? standardName = const $CopyWithPlaceholder(),
  }) {
    return NormalizeResultItem(
      candidates: candidates == const $CopyWithPlaceholder()
          ? _value.candidates
          // ignore: cast_nullable_to_non_nullable
          : candidates as List<NormalizeCandidate>,
      confidence: confidence == const $CopyWithPlaceholder()
          ? _value.confidence
          // ignore: cast_nullable_to_non_nullable
          : confidence as NormalizeResultItemConfidenceEnum,
      ingredientId: ingredientId == const $CopyWithPlaceholder()
          ? _value.ingredientId
          // ignore: cast_nullable_to_non_nullable
          : ingredientId as String?,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      standardName: standardName == const $CopyWithPlaceholder()
          ? _value.standardName
          // ignore: cast_nullable_to_non_nullable
          : standardName as String?,
    );
  }
}

extension $NormalizeResultItemCopyWith on NormalizeResultItem {
  /// Returns a callable class that can be used as follows: `instanceOfNormalizeResultItem.copyWith(...)` or like so:`instanceOfNormalizeResultItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NormalizeResultItemCWProxy get copyWith =>
      _$NormalizeResultItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NormalizeResultItem _$NormalizeResultItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'NormalizeResultItem',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'candidates',
            'confidence',
            'ingredient_id',
            'name',
            'standard_name',
          ],
        );
        final val = NormalizeResultItem(
          candidates: $checkedConvert(
            'candidates',
            (v) => (v as List<dynamic>)
                .map(
                  (e) => NormalizeCandidate.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
          ),
          confidence: $checkedConvert(
            'confidence',
            (v) => $enumDecode(_$NormalizeResultItemConfidenceEnumEnumMap, v),
          ),
          ingredientId: $checkedConvert('ingredient_id', (v) => v as String?),
          name: $checkedConvert('name', (v) => v as String),
          standardName: $checkedConvert('standard_name', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'ingredientId': 'ingredient_id',
        'standardName': 'standard_name',
      },
    );

Map<String, dynamic> _$NormalizeResultItemToJson(
  NormalizeResultItem instance,
) => <String, dynamic>{
  'candidates': instance.candidates.map((e) => e.toJson()).toList(),
  'confidence':
      _$NormalizeResultItemConfidenceEnumEnumMap[instance.confidence]!,
  'ingredient_id': instance.ingredientId,
  'name': instance.name,
  'standard_name': instance.standardName,
};

const _$NormalizeResultItemConfidenceEnumEnumMap = {
  NormalizeResultItemConfidenceEnum.exact: 'exact',
  NormalizeResultItemConfidenceEnum.alias: 'alias',
  NormalizeResultItemConfidenceEnum.fuzzy: 'fuzzy',
  NormalizeResultItemConfidenceEnum.ambiguous: 'ambiguous',
  NormalizeResultItemConfidenceEnum.unrecorded: 'unrecorded',
};
