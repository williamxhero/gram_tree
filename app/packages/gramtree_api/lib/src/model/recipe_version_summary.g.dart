// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_version_summary.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeVersionSummaryCWProxy {
  RecipeVersionSummary aiAssisted(bool aiAssisted);

  RecipeVersionSummary changeNote(String changeNote);

  RecipeVersionSummary createdAt(String createdAt);

  RecipeVersionSummary id(String id);

  RecipeVersionSummary previousVersionId(String? previousVersionId);

  RecipeVersionSummary versionNumber(int versionNumber);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeVersionSummary(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeVersionSummary(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeVersionSummary call({
    bool aiAssisted,
    String changeNote,
    String createdAt,
    String id,
    String? previousVersionId,
    int versionNumber,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeVersionSummary.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeVersionSummary.copyWith.fieldName(...)`
class _$RecipeVersionSummaryCWProxyImpl
    implements _$RecipeVersionSummaryCWProxy {
  const _$RecipeVersionSummaryCWProxyImpl(this._value);

  final RecipeVersionSummary _value;

  @override
  RecipeVersionSummary aiAssisted(bool aiAssisted) =>
      this(aiAssisted: aiAssisted);

  @override
  RecipeVersionSummary changeNote(String changeNote) =>
      this(changeNote: changeNote);

  @override
  RecipeVersionSummary createdAt(String createdAt) =>
      this(createdAt: createdAt);

  @override
  RecipeVersionSummary id(String id) => this(id: id);

  @override
  RecipeVersionSummary previousVersionId(String? previousVersionId) =>
      this(previousVersionId: previousVersionId);

  @override
  RecipeVersionSummary versionNumber(int versionNumber) =>
      this(versionNumber: versionNumber);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeVersionSummary(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeVersionSummary(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeVersionSummary call({
    Object? aiAssisted = const $CopyWithPlaceholder(),
    Object? changeNote = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? previousVersionId = const $CopyWithPlaceholder(),
    Object? versionNumber = const $CopyWithPlaceholder(),
  }) {
    return RecipeVersionSummary(
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
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      previousVersionId: previousVersionId == const $CopyWithPlaceholder()
          ? _value.previousVersionId
          // ignore: cast_nullable_to_non_nullable
          : previousVersionId as String?,
      versionNumber: versionNumber == const $CopyWithPlaceholder()
          ? _value.versionNumber
          // ignore: cast_nullable_to_non_nullable
          : versionNumber as int,
    );
  }
}

extension $RecipeVersionSummaryCopyWith on RecipeVersionSummary {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeVersionSummary.copyWith(...)` or like so:`instanceOfRecipeVersionSummary.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeVersionSummaryCWProxy get copyWith =>
      _$RecipeVersionSummaryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeVersionSummary _$RecipeVersionSummaryFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'RecipeVersionSummary',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'ai_assisted',
        'change_note',
        'created_at',
        'id',
        'version_number',
      ],
    );
    final val = RecipeVersionSummary(
      aiAssisted: $checkedConvert('ai_assisted', (v) => v as bool),
      changeNote: $checkedConvert('change_note', (v) => v as String),
      createdAt: $checkedConvert('created_at', (v) => v as String),
      id: $checkedConvert('id', (v) => v as String),
      previousVersionId: $checkedConvert(
        'previous_version_id',
        (v) => v as String?,
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
    'previousVersionId': 'previous_version_id',
    'versionNumber': 'version_number',
  },
);

Map<String, dynamic> _$RecipeVersionSummaryToJson(
  RecipeVersionSummary instance,
) => <String, dynamic>{
  'ai_assisted': instance.aiAssisted,
  'change_note': instance.changeNote,
  'created_at': instance.createdAt,
  'id': instance.id,
  'previous_version_id': ?instance.previousVersionId,
  'version_number': instance.versionNumber,
};
