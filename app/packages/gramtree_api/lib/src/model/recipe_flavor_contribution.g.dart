// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_flavor_contribution.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeFlavorContributionCWProxy {
  RecipeFlavorContribution numbing(int? numbing);

  RecipeFlavorContribution oily(int? oily);

  RecipeFlavorContribution salty(int? salty);

  RecipeFlavorContribution sour(int? sour);

  RecipeFlavorContribution spicy(int? spicy);

  RecipeFlavorContribution sweet(int? sweet);

  RecipeFlavorContribution umami(int? umami);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeFlavorContribution(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeFlavorContribution(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeFlavorContribution call({
    int? numbing,
    int? oily,
    int? salty,
    int? sour,
    int? spicy,
    int? sweet,
    int? umami,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeFlavorContribution.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeFlavorContribution.copyWith.fieldName(...)`
class _$RecipeFlavorContributionCWProxyImpl
    implements _$RecipeFlavorContributionCWProxy {
  const _$RecipeFlavorContributionCWProxyImpl(this._value);

  final RecipeFlavorContribution _value;

  @override
  RecipeFlavorContribution numbing(int? numbing) => this(numbing: numbing);

  @override
  RecipeFlavorContribution oily(int? oily) => this(oily: oily);

  @override
  RecipeFlavorContribution salty(int? salty) => this(salty: salty);

  @override
  RecipeFlavorContribution sour(int? sour) => this(sour: sour);

  @override
  RecipeFlavorContribution spicy(int? spicy) => this(spicy: spicy);

  @override
  RecipeFlavorContribution sweet(int? sweet) => this(sweet: sweet);

  @override
  RecipeFlavorContribution umami(int? umami) => this(umami: umami);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeFlavorContribution(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeFlavorContribution(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeFlavorContribution call({
    Object? numbing = const $CopyWithPlaceholder(),
    Object? oily = const $CopyWithPlaceholder(),
    Object? salty = const $CopyWithPlaceholder(),
    Object? sour = const $CopyWithPlaceholder(),
    Object? spicy = const $CopyWithPlaceholder(),
    Object? sweet = const $CopyWithPlaceholder(),
    Object? umami = const $CopyWithPlaceholder(),
  }) {
    return RecipeFlavorContribution(
      numbing: numbing == const $CopyWithPlaceholder()
          ? _value.numbing
          // ignore: cast_nullable_to_non_nullable
          : numbing as int?,
      oily: oily == const $CopyWithPlaceholder()
          ? _value.oily
          // ignore: cast_nullable_to_non_nullable
          : oily as int?,
      salty: salty == const $CopyWithPlaceholder()
          ? _value.salty
          // ignore: cast_nullable_to_non_nullable
          : salty as int?,
      sour: sour == const $CopyWithPlaceholder()
          ? _value.sour
          // ignore: cast_nullable_to_non_nullable
          : sour as int?,
      spicy: spicy == const $CopyWithPlaceholder()
          ? _value.spicy
          // ignore: cast_nullable_to_non_nullable
          : spicy as int?,
      sweet: sweet == const $CopyWithPlaceholder()
          ? _value.sweet
          // ignore: cast_nullable_to_non_nullable
          : sweet as int?,
      umami: umami == const $CopyWithPlaceholder()
          ? _value.umami
          // ignore: cast_nullable_to_non_nullable
          : umami as int?,
    );
  }
}

extension $RecipeFlavorContributionCopyWith on RecipeFlavorContribution {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeFlavorContribution.copyWith(...)` or like so:`instanceOfRecipeFlavorContribution.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeFlavorContributionCWProxy get copyWith =>
      _$RecipeFlavorContributionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeFlavorContribution _$RecipeFlavorContributionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecipeFlavorContribution', json, ($checkedConvert) {
  final val = RecipeFlavorContribution(
    numbing: $checkedConvert('numbing', (v) => (v as num?)?.toInt()),
    oily: $checkedConvert('oily', (v) => (v as num?)?.toInt()),
    salty: $checkedConvert('salty', (v) => (v as num?)?.toInt()),
    sour: $checkedConvert('sour', (v) => (v as num?)?.toInt()),
    spicy: $checkedConvert('spicy', (v) => (v as num?)?.toInt()),
    sweet: $checkedConvert('sweet', (v) => (v as num?)?.toInt()),
    umami: $checkedConvert('umami', (v) => (v as num?)?.toInt()),
  );
  return val;
});

Map<String, dynamic> _$RecipeFlavorContributionToJson(
  RecipeFlavorContribution instance,
) => <String, dynamic>{
  'numbing': ?instance.numbing,
  'oily': ?instance.oily,
  'salty': ?instance.salty,
  'sour': ?instance.sour,
  'spicy': ?instance.spicy,
  'sweet': ?instance.sweet,
  'umami': ?instance.umami,
};
