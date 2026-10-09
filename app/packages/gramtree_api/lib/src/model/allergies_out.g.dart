// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allergies_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AllergiesOutCWProxy {
  AllergiesOut authorizationVersion(int authorizationVersion);

  AllergiesOut availableCategories(List<String> availableCategories);

  AllergiesOut categories(List<String> categories);

  AllergiesOut consentId(String? consentId);

  AllergiesOut consentVersion(String consentVersion);

  AllergiesOut ingredients(List<AllergyIngredientOut> ingredients);

  AllergiesOut profileVersion(int profileVersion);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AllergiesOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AllergiesOut(...).copyWith(id: 12, name: "My name")
  /// ````
  AllergiesOut call({
    int authorizationVersion,
    List<String> availableCategories,
    List<String> categories,
    String? consentId,
    String consentVersion,
    List<AllergyIngredientOut> ingredients,
    int profileVersion,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAllergiesOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAllergiesOut.copyWith.fieldName(...)`
class _$AllergiesOutCWProxyImpl implements _$AllergiesOutCWProxy {
  const _$AllergiesOutCWProxyImpl(this._value);

  final AllergiesOut _value;

  @override
  AllergiesOut authorizationVersion(int authorizationVersion) =>
      this(authorizationVersion: authorizationVersion);

  @override
  AllergiesOut availableCategories(List<String> availableCategories) =>
      this(availableCategories: availableCategories);

  @override
  AllergiesOut categories(List<String> categories) =>
      this(categories: categories);

  @override
  AllergiesOut consentId(String? consentId) => this(consentId: consentId);

  @override
  AllergiesOut consentVersion(String consentVersion) =>
      this(consentVersion: consentVersion);

  @override
  AllergiesOut ingredients(List<AllergyIngredientOut> ingredients) =>
      this(ingredients: ingredients);

  @override
  AllergiesOut profileVersion(int profileVersion) =>
      this(profileVersion: profileVersion);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AllergiesOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AllergiesOut(...).copyWith(id: 12, name: "My name")
  /// ````
  AllergiesOut call({
    Object? authorizationVersion = const $CopyWithPlaceholder(),
    Object? availableCategories = const $CopyWithPlaceholder(),
    Object? categories = const $CopyWithPlaceholder(),
    Object? consentId = const $CopyWithPlaceholder(),
    Object? consentVersion = const $CopyWithPlaceholder(),
    Object? ingredients = const $CopyWithPlaceholder(),
    Object? profileVersion = const $CopyWithPlaceholder(),
  }) {
    return AllergiesOut(
      authorizationVersion: authorizationVersion == const $CopyWithPlaceholder()
          ? _value.authorizationVersion
          // ignore: cast_nullable_to_non_nullable
          : authorizationVersion as int,
      availableCategories: availableCategories == const $CopyWithPlaceholder()
          ? _value.availableCategories
          // ignore: cast_nullable_to_non_nullable
          : availableCategories as List<String>,
      categories: categories == const $CopyWithPlaceholder()
          ? _value.categories
          // ignore: cast_nullable_to_non_nullable
          : categories as List<String>,
      consentId: consentId == const $CopyWithPlaceholder()
          ? _value.consentId
          // ignore: cast_nullable_to_non_nullable
          : consentId as String?,
      consentVersion: consentVersion == const $CopyWithPlaceholder()
          ? _value.consentVersion
          // ignore: cast_nullable_to_non_nullable
          : consentVersion as String,
      ingredients: ingredients == const $CopyWithPlaceholder()
          ? _value.ingredients
          // ignore: cast_nullable_to_non_nullable
          : ingredients as List<AllergyIngredientOut>,
      profileVersion: profileVersion == const $CopyWithPlaceholder()
          ? _value.profileVersion
          // ignore: cast_nullable_to_non_nullable
          : profileVersion as int,
    );
  }
}

extension $AllergiesOutCopyWith on AllergiesOut {
  /// Returns a callable class that can be used as follows: `instanceOfAllergiesOut.copyWith(...)` or like so:`instanceOfAllergiesOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AllergiesOutCWProxy get copyWith => _$AllergiesOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllergiesOut _$AllergiesOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AllergiesOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'authorization_version',
            'available_categories',
            'categories',
            'consent_id',
            'consent_version',
            'ingredients',
            'profile_version',
          ],
        );
        final val = AllergiesOut(
          authorizationVersion: $checkedConvert(
            'authorization_version',
            (v) => (v as num).toInt(),
          ),
          availableCategories: $checkedConvert(
            'available_categories',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          categories: $checkedConvert(
            'categories',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          consentId: $checkedConvert('consent_id', (v) => v as String?),
          consentVersion: $checkedConvert(
            'consent_version',
            (v) => v as String,
          ),
          ingredients: $checkedConvert(
            'ingredients',
            (v) => (v as List<dynamic>)
                .map(
                  (e) =>
                      AllergyIngredientOut.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
          ),
          profileVersion: $checkedConvert(
            'profile_version',
            (v) => (v as num).toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'authorizationVersion': 'authorization_version',
        'availableCategories': 'available_categories',
        'consentId': 'consent_id',
        'consentVersion': 'consent_version',
        'profileVersion': 'profile_version',
      },
    );

Map<String, dynamic> _$AllergiesOutToJson(AllergiesOut instance) =>
    <String, dynamic>{
      'authorization_version': instance.authorizationVersion,
      'available_categories': instance.availableCategories,
      'categories': instance.categories,
      'consent_id': instance.consentId,
      'consent_version': instance.consentVersion,
      'ingredients': instance.ingredients.map((e) => e.toJson()).toList(),
      'profile_version': instance.profileVersion,
    };
