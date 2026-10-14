// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_preview.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletionPreviewCWProxy {
  DeletionPreview canExport(bool canExport);

  DeletionPreview deletes(List<String> deletes);

  DeletionPreview publicRecipeActionRequired(bool publicRecipeActionRequired);

  DeletionPreview publicRecipes(List<DeletionPublicRecipe> publicRecipes);

  DeletionPreview retains(List<String> retains);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DeletionPreview(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DeletionPreview(...).copyWith(id: 12, name: "My name")
  /// ````
  DeletionPreview call({
    bool canExport,
    List<String> deletes,
    bool publicRecipeActionRequired,
    List<DeletionPublicRecipe> publicRecipes,
    List<String> retains,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDeletionPreview.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDeletionPreview.copyWith.fieldName(...)`
class _$DeletionPreviewCWProxyImpl implements _$DeletionPreviewCWProxy {
  const _$DeletionPreviewCWProxyImpl(this._value);

  final DeletionPreview _value;

  @override
  DeletionPreview canExport(bool canExport) => this(canExport: canExport);

  @override
  DeletionPreview deletes(List<String> deletes) => this(deletes: deletes);

  @override
  DeletionPreview publicRecipeActionRequired(bool publicRecipeActionRequired) =>
      this(publicRecipeActionRequired: publicRecipeActionRequired);

  @override
  DeletionPreview publicRecipes(List<DeletionPublicRecipe> publicRecipes) =>
      this(publicRecipes: publicRecipes);

  @override
  DeletionPreview retains(List<String> retains) => this(retains: retains);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DeletionPreview(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DeletionPreview(...).copyWith(id: 12, name: "My name")
  /// ````
  DeletionPreview call({
    Object? canExport = const $CopyWithPlaceholder(),
    Object? deletes = const $CopyWithPlaceholder(),
    Object? publicRecipeActionRequired = const $CopyWithPlaceholder(),
    Object? publicRecipes = const $CopyWithPlaceholder(),
    Object? retains = const $CopyWithPlaceholder(),
  }) {
    return DeletionPreview(
      canExport: canExport == const $CopyWithPlaceholder()
          ? _value.canExport
          // ignore: cast_nullable_to_non_nullable
          : canExport as bool,
      deletes: deletes == const $CopyWithPlaceholder()
          ? _value.deletes
          // ignore: cast_nullable_to_non_nullable
          : deletes as List<String>,
      publicRecipeActionRequired:
          publicRecipeActionRequired == const $CopyWithPlaceholder()
          ? _value.publicRecipeActionRequired
          // ignore: cast_nullable_to_non_nullable
          : publicRecipeActionRequired as bool,
      publicRecipes: publicRecipes == const $CopyWithPlaceholder()
          ? _value.publicRecipes
          // ignore: cast_nullable_to_non_nullable
          : publicRecipes as List<DeletionPublicRecipe>,
      retains: retains == const $CopyWithPlaceholder()
          ? _value.retains
          // ignore: cast_nullable_to_non_nullable
          : retains as List<String>,
    );
  }
}

extension $DeletionPreviewCopyWith on DeletionPreview {
  /// Returns a callable class that can be used as follows: `instanceOfDeletionPreview.copyWith(...)` or like so:`instanceOfDeletionPreview.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletionPreviewCWProxy get copyWith => _$DeletionPreviewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletionPreview _$DeletionPreviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DeletionPreview',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'can_export',
            'deletes',
            'public_recipe_action_required',
            'public_recipes',
            'retains',
          ],
        );
        final val = DeletionPreview(
          canExport: $checkedConvert('can_export', (v) => v as bool),
          deletes: $checkedConvert(
            'deletes',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          publicRecipeActionRequired: $checkedConvert(
            'public_recipe_action_required',
            (v) => v as bool,
          ),
          publicRecipes: $checkedConvert(
            'public_recipes',
            (v) => (v as List<dynamic>)
                .map(
                  (e) =>
                      DeletionPublicRecipe.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
          ),
          retains: $checkedConvert(
            'retains',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'canExport': 'can_export',
        'publicRecipeActionRequired': 'public_recipe_action_required',
        'publicRecipes': 'public_recipes',
      },
    );

Map<String, dynamic> _$DeletionPreviewToJson(DeletionPreview instance) =>
    <String, dynamic>{
      'can_export': instance.canExport,
      'deletes': instance.deletes,
      'public_recipe_action_required': instance.publicRecipeActionRequired,
      'public_recipes': instance.publicRecipes.map((e) => e.toJson()).toList(),
      'retains': instance.retains,
    };
