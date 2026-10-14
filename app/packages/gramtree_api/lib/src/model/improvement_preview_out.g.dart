// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'improvement_preview_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ImprovementPreviewOutCWProxy {
  ImprovementPreviewOut comparison(RecipeFullComparison comparison);

  ImprovementPreviewOut microadjustPrompt(String? microadjustPrompt);

  ImprovementPreviewOut snapshot(RecipeSnapshot snapshot);

  ImprovementPreviewOut tasteProposal(ImprovementTasteProposal tasteProposal);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ImprovementPreviewOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ImprovementPreviewOut(...).copyWith(id: 12, name: "My name")
  /// ````
  ImprovementPreviewOut call({
    RecipeFullComparison comparison,
    String? microadjustPrompt,
    RecipeSnapshot snapshot,
    ImprovementTasteProposal tasteProposal,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfImprovementPreviewOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfImprovementPreviewOut.copyWith.fieldName(...)`
class _$ImprovementPreviewOutCWProxyImpl
    implements _$ImprovementPreviewOutCWProxy {
  const _$ImprovementPreviewOutCWProxyImpl(this._value);

  final ImprovementPreviewOut _value;

  @override
  ImprovementPreviewOut comparison(RecipeFullComparison comparison) =>
      this(comparison: comparison);

  @override
  ImprovementPreviewOut microadjustPrompt(String? microadjustPrompt) =>
      this(microadjustPrompt: microadjustPrompt);

  @override
  ImprovementPreviewOut snapshot(RecipeSnapshot snapshot) =>
      this(snapshot: snapshot);

  @override
  ImprovementPreviewOut tasteProposal(ImprovementTasteProposal tasteProposal) =>
      this(tasteProposal: tasteProposal);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ImprovementPreviewOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ImprovementPreviewOut(...).copyWith(id: 12, name: "My name")
  /// ````
  ImprovementPreviewOut call({
    Object? comparison = const $CopyWithPlaceholder(),
    Object? microadjustPrompt = const $CopyWithPlaceholder(),
    Object? snapshot = const $CopyWithPlaceholder(),
    Object? tasteProposal = const $CopyWithPlaceholder(),
  }) {
    return ImprovementPreviewOut(
      comparison: comparison == const $CopyWithPlaceholder()
          ? _value.comparison
          // ignore: cast_nullable_to_non_nullable
          : comparison as RecipeFullComparison,
      microadjustPrompt: microadjustPrompt == const $CopyWithPlaceholder()
          ? _value.microadjustPrompt
          // ignore: cast_nullable_to_non_nullable
          : microadjustPrompt as String?,
      snapshot: snapshot == const $CopyWithPlaceholder()
          ? _value.snapshot
          // ignore: cast_nullable_to_non_nullable
          : snapshot as RecipeSnapshot,
      tasteProposal: tasteProposal == const $CopyWithPlaceholder()
          ? _value.tasteProposal
          // ignore: cast_nullable_to_non_nullable
          : tasteProposal as ImprovementTasteProposal,
    );
  }
}

extension $ImprovementPreviewOutCopyWith on ImprovementPreviewOut {
  /// Returns a callable class that can be used as follows: `instanceOfImprovementPreviewOut.copyWith(...)` or like so:`instanceOfImprovementPreviewOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ImprovementPreviewOutCWProxy get copyWith =>
      _$ImprovementPreviewOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImprovementPreviewOut _$ImprovementPreviewOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ImprovementPreviewOut',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['comparison', 'snapshot', 'taste_proposal'],
    );
    final val = ImprovementPreviewOut(
      comparison: $checkedConvert(
        'comparison',
        (v) => RecipeFullComparison.fromJson(v as Map<String, dynamic>),
      ),
      microadjustPrompt: $checkedConvert(
        'microadjust_prompt',
        (v) => v as String?,
      ),
      snapshot: $checkedConvert(
        'snapshot',
        (v) => RecipeSnapshot.fromJson(v as Map<String, dynamic>),
      ),
      tasteProposal: $checkedConvert(
        'taste_proposal',
        (v) => ImprovementTasteProposal.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'microadjustPrompt': 'microadjust_prompt',
    'tasteProposal': 'taste_proposal',
  },
);

Map<String, dynamic> _$ImprovementPreviewOutToJson(
  ImprovementPreviewOut instance,
) => <String, dynamic>{
  'comparison': instance.comparison.toJson(),
  'microadjust_prompt': ?instance.microadjustPrompt,
  'snapshot': instance.snapshot.toJson(),
  'taste_proposal': instance.tasteProposal.toJson(),
};
