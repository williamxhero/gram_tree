// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_comparison_row.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IngredientComparisonRowCWProxy {
  IngredientComparisonRow after(RecipeIngredient? after);

  IngredientComparisonRow before(RecipeIngredient? before);

  IngredientComparisonRow changes(List<ComparisonChange>? changes);

  IngredientComparisonRow pairing(IngredientComparisonRowPairingEnum pairing);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IngredientComparisonRow(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IngredientComparisonRow(...).copyWith(id: 12, name: "My name")
  /// ````
  IngredientComparisonRow call({
    RecipeIngredient? after,
    RecipeIngredient? before,
    List<ComparisonChange>? changes,
    IngredientComparisonRowPairingEnum pairing,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfIngredientComparisonRow.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfIngredientComparisonRow.copyWith.fieldName(...)`
class _$IngredientComparisonRowCWProxyImpl
    implements _$IngredientComparisonRowCWProxy {
  const _$IngredientComparisonRowCWProxyImpl(this._value);

  final IngredientComparisonRow _value;

  @override
  IngredientComparisonRow after(RecipeIngredient? after) => this(after: after);

  @override
  IngredientComparisonRow before(RecipeIngredient? before) =>
      this(before: before);

  @override
  IngredientComparisonRow changes(List<ComparisonChange>? changes) =>
      this(changes: changes);

  @override
  IngredientComparisonRow pairing(IngredientComparisonRowPairingEnum pairing) =>
      this(pairing: pairing);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IngredientComparisonRow(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IngredientComparisonRow(...).copyWith(id: 12, name: "My name")
  /// ````
  IngredientComparisonRow call({
    Object? after = const $CopyWithPlaceholder(),
    Object? before = const $CopyWithPlaceholder(),
    Object? changes = const $CopyWithPlaceholder(),
    Object? pairing = const $CopyWithPlaceholder(),
  }) {
    return IngredientComparisonRow(
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
          : changes as List<ComparisonChange>?,
      pairing: pairing == const $CopyWithPlaceholder()
          ? _value.pairing
          // ignore: cast_nullable_to_non_nullable
          : pairing as IngredientComparisonRowPairingEnum,
    );
  }
}

extension $IngredientComparisonRowCopyWith on IngredientComparisonRow {
  /// Returns a callable class that can be used as follows: `instanceOfIngredientComparisonRow.copyWith(...)` or like so:`instanceOfIngredientComparisonRow.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$IngredientComparisonRowCWProxy get copyWith =>
      _$IngredientComparisonRowCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IngredientComparisonRow _$IngredientComparisonRowFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('IngredientComparisonRow', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['pairing']);
  final val = IngredientComparisonRow(
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
          ?.map((e) => ComparisonChange.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    pairing: $checkedConvert(
      'pairing',
      (v) => $enumDecode(_$IngredientComparisonRowPairingEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$IngredientComparisonRowToJson(
  IngredientComparisonRow instance,
) => <String, dynamic>{
  'after': ?instance.after?.toJson(),
  'before': ?instance.before?.toJson(),
  'changes': ?instance.changes?.map((e) => e.toJson()).toList(),
  'pairing': _$IngredientComparisonRowPairingEnumEnumMap[instance.pairing]!,
};

const _$IngredientComparisonRowPairingEnumEnumMap = {
  IngredientComparisonRowPairingEnum.stableId: 'stable_id',
  IngredientComparisonRowPairingEnum.identityGroup: 'identity_group',
  IngredientComparisonRowPairingEnum.groupReplacement: 'group_replacement',
  IngredientComparisonRowPairingEnum.unpaired: 'unpaired',
};
