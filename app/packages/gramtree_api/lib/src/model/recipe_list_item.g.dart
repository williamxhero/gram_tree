// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_list_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeListItemCWProxy {
  RecipeListItem activeTimeSeconds(int activeTimeSeconds);

  RecipeListItem difficulty(String? difficulty);

  RecipeListItem dish(DishOut dish);

  RecipeListItem id(String id);

  RecipeListItem servings(int servings);

  RecipeListItem totalTimeSeconds(int totalTimeSeconds);

  RecipeListItem updatedAt(String updatedAt);

  RecipeListItem versionNumber(int versionNumber);

  RecipeListItem visibility(RecipeListItemVisibilityEnum visibility);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeListItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeListItem(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeListItem call({
    int activeTimeSeconds,
    String? difficulty,
    DishOut dish,
    String id,
    int servings,
    int totalTimeSeconds,
    String updatedAt,
    int versionNumber,
    RecipeListItemVisibilityEnum visibility,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeListItem.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeListItem.copyWith.fieldName(...)`
class _$RecipeListItemCWProxyImpl implements _$RecipeListItemCWProxy {
  const _$RecipeListItemCWProxyImpl(this._value);

  final RecipeListItem _value;

  @override
  RecipeListItem activeTimeSeconds(int activeTimeSeconds) =>
      this(activeTimeSeconds: activeTimeSeconds);

  @override
  RecipeListItem difficulty(String? difficulty) => this(difficulty: difficulty);

  @override
  RecipeListItem dish(DishOut dish) => this(dish: dish);

  @override
  RecipeListItem id(String id) => this(id: id);

  @override
  RecipeListItem servings(int servings) => this(servings: servings);

  @override
  RecipeListItem totalTimeSeconds(int totalTimeSeconds) =>
      this(totalTimeSeconds: totalTimeSeconds);

  @override
  RecipeListItem updatedAt(String updatedAt) => this(updatedAt: updatedAt);

  @override
  RecipeListItem versionNumber(int versionNumber) =>
      this(versionNumber: versionNumber);

  @override
  RecipeListItem visibility(RecipeListItemVisibilityEnum visibility) =>
      this(visibility: visibility);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeListItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeListItem(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeListItem call({
    Object? activeTimeSeconds = const $CopyWithPlaceholder(),
    Object? difficulty = const $CopyWithPlaceholder(),
    Object? dish = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? servings = const $CopyWithPlaceholder(),
    Object? totalTimeSeconds = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? versionNumber = const $CopyWithPlaceholder(),
    Object? visibility = const $CopyWithPlaceholder(),
  }) {
    return RecipeListItem(
      activeTimeSeconds: activeTimeSeconds == const $CopyWithPlaceholder()
          ? _value.activeTimeSeconds
          // ignore: cast_nullable_to_non_nullable
          : activeTimeSeconds as int,
      difficulty: difficulty == const $CopyWithPlaceholder()
          ? _value.difficulty
          // ignore: cast_nullable_to_non_nullable
          : difficulty as String?,
      dish: dish == const $CopyWithPlaceholder()
          ? _value.dish
          // ignore: cast_nullable_to_non_nullable
          : dish as DishOut,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      servings: servings == const $CopyWithPlaceholder()
          ? _value.servings
          // ignore: cast_nullable_to_non_nullable
          : servings as int,
      totalTimeSeconds: totalTimeSeconds == const $CopyWithPlaceholder()
          ? _value.totalTimeSeconds
          // ignore: cast_nullable_to_non_nullable
          : totalTimeSeconds as int,
      updatedAt: updatedAt == const $CopyWithPlaceholder()
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as String,
      versionNumber: versionNumber == const $CopyWithPlaceholder()
          ? _value.versionNumber
          // ignore: cast_nullable_to_non_nullable
          : versionNumber as int,
      visibility: visibility == const $CopyWithPlaceholder()
          ? _value.visibility
          // ignore: cast_nullable_to_non_nullable
          : visibility as RecipeListItemVisibilityEnum,
    );
  }
}

extension $RecipeListItemCopyWith on RecipeListItem {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeListItem.copyWith(...)` or like so:`instanceOfRecipeListItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeListItemCWProxy get copyWith => _$RecipeListItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeListItem _$RecipeListItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RecipeListItem',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'active_time_seconds',
            'dish',
            'id',
            'servings',
            'total_time_seconds',
            'updated_at',
            'version_number',
            'visibility',
          ],
        );
        final val = RecipeListItem(
          activeTimeSeconds: $checkedConvert(
            'active_time_seconds',
            (v) => (v as num).toInt(),
          ),
          difficulty: $checkedConvert('difficulty', (v) => v as String?),
          dish: $checkedConvert(
            'dish',
            (v) => DishOut.fromJson(v as Map<String, dynamic>),
          ),
          id: $checkedConvert('id', (v) => v as String),
          servings: $checkedConvert('servings', (v) => (v as num).toInt()),
          totalTimeSeconds: $checkedConvert(
            'total_time_seconds',
            (v) => (v as num).toInt(),
          ),
          updatedAt: $checkedConvert('updated_at', (v) => v as String),
          versionNumber: $checkedConvert(
            'version_number',
            (v) => (v as num).toInt(),
          ),
          visibility: $checkedConvert(
            'visibility',
            (v) => $enumDecode(_$RecipeListItemVisibilityEnumEnumMap, v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'activeTimeSeconds': 'active_time_seconds',
        'totalTimeSeconds': 'total_time_seconds',
        'updatedAt': 'updated_at',
        'versionNumber': 'version_number',
      },
    );

Map<String, dynamic> _$RecipeListItemToJson(RecipeListItem instance) =>
    <String, dynamic>{
      'active_time_seconds': instance.activeTimeSeconds,
      'difficulty': ?instance.difficulty,
      'dish': instance.dish.toJson(),
      'id': instance.id,
      'servings': instance.servings,
      'total_time_seconds': instance.totalTimeSeconds,
      'updated_at': instance.updatedAt,
      'version_number': instance.versionNumber,
      'visibility': _$RecipeListItemVisibilityEnumEnumMap[instance.visibility]!,
    };

const _$RecipeListItemVisibilityEnumEnumMap = {
  RecipeListItemVisibilityEnum.private: 'private',
};
