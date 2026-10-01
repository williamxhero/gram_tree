// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_author.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeAuthorCWProxy {
  RecipeAuthor id(String id);

  RecipeAuthor nickname(String nickname);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeAuthor(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeAuthor(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeAuthor call({String id, String nickname});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeAuthor.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeAuthor.copyWith.fieldName(...)`
class _$RecipeAuthorCWProxyImpl implements _$RecipeAuthorCWProxy {
  const _$RecipeAuthorCWProxyImpl(this._value);

  final RecipeAuthor _value;

  @override
  RecipeAuthor id(String id) => this(id: id);

  @override
  RecipeAuthor nickname(String nickname) => this(nickname: nickname);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeAuthor(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeAuthor(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeAuthor call({
    Object? id = const $CopyWithPlaceholder(),
    Object? nickname = const $CopyWithPlaceholder(),
  }) {
    return RecipeAuthor(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      nickname: nickname == const $CopyWithPlaceholder()
          ? _value.nickname
          // ignore: cast_nullable_to_non_nullable
          : nickname as String,
    );
  }
}

extension $RecipeAuthorCopyWith on RecipeAuthor {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeAuthor.copyWith(...)` or like so:`instanceOfRecipeAuthor.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeAuthorCWProxy get copyWith => _$RecipeAuthorCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeAuthor _$RecipeAuthorFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RecipeAuthor', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'nickname']);
      final val = RecipeAuthor(
        id: $checkedConvert('id', (v) => v as String),
        nickname: $checkedConvert('nickname', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$RecipeAuthorToJson(RecipeAuthor instance) =>
    <String, dynamic>{'id': instance.id, 'nickname': instance.nickname};
