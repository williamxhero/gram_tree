// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'step_comparison_change.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StepComparisonChangeCWProxy {
  StepComparisonChange after(Object? after);

  StepComparisonChange basis(String basis);

  StepComparisonChange before(Object? before);

  StepComparisonChange field(String field);

  StepComparisonChange grade(StepComparisonChangeGradeEnum grade);

  StepComparisonChange kind(StepComparisonChangeKindEnum kind);

  StepComparisonChange relativeChange(num? relativeChange);

  StepComparisonChange ruleId(String ruleId);

  StepComparisonChange rulesVersion(String rulesVersion);

  StepComparisonChange unit(String? unit);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StepComparisonChange(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StepComparisonChange(...).copyWith(id: 12, name: "My name")
  /// ````
  StepComparisonChange call({
    Object? after,
    String basis,
    Object? before,
    String field,
    StepComparisonChangeGradeEnum grade,
    StepComparisonChangeKindEnum kind,
    num? relativeChange,
    String ruleId,
    String rulesVersion,
    String? unit,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStepComparisonChange.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStepComparisonChange.copyWith.fieldName(...)`
class _$StepComparisonChangeCWProxyImpl
    implements _$StepComparisonChangeCWProxy {
  const _$StepComparisonChangeCWProxyImpl(this._value);

  final StepComparisonChange _value;

  @override
  StepComparisonChange after(Object? after) => this(after: after);

  @override
  StepComparisonChange basis(String basis) => this(basis: basis);

  @override
  StepComparisonChange before(Object? before) => this(before: before);

  @override
  StepComparisonChange field(String field) => this(field: field);

  @override
  StepComparisonChange grade(StepComparisonChangeGradeEnum grade) =>
      this(grade: grade);

  @override
  StepComparisonChange kind(StepComparisonChangeKindEnum kind) =>
      this(kind: kind);

  @override
  StepComparisonChange relativeChange(num? relativeChange) =>
      this(relativeChange: relativeChange);

  @override
  StepComparisonChange ruleId(String ruleId) => this(ruleId: ruleId);

  @override
  StepComparisonChange rulesVersion(String rulesVersion) =>
      this(rulesVersion: rulesVersion);

  @override
  StepComparisonChange unit(String? unit) => this(unit: unit);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StepComparisonChange(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StepComparisonChange(...).copyWith(id: 12, name: "My name")
  /// ````
  StepComparisonChange call({
    Object? after = const $CopyWithPlaceholder(),
    Object? basis = const $CopyWithPlaceholder(),
    Object? before = const $CopyWithPlaceholder(),
    Object? field = const $CopyWithPlaceholder(),
    Object? grade = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? relativeChange = const $CopyWithPlaceholder(),
    Object? ruleId = const $CopyWithPlaceholder(),
    Object? rulesVersion = const $CopyWithPlaceholder(),
    Object? unit = const $CopyWithPlaceholder(),
  }) {
    return StepComparisonChange(
      after: after == const $CopyWithPlaceholder()
          ? _value.after
          // ignore: cast_nullable_to_non_nullable
          : after as Object?,
      basis: basis == const $CopyWithPlaceholder()
          ? _value.basis
          // ignore: cast_nullable_to_non_nullable
          : basis as String,
      before: before == const $CopyWithPlaceholder()
          ? _value.before
          // ignore: cast_nullable_to_non_nullable
          : before as Object?,
      field: field == const $CopyWithPlaceholder()
          ? _value.field
          // ignore: cast_nullable_to_non_nullable
          : field as String,
      grade: grade == const $CopyWithPlaceholder()
          ? _value.grade
          // ignore: cast_nullable_to_non_nullable
          : grade as StepComparisonChangeGradeEnum,
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as StepComparisonChangeKindEnum,
      relativeChange: relativeChange == const $CopyWithPlaceholder()
          ? _value.relativeChange
          // ignore: cast_nullable_to_non_nullable
          : relativeChange as num?,
      ruleId: ruleId == const $CopyWithPlaceholder()
          ? _value.ruleId
          // ignore: cast_nullable_to_non_nullable
          : ruleId as String,
      rulesVersion: rulesVersion == const $CopyWithPlaceholder()
          ? _value.rulesVersion
          // ignore: cast_nullable_to_non_nullable
          : rulesVersion as String,
      unit: unit == const $CopyWithPlaceholder()
          ? _value.unit
          // ignore: cast_nullable_to_non_nullable
          : unit as String?,
    );
  }
}

extension $StepComparisonChangeCopyWith on StepComparisonChange {
  /// Returns a callable class that can be used as follows: `instanceOfStepComparisonChange.copyWith(...)` or like so:`instanceOfStepComparisonChange.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StepComparisonChangeCWProxy get copyWith =>
      _$StepComparisonChangeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StepComparisonChange _$StepComparisonChangeFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'StepComparisonChange',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'basis',
        'field',
        'grade',
        'kind',
        'rule_id',
        'rules_version',
      ],
    );
    final val = StepComparisonChange(
      after: $checkedConvert('after', (v) => v),
      basis: $checkedConvert('basis', (v) => v as String),
      before: $checkedConvert('before', (v) => v),
      field: $checkedConvert('field', (v) => v as String),
      grade: $checkedConvert(
        'grade',
        (v) => $enumDecode(_$StepComparisonChangeGradeEnumEnumMap, v),
      ),
      kind: $checkedConvert(
        'kind',
        (v) => $enumDecode(_$StepComparisonChangeKindEnumEnumMap, v),
      ),
      relativeChange: $checkedConvert('relative_change', (v) => v as num?),
      ruleId: $checkedConvert('rule_id', (v) => v as String),
      rulesVersion: $checkedConvert('rules_version', (v) => v as String),
      unit: $checkedConvert('unit', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'relativeChange': 'relative_change',
    'ruleId': 'rule_id',
    'rulesVersion': 'rules_version',
  },
);

Map<String, dynamic> _$StepComparisonChangeToJson(
  StepComparisonChange instance,
) => <String, dynamic>{
  'after': ?instance.after,
  'basis': instance.basis,
  'before': ?instance.before,
  'field': instance.field,
  'grade': _$StepComparisonChangeGradeEnumEnumMap[instance.grade]!,
  'kind': _$StepComparisonChangeKindEnumEnumMap[instance.kind]!,
  'relative_change': ?instance.relativeChange,
  'rule_id': instance.ruleId,
  'rules_version': instance.rulesVersion,
  'unit': ?instance.unit,
};

const _$StepComparisonChangeGradeEnumEnumMap = {
  StepComparisonChangeGradeEnum.excluded: 'excluded',
  StepComparisonChangeGradeEnum.minor: 'minor',
  StepComparisonChangeGradeEnum.general: 'general',
  StepComparisonChangeGradeEnum.significant: 'significant',
};

const _$StepComparisonChangeKindEnumEnumMap = {
  StepComparisonChangeKindEnum.added: 'added',
  StepComparisonChangeKindEnum.removed: 'removed',
  StepComparisonChangeKindEnum.field: 'field',
  StepComparisonChangeKindEnum.text: 'text',
  StepComparisonChangeKindEnum.order: 'order',
};
