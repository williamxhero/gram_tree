// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mold_conversion_step.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MoldConversionStepCWProxy {
  MoldConversionStep donenessWarning(bool? donenessWarning);

  MoldConversionStep donenessWarningText(String? donenessWarningText);

  MoldConversionStep durationSeconds(int durationSeconds);

  MoldConversionStep heat(String? heat);

  MoldConversionStep id(String id);

  MoldConversionStep instruction(String instruction);

  MoldConversionStep temperatureCelsius(num? temperatureCelsius);

  MoldConversionStep timeAdvisory(String? timeAdvisory);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MoldConversionStep(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MoldConversionStep(...).copyWith(id: 12, name: "My name")
  /// ````
  MoldConversionStep call({
    bool? donenessWarning,
    String? donenessWarningText,
    int durationSeconds,
    String? heat,
    String id,
    String instruction,
    num? temperatureCelsius,
    String? timeAdvisory,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMoldConversionStep.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMoldConversionStep.copyWith.fieldName(...)`
class _$MoldConversionStepCWProxyImpl implements _$MoldConversionStepCWProxy {
  const _$MoldConversionStepCWProxyImpl(this._value);

  final MoldConversionStep _value;

  @override
  MoldConversionStep donenessWarning(bool? donenessWarning) =>
      this(donenessWarning: donenessWarning);

  @override
  MoldConversionStep donenessWarningText(String? donenessWarningText) =>
      this(donenessWarningText: donenessWarningText);

  @override
  MoldConversionStep durationSeconds(int durationSeconds) =>
      this(durationSeconds: durationSeconds);

  @override
  MoldConversionStep heat(String? heat) => this(heat: heat);

  @override
  MoldConversionStep id(String id) => this(id: id);

  @override
  MoldConversionStep instruction(String instruction) =>
      this(instruction: instruction);

  @override
  MoldConversionStep temperatureCelsius(num? temperatureCelsius) =>
      this(temperatureCelsius: temperatureCelsius);

  @override
  MoldConversionStep timeAdvisory(String? timeAdvisory) =>
      this(timeAdvisory: timeAdvisory);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MoldConversionStep(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MoldConversionStep(...).copyWith(id: 12, name: "My name")
  /// ````
  MoldConversionStep call({
    Object? donenessWarning = const $CopyWithPlaceholder(),
    Object? donenessWarningText = const $CopyWithPlaceholder(),
    Object? durationSeconds = const $CopyWithPlaceholder(),
    Object? heat = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? instruction = const $CopyWithPlaceholder(),
    Object? temperatureCelsius = const $CopyWithPlaceholder(),
    Object? timeAdvisory = const $CopyWithPlaceholder(),
  }) {
    return MoldConversionStep(
      donenessWarning: donenessWarning == const $CopyWithPlaceholder()
          ? _value.donenessWarning
          // ignore: cast_nullable_to_non_nullable
          : donenessWarning as bool?,
      donenessWarningText: donenessWarningText == const $CopyWithPlaceholder()
          ? _value.donenessWarningText
          // ignore: cast_nullable_to_non_nullable
          : donenessWarningText as String?,
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
      timeAdvisory: timeAdvisory == const $CopyWithPlaceholder()
          ? _value.timeAdvisory
          // ignore: cast_nullable_to_non_nullable
          : timeAdvisory as String?,
    );
  }
}

extension $MoldConversionStepCopyWith on MoldConversionStep {
  /// Returns a callable class that can be used as follows: `instanceOfMoldConversionStep.copyWith(...)` or like so:`instanceOfMoldConversionStep.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MoldConversionStepCWProxy get copyWith =>
      _$MoldConversionStepCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoldConversionStep _$MoldConversionStepFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'MoldConversionStep',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['duration_seconds', 'id', 'instruction'],
        );
        final val = MoldConversionStep(
          donenessWarning: $checkedConvert(
            'doneness_warning',
            (v) => v as bool? ?? false,
          ),
          donenessWarningText: $checkedConvert(
            'doneness_warning_text',
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
          timeAdvisory: $checkedConvert('time_advisory', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'donenessWarning': 'doneness_warning',
        'donenessWarningText': 'doneness_warning_text',
        'durationSeconds': 'duration_seconds',
        'temperatureCelsius': 'temperature_celsius',
        'timeAdvisory': 'time_advisory',
      },
    );

Map<String, dynamic> _$MoldConversionStepToJson(MoldConversionStep instance) =>
    <String, dynamic>{
      'doneness_warning': ?instance.donenessWarning,
      'doneness_warning_text': ?instance.donenessWarningText,
      'duration_seconds': instance.durationSeconds,
      'heat': ?instance.heat,
      'id': instance.id,
      'instruction': instance.instruction,
      'temperature_celsius': ?instance.temperatureCelsius,
      'time_advisory': ?instance.timeAdvisory,
    };
