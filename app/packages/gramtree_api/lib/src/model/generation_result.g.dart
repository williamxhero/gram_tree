// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generation_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GenerationResultCWProxy {
  GenerationResult draft(GeneratedDraft? draft);

  GenerationResult error(String? error);

  GenerationResult ingredientConfirmations(
    List<String>? ingredientConfirmations,
  );

  GenerationResult numericWarnings(List<String>? numericWarnings);

  GenerationResult requestId(String requestId);

  GenerationResult safety(RecipeSafetyResult? safety);

  GenerationResult status(AIStatus status);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GenerationResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GenerationResult(...).copyWith(id: 12, name: "My name")
  /// ````
  GenerationResult call({
    GeneratedDraft? draft,
    String? error,
    List<String>? ingredientConfirmations,
    List<String>? numericWarnings,
    String requestId,
    RecipeSafetyResult? safety,
    AIStatus status,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGenerationResult.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGenerationResult.copyWith.fieldName(...)`
class _$GenerationResultCWProxyImpl implements _$GenerationResultCWProxy {
  const _$GenerationResultCWProxyImpl(this._value);

  final GenerationResult _value;

  @override
  GenerationResult draft(GeneratedDraft? draft) => this(draft: draft);

  @override
  GenerationResult error(String? error) => this(error: error);

  @override
  GenerationResult ingredientConfirmations(
    List<String>? ingredientConfirmations,
  ) => this(ingredientConfirmations: ingredientConfirmations);

  @override
  GenerationResult numericWarnings(List<String>? numericWarnings) =>
      this(numericWarnings: numericWarnings);

  @override
  GenerationResult requestId(String requestId) => this(requestId: requestId);

  @override
  GenerationResult safety(RecipeSafetyResult? safety) => this(safety: safety);

  @override
  GenerationResult status(AIStatus status) => this(status: status);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GenerationResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GenerationResult(...).copyWith(id: 12, name: "My name")
  /// ````
  GenerationResult call({
    Object? draft = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
    Object? ingredientConfirmations = const $CopyWithPlaceholder(),
    Object? numericWarnings = const $CopyWithPlaceholder(),
    Object? requestId = const $CopyWithPlaceholder(),
    Object? safety = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return GenerationResult(
      draft: draft == const $CopyWithPlaceholder()
          ? _value.draft
          // ignore: cast_nullable_to_non_nullable
          : draft as GeneratedDraft?,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
      ingredientConfirmations:
          ingredientConfirmations == const $CopyWithPlaceholder()
          ? _value.ingredientConfirmations
          // ignore: cast_nullable_to_non_nullable
          : ingredientConfirmations as List<String>?,
      numericWarnings: numericWarnings == const $CopyWithPlaceholder()
          ? _value.numericWarnings
          // ignore: cast_nullable_to_non_nullable
          : numericWarnings as List<String>?,
      requestId: requestId == const $CopyWithPlaceholder()
          ? _value.requestId
          // ignore: cast_nullable_to_non_nullable
          : requestId as String,
      safety: safety == const $CopyWithPlaceholder()
          ? _value.safety
          // ignore: cast_nullable_to_non_nullable
          : safety as RecipeSafetyResult?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as AIStatus,
    );
  }
}

extension $GenerationResultCopyWith on GenerationResult {
  /// Returns a callable class that can be used as follows: `instanceOfGenerationResult.copyWith(...)` or like so:`instanceOfGenerationResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GenerationResultCWProxy get copyWith => _$GenerationResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenerationResult _$GenerationResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'GenerationResult',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['request_id', 'status']);
        final val = GenerationResult(
          draft: $checkedConvert(
            'draft',
            (v) => v == null
                ? null
                : GeneratedDraft.fromJson(v as Map<String, dynamic>),
          ),
          error: $checkedConvert('error', (v) => v as String?),
          ingredientConfirmations: $checkedConvert(
            'ingredient_confirmations',
            (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
          ),
          numericWarnings: $checkedConvert(
            'numeric_warnings',
            (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
          ),
          requestId: $checkedConvert('request_id', (v) => v as String),
          safety: $checkedConvert(
            'safety',
            (v) => v == null
                ? null
                : RecipeSafetyResult.fromJson(v as Map<String, dynamic>),
          ),
          status: $checkedConvert(
            'status',
            (v) => AIStatus.fromJson(v as Map<String, dynamic>),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'ingredientConfirmations': 'ingredient_confirmations',
        'numericWarnings': 'numeric_warnings',
        'requestId': 'request_id',
      },
    );

Map<String, dynamic> _$GenerationResultToJson(GenerationResult instance) =>
    <String, dynamic>{
      'draft': ?instance.draft?.toJson(),
      'error': ?instance.error,
      'ingredient_confirmations': ?instance.ingredientConfirmations,
      'numeric_warnings': ?instance.numericWarnings,
      'request_id': instance.requestId,
      'safety': ?instance.safety?.toJson(),
      'status': instance.status.toJson(),
    };
