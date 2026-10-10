// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_explanation_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ChangeExplanationInputCWProxy {
  ChangeExplanationInput baseVersionId(String? baseVersionId);

  ChangeExplanationInput generationRequestId(String? generationRequestId);

  ChangeExplanationInput modificationId(String? modificationId);

  ChangeExplanationInput recipeId(String? recipeId);

  ChangeExplanationInput revision(int? revision);

  ChangeExplanationInput snapshot(RecipeSnapshot? snapshot);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ChangeExplanationInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ChangeExplanationInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ChangeExplanationInput call({
    String? baseVersionId,
    String? generationRequestId,
    String? modificationId,
    String? recipeId,
    int? revision,
    RecipeSnapshot? snapshot,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfChangeExplanationInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfChangeExplanationInput.copyWith.fieldName(...)`
class _$ChangeExplanationInputCWProxyImpl
    implements _$ChangeExplanationInputCWProxy {
  const _$ChangeExplanationInputCWProxyImpl(this._value);

  final ChangeExplanationInput _value;

  @override
  ChangeExplanationInput baseVersionId(String? baseVersionId) =>
      this(baseVersionId: baseVersionId);

  @override
  ChangeExplanationInput generationRequestId(String? generationRequestId) =>
      this(generationRequestId: generationRequestId);

  @override
  ChangeExplanationInput modificationId(String? modificationId) =>
      this(modificationId: modificationId);

  @override
  ChangeExplanationInput recipeId(String? recipeId) => this(recipeId: recipeId);

  @override
  ChangeExplanationInput revision(int? revision) => this(revision: revision);

  @override
  ChangeExplanationInput snapshot(RecipeSnapshot? snapshot) =>
      this(snapshot: snapshot);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ChangeExplanationInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ChangeExplanationInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ChangeExplanationInput call({
    Object? baseVersionId = const $CopyWithPlaceholder(),
    Object? generationRequestId = const $CopyWithPlaceholder(),
    Object? modificationId = const $CopyWithPlaceholder(),
    Object? recipeId = const $CopyWithPlaceholder(),
    Object? revision = const $CopyWithPlaceholder(),
    Object? snapshot = const $CopyWithPlaceholder(),
  }) {
    return ChangeExplanationInput(
      baseVersionId: baseVersionId == const $CopyWithPlaceholder()
          ? _value.baseVersionId
          // ignore: cast_nullable_to_non_nullable
          : baseVersionId as String?,
      generationRequestId: generationRequestId == const $CopyWithPlaceholder()
          ? _value.generationRequestId
          // ignore: cast_nullable_to_non_nullable
          : generationRequestId as String?,
      modificationId: modificationId == const $CopyWithPlaceholder()
          ? _value.modificationId
          // ignore: cast_nullable_to_non_nullable
          : modificationId as String?,
      recipeId: recipeId == const $CopyWithPlaceholder()
          ? _value.recipeId
          // ignore: cast_nullable_to_non_nullable
          : recipeId as String?,
      revision: revision == const $CopyWithPlaceholder()
          ? _value.revision
          // ignore: cast_nullable_to_non_nullable
          : revision as int?,
      snapshot: snapshot == const $CopyWithPlaceholder()
          ? _value.snapshot
          // ignore: cast_nullable_to_non_nullable
          : snapshot as RecipeSnapshot?,
    );
  }
}

extension $ChangeExplanationInputCopyWith on ChangeExplanationInput {
  /// Returns a callable class that can be used as follows: `instanceOfChangeExplanationInput.copyWith(...)` or like so:`instanceOfChangeExplanationInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ChangeExplanationInputCWProxy get copyWith =>
      _$ChangeExplanationInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChangeExplanationInput _$ChangeExplanationInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ChangeExplanationInput',
  json,
  ($checkedConvert) {
    final val = ChangeExplanationInput(
      baseVersionId: $checkedConvert('base_version_id', (v) => v as String?),
      generationRequestId: $checkedConvert(
        'generation_request_id',
        (v) => v as String?,
      ),
      modificationId: $checkedConvert('modification_id', (v) => v as String?),
      recipeId: $checkedConvert('recipe_id', (v) => v as String?),
      revision: $checkedConvert('revision', (v) => (v as num?)?.toInt()),
      snapshot: $checkedConvert(
        'snapshot',
        (v) => v == null
            ? null
            : RecipeSnapshot.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'baseVersionId': 'base_version_id',
    'generationRequestId': 'generation_request_id',
    'modificationId': 'modification_id',
    'recipeId': 'recipe_id',
  },
);

Map<String, dynamic> _$ChangeExplanationInputToJson(
  ChangeExplanationInput instance,
) => <String, dynamic>{
  'base_version_id': ?instance.baseVersionId,
  'generation_request_id': ?instance.generationRequestId,
  'modification_id': ?instance.modificationId,
  'recipe_id': ?instance.recipeId,
  'revision': ?instance.revision,
  'snapshot': ?instance.snapshot?.toJson(),
};
