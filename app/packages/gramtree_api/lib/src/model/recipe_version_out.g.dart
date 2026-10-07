// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_version_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeVersionOutCWProxy {
  RecipeVersionOut aiAssisted(bool aiAssisted);

  RecipeVersionOut changeNote(String changeNote);

  RecipeVersionOut createdAt(String createdAt);

  RecipeVersionOut derived(RecipeDerived derived);

  RecipeVersionOut editOperations(List<Object> editOperations);

  RecipeVersionOut id(String id);

  RecipeVersionOut images(List<RecipeImageOut>? images);

  RecipeVersionOut previousVersionId(String? previousVersionId);

  RecipeVersionOut reproducibility(
    RecipeReproducibilityResult? reproducibility,
  );

  RecipeVersionOut safety(RecipeSafetyResult? safety);

  RecipeVersionOut safetyAtSave(RecipeSafetyResult? safetyAtSave);

  RecipeVersionOut snapshot(RecipeSnapshot snapshot);

  RecipeVersionOut versionNumber(int versionNumber);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeVersionOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeVersionOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeVersionOut call({
    bool aiAssisted,
    String changeNote,
    String createdAt,
    RecipeDerived derived,
    List<Object> editOperations,
    String id,
    List<RecipeImageOut>? images,
    String? previousVersionId,
    RecipeReproducibilityResult? reproducibility,
    RecipeSafetyResult? safety,
    RecipeSafetyResult? safetyAtSave,
    RecipeSnapshot snapshot,
    int versionNumber,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeVersionOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeVersionOut.copyWith.fieldName(...)`
class _$RecipeVersionOutCWProxyImpl implements _$RecipeVersionOutCWProxy {
  const _$RecipeVersionOutCWProxyImpl(this._value);

  final RecipeVersionOut _value;

  @override
  RecipeVersionOut aiAssisted(bool aiAssisted) => this(aiAssisted: aiAssisted);

  @override
  RecipeVersionOut changeNote(String changeNote) =>
      this(changeNote: changeNote);

  @override
  RecipeVersionOut createdAt(String createdAt) => this(createdAt: createdAt);

  @override
  RecipeVersionOut derived(RecipeDerived derived) => this(derived: derived);

  @override
  RecipeVersionOut editOperations(List<Object> editOperations) =>
      this(editOperations: editOperations);

  @override
  RecipeVersionOut id(String id) => this(id: id);

  @override
  RecipeVersionOut images(List<RecipeImageOut>? images) => this(images: images);

  @override
  RecipeVersionOut previousVersionId(String? previousVersionId) =>
      this(previousVersionId: previousVersionId);

  @override
  RecipeVersionOut reproducibility(
    RecipeReproducibilityResult? reproducibility,
  ) => this(reproducibility: reproducibility);

  @override
  RecipeVersionOut safety(RecipeSafetyResult? safety) => this(safety: safety);

  @override
  RecipeVersionOut safetyAtSave(RecipeSafetyResult? safetyAtSave) =>
      this(safetyAtSave: safetyAtSave);

  @override
  RecipeVersionOut snapshot(RecipeSnapshot snapshot) =>
      this(snapshot: snapshot);

  @override
  RecipeVersionOut versionNumber(int versionNumber) =>
      this(versionNumber: versionNumber);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeVersionOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeVersionOut(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeVersionOut call({
    Object? aiAssisted = const $CopyWithPlaceholder(),
    Object? changeNote = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? derived = const $CopyWithPlaceholder(),
    Object? editOperations = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? images = const $CopyWithPlaceholder(),
    Object? previousVersionId = const $CopyWithPlaceholder(),
    Object? reproducibility = const $CopyWithPlaceholder(),
    Object? safety = const $CopyWithPlaceholder(),
    Object? safetyAtSave = const $CopyWithPlaceholder(),
    Object? snapshot = const $CopyWithPlaceholder(),
    Object? versionNumber = const $CopyWithPlaceholder(),
  }) {
    return RecipeVersionOut(
      aiAssisted: aiAssisted == const $CopyWithPlaceholder()
          ? _value.aiAssisted
          // ignore: cast_nullable_to_non_nullable
          : aiAssisted as bool,
      changeNote: changeNote == const $CopyWithPlaceholder()
          ? _value.changeNote
          // ignore: cast_nullable_to_non_nullable
          : changeNote as String,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as String,
      derived: derived == const $CopyWithPlaceholder()
          ? _value.derived
          // ignore: cast_nullable_to_non_nullable
          : derived as RecipeDerived,
      editOperations: editOperations == const $CopyWithPlaceholder()
          ? _value.editOperations
          // ignore: cast_nullable_to_non_nullable
          : editOperations as List<Object>,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      images: images == const $CopyWithPlaceholder()
          ? _value.images
          // ignore: cast_nullable_to_non_nullable
          : images as List<RecipeImageOut>?,
      previousVersionId: previousVersionId == const $CopyWithPlaceholder()
          ? _value.previousVersionId
          // ignore: cast_nullable_to_non_nullable
          : previousVersionId as String?,
      reproducibility: reproducibility == const $CopyWithPlaceholder()
          ? _value.reproducibility
          // ignore: cast_nullable_to_non_nullable
          : reproducibility as RecipeReproducibilityResult?,
      safety: safety == const $CopyWithPlaceholder()
          ? _value.safety
          // ignore: cast_nullable_to_non_nullable
          : safety as RecipeSafetyResult?,
      safetyAtSave: safetyAtSave == const $CopyWithPlaceholder()
          ? _value.safetyAtSave
          // ignore: cast_nullable_to_non_nullable
          : safetyAtSave as RecipeSafetyResult?,
      snapshot: snapshot == const $CopyWithPlaceholder()
          ? _value.snapshot
          // ignore: cast_nullable_to_non_nullable
          : snapshot as RecipeSnapshot,
      versionNumber: versionNumber == const $CopyWithPlaceholder()
          ? _value.versionNumber
          // ignore: cast_nullable_to_non_nullable
          : versionNumber as int,
    );
  }
}

extension $RecipeVersionOutCopyWith on RecipeVersionOut {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeVersionOut.copyWith(...)` or like so:`instanceOfRecipeVersionOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeVersionOutCWProxy get copyWith => _$RecipeVersionOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeVersionOut _$RecipeVersionOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RecipeVersionOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'ai_assisted',
            'change_note',
            'created_at',
            'derived',
            'edit_operations',
            'id',
            'snapshot',
            'version_number',
          ],
        );
        final val = RecipeVersionOut(
          aiAssisted: $checkedConvert('ai_assisted', (v) => v as bool),
          changeNote: $checkedConvert('change_note', (v) => v as String),
          createdAt: $checkedConvert('created_at', (v) => v as String),
          derived: $checkedConvert(
            'derived',
            (v) => RecipeDerived.fromJson(v as Map<String, dynamic>),
          ),
          editOperations: $checkedConvert(
            'edit_operations',
            (v) => (v as List<dynamic>).map((e) => e as Object).toList(),
          ),
          id: $checkedConvert('id', (v) => v as String),
          images: $checkedConvert(
            'images',
            (v) => (v as List<dynamic>?)
                ?.map((e) => RecipeImageOut.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
          previousVersionId: $checkedConvert(
            'previous_version_id',
            (v) => v as String?,
          ),
          reproducibility: $checkedConvert(
            'reproducibility',
            (v) => v == null
                ? null
                : RecipeReproducibilityResult.fromJson(
                    v as Map<String, dynamic>,
                  ),
          ),
          safety: $checkedConvert(
            'safety',
            (v) => v == null
                ? null
                : RecipeSafetyResult.fromJson(v as Map<String, dynamic>),
          ),
          safetyAtSave: $checkedConvert(
            'safety_at_save',
            (v) => v == null
                ? null
                : RecipeSafetyResult.fromJson(v as Map<String, dynamic>),
          ),
          snapshot: $checkedConvert(
            'snapshot',
            (v) => RecipeSnapshot.fromJson(v as Map<String, dynamic>),
          ),
          versionNumber: $checkedConvert(
            'version_number',
            (v) => (v as num).toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'aiAssisted': 'ai_assisted',
        'changeNote': 'change_note',
        'createdAt': 'created_at',
        'editOperations': 'edit_operations',
        'previousVersionId': 'previous_version_id',
        'safetyAtSave': 'safety_at_save',
        'versionNumber': 'version_number',
      },
    );

Map<String, dynamic> _$RecipeVersionOutToJson(RecipeVersionOut instance) =>
    <String, dynamic>{
      'ai_assisted': instance.aiAssisted,
      'change_note': instance.changeNote,
      'created_at': instance.createdAt,
      'derived': instance.derived.toJson(),
      'edit_operations': instance.editOperations,
      'id': instance.id,
      'images': ?instance.images?.map((e) => e.toJson()).toList(),
      'previous_version_id': ?instance.previousVersionId,
      'reproducibility': ?instance.reproducibility?.toJson(),
      'safety': ?instance.safety?.toJson(),
      'safety_at_save': ?instance.safetyAtSave?.toJson(),
      'snapshot': instance.snapshot.toJson(),
      'version_number': instance.versionNumber,
    };
