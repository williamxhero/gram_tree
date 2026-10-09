// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comparison_version.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComparisonVersionCWProxy {
  ComparisonVersion author(String author);

  ComparisonVersion dishName(String dishName);

  ComparisonVersion recipeId(String recipeId);

  ComparisonVersion servings(int servings);

  ComparisonVersion versionId(String versionId);

  ComparisonVersion versionNumber(int versionNumber);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComparisonVersion(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComparisonVersion(...).copyWith(id: 12, name: "My name")
  /// ````
  ComparisonVersion call({
    String author,
    String dishName,
    String recipeId,
    int servings,
    String versionId,
    int versionNumber,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfComparisonVersion.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfComparisonVersion.copyWith.fieldName(...)`
class _$ComparisonVersionCWProxyImpl implements _$ComparisonVersionCWProxy {
  const _$ComparisonVersionCWProxyImpl(this._value);

  final ComparisonVersion _value;

  @override
  ComparisonVersion author(String author) => this(author: author);

  @override
  ComparisonVersion dishName(String dishName) => this(dishName: dishName);

  @override
  ComparisonVersion recipeId(String recipeId) => this(recipeId: recipeId);

  @override
  ComparisonVersion servings(int servings) => this(servings: servings);

  @override
  ComparisonVersion versionId(String versionId) => this(versionId: versionId);

  @override
  ComparisonVersion versionNumber(int versionNumber) =>
      this(versionNumber: versionNumber);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComparisonVersion(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComparisonVersion(...).copyWith(id: 12, name: "My name")
  /// ````
  ComparisonVersion call({
    Object? author = const $CopyWithPlaceholder(),
    Object? dishName = const $CopyWithPlaceholder(),
    Object? recipeId = const $CopyWithPlaceholder(),
    Object? servings = const $CopyWithPlaceholder(),
    Object? versionId = const $CopyWithPlaceholder(),
    Object? versionNumber = const $CopyWithPlaceholder(),
  }) {
    return ComparisonVersion(
      author: author == const $CopyWithPlaceholder()
          ? _value.author
          // ignore: cast_nullable_to_non_nullable
          : author as String,
      dishName: dishName == const $CopyWithPlaceholder()
          ? _value.dishName
          // ignore: cast_nullable_to_non_nullable
          : dishName as String,
      recipeId: recipeId == const $CopyWithPlaceholder()
          ? _value.recipeId
          // ignore: cast_nullable_to_non_nullable
          : recipeId as String,
      servings: servings == const $CopyWithPlaceholder()
          ? _value.servings
          // ignore: cast_nullable_to_non_nullable
          : servings as int,
      versionId: versionId == const $CopyWithPlaceholder()
          ? _value.versionId
          // ignore: cast_nullable_to_non_nullable
          : versionId as String,
      versionNumber: versionNumber == const $CopyWithPlaceholder()
          ? _value.versionNumber
          // ignore: cast_nullable_to_non_nullable
          : versionNumber as int,
    );
  }
}

extension $ComparisonVersionCopyWith on ComparisonVersion {
  /// Returns a callable class that can be used as follows: `instanceOfComparisonVersion.copyWith(...)` or like so:`instanceOfComparisonVersion.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComparisonVersionCWProxy get copyWith =>
      _$ComparisonVersionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComparisonVersion _$ComparisonVersionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ComparisonVersion',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'author',
            'dish_name',
            'recipe_id',
            'servings',
            'version_id',
            'version_number',
          ],
        );
        final val = ComparisonVersion(
          author: $checkedConvert('author', (v) => v as String),
          dishName: $checkedConvert('dish_name', (v) => v as String),
          recipeId: $checkedConvert('recipe_id', (v) => v as String),
          servings: $checkedConvert('servings', (v) => (v as num).toInt()),
          versionId: $checkedConvert('version_id', (v) => v as String),
          versionNumber: $checkedConvert(
            'version_number',
            (v) => (v as num).toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'dishName': 'dish_name',
        'recipeId': 'recipe_id',
        'versionId': 'version_id',
        'versionNumber': 'version_number',
      },
    );

Map<String, dynamic> _$ComparisonVersionToJson(ComparisonVersion instance) =>
    <String, dynamic>{
      'author': instance.author,
      'dish_name': instance.dishName,
      'recipe_id': instance.recipeId,
      'servings': instance.servings,
      'version_id': instance.versionId,
      'version_number': instance.versionNumber,
    };
