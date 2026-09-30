// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_ingredient_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SearchIngredientOutCWProxy {
  SearchIngredientOut aliases(List<String> aliases);

  SearchIngredientOut category(String category);

  SearchIngredientOut id(String id);

  SearchIngredientOut matchedName(String matchedName);

  SearchIngredientOut pinyin(String pinyin);

  SearchIngredientOut pinyinInitials(String pinyinInitials);

  SearchIngredientOut standardName(String standardName);

  SearchIngredientOut version(String version);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SearchIngredientOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SearchIngredientOut(...).copyWith(id: 12, name: "My name")
  /// ````
  SearchIngredientOut call({
    List<String> aliases,
    String category,
    String id,
    String matchedName,
    String pinyin,
    String pinyinInitials,
    String standardName,
    String version,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSearchIngredientOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSearchIngredientOut.copyWith.fieldName(...)`
class _$SearchIngredientOutCWProxyImpl implements _$SearchIngredientOutCWProxy {
  const _$SearchIngredientOutCWProxyImpl(this._value);

  final SearchIngredientOut _value;

  @override
  SearchIngredientOut aliases(List<String> aliases) => this(aliases: aliases);

  @override
  SearchIngredientOut category(String category) => this(category: category);

  @override
  SearchIngredientOut id(String id) => this(id: id);

  @override
  SearchIngredientOut matchedName(String matchedName) =>
      this(matchedName: matchedName);

  @override
  SearchIngredientOut pinyin(String pinyin) => this(pinyin: pinyin);

  @override
  SearchIngredientOut pinyinInitials(String pinyinInitials) =>
      this(pinyinInitials: pinyinInitials);

  @override
  SearchIngredientOut standardName(String standardName) =>
      this(standardName: standardName);

  @override
  SearchIngredientOut version(String version) => this(version: version);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SearchIngredientOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SearchIngredientOut(...).copyWith(id: 12, name: "My name")
  /// ````
  SearchIngredientOut call({
    Object? aliases = const $CopyWithPlaceholder(),
    Object? category = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? matchedName = const $CopyWithPlaceholder(),
    Object? pinyin = const $CopyWithPlaceholder(),
    Object? pinyinInitials = const $CopyWithPlaceholder(),
    Object? standardName = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
  }) {
    return SearchIngredientOut(
      aliases: aliases == const $CopyWithPlaceholder()
          ? _value.aliases
          // ignore: cast_nullable_to_non_nullable
          : aliases as List<String>,
      category: category == const $CopyWithPlaceholder()
          ? _value.category
          // ignore: cast_nullable_to_non_nullable
          : category as String,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      matchedName: matchedName == const $CopyWithPlaceholder()
          ? _value.matchedName
          // ignore: cast_nullable_to_non_nullable
          : matchedName as String,
      pinyin: pinyin == const $CopyWithPlaceholder()
          ? _value.pinyin
          // ignore: cast_nullable_to_non_nullable
          : pinyin as String,
      pinyinInitials: pinyinInitials == const $CopyWithPlaceholder()
          ? _value.pinyinInitials
          // ignore: cast_nullable_to_non_nullable
          : pinyinInitials as String,
      standardName: standardName == const $CopyWithPlaceholder()
          ? _value.standardName
          // ignore: cast_nullable_to_non_nullable
          : standardName as String,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as String,
    );
  }
}

extension $SearchIngredientOutCopyWith on SearchIngredientOut {
  /// Returns a callable class that can be used as follows: `instanceOfSearchIngredientOut.copyWith(...)` or like so:`instanceOfSearchIngredientOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SearchIngredientOutCWProxy get copyWith =>
      _$SearchIngredientOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchIngredientOut _$SearchIngredientOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SearchIngredientOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'aliases',
            'category',
            'id',
            'matched_name',
            'pinyin',
            'pinyin_initials',
            'standard_name',
            'version',
          ],
        );
        final val = SearchIngredientOut(
          aliases: $checkedConvert(
            'aliases',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          category: $checkedConvert('category', (v) => v as String),
          id: $checkedConvert('id', (v) => v as String),
          matchedName: $checkedConvert('matched_name', (v) => v as String),
          pinyin: $checkedConvert('pinyin', (v) => v as String),
          pinyinInitials: $checkedConvert(
            'pinyin_initials',
            (v) => v as String,
          ),
          standardName: $checkedConvert('standard_name', (v) => v as String),
          version: $checkedConvert('version', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'matchedName': 'matched_name',
        'pinyinInitials': 'pinyin_initials',
        'standardName': 'standard_name',
      },
    );

Map<String, dynamic> _$SearchIngredientOutToJson(
  SearchIngredientOut instance,
) => <String, dynamic>{
  'aliases': instance.aliases,
  'category': instance.category,
  'id': instance.id,
  'matched_name': instance.matchedName,
  'pinyin': instance.pinyin,
  'pinyin_initials': instance.pinyinInitials,
  'standard_name': instance.standardName,
  'version': instance.version,
};
