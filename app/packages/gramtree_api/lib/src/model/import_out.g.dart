// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ImportOutCWProxy {
  ImportOut failedImages(List<int>? failedImages);

  ImportOut fieldStates(Map<String, String>? fieldStates);

  ImportOut importId(String? importId);

  ImportOut nextStep(String? nextStep);

  ImportOut reason(String? reason);

  ImportOut recipe(RecipeDetail? recipe);

  ImportOut reproducibility(Object? reproducibility);

  ImportOut status(String status);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ImportOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ImportOut(...).copyWith(id: 12, name: "My name")
  /// ````
  ImportOut call({
    List<int>? failedImages,
    Map<String, String>? fieldStates,
    String? importId,
    String? nextStep,
    String? reason,
    RecipeDetail? recipe,
    Object? reproducibility,
    String status,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfImportOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfImportOut.copyWith.fieldName(...)`
class _$ImportOutCWProxyImpl implements _$ImportOutCWProxy {
  const _$ImportOutCWProxyImpl(this._value);

  final ImportOut _value;

  @override
  ImportOut failedImages(List<int>? failedImages) =>
      this(failedImages: failedImages);

  @override
  ImportOut fieldStates(Map<String, String>? fieldStates) =>
      this(fieldStates: fieldStates);

  @override
  ImportOut importId(String? importId) => this(importId: importId);

  @override
  ImportOut nextStep(String? nextStep) => this(nextStep: nextStep);

  @override
  ImportOut reason(String? reason) => this(reason: reason);

  @override
  ImportOut recipe(RecipeDetail? recipe) => this(recipe: recipe);

  @override
  ImportOut reproducibility(Object? reproducibility) =>
      this(reproducibility: reproducibility);

  @override
  ImportOut status(String status) => this(status: status);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ImportOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ImportOut(...).copyWith(id: 12, name: "My name")
  /// ````
  ImportOut call({
    Object? failedImages = const $CopyWithPlaceholder(),
    Object? fieldStates = const $CopyWithPlaceholder(),
    Object? importId = const $CopyWithPlaceholder(),
    Object? nextStep = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? recipe = const $CopyWithPlaceholder(),
    Object? reproducibility = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return ImportOut(
      failedImages: failedImages == const $CopyWithPlaceholder()
          ? _value.failedImages
          // ignore: cast_nullable_to_non_nullable
          : failedImages as List<int>?,
      fieldStates: fieldStates == const $CopyWithPlaceholder()
          ? _value.fieldStates
          // ignore: cast_nullable_to_non_nullable
          : fieldStates as Map<String, String>?,
      importId: importId == const $CopyWithPlaceholder()
          ? _value.importId
          // ignore: cast_nullable_to_non_nullable
          : importId as String?,
      nextStep: nextStep == const $CopyWithPlaceholder()
          ? _value.nextStep
          // ignore: cast_nullable_to_non_nullable
          : nextStep as String?,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String?,
      recipe: recipe == const $CopyWithPlaceholder()
          ? _value.recipe
          // ignore: cast_nullable_to_non_nullable
          : recipe as RecipeDetail?,
      reproducibility: reproducibility == const $CopyWithPlaceholder()
          ? _value.reproducibility
          // ignore: cast_nullable_to_non_nullable
          : reproducibility as Object?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as String,
    );
  }
}

extension $ImportOutCopyWith on ImportOut {
  /// Returns a callable class that can be used as follows: `instanceOfImportOut.copyWith(...)` or like so:`instanceOfImportOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ImportOutCWProxy get copyWith => _$ImportOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportOut _$ImportOutFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ImportOut',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['status']);
    final val = ImportOut(
      failedImages: $checkedConvert(
        'failed_images',
        (v) => (v as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
      ),
      fieldStates: $checkedConvert(
        'field_states',
        (v) => (v as Map<String, dynamic>?)?.map(
          (k, e) => MapEntry(k, e as String),
        ),
      ),
      importId: $checkedConvert('import_id', (v) => v as String?),
      nextStep: $checkedConvert('next_step', (v) => v as String?),
      reason: $checkedConvert('reason', (v) => v as String?),
      recipe: $checkedConvert(
        'recipe',
        (v) =>
            v == null ? null : RecipeDetail.fromJson(v as Map<String, dynamic>),
      ),
      reproducibility: $checkedConvert('reproducibility', (v) => v),
      status: $checkedConvert('status', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'failedImages': 'failed_images',
    'fieldStates': 'field_states',
    'importId': 'import_id',
    'nextStep': 'next_step',
  },
);

Map<String, dynamic> _$ImportOutToJson(ImportOut instance) => <String, dynamic>{
  'failed_images': ?instance.failedImages,
  'field_states': ?instance.fieldStates,
  'import_id': ?instance.importId,
  'next_step': ?instance.nextStep,
  'reason': ?instance.reason,
  'recipe': ?instance.recipe?.toJson(),
  'reproducibility': ?instance.reproducibility,
  'status': instance.status,
};
