// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'graded_comparison_change.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GradedComparisonChangeCWProxy {
  GradedComparisonChange after(Object? after);

  GradedComparisonChange basis(String basis);

  GradedComparisonChange before(Object? before);

  GradedComparisonChange field(String field);

  GradedComparisonChange grade(GradedComparisonChangeGradeEnum grade);

  GradedComparisonChange kind(GradedComparisonChangeKindEnum kind);

  GradedComparisonChange relativeChange(num? relativeChange);

  GradedComparisonChange ruleId(String ruleId);

  GradedComparisonChange rulesVersion(String rulesVersion);

  GradedComparisonChange unit(String? unit);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradedComparisonChange(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradedComparisonChange(...).copyWith(id: 12, name: "My name")
  /// ````
  GradedComparisonChange call({
    Object? after,
    String basis,
    Object? before,
    String field,
    GradedComparisonChangeGradeEnum grade,
    GradedComparisonChangeKindEnum kind,
    num? relativeChange,
    String ruleId,
    String rulesVersion,
    String? unit,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGradedComparisonChange.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGradedComparisonChange.copyWith.fieldName(...)`
class _$GradedComparisonChangeCWProxyImpl
    implements _$GradedComparisonChangeCWProxy {
  const _$GradedComparisonChangeCWProxyImpl(this._value);

  final GradedComparisonChange _value;

  @override
  GradedComparisonChange after(Object? after) => this(after: after);

  @override
  GradedComparisonChange basis(String basis) => this(basis: basis);

  @override
  GradedComparisonChange before(Object? before) => this(before: before);

  @override
  GradedComparisonChange field(String field) => this(field: field);

  @override
  GradedComparisonChange grade(GradedComparisonChangeGradeEnum grade) =>
      this(grade: grade);

  @override
  GradedComparisonChange kind(GradedComparisonChangeKindEnum kind) =>
      this(kind: kind);

  @override
  GradedComparisonChange relativeChange(num? relativeChange) =>
      this(relativeChange: relativeChange);

  @override
  GradedComparisonChange ruleId(String ruleId) => this(ruleId: ruleId);

  @override
  GradedComparisonChange rulesVersion(String rulesVersion) =>
      this(rulesVersion: rulesVersion);

  @override
  GradedComparisonChange unit(String? unit) => this(unit: unit);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradedComparisonChange(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradedComparisonChange(...).copyWith(id: 12, name: "My name")
  /// ````
  GradedComparisonChange call({
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
    return GradedComparisonChange(
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
          : grade as GradedComparisonChangeGradeEnum,
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as GradedComparisonChangeKindEnum,
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

extension $GradedComparisonChangeCopyWith on GradedComparisonChange {
  /// Returns a callable class that can be used as follows: `instanceOfGradedComparisonChange.copyWith(...)` or like so:`instanceOfGradedComparisonChange.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GradedComparisonChangeCWProxy get copyWith =>
      _$GradedComparisonChangeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GradedComparisonChange _$GradedComparisonChangeFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'GradedComparisonChange',
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
    final val = GradedComparisonChange(
      after: $checkedConvert('after', (v) => v),
      basis: $checkedConvert('basis', (v) => v as String),
      before: $checkedConvert('before', (v) => v),
      field: $checkedConvert('field', (v) => v as String),
      grade: $checkedConvert(
        'grade',
        (v) => $enumDecode(_$GradedComparisonChangeGradeEnumEnumMap, v),
      ),
      kind: $checkedConvert(
        'kind',
        (v) => $enumDecode(_$GradedComparisonChangeKindEnumEnumMap, v),
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

Map<String, dynamic> _$GradedComparisonChangeToJson(
  GradedComparisonChange instance,
) => <String, dynamic>{
  'after': ?instance.after,
  'basis': instance.basis,
  'before': ?instance.before,
  'field': instance.field,
  'grade': _$GradedComparisonChangeGradeEnumEnumMap[instance.grade]!,
  'kind': _$GradedComparisonChangeKindEnumEnumMap[instance.kind]!,
  'relative_change': ?instance.relativeChange,
  'rule_id': instance.ruleId,
  'rules_version': instance.rulesVersion,
  'unit': ?instance.unit,
};

const _$GradedComparisonChangeGradeEnumEnumMap = {
  GradedComparisonChangeGradeEnum.excluded: 'excluded',
  GradedComparisonChangeGradeEnum.minor: 'minor',
  GradedComparisonChangeGradeEnum.general: 'general',
  GradedComparisonChangeGradeEnum.significant: 'significant',
};

const _$GradedComparisonChangeKindEnumEnumMap = {
  GradedComparisonChangeKindEnum.added: 'added',
  GradedComparisonChangeKindEnum.removed: 'removed',
  GradedComparisonChangeKindEnum.replacement: 'replacement',
  GradedComparisonChangeKindEnum.quantity: 'quantity',
  GradedComparisonChangeKindEnum.unit: 'unit',
  GradedComparisonChangeKindEnum.field: 'field',
  GradedComparisonChangeKindEnum.text: 'text',
};
