// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_safety_finding.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeSafetyFindingCWProxy {
  RecipeSafetyFinding basis(String basis);

  RecipeSafetyFinding ingredientIds(List<String>? ingredientIds);

  RecipeSafetyFinding message(String message);

  RecipeSafetyFinding restMinutes(int? restMinutes);

  RecipeSafetyFinding ruleId(String ruleId);

  RecipeSafetyFinding severity(RecipeSafetyFindingSeverityEnum severity);

  RecipeSafetyFinding stepIds(List<String>? stepIds);

  RecipeSafetyFinding thresholdCelsius(num? thresholdCelsius);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeSafetyFinding(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeSafetyFinding(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeSafetyFinding call({
    String basis,
    List<String>? ingredientIds,
    String message,
    int? restMinutes,
    String ruleId,
    RecipeSafetyFindingSeverityEnum severity,
    List<String>? stepIds,
    num? thresholdCelsius,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeSafetyFinding.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeSafetyFinding.copyWith.fieldName(...)`
class _$RecipeSafetyFindingCWProxyImpl implements _$RecipeSafetyFindingCWProxy {
  const _$RecipeSafetyFindingCWProxyImpl(this._value);

  final RecipeSafetyFinding _value;

  @override
  RecipeSafetyFinding basis(String basis) => this(basis: basis);

  @override
  RecipeSafetyFinding ingredientIds(List<String>? ingredientIds) =>
      this(ingredientIds: ingredientIds);

  @override
  RecipeSafetyFinding message(String message) => this(message: message);

  @override
  RecipeSafetyFinding restMinutes(int? restMinutes) =>
      this(restMinutes: restMinutes);

  @override
  RecipeSafetyFinding ruleId(String ruleId) => this(ruleId: ruleId);

  @override
  RecipeSafetyFinding severity(RecipeSafetyFindingSeverityEnum severity) =>
      this(severity: severity);

  @override
  RecipeSafetyFinding stepIds(List<String>? stepIds) => this(stepIds: stepIds);

  @override
  RecipeSafetyFinding thresholdCelsius(num? thresholdCelsius) =>
      this(thresholdCelsius: thresholdCelsius);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeSafetyFinding(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeSafetyFinding(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeSafetyFinding call({
    Object? basis = const $CopyWithPlaceholder(),
    Object? ingredientIds = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
    Object? restMinutes = const $CopyWithPlaceholder(),
    Object? ruleId = const $CopyWithPlaceholder(),
    Object? severity = const $CopyWithPlaceholder(),
    Object? stepIds = const $CopyWithPlaceholder(),
    Object? thresholdCelsius = const $CopyWithPlaceholder(),
  }) {
    return RecipeSafetyFinding(
      basis: basis == const $CopyWithPlaceholder()
          ? _value.basis
          // ignore: cast_nullable_to_non_nullable
          : basis as String,
      ingredientIds: ingredientIds == const $CopyWithPlaceholder()
          ? _value.ingredientIds
          // ignore: cast_nullable_to_non_nullable
          : ingredientIds as List<String>?,
      message: message == const $CopyWithPlaceholder()
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
      restMinutes: restMinutes == const $CopyWithPlaceholder()
          ? _value.restMinutes
          // ignore: cast_nullable_to_non_nullable
          : restMinutes as int?,
      ruleId: ruleId == const $CopyWithPlaceholder()
          ? _value.ruleId
          // ignore: cast_nullable_to_non_nullable
          : ruleId as String,
      severity: severity == const $CopyWithPlaceholder()
          ? _value.severity
          // ignore: cast_nullable_to_non_nullable
          : severity as RecipeSafetyFindingSeverityEnum,
      stepIds: stepIds == const $CopyWithPlaceholder()
          ? _value.stepIds
          // ignore: cast_nullable_to_non_nullable
          : stepIds as List<String>?,
      thresholdCelsius: thresholdCelsius == const $CopyWithPlaceholder()
          ? _value.thresholdCelsius
          // ignore: cast_nullable_to_non_nullable
          : thresholdCelsius as num?,
    );
  }
}

extension $RecipeSafetyFindingCopyWith on RecipeSafetyFinding {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeSafetyFinding.copyWith(...)` or like so:`instanceOfRecipeSafetyFinding.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeSafetyFindingCWProxy get copyWith =>
      _$RecipeSafetyFindingCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeSafetyFinding _$RecipeSafetyFindingFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'RecipeSafetyFinding',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['basis', 'message', 'rule_id', 'severity'],
    );
    final val = RecipeSafetyFinding(
      basis: $checkedConvert('basis', (v) => v as String),
      ingredientIds: $checkedConvert(
        'ingredient_ids',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      message: $checkedConvert('message', (v) => v as String),
      restMinutes: $checkedConvert('rest_minutes', (v) => (v as num?)?.toInt()),
      ruleId: $checkedConvert('rule_id', (v) => v as String),
      severity: $checkedConvert(
        'severity',
        (v) => $enumDecode(_$RecipeSafetyFindingSeverityEnumEnumMap, v),
      ),
      stepIds: $checkedConvert(
        'step_ids',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      thresholdCelsius: $checkedConvert('threshold_celsius', (v) => v as num?),
    );
    return val;
  },
  fieldKeyMap: const {
    'ingredientIds': 'ingredient_ids',
    'restMinutes': 'rest_minutes',
    'ruleId': 'rule_id',
    'stepIds': 'step_ids',
    'thresholdCelsius': 'threshold_celsius',
  },
);

Map<String, dynamic> _$RecipeSafetyFindingToJson(
  RecipeSafetyFinding instance,
) => <String, dynamic>{
  'basis': instance.basis,
  'ingredient_ids': ?instance.ingredientIds,
  'message': instance.message,
  'rest_minutes': ?instance.restMinutes,
  'rule_id': instance.ruleId,
  'severity': _$RecipeSafetyFindingSeverityEnumEnumMap[instance.severity]!,
  'step_ids': ?instance.stepIds,
  'threshold_celsius': ?instance.thresholdCelsius,
};

const _$RecipeSafetyFindingSeverityEnumEnumMap = {
  RecipeSafetyFindingSeverityEnum.info: 'info',
  RecipeSafetyFindingSeverityEnum.warning: 'warning',
  RecipeSafetyFindingSeverityEnum.highRisk: 'high_risk',
};
