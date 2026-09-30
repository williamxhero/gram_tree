// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_detail.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IngredientDetailCWProxy {
  IngredientDetail aliases(List<String> aliases);

  IngredientDetail attributes(IngredientAttributes attributes);

  IngredientDetail category(String category);

  IngredientDetail id(String id);

  IngredientDetail pinyin(String pinyin);

  IngredientDetail pinyinInitials(String pinyinInitials);

  IngredientDetail requestedId(String? requestedId);

  IngredientDetail standardName(String standardName);

  IngredientDetail version(String version);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IngredientDetail(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IngredientDetail(...).copyWith(id: 12, name: "My name")
  /// ````
  IngredientDetail call({
    List<String> aliases,
    IngredientAttributes attributes,
    String category,
    String id,
    String pinyin,
    String pinyinInitials,
    String? requestedId,
    String standardName,
    String version,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfIngredientDetail.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfIngredientDetail.copyWith.fieldName(...)`
class _$IngredientDetailCWProxyImpl implements _$IngredientDetailCWProxy {
  const _$IngredientDetailCWProxyImpl(this._value);

  final IngredientDetail _value;

  @override
  IngredientDetail aliases(List<String> aliases) => this(aliases: aliases);

  @override
  IngredientDetail attributes(IngredientAttributes attributes) =>
      this(attributes: attributes);

  @override
  IngredientDetail category(String category) => this(category: category);

  @override
  IngredientDetail id(String id) => this(id: id);

  @override
  IngredientDetail pinyin(String pinyin) => this(pinyin: pinyin);

  @override
  IngredientDetail pinyinInitials(String pinyinInitials) =>
      this(pinyinInitials: pinyinInitials);

  @override
  IngredientDetail requestedId(String? requestedId) =>
      this(requestedId: requestedId);

  @override
  IngredientDetail standardName(String standardName) =>
      this(standardName: standardName);

  @override
  IngredientDetail version(String version) => this(version: version);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IngredientDetail(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IngredientDetail(...).copyWith(id: 12, name: "My name")
  /// ````
  IngredientDetail call({
    Object? aliases = const $CopyWithPlaceholder(),
    Object? attributes = const $CopyWithPlaceholder(),
    Object? category = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? pinyin = const $CopyWithPlaceholder(),
    Object? pinyinInitials = const $CopyWithPlaceholder(),
    Object? requestedId = const $CopyWithPlaceholder(),
    Object? standardName = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
  }) {
    return IngredientDetail(
      aliases: aliases == const $CopyWithPlaceholder()
          ? _value.aliases
          // ignore: cast_nullable_to_non_nullable
          : aliases as List<String>,
      attributes: attributes == const $CopyWithPlaceholder()
          ? _value.attributes
          // ignore: cast_nullable_to_non_nullable
          : attributes as IngredientAttributes,
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
      requestedId: requestedId == const $CopyWithPlaceholder()
          ? _value.requestedId
          // ignore: cast_nullable_to_non_nullable
          : requestedId as String?,
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

extension $IngredientDetailCopyWith on IngredientDetail {
  /// Returns a callable class that can be used as follows: `instanceOfIngredientDetail.copyWith(...)` or like so:`instanceOfIngredientDetail.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$IngredientDetailCWProxy get copyWith => _$IngredientDetailCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IngredientDetail _$IngredientDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'IngredientDetail',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'aliases',
            'attributes',
            'category',
            'id',
            'pinyin',
            'pinyin_initials',
            'standard_name',
            'version',
          ],
        );
        final val = IngredientDetail(
          aliases: $checkedConvert(
            'aliases',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          attributes: $checkedConvert(
            'attributes',
            (v) => IngredientAttributes.fromJson(v as Map<String, dynamic>),
          ),
          category: $checkedConvert('category', (v) => v as String),
          id: $checkedConvert('id', (v) => v as String),
          pinyin: $checkedConvert('pinyin', (v) => v as String),
          pinyinInitials: $checkedConvert(
            'pinyin_initials',
            (v) => v as String,
          ),
          requestedId: $checkedConvert('requested_id', (v) => v as String?),
          standardName: $checkedConvert('standard_name', (v) => v as String),
          version: $checkedConvert('version', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'pinyinInitials': 'pinyin_initials',
        'requestedId': 'requested_id',
        'standardName': 'standard_name',
      },
    );

Map<String, dynamic> _$IngredientDetailToJson(IngredientDetail instance) =>
    <String, dynamic>{
      'aliases': instance.aliases,
      'attributes': instance.attributes.toJson(),
      'category': instance.category,
      'id': instance.id,
      'pinyin': instance.pinyin,
      'pinyin_initials': instance.pinyinInitials,
      'requested_id': ?instance.requestedId,
      'standard_name': instance.standardName,
      'version': instance.version,
    };
