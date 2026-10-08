// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allergies_write.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AllergiesWriteCWProxy {
  AllergiesWrite authorizationVersion(int authorizationVersion);

  AllergiesWrite categories(List<String> categories);

  AllergiesWrite consentId(String consentId);

  AllergiesWrite ingredientIds(List<String> ingredientIds);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AllergiesWrite(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AllergiesWrite(...).copyWith(id: 12, name: "My name")
  /// ````
  AllergiesWrite call({
    int authorizationVersion,
    List<String> categories,
    String consentId,
    List<String> ingredientIds,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAllergiesWrite.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAllergiesWrite.copyWith.fieldName(...)`
class _$AllergiesWriteCWProxyImpl implements _$AllergiesWriteCWProxy {
  const _$AllergiesWriteCWProxyImpl(this._value);

  final AllergiesWrite _value;

  @override
  AllergiesWrite authorizationVersion(int authorizationVersion) =>
      this(authorizationVersion: authorizationVersion);

  @override
  AllergiesWrite categories(List<String> categories) =>
      this(categories: categories);

  @override
  AllergiesWrite consentId(String consentId) => this(consentId: consentId);

  @override
  AllergiesWrite ingredientIds(List<String> ingredientIds) =>
      this(ingredientIds: ingredientIds);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AllergiesWrite(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AllergiesWrite(...).copyWith(id: 12, name: "My name")
  /// ````
  AllergiesWrite call({
    Object? authorizationVersion = const $CopyWithPlaceholder(),
    Object? categories = const $CopyWithPlaceholder(),
    Object? consentId = const $CopyWithPlaceholder(),
    Object? ingredientIds = const $CopyWithPlaceholder(),
  }) {
    return AllergiesWrite(
      authorizationVersion: authorizationVersion == const $CopyWithPlaceholder()
          ? _value.authorizationVersion
          // ignore: cast_nullable_to_non_nullable
          : authorizationVersion as int,
      categories: categories == const $CopyWithPlaceholder()
          ? _value.categories
          // ignore: cast_nullable_to_non_nullable
          : categories as List<String>,
      consentId: consentId == const $CopyWithPlaceholder()
          ? _value.consentId
          // ignore: cast_nullable_to_non_nullable
          : consentId as String,
      ingredientIds: ingredientIds == const $CopyWithPlaceholder()
          ? _value.ingredientIds
          // ignore: cast_nullable_to_non_nullable
          : ingredientIds as List<String>,
    );
  }
}

extension $AllergiesWriteCopyWith on AllergiesWrite {
  /// Returns a callable class that can be used as follows: `instanceOfAllergiesWrite.copyWith(...)` or like so:`instanceOfAllergiesWrite.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AllergiesWriteCWProxy get copyWith => _$AllergiesWriteCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllergiesWrite _$AllergiesWriteFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AllergiesWrite',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'authorization_version',
            'categories',
            'consent_id',
            'ingredient_ids',
          ],
        );
        final val = AllergiesWrite(
          authorizationVersion: $checkedConvert(
            'authorization_version',
            (v) => (v as num).toInt(),
          ),
          categories: $checkedConvert(
            'categories',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          consentId: $checkedConvert('consent_id', (v) => v as String),
          ingredientIds: $checkedConvert(
            'ingredient_ids',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'authorizationVersion': 'authorization_version',
        'consentId': 'consent_id',
        'ingredientIds': 'ingredient_ids',
      },
    );

Map<String, dynamic> _$AllergiesWriteToJson(AllergiesWrite instance) =>
    <String, dynamic>{
      'authorization_version': instance.authorizationVersion,
      'categories': instance.categories,
      'consent_id': instance.consentId,
      'ingredient_ids': instance.ingredientIds,
    };
