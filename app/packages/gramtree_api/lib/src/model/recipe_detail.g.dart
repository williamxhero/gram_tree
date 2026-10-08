// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_detail.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeDetailCWProxy {
  RecipeDetail author(RecipeAuthor author);

  RecipeDetail createdAt(String createdAt);

  RecipeDetail defaultServings(int? defaultServings);

  RecipeDetail dish(DishOut dish);

  RecipeDetail id(String id);

  RecipeDetail rootRecipeId(String? rootRecipeId);

  RecipeDetail sourceVersionId(String? sourceVersionId);

  RecipeDetail tasteProfileVersion(int? tasteProfileVersion);

  RecipeDetail updatedAt(String updatedAt);

  RecipeDetail version(RecipeVersionOut version);

  RecipeDetail visibility(RecipeDetailVisibilityEnum visibility);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeDetail(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeDetail(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeDetail call({
    RecipeAuthor author,
    String createdAt,
    int? defaultServings,
    DishOut dish,
    String id,
    String? rootRecipeId,
    String? sourceVersionId,
    int? tasteProfileVersion,
    String updatedAt,
    RecipeVersionOut version,
    RecipeDetailVisibilityEnum visibility,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeDetail.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeDetail.copyWith.fieldName(...)`
class _$RecipeDetailCWProxyImpl implements _$RecipeDetailCWProxy {
  const _$RecipeDetailCWProxyImpl(this._value);

  final RecipeDetail _value;

  @override
  RecipeDetail author(RecipeAuthor author) => this(author: author);

  @override
  RecipeDetail createdAt(String createdAt) => this(createdAt: createdAt);

  @override
  RecipeDetail defaultServings(int? defaultServings) =>
      this(defaultServings: defaultServings);

  @override
  RecipeDetail dish(DishOut dish) => this(dish: dish);

  @override
  RecipeDetail id(String id) => this(id: id);

  @override
  RecipeDetail rootRecipeId(String? rootRecipeId) =>
      this(rootRecipeId: rootRecipeId);

  @override
  RecipeDetail sourceVersionId(String? sourceVersionId) =>
      this(sourceVersionId: sourceVersionId);

  @override
  RecipeDetail tasteProfileVersion(int? tasteProfileVersion) =>
      this(tasteProfileVersion: tasteProfileVersion);

  @override
  RecipeDetail updatedAt(String updatedAt) => this(updatedAt: updatedAt);

  @override
  RecipeDetail version(RecipeVersionOut version) => this(version: version);

  @override
  RecipeDetail visibility(RecipeDetailVisibilityEnum visibility) =>
      this(visibility: visibility);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeDetail(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeDetail(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeDetail call({
    Object? author = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? defaultServings = const $CopyWithPlaceholder(),
    Object? dish = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? rootRecipeId = const $CopyWithPlaceholder(),
    Object? sourceVersionId = const $CopyWithPlaceholder(),
    Object? tasteProfileVersion = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? visibility = const $CopyWithPlaceholder(),
  }) {
    return RecipeDetail(
      author: author == const $CopyWithPlaceholder()
          ? _value.author
          // ignore: cast_nullable_to_non_nullable
          : author as RecipeAuthor,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as String,
      defaultServings: defaultServings == const $CopyWithPlaceholder()
          ? _value.defaultServings
          // ignore: cast_nullable_to_non_nullable
          : defaultServings as int?,
      dish: dish == const $CopyWithPlaceholder()
          ? _value.dish
          // ignore: cast_nullable_to_non_nullable
          : dish as DishOut,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      rootRecipeId: rootRecipeId == const $CopyWithPlaceholder()
          ? _value.rootRecipeId
          // ignore: cast_nullable_to_non_nullable
          : rootRecipeId as String?,
      sourceVersionId: sourceVersionId == const $CopyWithPlaceholder()
          ? _value.sourceVersionId
          // ignore: cast_nullable_to_non_nullable
          : sourceVersionId as String?,
      tasteProfileVersion: tasteProfileVersion == const $CopyWithPlaceholder()
          ? _value.tasteProfileVersion
          // ignore: cast_nullable_to_non_nullable
          : tasteProfileVersion as int?,
      updatedAt: updatedAt == const $CopyWithPlaceholder()
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as String,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as RecipeVersionOut,
      visibility: visibility == const $CopyWithPlaceholder()
          ? _value.visibility
          // ignore: cast_nullable_to_non_nullable
          : visibility as RecipeDetailVisibilityEnum,
    );
  }
}

extension $RecipeDetailCopyWith on RecipeDetail {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeDetail.copyWith(...)` or like so:`instanceOfRecipeDetail.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeDetailCWProxy get copyWith => _$RecipeDetailCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeDetail _$RecipeDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RecipeDetail',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'author',
            'created_at',
            'dish',
            'id',
            'updated_at',
            'version',
            'visibility',
          ],
        );
        final val = RecipeDetail(
          author: $checkedConvert(
            'author',
            (v) => RecipeAuthor.fromJson(v as Map<String, dynamic>),
          ),
          createdAt: $checkedConvert('created_at', (v) => v as String),
          defaultServings: $checkedConvert(
            'default_servings',
            (v) => (v as num?)?.toInt(),
          ),
          dish: $checkedConvert(
            'dish',
            (v) => DishOut.fromJson(v as Map<String, dynamic>),
          ),
          id: $checkedConvert('id', (v) => v as String),
          rootRecipeId: $checkedConvert('root_recipe_id', (v) => v as String?),
          sourceVersionId: $checkedConvert(
            'source_version_id',
            (v) => v as String?,
          ),
          tasteProfileVersion: $checkedConvert(
            'taste_profile_version',
            (v) => (v as num?)?.toInt(),
          ),
          updatedAt: $checkedConvert('updated_at', (v) => v as String),
          version: $checkedConvert(
            'version',
            (v) => RecipeVersionOut.fromJson(v as Map<String, dynamic>),
          ),
          visibility: $checkedConvert(
            'visibility',
            (v) => $enumDecode(_$RecipeDetailVisibilityEnumEnumMap, v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'createdAt': 'created_at',
        'defaultServings': 'default_servings',
        'rootRecipeId': 'root_recipe_id',
        'sourceVersionId': 'source_version_id',
        'tasteProfileVersion': 'taste_profile_version',
        'updatedAt': 'updated_at',
      },
    );

Map<String, dynamic> _$RecipeDetailToJson(RecipeDetail instance) =>
    <String, dynamic>{
      'author': instance.author.toJson(),
      'created_at': instance.createdAt,
      'default_servings': ?instance.defaultServings,
      'dish': instance.dish.toJson(),
      'id': instance.id,
      'root_recipe_id': ?instance.rootRecipeId,
      'source_version_id': ?instance.sourceVersionId,
      'taste_profile_version': ?instance.tasteProfileVersion,
      'updated_at': instance.updatedAt,
      'version': instance.version.toJson(),
      'visibility': _$RecipeDetailVisibilityEnumEnumMap[instance.visibility]!,
    };

const _$RecipeDetailVisibilityEnumEnumMap = {
  RecipeDetailVisibilityEnum.private: 'private',
};
