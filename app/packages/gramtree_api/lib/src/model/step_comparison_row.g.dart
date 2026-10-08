// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'step_comparison_row.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StepComparisonRowCWProxy {
  StepComparisonRow after(RecipeStep? after);

  StepComparisonRow afterIndex(int? afterIndex);

  StepComparisonRow alignment(StepComparisonRowAlignmentEnum alignment);

  StepComparisonRow basis(String basis);

  StepComparisonRow before(RecipeStep? before);

  StepComparisonRow beforeIndex(int? beforeIndex);

  StepComparisonRow changes(List<StepComparisonChange>? changes);

  StepComparisonRow confidence(num confidence);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StepComparisonRow(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StepComparisonRow(...).copyWith(id: 12, name: "My name")
  /// ````
  StepComparisonRow call({
    RecipeStep? after,
    int? afterIndex,
    StepComparisonRowAlignmentEnum alignment,
    String basis,
    RecipeStep? before,
    int? beforeIndex,
    List<StepComparisonChange>? changes,
    num confidence,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStepComparisonRow.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStepComparisonRow.copyWith.fieldName(...)`
class _$StepComparisonRowCWProxyImpl implements _$StepComparisonRowCWProxy {
  const _$StepComparisonRowCWProxyImpl(this._value);

  final StepComparisonRow _value;

  @override
  StepComparisonRow after(RecipeStep? after) => this(after: after);

  @override
  StepComparisonRow afterIndex(int? afterIndex) => this(afterIndex: afterIndex);

  @override
  StepComparisonRow alignment(StepComparisonRowAlignmentEnum alignment) =>
      this(alignment: alignment);

  @override
  StepComparisonRow basis(String basis) => this(basis: basis);

  @override
  StepComparisonRow before(RecipeStep? before) => this(before: before);

  @override
  StepComparisonRow beforeIndex(int? beforeIndex) =>
      this(beforeIndex: beforeIndex);

  @override
  StepComparisonRow changes(List<StepComparisonChange>? changes) =>
      this(changes: changes);

  @override
  StepComparisonRow confidence(num confidence) => this(confidence: confidence);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StepComparisonRow(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StepComparisonRow(...).copyWith(id: 12, name: "My name")
  /// ````
  StepComparisonRow call({
    Object? after = const $CopyWithPlaceholder(),
    Object? afterIndex = const $CopyWithPlaceholder(),
    Object? alignment = const $CopyWithPlaceholder(),
    Object? basis = const $CopyWithPlaceholder(),
    Object? before = const $CopyWithPlaceholder(),
    Object? beforeIndex = const $CopyWithPlaceholder(),
    Object? changes = const $CopyWithPlaceholder(),
    Object? confidence = const $CopyWithPlaceholder(),
  }) {
    return StepComparisonRow(
      after: after == const $CopyWithPlaceholder()
          ? _value.after
          // ignore: cast_nullable_to_non_nullable
          : after as RecipeStep?,
      afterIndex: afterIndex == const $CopyWithPlaceholder()
          ? _value.afterIndex
          // ignore: cast_nullable_to_non_nullable
          : afterIndex as int?,
      alignment: alignment == const $CopyWithPlaceholder()
          ? _value.alignment
          // ignore: cast_nullable_to_non_nullable
          : alignment as StepComparisonRowAlignmentEnum,
      basis: basis == const $CopyWithPlaceholder()
          ? _value.basis
          // ignore: cast_nullable_to_non_nullable
          : basis as String,
      before: before == const $CopyWithPlaceholder()
          ? _value.before
          // ignore: cast_nullable_to_non_nullable
          : before as RecipeStep?,
      beforeIndex: beforeIndex == const $CopyWithPlaceholder()
          ? _value.beforeIndex
          // ignore: cast_nullable_to_non_nullable
          : beforeIndex as int?,
      changes: changes == const $CopyWithPlaceholder()
          ? _value.changes
          // ignore: cast_nullable_to_non_nullable
          : changes as List<StepComparisonChange>?,
      confidence: confidence == const $CopyWithPlaceholder()
          ? _value.confidence
          // ignore: cast_nullable_to_non_nullable
          : confidence as num,
    );
  }
}

extension $StepComparisonRowCopyWith on StepComparisonRow {
  /// Returns a callable class that can be used as follows: `instanceOfStepComparisonRow.copyWith(...)` or like so:`instanceOfStepComparisonRow.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StepComparisonRowCWProxy get copyWith =>
      _$StepComparisonRowCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StepComparisonRow _$StepComparisonRowFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'StepComparisonRow',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['alignment', 'basis', 'confidence']);
    final val = StepComparisonRow(
      after: $checkedConvert(
        'after',
        (v) =>
            v == null ? null : RecipeStep.fromJson(v as Map<String, dynamic>),
      ),
      afterIndex: $checkedConvert('after_index', (v) => (v as num?)?.toInt()),
      alignment: $checkedConvert(
        'alignment',
        (v) => $enumDecode(_$StepComparisonRowAlignmentEnumEnumMap, v),
      ),
      basis: $checkedConvert('basis', (v) => v as String),
      before: $checkedConvert(
        'before',
        (v) =>
            v == null ? null : RecipeStep.fromJson(v as Map<String, dynamic>),
      ),
      beforeIndex: $checkedConvert('before_index', (v) => (v as num?)?.toInt()),
      changes: $checkedConvert(
        'changes',
        (v) => (v as List<dynamic>?)
            ?.map(
              (e) => StepComparisonChange.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      confidence: $checkedConvert('confidence', (v) => v as num),
    );
    return val;
  },
  fieldKeyMap: const {
    'afterIndex': 'after_index',
    'beforeIndex': 'before_index',
  },
);

Map<String, dynamic> _$StepComparisonRowToJson(StepComparisonRow instance) =>
    <String, dynamic>{
      'after': ?instance.after?.toJson(),
      'after_index': ?instance.afterIndex,
      'alignment': _$StepComparisonRowAlignmentEnumEnumMap[instance.alignment]!,
      'basis': instance.basis,
      'before': ?instance.before?.toJson(),
      'before_index': ?instance.beforeIndex,
      'changes': ?instance.changes?.map((e) => e.toJson()).toList(),
      'confidence': instance.confidence,
    };

const _$StepComparisonRowAlignmentEnumEnumMap = {
  StepComparisonRowAlignmentEnum.deterministic: 'deterministic',
  StepComparisonRowAlignmentEnum.uncertain: 'uncertain',
  StepComparisonRowAlignmentEnum.unpaired: 'unpaired',
};
