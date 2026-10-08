// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_comparison_assistance.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeComparisonAssistanceCWProxy {
  RecipeComparisonAssistance alignments(List<AssistedStepPair>? alignments);

  RecipeComparisonAssistance fromVersionId(String fromVersionId);

  RecipeComparisonAssistance interpretation(SourcedValue? interpretation);

  RecipeComparisonAssistance reasonCode(String? reasonCode);

  RecipeComparisonAssistance rulesVersion(String rulesVersion);

  RecipeComparisonAssistance status(
    RecipeComparisonAssistanceStatusEnum status,
  );

  RecipeComparisonAssistance toVersionId(String toVersionId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeComparisonAssistance(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeComparisonAssistance(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeComparisonAssistance call({
    List<AssistedStepPair>? alignments,
    String fromVersionId,
    SourcedValue? interpretation,
    String? reasonCode,
    String rulesVersion,
    RecipeComparisonAssistanceStatusEnum status,
    String toVersionId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeComparisonAssistance.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeComparisonAssistance.copyWith.fieldName(...)`
class _$RecipeComparisonAssistanceCWProxyImpl
    implements _$RecipeComparisonAssistanceCWProxy {
  const _$RecipeComparisonAssistanceCWProxyImpl(this._value);

  final RecipeComparisonAssistance _value;

  @override
  RecipeComparisonAssistance alignments(List<AssistedStepPair>? alignments) =>
      this(alignments: alignments);

  @override
  RecipeComparisonAssistance fromVersionId(String fromVersionId) =>
      this(fromVersionId: fromVersionId);

  @override
  RecipeComparisonAssistance interpretation(SourcedValue? interpretation) =>
      this(interpretation: interpretation);

  @override
  RecipeComparisonAssistance reasonCode(String? reasonCode) =>
      this(reasonCode: reasonCode);

  @override
  RecipeComparisonAssistance rulesVersion(String rulesVersion) =>
      this(rulesVersion: rulesVersion);

  @override
  RecipeComparisonAssistance status(
    RecipeComparisonAssistanceStatusEnum status,
  ) => this(status: status);

  @override
  RecipeComparisonAssistance toVersionId(String toVersionId) =>
      this(toVersionId: toVersionId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeComparisonAssistance(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeComparisonAssistance(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeComparisonAssistance call({
    Object? alignments = const $CopyWithPlaceholder(),
    Object? fromVersionId = const $CopyWithPlaceholder(),
    Object? interpretation = const $CopyWithPlaceholder(),
    Object? reasonCode = const $CopyWithPlaceholder(),
    Object? rulesVersion = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? toVersionId = const $CopyWithPlaceholder(),
  }) {
    return RecipeComparisonAssistance(
      alignments: alignments == const $CopyWithPlaceholder()
          ? _value.alignments
          // ignore: cast_nullable_to_non_nullable
          : alignments as List<AssistedStepPair>?,
      fromVersionId: fromVersionId == const $CopyWithPlaceholder()
          ? _value.fromVersionId
          // ignore: cast_nullable_to_non_nullable
          : fromVersionId as String,
      interpretation: interpretation == const $CopyWithPlaceholder()
          ? _value.interpretation
          // ignore: cast_nullable_to_non_nullable
          : interpretation as SourcedValue?,
      reasonCode: reasonCode == const $CopyWithPlaceholder()
          ? _value.reasonCode
          // ignore: cast_nullable_to_non_nullable
          : reasonCode as String?,
      rulesVersion: rulesVersion == const $CopyWithPlaceholder()
          ? _value.rulesVersion
          // ignore: cast_nullable_to_non_nullable
          : rulesVersion as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as RecipeComparisonAssistanceStatusEnum,
      toVersionId: toVersionId == const $CopyWithPlaceholder()
          ? _value.toVersionId
          // ignore: cast_nullable_to_non_nullable
          : toVersionId as String,
    );
  }
}

extension $RecipeComparisonAssistanceCopyWith on RecipeComparisonAssistance {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeComparisonAssistance.copyWith(...)` or like so:`instanceOfRecipeComparisonAssistance.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeComparisonAssistanceCWProxy get copyWith =>
      _$RecipeComparisonAssistanceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeComparisonAssistance _$RecipeComparisonAssistanceFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'RecipeComparisonAssistance',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'from_version_id',
        'rules_version',
        'status',
        'to_version_id',
      ],
    );
    final val = RecipeComparisonAssistance(
      alignments: $checkedConvert(
        'alignments',
        (v) => (v as List<dynamic>?)
            ?.map((e) => AssistedStepPair.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      fromVersionId: $checkedConvert('from_version_id', (v) => v as String),
      interpretation: $checkedConvert(
        'interpretation',
        (v) =>
            v == null ? null : SourcedValue.fromJson(v as Map<String, dynamic>),
      ),
      reasonCode: $checkedConvert('reason_code', (v) => v as String?),
      rulesVersion: $checkedConvert('rules_version', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$RecipeComparisonAssistanceStatusEnumEnumMap, v),
      ),
      toVersionId: $checkedConvert('to_version_id', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'fromVersionId': 'from_version_id',
    'reasonCode': 'reason_code',
    'rulesVersion': 'rules_version',
    'toVersionId': 'to_version_id',
  },
);

Map<String, dynamic> _$RecipeComparisonAssistanceToJson(
  RecipeComparisonAssistance instance,
) => <String, dynamic>{
  'alignments': ?instance.alignments?.map((e) => e.toJson()).toList(),
  'from_version_id': instance.fromVersionId,
  'interpretation': ?instance.interpretation?.toJson(),
  'reason_code': ?instance.reasonCode,
  'rules_version': instance.rulesVersion,
  'status': _$RecipeComparisonAssistanceStatusEnumEnumMap[instance.status]!,
  'to_version_id': instance.toVersionId,
};

const _$RecipeComparisonAssistanceStatusEnumEnumMap = {
  RecipeComparisonAssistanceStatusEnum.ready: 'ready',
  RecipeComparisonAssistanceStatusEnum.unavailable: 'unavailable',
};
