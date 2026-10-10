// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modification_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ModificationInputCWProxy {
  ModificationInput baseVersionId(String? baseVersionId);

  ModificationInput generationRequestId(String? generationRequestId);

  ModificationInput recipeId(String? recipeId);

  ModificationInput requestId(String? requestId);

  ModificationInput retryFailed(bool? retryFailed);

  ModificationInput text(String text);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModificationInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModificationInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ModificationInput call({
    String? baseVersionId,
    String? generationRequestId,
    String? recipeId,
    String? requestId,
    bool? retryFailed,
    String text,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfModificationInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfModificationInput.copyWith.fieldName(...)`
class _$ModificationInputCWProxyImpl implements _$ModificationInputCWProxy {
  const _$ModificationInputCWProxyImpl(this._value);

  final ModificationInput _value;

  @override
  ModificationInput baseVersionId(String? baseVersionId) =>
      this(baseVersionId: baseVersionId);

  @override
  ModificationInput generationRequestId(String? generationRequestId) =>
      this(generationRequestId: generationRequestId);

  @override
  ModificationInput recipeId(String? recipeId) => this(recipeId: recipeId);

  @override
  ModificationInput requestId(String? requestId) => this(requestId: requestId);

  @override
  ModificationInput retryFailed(bool? retryFailed) =>
      this(retryFailed: retryFailed);

  @override
  ModificationInput text(String text) => this(text: text);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModificationInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModificationInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ModificationInput call({
    Object? baseVersionId = const $CopyWithPlaceholder(),
    Object? generationRequestId = const $CopyWithPlaceholder(),
    Object? recipeId = const $CopyWithPlaceholder(),
    Object? requestId = const $CopyWithPlaceholder(),
    Object? retryFailed = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return ModificationInput(
      baseVersionId: baseVersionId == const $CopyWithPlaceholder()
          ? _value.baseVersionId
          // ignore: cast_nullable_to_non_nullable
          : baseVersionId as String?,
      generationRequestId: generationRequestId == const $CopyWithPlaceholder()
          ? _value.generationRequestId
          // ignore: cast_nullable_to_non_nullable
          : generationRequestId as String?,
      recipeId: recipeId == const $CopyWithPlaceholder()
          ? _value.recipeId
          // ignore: cast_nullable_to_non_nullable
          : recipeId as String?,
      requestId: requestId == const $CopyWithPlaceholder()
          ? _value.requestId
          // ignore: cast_nullable_to_non_nullable
          : requestId as String?,
      retryFailed: retryFailed == const $CopyWithPlaceholder()
          ? _value.retryFailed
          // ignore: cast_nullable_to_non_nullable
          : retryFailed as bool?,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $ModificationInputCopyWith on ModificationInput {
  /// Returns a callable class that can be used as follows: `instanceOfModificationInput.copyWith(...)` or like so:`instanceOfModificationInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ModificationInputCWProxy get copyWith =>
      _$ModificationInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModificationInput _$ModificationInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ModificationInput',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['text']);
    final val = ModificationInput(
      baseVersionId: $checkedConvert('base_version_id', (v) => v as String?),
      generationRequestId: $checkedConvert(
        'generation_request_id',
        (v) => v as String?,
      ),
      recipeId: $checkedConvert('recipe_id', (v) => v as String?),
      requestId: $checkedConvert('request_id', (v) => v as String?),
      retryFailed: $checkedConvert('retry_failed', (v) => v as bool? ?? false),
      text: $checkedConvert('text', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'baseVersionId': 'base_version_id',
    'generationRequestId': 'generation_request_id',
    'recipeId': 'recipe_id',
    'requestId': 'request_id',
    'retryFailed': 'retry_failed',
  },
);

Map<String, dynamic> _$ModificationInputToJson(ModificationInput instance) =>
    <String, dynamic>{
      'base_version_id': ?instance.baseVersionId,
      'generation_request_id': ?instance.generationRequestId,
      'recipe_id': ?instance.recipeId,
      'request_id': ?instance.requestId,
      'retry_failed': ?instance.retryFailed,
      'text': instance.text,
    };
