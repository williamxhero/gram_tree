// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'graded_ingredient_comparison_row.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GradedIngredientComparisonRowCWProxy {
  GradedIngredientComparisonRow after(RecipeIngredient? after);

  GradedIngredientComparisonRow before(RecipeIngredient? before);

  GradedIngredientComparisonRow changes(List<GradedComparisonChange>? changes);

  GradedIngredientComparisonRow pairing(
    GradedIngredientComparisonRowPairingEnum pairing,
  );

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradedIngredientComparisonRow(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradedIngredientComparisonRow(...).copyWith(id: 12, name: "My name")
  /// ````
  GradedIngredientComparisonRow call({
    RecipeIngredient? after,
    RecipeIngredient? before,
    List<GradedComparisonChange>? changes,
    GradedIngredientComparisonRowPairingEnum pairing,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGradedIngredientComparisonRow.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGradedIngredientComparisonRow.copyWith.fieldName(...)`
class _$GradedIngredientComparisonRowCWProxyImpl
    implements _$GradedIngredientComparisonRowCWProxy {
  const _$GradedIngredientComparisonRowCWProxyImpl(this._value);

  final GradedIngredientComparisonRow _value;

  @override
  GradedIngredientComparisonRow after(RecipeIngredient? after) =>
      this(after: after);

  @override
  GradedIngredientComparisonRow before(RecipeIngredient? before) =>
      this(before: before);

  @override
  GradedIngredientComparisonRow changes(
    List<GradedComparisonChange>? changes,
  ) => this(changes: changes);

  @override
  GradedIngredientComparisonRow pairing(
    GradedIngredientComparisonRowPairingEnum pairing,
  ) => this(pairing: pairing);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradedIngredientComparisonRow(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradedIngredientComparisonRow(...).copyWith(id: 12, name: "My name")
  /// ````
  GradedIngredientComparisonRow call({
    Object? after = const $CopyWithPlaceholder(),
    Object? before = const $CopyWithPlaceholder(),
    Object? changes = const $CopyWithPlaceholder(),
    Object? pairing = const $CopyWithPlaceholder(),
  }) {
    return GradedIngredientComparisonRow(
      after: after == const $CopyWithPlaceholder()
          ? _value.after
          // ignore: cast_nullable_to_non_nullable
          : after as RecipeIngredient?,
      before: before == const $CopyWithPlaceholder()
          ? _value.before
          // ignore: cast_nullable_to_non_nullable
          : before as RecipeIngredient?,
      changes: changes == const $CopyWithPlaceholder()
          ? _value.changes
          // ignore: cast_nullable_to_non_nullable
          : changes as List<GradedComparisonChange>?,
      pairing: pairing == const $CopyWithPlaceholder()
          ? _value.pairing
          // ignore: cast_nullable_to_non_nullable
          : pairing as GradedIngredientComparisonRowPairingEnum,
    );
  }
}

extension $GradedIngredientComparisonRowCopyWith
    on GradedIngredientComparisonRow {
  /// Returns a callable class that can be used as follows: `instanceOfGradedIngredientComparisonRow.copyWith(...)` or like so:`instanceOfGradedIngredientComparisonRow.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GradedIngredientComparisonRowCWProxy get copyWith =>
      _$GradedIngredientComparisonRowCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GradedIngredientComparisonRow _$GradedIngredientComparisonRowFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GradedIngredientComparisonRow', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['pairing']);
  final val = GradedIngredientComparisonRow(
    after: $checkedConvert(
      'after',
      (v) => v == null
          ? null
          : RecipeIngredient.fromJson(v as Map<String, dynamic>),
    ),
    before: $checkedConvert(
      'before',
      (v) => v == null
          ? null
          : RecipeIngredient.fromJson(v as Map<String, dynamic>),
    ),
    changes: $checkedConvert(
      'changes',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => GradedComparisonChange.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    pairing: $checkedConvert(
      'pairing',
      (v) => $enumDecode(_$GradedIngredientComparisonRowPairingEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$GradedIngredientComparisonRowToJson(
  GradedIngredientComparisonRow instance,
) => <String, dynamic>{
  'after': ?instance.after?.toJson(),
  'before': ?instance.before?.toJson(),
  'changes': ?instance.changes?.map((e) => e.toJson()).toList(),
  'pairing':
      _$GradedIngredientComparisonRowPairingEnumEnumMap[instance.pairing]!,
};

const _$GradedIngredientComparisonRowPairingEnumEnumMap = {
  GradedIngredientComparisonRowPairingEnum.stableId: 'stable_id',
  GradedIngredientComparisonRowPairingEnum.identityGroup: 'identity_group',
  GradedIngredientComparisonRowPairingEnum.groupReplacement:
      'group_replacement',
  GradedIngredientComparisonRowPairingEnum.unpaired: 'unpaired',
};
