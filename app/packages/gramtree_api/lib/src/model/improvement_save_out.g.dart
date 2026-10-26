// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'improvement_save_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ImprovementSaveOutCWProxy {
  ImprovementSaveOut outcome(ImprovementSaveOutOutcomeEnum outcome);

  ImprovementSaveOut profileVersion(int? profileVersion);

  ImprovementSaveOut recipe(RecipeDetail? recipe);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ImprovementSaveOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ImprovementSaveOut(...).copyWith(id: 12, name: "My name")
  /// ````
  ImprovementSaveOut call({
    ImprovementSaveOutOutcomeEnum outcome,
    int? profileVersion,
    RecipeDetail? recipe,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfImprovementSaveOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfImprovementSaveOut.copyWith.fieldName(...)`
class _$ImprovementSaveOutCWProxyImpl implements _$ImprovementSaveOutCWProxy {
  const _$ImprovementSaveOutCWProxyImpl(this._value);

  final ImprovementSaveOut _value;

  @override
  ImprovementSaveOut outcome(ImprovementSaveOutOutcomeEnum outcome) =>
      this(outcome: outcome);

  @override
  ImprovementSaveOut profileVersion(int? profileVersion) =>
      this(profileVersion: profileVersion);

  @override
  ImprovementSaveOut recipe(RecipeDetail? recipe) => this(recipe: recipe);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ImprovementSaveOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ImprovementSaveOut(...).copyWith(id: 12, name: "My name")
  /// ````
  ImprovementSaveOut call({
    Object? outcome = const $CopyWithPlaceholder(),
    Object? profileVersion = const $CopyWithPlaceholder(),
    Object? recipe = const $CopyWithPlaceholder(),
  }) {
    return ImprovementSaveOut(
      outcome: outcome == const $CopyWithPlaceholder()
          ? _value.outcome
          // ignore: cast_nullable_to_non_nullable
          : outcome as ImprovementSaveOutOutcomeEnum,
      profileVersion: profileVersion == const $CopyWithPlaceholder()
          ? _value.profileVersion
          // ignore: cast_nullable_to_non_nullable
          : profileVersion as int?,
      recipe: recipe == const $CopyWithPlaceholder()
          ? _value.recipe
          // ignore: cast_nullable_to_non_nullable
          : recipe as RecipeDetail?,
    );
  }
}

extension $ImprovementSaveOutCopyWith on ImprovementSaveOut {
  /// Returns a callable class that can be used as follows: `instanceOfImprovementSaveOut.copyWith(...)` or like so:`instanceOfImprovementSaveOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ImprovementSaveOutCWProxy get copyWith =>
      _$ImprovementSaveOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImprovementSaveOut _$ImprovementSaveOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ImprovementSaveOut', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['outcome']);
      final val = ImprovementSaveOut(
        outcome: $checkedConvert(
          'outcome',
          (v) => $enumDecode(_$ImprovementSaveOutOutcomeEnumEnumMap, v),
        ),
        profileVersion: $checkedConvert(
          'profile_version',
          (v) => (v as num?)?.toInt(),
        ),
        recipe: $checkedConvert(
          'recipe',
          (v) => v == null
              ? null
              : RecipeDetail.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'profileVersion': 'profile_version'});

Map<String, dynamic> _$ImprovementSaveOutToJson(ImprovementSaveOut instance) =>
    <String, dynamic>{
      'outcome': _$ImprovementSaveOutOutcomeEnumEnumMap[instance.outcome]!,
      'profile_version': ?instance.profileVersion,
      'recipe': ?instance.recipe?.toJson(),
    };

const _$ImprovementSaveOutOutcomeEnumEnumMap = {
  ImprovementSaveOutOutcomeEnum.branch: 'branch',
  ImprovementSaveOutOutcomeEnum.taste: 'taste',
};
