// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'taste_profile_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TasteProfileOutCWProxy {
  TasteProfileOut flavors(Map<String, TasteFlavorOut> flavors);

  TasteProfileOut id(String id);

  TasteProfileOut ingredientCategories(List<String> ingredientCategories);

  TasteProfileOut ingredientPreferences(
    List<IngredientPreferenceOut> ingredientPreferences,
  );

  TasteProfileOut localCuisines(List<LocalCuisineOut> localCuisines);

  TasteProfileOut scale(TasteScale scale);

  TasteProfileOut version(int version);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TasteProfileOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TasteProfileOut(...).copyWith(id: 12, name: "My name")
  /// ````
  TasteProfileOut call({
    Map<String, TasteFlavorOut> flavors,
    String id,
    List<String> ingredientCategories,
    List<IngredientPreferenceOut> ingredientPreferences,
    List<LocalCuisineOut> localCuisines,
    TasteScale scale,
    int version,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTasteProfileOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTasteProfileOut.copyWith.fieldName(...)`
class _$TasteProfileOutCWProxyImpl implements _$TasteProfileOutCWProxy {
  const _$TasteProfileOutCWProxyImpl(this._value);

  final TasteProfileOut _value;

  @override
  TasteProfileOut flavors(Map<String, TasteFlavorOut> flavors) =>
      this(flavors: flavors);

  @override
  TasteProfileOut id(String id) => this(id: id);

  @override
  TasteProfileOut ingredientCategories(List<String> ingredientCategories) =>
      this(ingredientCategories: ingredientCategories);

  @override
  TasteProfileOut ingredientPreferences(
    List<IngredientPreferenceOut> ingredientPreferences,
  ) => this(ingredientPreferences: ingredientPreferences);

  @override
  TasteProfileOut localCuisines(List<LocalCuisineOut> localCuisines) =>
      this(localCuisines: localCuisines);

  @override
  TasteProfileOut scale(TasteScale scale) => this(scale: scale);

  @override
  TasteProfileOut version(int version) => this(version: version);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TasteProfileOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TasteProfileOut(...).copyWith(id: 12, name: "My name")
  /// ````
  TasteProfileOut call({
    Object? flavors = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? ingredientCategories = const $CopyWithPlaceholder(),
    Object? ingredientPreferences = const $CopyWithPlaceholder(),
    Object? localCuisines = const $CopyWithPlaceholder(),
    Object? scale = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
  }) {
    return TasteProfileOut(
      flavors: flavors == const $CopyWithPlaceholder()
          ? _value.flavors
          // ignore: cast_nullable_to_non_nullable
          : flavors as Map<String, TasteFlavorOut>,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      ingredientCategories: ingredientCategories == const $CopyWithPlaceholder()
          ? _value.ingredientCategories
          // ignore: cast_nullable_to_non_nullable
          : ingredientCategories as List<String>,
      ingredientPreferences:
          ingredientPreferences == const $CopyWithPlaceholder()
          ? _value.ingredientPreferences
          // ignore: cast_nullable_to_non_nullable
          : ingredientPreferences as List<IngredientPreferenceOut>,
      localCuisines: localCuisines == const $CopyWithPlaceholder()
          ? _value.localCuisines
          // ignore: cast_nullable_to_non_nullable
          : localCuisines as List<LocalCuisineOut>,
      scale: scale == const $CopyWithPlaceholder()
          ? _value.scale
          // ignore: cast_nullable_to_non_nullable
          : scale as TasteScale,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
    );
  }
}

extension $TasteProfileOutCopyWith on TasteProfileOut {
  /// Returns a callable class that can be used as follows: `instanceOfTasteProfileOut.copyWith(...)` or like so:`instanceOfTasteProfileOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TasteProfileOutCWProxy get copyWith => _$TasteProfileOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TasteProfileOut _$TasteProfileOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'TasteProfileOut',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'flavors',
        'id',
        'ingredient_categories',
        'ingredient_preferences',
        'local_cuisines',
        'scale',
        'version',
      ],
    );
    final val = TasteProfileOut(
      flavors: $checkedConvert(
        'flavors',
        (v) => (v as Map<String, dynamic>).map(
          (k, e) =>
              MapEntry(k, TasteFlavorOut.fromJson(e as Map<String, dynamic>)),
        ),
      ),
      id: $checkedConvert('id', (v) => v as String),
      ingredientCategories: $checkedConvert(
        'ingredient_categories',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      ingredientPreferences: $checkedConvert(
        'ingredient_preferences',
        (v) => (v as List<dynamic>)
            .map(
              (e) =>
                  IngredientPreferenceOut.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      localCuisines: $checkedConvert(
        'local_cuisines',
        (v) => (v as List<dynamic>)
            .map((e) => LocalCuisineOut.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      scale: $checkedConvert(
        'scale',
        (v) => TasteScale.fromJson(v as Map<String, dynamic>),
      ),
      version: $checkedConvert('version', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'ingredientCategories': 'ingredient_categories',
    'ingredientPreferences': 'ingredient_preferences',
    'localCuisines': 'local_cuisines',
  },
);

Map<String, dynamic> _$TasteProfileOutToJson(TasteProfileOut instance) =>
    <String, dynamic>{
      'flavors': instance.flavors.map((k, e) => MapEntry(k, e.toJson())),
      'id': instance.id,
      'ingredient_categories': instance.ingredientCategories,
      'ingredient_preferences': instance.ingredientPreferences
          .map((e) => e.toJson())
          .toList(),
      'local_cuisines': instance.localCuisines.map((e) => e.toJson()).toList(),
      'scale': instance.scale.toJson(),
      'version': instance.version,
    };
