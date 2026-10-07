// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generated_draft.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GeneratedDraftCWProxy {
  GeneratedDraft cuisine(String cuisine);

  GeneratedDraft rationale(String rationale);

  GeneratedDraft recipe(RecipeCreate recipe);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GeneratedDraft(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GeneratedDraft(...).copyWith(id: 12, name: "My name")
  /// ````
  GeneratedDraft call({String cuisine, String rationale, RecipeCreate recipe});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGeneratedDraft.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGeneratedDraft.copyWith.fieldName(...)`
class _$GeneratedDraftCWProxyImpl implements _$GeneratedDraftCWProxy {
  const _$GeneratedDraftCWProxyImpl(this._value);

  final GeneratedDraft _value;

  @override
  GeneratedDraft cuisine(String cuisine) => this(cuisine: cuisine);

  @override
  GeneratedDraft rationale(String rationale) => this(rationale: rationale);

  @override
  GeneratedDraft recipe(RecipeCreate recipe) => this(recipe: recipe);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GeneratedDraft(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GeneratedDraft(...).copyWith(id: 12, name: "My name")
  /// ````
  GeneratedDraft call({
    Object? cuisine = const $CopyWithPlaceholder(),
    Object? rationale = const $CopyWithPlaceholder(),
    Object? recipe = const $CopyWithPlaceholder(),
  }) {
    return GeneratedDraft(
      cuisine: cuisine == const $CopyWithPlaceholder()
          ? _value.cuisine
          // ignore: cast_nullable_to_non_nullable
          : cuisine as String,
      rationale: rationale == const $CopyWithPlaceholder()
          ? _value.rationale
          // ignore: cast_nullable_to_non_nullable
          : rationale as String,
      recipe: recipe == const $CopyWithPlaceholder()
          ? _value.recipe
          // ignore: cast_nullable_to_non_nullable
          : recipe as RecipeCreate,
    );
  }
}

extension $GeneratedDraftCopyWith on GeneratedDraft {
  /// Returns a callable class that can be used as follows: `instanceOfGeneratedDraft.copyWith(...)` or like so:`instanceOfGeneratedDraft.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GeneratedDraftCWProxy get copyWith => _$GeneratedDraftCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratedDraft _$GeneratedDraftFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GeneratedDraft', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['cuisine', 'rationale', 'recipe']);
      final val = GeneratedDraft(
        cuisine: $checkedConvert('cuisine', (v) => v as String),
        rationale: $checkedConvert('rationale', (v) => v as String),
        recipe: $checkedConvert(
          'recipe',
          (v) => RecipeCreate.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GeneratedDraftToJson(GeneratedDraft instance) =>
    <String, dynamic>{
      'cuisine': instance.cuisine,
      'rationale': instance.rationale,
      'recipe': instance.recipe.toJson(),
    };
