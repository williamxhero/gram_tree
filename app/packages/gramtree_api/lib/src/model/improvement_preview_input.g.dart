// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'improvement_preview_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ImprovementPreviewInputCWProxy {
  ImprovementPreviewInput changeNote(String? changeNote);

  ImprovementPreviewInput explanationFingerprint(
    String? explanationFingerprint,
  );

  ImprovementPreviewInput fromCookingRecordId(String? fromCookingRecordId);

  ImprovementPreviewInput modificationRequestId(String? modificationRequestId);

  ImprovementPreviewInput modificationRevision(int? modificationRevision);

  ImprovementPreviewInput snapshot(RecipeSnapshot? snapshot);

  ImprovementPreviewInput sourceVersionId(String sourceVersionId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ImprovementPreviewInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ImprovementPreviewInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ImprovementPreviewInput call({
    String? changeNote,
    String? explanationFingerprint,
    String? fromCookingRecordId,
    String? modificationRequestId,
    int? modificationRevision,
    RecipeSnapshot? snapshot,
    String sourceVersionId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfImprovementPreviewInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfImprovementPreviewInput.copyWith.fieldName(...)`
class _$ImprovementPreviewInputCWProxyImpl
    implements _$ImprovementPreviewInputCWProxy {
  const _$ImprovementPreviewInputCWProxyImpl(this._value);

  final ImprovementPreviewInput _value;

  @override
  ImprovementPreviewInput changeNote(String? changeNote) =>
      this(changeNote: changeNote);

  @override
  ImprovementPreviewInput explanationFingerprint(
    String? explanationFingerprint,
  ) => this(explanationFingerprint: explanationFingerprint);

  @override
  ImprovementPreviewInput fromCookingRecordId(String? fromCookingRecordId) =>
      this(fromCookingRecordId: fromCookingRecordId);

  @override
  ImprovementPreviewInput modificationRequestId(
    String? modificationRequestId,
  ) => this(modificationRequestId: modificationRequestId);

  @override
  ImprovementPreviewInput modificationRevision(int? modificationRevision) =>
      this(modificationRevision: modificationRevision);

  @override
  ImprovementPreviewInput snapshot(RecipeSnapshot? snapshot) =>
      this(snapshot: snapshot);

  @override
  ImprovementPreviewInput sourceVersionId(String sourceVersionId) =>
      this(sourceVersionId: sourceVersionId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ImprovementPreviewInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ImprovementPreviewInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ImprovementPreviewInput call({
    Object? changeNote = const $CopyWithPlaceholder(),
    Object? explanationFingerprint = const $CopyWithPlaceholder(),
    Object? fromCookingRecordId = const $CopyWithPlaceholder(),
    Object? modificationRequestId = const $CopyWithPlaceholder(),
    Object? modificationRevision = const $CopyWithPlaceholder(),
    Object? snapshot = const $CopyWithPlaceholder(),
    Object? sourceVersionId = const $CopyWithPlaceholder(),
  }) {
    return ImprovementPreviewInput(
      changeNote: changeNote == const $CopyWithPlaceholder()
          ? _value.changeNote
          // ignore: cast_nullable_to_non_nullable
          : changeNote as String?,
      explanationFingerprint:
          explanationFingerprint == const $CopyWithPlaceholder()
          ? _value.explanationFingerprint
          // ignore: cast_nullable_to_non_nullable
          : explanationFingerprint as String?,
      fromCookingRecordId: fromCookingRecordId == const $CopyWithPlaceholder()
          ? _value.fromCookingRecordId
          // ignore: cast_nullable_to_non_nullable
          : fromCookingRecordId as String?,
      modificationRequestId:
          modificationRequestId == const $CopyWithPlaceholder()
          ? _value.modificationRequestId
          // ignore: cast_nullable_to_non_nullable
          : modificationRequestId as String?,
      modificationRevision: modificationRevision == const $CopyWithPlaceholder()
          ? _value.modificationRevision
          // ignore: cast_nullable_to_non_nullable
          : modificationRevision as int?,
      snapshot: snapshot == const $CopyWithPlaceholder()
          ? _value.snapshot
          // ignore: cast_nullable_to_non_nullable
          : snapshot as RecipeSnapshot?,
      sourceVersionId: sourceVersionId == const $CopyWithPlaceholder()
          ? _value.sourceVersionId
          // ignore: cast_nullable_to_non_nullable
          : sourceVersionId as String,
    );
  }
}

extension $ImprovementPreviewInputCopyWith on ImprovementPreviewInput {
  /// Returns a callable class that can be used as follows: `instanceOfImprovementPreviewInput.copyWith(...)` or like so:`instanceOfImprovementPreviewInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ImprovementPreviewInputCWProxy get copyWith =>
      _$ImprovementPreviewInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImprovementPreviewInput _$ImprovementPreviewInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ImprovementPreviewInput',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['source_version_id']);
    final val = ImprovementPreviewInput(
      changeNote: $checkedConvert('change_note', (v) => v as String? ?? ''),
      explanationFingerprint: $checkedConvert(
        'explanation_fingerprint',
        (v) => v as String?,
      ),
      fromCookingRecordId: $checkedConvert(
        'from_cooking_record_id',
        (v) => v as String?,
      ),
      modificationRequestId: $checkedConvert(
        'modification_request_id',
        (v) => v as String?,
      ),
      modificationRevision: $checkedConvert(
        'modification_revision',
        (v) => (v as num?)?.toInt(),
      ),
      snapshot: $checkedConvert(
        'snapshot',
        (v) => v == null
            ? null
            : RecipeSnapshot.fromJson(v as Map<String, dynamic>),
      ),
      sourceVersionId: $checkedConvert('source_version_id', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'changeNote': 'change_note',
    'explanationFingerprint': 'explanation_fingerprint',
    'fromCookingRecordId': 'from_cooking_record_id',
    'modificationRequestId': 'modification_request_id',
    'modificationRevision': 'modification_revision',
    'sourceVersionId': 'source_version_id',
  },
);

Map<String, dynamic> _$ImprovementPreviewInputToJson(
  ImprovementPreviewInput instance,
) => <String, dynamic>{
  'change_note': ?instance.changeNote,
  'explanation_fingerprint': ?instance.explanationFingerprint,
  'from_cooking_record_id': ?instance.fromCookingRecordId,
  'modification_request_id': ?instance.modificationRequestId,
  'modification_revision': ?instance.modificationRevision,
  'snapshot': ?instance.snapshot?.toJson(),
  'source_version_id': instance.sourceVersionId,
};
