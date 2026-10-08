// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_advice.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BatchAdviceCWProxy {
  BatchAdvice basis(String basis);

  BatchAdvice risk(String risk);

  BatchAdvice steps(List<BatchStepAdvice> steps);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BatchAdvice(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BatchAdvice(...).copyWith(id: 12, name: "My name")
  /// ````
  BatchAdvice call({String basis, String risk, List<BatchStepAdvice> steps});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfBatchAdvice.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfBatchAdvice.copyWith.fieldName(...)`
class _$BatchAdviceCWProxyImpl implements _$BatchAdviceCWProxy {
  const _$BatchAdviceCWProxyImpl(this._value);

  final BatchAdvice _value;

  @override
  BatchAdvice basis(String basis) => this(basis: basis);

  @override
  BatchAdvice risk(String risk) => this(risk: risk);

  @override
  BatchAdvice steps(List<BatchStepAdvice> steps) => this(steps: steps);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BatchAdvice(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BatchAdvice(...).copyWith(id: 12, name: "My name")
  /// ````
  BatchAdvice call({
    Object? basis = const $CopyWithPlaceholder(),
    Object? risk = const $CopyWithPlaceholder(),
    Object? steps = const $CopyWithPlaceholder(),
  }) {
    return BatchAdvice(
      basis: basis == const $CopyWithPlaceholder()
          ? _value.basis
          // ignore: cast_nullable_to_non_nullable
          : basis as String,
      risk: risk == const $CopyWithPlaceholder()
          ? _value.risk
          // ignore: cast_nullable_to_non_nullable
          : risk as String,
      steps: steps == const $CopyWithPlaceholder()
          ? _value.steps
          // ignore: cast_nullable_to_non_nullable
          : steps as List<BatchStepAdvice>,
    );
  }
}

extension $BatchAdviceCopyWith on BatchAdvice {
  /// Returns a callable class that can be used as follows: `instanceOfBatchAdvice.copyWith(...)` or like so:`instanceOfBatchAdvice.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BatchAdviceCWProxy get copyWith => _$BatchAdviceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BatchAdvice _$BatchAdviceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BatchAdvice', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['basis', 'risk', 'steps']);
      final val = BatchAdvice(
        basis: $checkedConvert('basis', (v) => v as String),
        risk: $checkedConvert('risk', (v) => v as String),
        steps: $checkedConvert(
          'steps',
          (v) => (v as List<dynamic>)
              .map((e) => BatchStepAdvice.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$BatchAdviceToJson(BatchAdvice instance) =>
    <String, dynamic>{
      'basis': instance.basis,
      'risk': instance.risk,
      'steps': instance.steps.map((e) => e.toJson()).toList(),
    };
