// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IngredientOutCWProxy {
  IngredientOut aliases(List<String> aliases);

  IngredientOut category(String category);

  IngredientOut id(String id);

  IngredientOut pinyin(String pinyin);

  IngredientOut pinyinInitials(String pinyinInitials);

  IngredientOut standardName(String standardName);

  IngredientOut version(String version);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IngredientOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IngredientOut(...).copyWith(id: 12, name: "My name")
  /// ````
  IngredientOut call({
    List<String> aliases,
    String category,
    String id,
    String pinyin,
    String pinyinInitials,
    String standardName,
    String version,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfIngredientOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfIngredientOut.copyWith.fieldName(...)`
class _$IngredientOutCWProxyImpl implements _$IngredientOutCWProxy {
  const _$IngredientOutCWProxyImpl(this._value);

  final IngredientOut _value;

  @override
  IngredientOut aliases(List<String> aliases) => this(aliases: aliases);

  @override
  IngredientOut category(String category) => this(category: category);

  @override
  IngredientOut id(String id) => this(id: id);

  @override
  IngredientOut pinyin(String pinyin) => this(pinyin: pinyin);

  @override
  IngredientOut pinyinInitials(String pinyinInitials) =>
      this(pinyinInitials: pinyinInitials);

  @override
  IngredientOut standardName(String standardName) =>
      this(standardName: standardName);

  @override
  IngredientOut version(String version) => this(version: version);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IngredientOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IngredientOut(...).copyWith(id: 12, name: "My name")
  /// ````
  IngredientOut call({
    Object? aliases = const $CopyWithPlaceholder(),
    Object? category = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? pinyin = const $CopyWithPlaceholder(),
    Object? pinyinInitials = const $CopyWithPlaceholder(),
    Object? standardName = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
  }) {
    return IngredientOut(
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

extension $IngredientOutCopyWith on IngredientOut {
  /// Returns a callable class that can be used as follows: `instanceOfIngredientOut.copyWith(...)` or like so:`instanceOfIngredientOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$IngredientOutCWProxy get copyWith => _$IngredientOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IngredientOut _$IngredientOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'IngredientOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'aliases',
            'category',
            'id',
            'pinyin',
            'pinyin_initials',
            'standard_name',
            'version',
          ],
        );
        final val = IngredientOut(
          aliases: $checkedConvert(
            'aliases',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          category: $checkedConvert('category', (v) => v as String),
          id: $checkedConvert('id', (v) => v as String),
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
        'pinyinInitials': 'pinyin_initials',
        'standardName': 'standard_name',
      },
    );

Map<String, dynamic> _$IngredientOutToJson(IngredientOut instance) =>
    <String, dynamic>{
      'aliases': instance.aliases,
      'category': instance.category,
      'id': instance.id,
      'pinyin': instance.pinyin,
      'pinyin_initials': instance.pinyinInitials,
      'standard_name': instance.standardName,
      'version': instance.version,
    };
