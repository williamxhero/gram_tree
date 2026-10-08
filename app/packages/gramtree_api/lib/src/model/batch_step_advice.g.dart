// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_step_advice.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BatchStepAdviceCWProxy {
  BatchStepAdvice basis(String basis);

  BatchStepAdvice batchCount(int batchCount);

  BatchStepAdvice batchGuidance(String batchGuidance);

  BatchStepAdvice confidence(num confidence);

  BatchStepAdvice doneness(String doneness);

  BatchStepAdvice risk(String risk);

  BatchStepAdvice source_(BatchStepAdviceSource_Enum source_);

  BatchStepAdvice stepId(String stepId);

  BatchStepAdvice suggestedDurationSeconds(int suggestedDurationSeconds);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BatchStepAdvice(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BatchStepAdvice(...).copyWith(id: 12, name: "My name")
  /// ````
  BatchStepAdvice call({
    String basis,
    int batchCount,
    String batchGuidance,
    num confidence,
    String doneness,
    String risk,
    BatchStepAdviceSource_Enum source_,
    String stepId,
    int suggestedDurationSeconds,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfBatchStepAdvice.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfBatchStepAdvice.copyWith.fieldName(...)`
class _$BatchStepAdviceCWProxyImpl implements _$BatchStepAdviceCWProxy {
  const _$BatchStepAdviceCWProxyImpl(this._value);

  final BatchStepAdvice _value;

  @override
  BatchStepAdvice basis(String basis) => this(basis: basis);

  @override
  BatchStepAdvice batchCount(int batchCount) => this(batchCount: batchCount);

  @override
  BatchStepAdvice batchGuidance(String batchGuidance) =>
      this(batchGuidance: batchGuidance);

  @override
  BatchStepAdvice confidence(num confidence) => this(confidence: confidence);

  @override
  BatchStepAdvice doneness(String doneness) => this(doneness: doneness);

  @override
  BatchStepAdvice risk(String risk) => this(risk: risk);

  @override
  BatchStepAdvice source_(BatchStepAdviceSource_Enum source_) =>
      this(source_: source_);

  @override
  BatchStepAdvice stepId(String stepId) => this(stepId: stepId);

  @override
  BatchStepAdvice suggestedDurationSeconds(int suggestedDurationSeconds) =>
      this(suggestedDurationSeconds: suggestedDurationSeconds);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BatchStepAdvice(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BatchStepAdvice(...).copyWith(id: 12, name: "My name")
  /// ````
  BatchStepAdvice call({
    Object? basis = const $CopyWithPlaceholder(),
    Object? batchCount = const $CopyWithPlaceholder(),
    Object? batchGuidance = const $CopyWithPlaceholder(),
    Object? confidence = const $CopyWithPlaceholder(),
    Object? doneness = const $CopyWithPlaceholder(),
    Object? risk = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? stepId = const $CopyWithPlaceholder(),
    Object? suggestedDurationSeconds = const $CopyWithPlaceholder(),
  }) {
    return BatchStepAdvice(
      basis: basis == const $CopyWithPlaceholder()
          ? _value.basis
          // ignore: cast_nullable_to_non_nullable
          : basis as String,
      batchCount: batchCount == const $CopyWithPlaceholder()
          ? _value.batchCount
          // ignore: cast_nullable_to_non_nullable
          : batchCount as int,
      batchGuidance: batchGuidance == const $CopyWithPlaceholder()
          ? _value.batchGuidance
          // ignore: cast_nullable_to_non_nullable
          : batchGuidance as String,
      confidence: confidence == const $CopyWithPlaceholder()
          ? _value.confidence
          // ignore: cast_nullable_to_non_nullable
          : confidence as num,
      doneness: doneness == const $CopyWithPlaceholder()
          ? _value.doneness
          // ignore: cast_nullable_to_non_nullable
          : doneness as String,
      risk: risk == const $CopyWithPlaceholder()
          ? _value.risk
          // ignore: cast_nullable_to_non_nullable
          : risk as String,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as BatchStepAdviceSource_Enum,
      stepId: stepId == const $CopyWithPlaceholder()
          ? _value.stepId
          // ignore: cast_nullable_to_non_nullable
          : stepId as String,
      suggestedDurationSeconds:
          suggestedDurationSeconds == const $CopyWithPlaceholder()
          ? _value.suggestedDurationSeconds
          // ignore: cast_nullable_to_non_nullable
          : suggestedDurationSeconds as int,
    );
  }
}

extension $BatchStepAdviceCopyWith on BatchStepAdvice {
  /// Returns a callable class that can be used as follows: `instanceOfBatchStepAdvice.copyWith(...)` or like so:`instanceOfBatchStepAdvice.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BatchStepAdviceCWProxy get copyWith => _$BatchStepAdviceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BatchStepAdvice _$BatchStepAdviceFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'BatchStepAdvice',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'basis',
            'batch_count',
            'batch_guidance',
            'confidence',
            'doneness',
            'risk',
            'source',
            'step_id',
            'suggested_duration_seconds',
          ],
        );
        final val = BatchStepAdvice(
          basis: $checkedConvert('basis', (v) => v as String),
          batchCount: $checkedConvert('batch_count', (v) => (v as num).toInt()),
          batchGuidance: $checkedConvert('batch_guidance', (v) => v as String),
          confidence: $checkedConvert('confidence', (v) => v as num),
          doneness: $checkedConvert('doneness', (v) => v as String),
          risk: $checkedConvert('risk', (v) => v as String),
          source_: $checkedConvert(
            'source',
            (v) => $enumDecode(_$BatchStepAdviceSource_EnumEnumMap, v),
          ),
          stepId: $checkedConvert('step_id', (v) => v as String),
          suggestedDurationSeconds: $checkedConvert(
            'suggested_duration_seconds',
            (v) => (v as num).toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'batchCount': 'batch_count',
        'batchGuidance': 'batch_guidance',
        'source_': 'source',
        'stepId': 'step_id',
        'suggestedDurationSeconds': 'suggested_duration_seconds',
      },
    );

Map<String, dynamic> _$BatchStepAdviceToJson(BatchStepAdvice instance) =>
    <String, dynamic>{
      'basis': instance.basis,
      'batch_count': instance.batchCount,
      'batch_guidance': instance.batchGuidance,
      'confidence': instance.confidence,
      'doneness': instance.doneness,
      'risk': instance.risk,
      'source': _$BatchStepAdviceSource_EnumEnumMap[instance.source_]!,
      'step_id': instance.stepId,
      'suggested_duration_seconds': instance.suggestedDurationSeconds,
    };

const _$BatchStepAdviceSource_EnumEnumMap = {
  BatchStepAdviceSource_Enum.aiEstimated: 'ai_estimated',
};
