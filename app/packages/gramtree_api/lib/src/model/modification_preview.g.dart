// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modification_preview.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ModificationPreviewCWProxy {
  ModificationPreview baseVersionId(String? baseVersionId);

  ModificationPreview decisions(List<ModificationDecisionOut>? decisions);

  ModificationPreview error(String? error);

  ModificationPreview generationRequestId(String? generationRequestId);

  ModificationPreview id(String id);

  ModificationPreview intent(ModificationIntent? intent);

  ModificationPreview operations(List<ModificationOperation>? operations);

  ModificationPreview recipeId(String? recipeId);

  ModificationPreview reproducibility(
    RecipeReproducibilityResult reproducibility,
  );

  ModificationPreview revision(int revision);

  ModificationPreview safety(RecipeSafetyResult safety);

  ModificationPreview snapshot(RecipeSnapshot snapshot);

  ModificationPreview status(AIStatus status);

  ModificationPreview warnings(List<String>? warnings);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModificationPreview(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModificationPreview(...).copyWith(id: 12, name: "My name")
  /// ````
  ModificationPreview call({
    String? baseVersionId,
    List<ModificationDecisionOut>? decisions,
    String? error,
    String? generationRequestId,
    String id,
    ModificationIntent? intent,
    List<ModificationOperation>? operations,
    String? recipeId,
    RecipeReproducibilityResult reproducibility,
    int revision,
    RecipeSafetyResult safety,
    RecipeSnapshot snapshot,
    AIStatus status,
    List<String>? warnings,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfModificationPreview.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfModificationPreview.copyWith.fieldName(...)`
class _$ModificationPreviewCWProxyImpl implements _$ModificationPreviewCWProxy {
  const _$ModificationPreviewCWProxyImpl(this._value);

  final ModificationPreview _value;

  @override
  ModificationPreview baseVersionId(String? baseVersionId) =>
      this(baseVersionId: baseVersionId);

  @override
  ModificationPreview decisions(List<ModificationDecisionOut>? decisions) =>
      this(decisions: decisions);

  @override
  ModificationPreview error(String? error) => this(error: error);

  @override
  ModificationPreview generationRequestId(String? generationRequestId) =>
      this(generationRequestId: generationRequestId);

  @override
  ModificationPreview id(String id) => this(id: id);

  @override
  ModificationPreview intent(ModificationIntent? intent) =>
      this(intent: intent);

  @override
  ModificationPreview operations(List<ModificationOperation>? operations) =>
      this(operations: operations);

  @override
  ModificationPreview recipeId(String? recipeId) => this(recipeId: recipeId);

  @override
  ModificationPreview reproducibility(
    RecipeReproducibilityResult reproducibility,
  ) => this(reproducibility: reproducibility);

  @override
  ModificationPreview revision(int revision) => this(revision: revision);

  @override
  ModificationPreview safety(RecipeSafetyResult safety) => this(safety: safety);

  @override
  ModificationPreview snapshot(RecipeSnapshot snapshot) =>
      this(snapshot: snapshot);

  @override
  ModificationPreview status(AIStatus status) => this(status: status);

  @override
  ModificationPreview warnings(List<String>? warnings) =>
      this(warnings: warnings);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModificationPreview(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModificationPreview(...).copyWith(id: 12, name: "My name")
  /// ````
  ModificationPreview call({
    Object? baseVersionId = const $CopyWithPlaceholder(),
    Object? decisions = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
    Object? generationRequestId = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? intent = const $CopyWithPlaceholder(),
    Object? operations = const $CopyWithPlaceholder(),
    Object? recipeId = const $CopyWithPlaceholder(),
    Object? reproducibility = const $CopyWithPlaceholder(),
    Object? revision = const $CopyWithPlaceholder(),
    Object? safety = const $CopyWithPlaceholder(),
    Object? snapshot = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? warnings = const $CopyWithPlaceholder(),
  }) {
    return ModificationPreview(
      baseVersionId: baseVersionId == const $CopyWithPlaceholder()
          ? _value.baseVersionId
          // ignore: cast_nullable_to_non_nullable
          : baseVersionId as String?,
      decisions: decisions == const $CopyWithPlaceholder()
          ? _value.decisions
          // ignore: cast_nullable_to_non_nullable
          : decisions as List<ModificationDecisionOut>?,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
      generationRequestId: generationRequestId == const $CopyWithPlaceholder()
          ? _value.generationRequestId
          // ignore: cast_nullable_to_non_nullable
          : generationRequestId as String?,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      intent: intent == const $CopyWithPlaceholder()
          ? _value.intent
          // ignore: cast_nullable_to_non_nullable
          : intent as ModificationIntent?,
      operations: operations == const $CopyWithPlaceholder()
          ? _value.operations
          // ignore: cast_nullable_to_non_nullable
          : operations as List<ModificationOperation>?,
      recipeId: recipeId == const $CopyWithPlaceholder()
          ? _value.recipeId
          // ignore: cast_nullable_to_non_nullable
          : recipeId as String?,
      reproducibility: reproducibility == const $CopyWithPlaceholder()
          ? _value.reproducibility
          // ignore: cast_nullable_to_non_nullable
          : reproducibility as RecipeReproducibilityResult,
      revision: revision == const $CopyWithPlaceholder()
          ? _value.revision
          // ignore: cast_nullable_to_non_nullable
          : revision as int,
      safety: safety == const $CopyWithPlaceholder()
          ? _value.safety
          // ignore: cast_nullable_to_non_nullable
          : safety as RecipeSafetyResult,
      snapshot: snapshot == const $CopyWithPlaceholder()
          ? _value.snapshot
          // ignore: cast_nullable_to_non_nullable
          : snapshot as RecipeSnapshot,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as AIStatus,
      warnings: warnings == const $CopyWithPlaceholder()
          ? _value.warnings
          // ignore: cast_nullable_to_non_nullable
          : warnings as List<String>?,
    );
  }
}

extension $ModificationPreviewCopyWith on ModificationPreview {
  /// Returns a callable class that can be used as follows: `instanceOfModificationPreview.copyWith(...)` or like so:`instanceOfModificationPreview.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ModificationPreviewCWProxy get copyWith =>
      _$ModificationPreviewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModificationPreview _$ModificationPreviewFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ModificationPreview',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'reproducibility',
        'revision',
        'safety',
        'snapshot',
        'status',
      ],
    );
    final val = ModificationPreview(
      baseVersionId: $checkedConvert('base_version_id', (v) => v as String?),
      decisions: $checkedConvert(
        'decisions',
        (v) => (v as List<dynamic>?)
            ?.map(
              (e) =>
                  ModificationDecisionOut.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      error: $checkedConvert('error', (v) => v as String?),
      generationRequestId: $checkedConvert(
        'generation_request_id',
        (v) => v as String?,
      ),
      id: $checkedConvert('id', (v) => v as String),
      intent: $checkedConvert(
        'intent',
        (v) => v == null
            ? null
            : ModificationIntent.fromJson(v as Map<String, dynamic>),
      ),
      operations: $checkedConvert(
        'operations',
        (v) => (v as List<dynamic>?)
            ?.map(
              (e) => ModificationOperation.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      recipeId: $checkedConvert('recipe_id', (v) => v as String?),
      reproducibility: $checkedConvert(
        'reproducibility',
        (v) => RecipeReproducibilityResult.fromJson(v as Map<String, dynamic>),
      ),
      revision: $checkedConvert('revision', (v) => (v as num).toInt()),
      safety: $checkedConvert(
        'safety',
        (v) => RecipeSafetyResult.fromJson(v as Map<String, dynamic>),
      ),
      snapshot: $checkedConvert(
        'snapshot',
        (v) => RecipeSnapshot.fromJson(v as Map<String, dynamic>),
      ),
      status: $checkedConvert(
        'status',
        (v) => AIStatus.fromJson(v as Map<String, dynamic>),
      ),
      warnings: $checkedConvert(
        'warnings',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'baseVersionId': 'base_version_id',
    'generationRequestId': 'generation_request_id',
    'recipeId': 'recipe_id',
  },
);

Map<String, dynamic> _$ModificationPreviewToJson(
  ModificationPreview instance,
) => <String, dynamic>{
  'base_version_id': ?instance.baseVersionId,
  'decisions': ?instance.decisions?.map((e) => e.toJson()).toList(),
  'error': ?instance.error,
  'generation_request_id': ?instance.generationRequestId,
  'id': instance.id,
  'intent': ?instance.intent?.toJson(),
  'operations': ?instance.operations?.map((e) => e.toJson()).toList(),
  'recipe_id': ?instance.recipeId,
  'reproducibility': instance.reproducibility.toJson(),
  'revision': instance.revision,
  'safety': instance.safety.toJson(),
  'snapshot': instance.snapshot.toJson(),
  'status': instance.status.toJson(),
  'warnings': ?instance.warnings,
};
