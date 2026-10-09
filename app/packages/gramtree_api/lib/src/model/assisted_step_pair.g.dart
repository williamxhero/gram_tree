// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assisted_step_pair.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AssistedStepPairCWProxy {
  AssistedStepPair afterStepId(String afterStepId);

  AssistedStepPair alignment(AssistedStepPairAlignmentEnum alignment);

  AssistedStepPair basis(SourceBasis basis);

  AssistedStepPair beforeStepId(String beforeStepId);

  AssistedStepPair confidence(num confidence);

  AssistedStepPair sourceType(AssistedStepPairSourceTypeEnum sourceType);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AssistedStepPair(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AssistedStepPair(...).copyWith(id: 12, name: "My name")
  /// ````
  AssistedStepPair call({
    String afterStepId,
    AssistedStepPairAlignmentEnum alignment,
    SourceBasis basis,
    String beforeStepId,
    num confidence,
    AssistedStepPairSourceTypeEnum sourceType,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAssistedStepPair.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAssistedStepPair.copyWith.fieldName(...)`
class _$AssistedStepPairCWProxyImpl implements _$AssistedStepPairCWProxy {
  const _$AssistedStepPairCWProxyImpl(this._value);

  final AssistedStepPair _value;

  @override
  AssistedStepPair afterStepId(String afterStepId) =>
      this(afterStepId: afterStepId);

  @override
  AssistedStepPair alignment(AssistedStepPairAlignmentEnum alignment) =>
      this(alignment: alignment);

  @override
  AssistedStepPair basis(SourceBasis basis) => this(basis: basis);

  @override
  AssistedStepPair beforeStepId(String beforeStepId) =>
      this(beforeStepId: beforeStepId);

  @override
  AssistedStepPair confidence(num confidence) => this(confidence: confidence);

  @override
  AssistedStepPair sourceType(AssistedStepPairSourceTypeEnum sourceType) =>
      this(sourceType: sourceType);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AssistedStepPair(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AssistedStepPair(...).copyWith(id: 12, name: "My name")
  /// ````
  AssistedStepPair call({
    Object? afterStepId = const $CopyWithPlaceholder(),
    Object? alignment = const $CopyWithPlaceholder(),
    Object? basis = const $CopyWithPlaceholder(),
    Object? beforeStepId = const $CopyWithPlaceholder(),
    Object? confidence = const $CopyWithPlaceholder(),
    Object? sourceType = const $CopyWithPlaceholder(),
  }) {
    return AssistedStepPair(
      afterStepId: afterStepId == const $CopyWithPlaceholder()
          ? _value.afterStepId
          // ignore: cast_nullable_to_non_nullable
          : afterStepId as String,
      alignment: alignment == const $CopyWithPlaceholder()
          ? _value.alignment
          // ignore: cast_nullable_to_non_nullable
          : alignment as AssistedStepPairAlignmentEnum,
      basis: basis == const $CopyWithPlaceholder()
          ? _value.basis
          // ignore: cast_nullable_to_non_nullable
          : basis as SourceBasis,
      beforeStepId: beforeStepId == const $CopyWithPlaceholder()
          ? _value.beforeStepId
          // ignore: cast_nullable_to_non_nullable
          : beforeStepId as String,
      confidence: confidence == const $CopyWithPlaceholder()
          ? _value.confidence
          // ignore: cast_nullable_to_non_nullable
          : confidence as num,
      sourceType: sourceType == const $CopyWithPlaceholder()
          ? _value.sourceType
          // ignore: cast_nullable_to_non_nullable
          : sourceType as AssistedStepPairSourceTypeEnum,
    );
  }
}

extension $AssistedStepPairCopyWith on AssistedStepPair {
  /// Returns a callable class that can be used as follows: `instanceOfAssistedStepPair.copyWith(...)` or like so:`instanceOfAssistedStepPair.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AssistedStepPairCWProxy get copyWith => _$AssistedStepPairCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssistedStepPair _$AssistedStepPairFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AssistedStepPair',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'after_step_id',
            'alignment',
            'basis',
            'before_step_id',
            'confidence',
            'source_type',
          ],
        );
        final val = AssistedStepPair(
          afterStepId: $checkedConvert('after_step_id', (v) => v as String),
          alignment: $checkedConvert(
            'alignment',
            (v) => $enumDecode(_$AssistedStepPairAlignmentEnumEnumMap, v),
          ),
          basis: $checkedConvert(
            'basis',
            (v) => SourceBasis.fromJson(v as Map<String, dynamic>),
          ),
          beforeStepId: $checkedConvert('before_step_id', (v) => v as String),
          confidence: $checkedConvert('confidence', (v) => v as num),
          sourceType: $checkedConvert(
            'source_type',
            (v) => $enumDecode(_$AssistedStepPairSourceTypeEnumEnumMap, v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'afterStepId': 'after_step_id',
        'beforeStepId': 'before_step_id',
        'sourceType': 'source_type',
      },
    );

Map<String, dynamic> _$AssistedStepPairToJson(
  AssistedStepPair instance,
) => <String, dynamic>{
  'after_step_id': instance.afterStepId,
  'alignment': _$AssistedStepPairAlignmentEnumEnumMap[instance.alignment]!,
  'basis': instance.basis.toJson(),
  'before_step_id': instance.beforeStepId,
  'confidence': instance.confidence,
  'source_type': _$AssistedStepPairSourceTypeEnumEnumMap[instance.sourceType]!,
};

const _$AssistedStepPairAlignmentEnumEnumMap = {
  AssistedStepPairAlignmentEnum.aiAssisted: 'ai_assisted',
};

const _$AssistedStepPairSourceTypeEnumEnumMap = {
  AssistedStepPairSourceTypeEnum.aiEstimated: 'ai_estimated',
};
