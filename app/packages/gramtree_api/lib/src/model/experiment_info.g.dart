// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'experiment_info.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ExperimentInfoCWProxy {
  ExperimentInfo experiment(String experiment);

  ExperimentInfo variant(String variant);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExperimentInfo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExperimentInfo(...).copyWith(id: 12, name: "My name")
  /// ````
  ExperimentInfo call({String experiment, String variant});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfExperimentInfo.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfExperimentInfo.copyWith.fieldName(...)`
class _$ExperimentInfoCWProxyImpl implements _$ExperimentInfoCWProxy {
  const _$ExperimentInfoCWProxyImpl(this._value);

  final ExperimentInfo _value;

  @override
  ExperimentInfo experiment(String experiment) => this(experiment: experiment);

  @override
  ExperimentInfo variant(String variant) => this(variant: variant);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExperimentInfo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExperimentInfo(...).copyWith(id: 12, name: "My name")
  /// ````
  ExperimentInfo call({
    Object? experiment = const $CopyWithPlaceholder(),
    Object? variant = const $CopyWithPlaceholder(),
  }) {
    return ExperimentInfo(
      experiment: experiment == const $CopyWithPlaceholder()
          ? _value.experiment
          // ignore: cast_nullable_to_non_nullable
          : experiment as String,
      variant: variant == const $CopyWithPlaceholder()
          ? _value.variant
          // ignore: cast_nullable_to_non_nullable
          : variant as String,
    );
  }
}

extension $ExperimentInfoCopyWith on ExperimentInfo {
  /// Returns a callable class that can be used as follows: `instanceOfExperimentInfo.copyWith(...)` or like so:`instanceOfExperimentInfo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ExperimentInfoCWProxy get copyWith => _$ExperimentInfoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExperimentInfo _$ExperimentInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ExperimentInfo', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['experiment', 'variant']);
      final val = ExperimentInfo(
        experiment: $checkedConvert('experiment', (v) => v as String),
        variant: $checkedConvert('variant', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ExperimentInfoToJson(ExperimentInfo instance) =>
    <String, dynamic>{
      'experiment': instance.experiment,
      'variant': instance.variant,
    };
