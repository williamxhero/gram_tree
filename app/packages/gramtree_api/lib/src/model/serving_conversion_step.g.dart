// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serving_conversion_step.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ServingConversionStepCWProxy {
  ServingConversionStep batchWarning(bool? batchWarning);

  ServingConversionStep batchWarningText(String? batchWarningText);

  ServingConversionStep durationSeconds(int durationSeconds);

  ServingConversionStep heat(String? heat);

  ServingConversionStep id(String id);

  ServingConversionStep instruction(String instruction);

  ServingConversionStep temperatureCelsius(num? temperatureCelsius);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ServingConversionStep(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ServingConversionStep(...).copyWith(id: 12, name: "My name")
  /// ````
  ServingConversionStep call({
    bool? batchWarning,
    String? batchWarningText,
    int durationSeconds,
    String? heat,
    String id,
    String instruction,
    num? temperatureCelsius,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfServingConversionStep.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfServingConversionStep.copyWith.fieldName(...)`
class _$ServingConversionStepCWProxyImpl
    implements _$ServingConversionStepCWProxy {
  const _$ServingConversionStepCWProxyImpl(this._value);

  final ServingConversionStep _value;

  @override
  ServingConversionStep batchWarning(bool? batchWarning) =>
      this(batchWarning: batchWarning);

  @override
  ServingConversionStep batchWarningText(String? batchWarningText) =>
      this(batchWarningText: batchWarningText);

  @override
  ServingConversionStep durationSeconds(int durationSeconds) =>
      this(durationSeconds: durationSeconds);

  @override
  ServingConversionStep heat(String? heat) => this(heat: heat);

  @override
  ServingConversionStep id(String id) => this(id: id);

  @override
  ServingConversionStep instruction(String instruction) =>
      this(instruction: instruction);

  @override
  ServingConversionStep temperatureCelsius(num? temperatureCelsius) =>
      this(temperatureCelsius: temperatureCelsius);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ServingConversionStep(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ServingConversionStep(...).copyWith(id: 12, name: "My name")
  /// ````
  ServingConversionStep call({
    Object? batchWarning = const $CopyWithPlaceholder(),
    Object? batchWarningText = const $CopyWithPlaceholder(),
    Object? durationSeconds = const $CopyWithPlaceholder(),
    Object? heat = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? instruction = const $CopyWithPlaceholder(),
    Object? temperatureCelsius = const $CopyWithPlaceholder(),
  }) {
    return ServingConversionStep(
      batchWarning: batchWarning == const $CopyWithPlaceholder()
          ? _value.batchWarning
          // ignore: cast_nullable_to_non_nullable
          : batchWarning as bool?,
      batchWarningText: batchWarningText == const $CopyWithPlaceholder()
          ? _value.batchWarningText
          // ignore: cast_nullable_to_non_nullable
          : batchWarningText as String?,
      durationSeconds: durationSeconds == const $CopyWithPlaceholder()
          ? _value.durationSeconds
          // ignore: cast_nullable_to_non_nullable
          : durationSeconds as int,
      heat: heat == const $CopyWithPlaceholder()
          ? _value.heat
          // ignore: cast_nullable_to_non_nullable
          : heat as String?,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      instruction: instruction == const $CopyWithPlaceholder()
          ? _value.instruction
          // ignore: cast_nullable_to_non_nullable
          : instruction as String,
      temperatureCelsius: temperatureCelsius == const $CopyWithPlaceholder()
          ? _value.temperatureCelsius
          // ignore: cast_nullable_to_non_nullable
          : temperatureCelsius as num?,
    );
  }
}

extension $ServingConversionStepCopyWith on ServingConversionStep {
  /// Returns a callable class that can be used as follows: `instanceOfServingConversionStep.copyWith(...)` or like so:`instanceOfServingConversionStep.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ServingConversionStepCWProxy get copyWith =>
      _$ServingConversionStepCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServingConversionStep _$ServingConversionStepFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ServingConversionStep',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['duration_seconds', 'id', 'instruction'],
    );
    final val = ServingConversionStep(
      batchWarning: $checkedConvert(
        'batch_warning',
        (v) => v as bool? ?? false,
      ),
      batchWarningText: $checkedConvert(
        'batch_warning_text',
        (v) => v as String?,
      ),
      durationSeconds: $checkedConvert(
        'duration_seconds',
        (v) => (v as num).toInt(),
      ),
      heat: $checkedConvert('heat', (v) => v as String?),
      id: $checkedConvert('id', (v) => v as String),
      instruction: $checkedConvert('instruction', (v) => v as String),
      temperatureCelsius: $checkedConvert(
        'temperature_celsius',
        (v) => v as num?,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'batchWarning': 'batch_warning',
    'batchWarningText': 'batch_warning_text',
    'durationSeconds': 'duration_seconds',
    'temperatureCelsius': 'temperature_celsius',
  },
);

Map<String, dynamic> _$ServingConversionStepToJson(
  ServingConversionStep instance,
) => <String, dynamic>{
  'batch_warning': ?instance.batchWarning,
  'batch_warning_text': ?instance.batchWarningText,
  'duration_seconds': instance.durationSeconds,
  'heat': ?instance.heat,
  'id': instance.id,
  'instruction': instance.instruction,
  'temperature_celsius': ?instance.temperatureCelsius,
};
