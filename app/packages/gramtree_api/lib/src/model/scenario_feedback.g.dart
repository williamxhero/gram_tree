// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scenario_feedback.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ScenarioFeedbackCWProxy {
  ScenarioFeedback componentId(String componentId);

  ScenarioFeedback sourceType(ScenarioFeedbackSourceTypeEnum sourceType);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ScenarioFeedback(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ScenarioFeedback(...).copyWith(id: 12, name: "My name")
  /// ````
  ScenarioFeedback call({
    String componentId,
    ScenarioFeedbackSourceTypeEnum sourceType,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfScenarioFeedback.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfScenarioFeedback.copyWith.fieldName(...)`
class _$ScenarioFeedbackCWProxyImpl implements _$ScenarioFeedbackCWProxy {
  const _$ScenarioFeedbackCWProxyImpl(this._value);

  final ScenarioFeedback _value;

  @override
  ScenarioFeedback componentId(String componentId) =>
      this(componentId: componentId);

  @override
  ScenarioFeedback sourceType(ScenarioFeedbackSourceTypeEnum sourceType) =>
      this(sourceType: sourceType);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ScenarioFeedback(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ScenarioFeedback(...).copyWith(id: 12, name: "My name")
  /// ````
  ScenarioFeedback call({
    Object? componentId = const $CopyWithPlaceholder(),
    Object? sourceType = const $CopyWithPlaceholder(),
  }) {
    return ScenarioFeedback(
      componentId: componentId == const $CopyWithPlaceholder()
          ? _value.componentId
          // ignore: cast_nullable_to_non_nullable
          : componentId as String,
      sourceType: sourceType == const $CopyWithPlaceholder()
          ? _value.sourceType
          // ignore: cast_nullable_to_non_nullable
          : sourceType as ScenarioFeedbackSourceTypeEnum,
    );
  }
}

extension $ScenarioFeedbackCopyWith on ScenarioFeedback {
  /// Returns a callable class that can be used as follows: `instanceOfScenarioFeedback.copyWith(...)` or like so:`instanceOfScenarioFeedback.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ScenarioFeedbackCWProxy get copyWith => _$ScenarioFeedbackCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScenarioFeedback _$ScenarioFeedbackFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ScenarioFeedback',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['component_id', 'source_type']);
        final val = ScenarioFeedback(
          componentId: $checkedConvert('component_id', (v) => v as String),
          sourceType: $checkedConvert(
            'source_type',
            (v) => $enumDecode(_$ScenarioFeedbackSourceTypeEnumEnumMap, v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'componentId': 'component_id',
        'sourceType': 'source_type',
      },
    );

Map<String, dynamic> _$ScenarioFeedbackToJson(
  ScenarioFeedback instance,
) => <String, dynamic>{
  'component_id': instance.componentId,
  'source_type': _$ScenarioFeedbackSourceTypeEnumEnumMap[instance.sourceType]!,
};

const _$ScenarioFeedbackSourceTypeEnumEnumMap = {
  ScenarioFeedbackSourceTypeEnum.scenarioAdjusted: 'scenario_adjusted',
};
