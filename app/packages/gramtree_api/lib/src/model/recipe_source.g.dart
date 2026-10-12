// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_source.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeSourceCWProxy {
  RecipeSource kind(RecipeSourceKindEnum kind);

  RecipeSource note(String? note);

  RecipeSource platform(String? platform);

  RecipeSource url(String? url);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeSource(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeSource(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeSource call({
    RecipeSourceKindEnum kind,
    String? note,
    String? platform,
    String? url,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeSource.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeSource.copyWith.fieldName(...)`
class _$RecipeSourceCWProxyImpl implements _$RecipeSourceCWProxy {
  const _$RecipeSourceCWProxyImpl(this._value);

  final RecipeSource _value;

  @override
  RecipeSource kind(RecipeSourceKindEnum kind) => this(kind: kind);

  @override
  RecipeSource note(String? note) => this(note: note);

  @override
  RecipeSource platform(String? platform) => this(platform: platform);

  @override
  RecipeSource url(String? url) => this(url: url);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeSource(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeSource(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeSource call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
  }) {
    return RecipeSource(
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as RecipeSourceKindEnum,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
      platform: platform == const $CopyWithPlaceholder()
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as String?,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
    );
  }
}

extension $RecipeSourceCopyWith on RecipeSource {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeSource.copyWith(...)` or like so:`instanceOfRecipeSource.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeSourceCWProxy get copyWith => _$RecipeSourceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeSource _$RecipeSourceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RecipeSource', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['kind']);
      final val = RecipeSource(
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$RecipeSourceKindEnumEnumMap, v),
        ),
        note: $checkedConvert('note', (v) => v as String?),
        platform: $checkedConvert('platform', (v) => v as String? ?? 'unknown'),
        url: $checkedConvert('url', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$RecipeSourceToJson(RecipeSource instance) =>
    <String, dynamic>{
      'kind': _$RecipeSourceKindEnumEnumMap[instance.kind]!,
      'note': ?instance.note,
      'platform': ?instance.platform,
      'url': ?instance.url,
    };

const _$RecipeSourceKindEnumEnumMap = {
  RecipeSourceKindEnum.imported: 'imported',
};
