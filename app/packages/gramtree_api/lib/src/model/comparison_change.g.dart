// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comparison_change.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComparisonChangeCWProxy {
  ComparisonChange after(Object? after);

  ComparisonChange basis(String basis);

  ComparisonChange before(Object? before);

  ComparisonChange field(String field);

  ComparisonChange kind(ComparisonChangeKindEnum kind);

  ComparisonChange relativeChange(num? relativeChange);

  ComparisonChange unit(String? unit);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComparisonChange(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComparisonChange(...).copyWith(id: 12, name: "My name")
  /// ````
  ComparisonChange call({
    Object? after,
    String basis,
    Object? before,
    String field,
    ComparisonChangeKindEnum kind,
    num? relativeChange,
    String? unit,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfComparisonChange.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfComparisonChange.copyWith.fieldName(...)`
class _$ComparisonChangeCWProxyImpl implements _$ComparisonChangeCWProxy {
  const _$ComparisonChangeCWProxyImpl(this._value);

  final ComparisonChange _value;

  @override
  ComparisonChange after(Object? after) => this(after: after);

  @override
  ComparisonChange basis(String basis) => this(basis: basis);

  @override
  ComparisonChange before(Object? before) => this(before: before);

  @override
  ComparisonChange field(String field) => this(field: field);

  @override
  ComparisonChange kind(ComparisonChangeKindEnum kind) => this(kind: kind);

  @override
  ComparisonChange relativeChange(num? relativeChange) =>
      this(relativeChange: relativeChange);

  @override
  ComparisonChange unit(String? unit) => this(unit: unit);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComparisonChange(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComparisonChange(...).copyWith(id: 12, name: "My name")
  /// ````
  ComparisonChange call({
    Object? after = const $CopyWithPlaceholder(),
    Object? basis = const $CopyWithPlaceholder(),
    Object? before = const $CopyWithPlaceholder(),
    Object? field = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? relativeChange = const $CopyWithPlaceholder(),
    Object? unit = const $CopyWithPlaceholder(),
  }) {
    return ComparisonChange(
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
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as ComparisonChangeKindEnum,
      relativeChange: relativeChange == const $CopyWithPlaceholder()
          ? _value.relativeChange
          // ignore: cast_nullable_to_non_nullable
          : relativeChange as num?,
      unit: unit == const $CopyWithPlaceholder()
          ? _value.unit
          // ignore: cast_nullable_to_non_nullable
          : unit as String?,
    );
  }
}

extension $ComparisonChangeCopyWith on ComparisonChange {
  /// Returns a callable class that can be used as follows: `instanceOfComparisonChange.copyWith(...)` or like so:`instanceOfComparisonChange.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComparisonChangeCWProxy get copyWith => _$ComparisonChangeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComparisonChange _$ComparisonChangeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ComparisonChange', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['basis', 'field', 'kind']);
      final val = ComparisonChange(
        after: $checkedConvert('after', (v) => v),
        basis: $checkedConvert('basis', (v) => v as String),
        before: $checkedConvert('before', (v) => v),
        field: $checkedConvert('field', (v) => v as String),
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$ComparisonChangeKindEnumEnumMap, v),
        ),
        relativeChange: $checkedConvert('relative_change', (v) => v as num?),
        unit: $checkedConvert('unit', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'relativeChange': 'relative_change'});

Map<String, dynamic> _$ComparisonChangeToJson(ComparisonChange instance) =>
    <String, dynamic>{
      'after': ?instance.after,
      'basis': instance.basis,
      'before': ?instance.before,
      'field': instance.field,
      'kind': _$ComparisonChangeKindEnumEnumMap[instance.kind]!,
      'relative_change': ?instance.relativeChange,
      'unit': ?instance.unit,
    };

const _$ComparisonChangeKindEnumEnumMap = {
  ComparisonChangeKindEnum.added: 'added',
  ComparisonChangeKindEnum.removed: 'removed',
  ComparisonChangeKindEnum.replacement: 'replacement',
  ComparisonChangeKindEnum.quantity: 'quantity',
  ComparisonChangeKindEnum.unit: 'unit',
  ComparisonChangeKindEnum.field: 'field',
  ComparisonChangeKindEnum.text: 'text',
};
