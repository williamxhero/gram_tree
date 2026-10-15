// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'improvement_draft_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ImprovementDraftOutCWProxy {
  ImprovementDraftOut aiAssisted(bool aiAssisted);

  ImprovementDraftOut dishName(String dishName);

  ImprovementDraftOut id(String id);

  ImprovementDraftOut snapshot(RecipeSnapshot snapshot);

  ImprovementDraftOut sourceRecipeId(String sourceRecipeId);

  ImprovementDraftOut sourceVersionId(String sourceVersionId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ImprovementDraftOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ImprovementDraftOut(...).copyWith(id: 12, name: "My name")
  /// ````
  ImprovementDraftOut call({
    bool aiAssisted,
    String dishName,
    String id,
    RecipeSnapshot snapshot,
    String sourceRecipeId,
    String sourceVersionId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfImprovementDraftOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfImprovementDraftOut.copyWith.fieldName(...)`
class _$ImprovementDraftOutCWProxyImpl implements _$ImprovementDraftOutCWProxy {
  const _$ImprovementDraftOutCWProxyImpl(this._value);

  final ImprovementDraftOut _value;

  @override
  ImprovementDraftOut aiAssisted(bool aiAssisted) =>
      this(aiAssisted: aiAssisted);

  @override
  ImprovementDraftOut dishName(String dishName) => this(dishName: dishName);

  @override
  ImprovementDraftOut id(String id) => this(id: id);

  @override
  ImprovementDraftOut snapshot(RecipeSnapshot snapshot) =>
      this(snapshot: snapshot);

  @override
  ImprovementDraftOut sourceRecipeId(String sourceRecipeId) =>
      this(sourceRecipeId: sourceRecipeId);

  @override
  ImprovementDraftOut sourceVersionId(String sourceVersionId) =>
      this(sourceVersionId: sourceVersionId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ImprovementDraftOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ImprovementDraftOut(...).copyWith(id: 12, name: "My name")
  /// ````
  ImprovementDraftOut call({
    Object? aiAssisted = const $CopyWithPlaceholder(),
    Object? dishName = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? snapshot = const $CopyWithPlaceholder(),
    Object? sourceRecipeId = const $CopyWithPlaceholder(),
    Object? sourceVersionId = const $CopyWithPlaceholder(),
  }) {
    return ImprovementDraftOut(
      aiAssisted: aiAssisted == const $CopyWithPlaceholder()
          ? _value.aiAssisted
          // ignore: cast_nullable_to_non_nullable
          : aiAssisted as bool,
      dishName: dishName == const $CopyWithPlaceholder()
          ? _value.dishName
          // ignore: cast_nullable_to_non_nullable
          : dishName as String,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      snapshot: snapshot == const $CopyWithPlaceholder()
          ? _value.snapshot
          // ignore: cast_nullable_to_non_nullable
          : snapshot as RecipeSnapshot,
      sourceRecipeId: sourceRecipeId == const $CopyWithPlaceholder()
          ? _value.sourceRecipeId
          // ignore: cast_nullable_to_non_nullable
          : sourceRecipeId as String,
      sourceVersionId: sourceVersionId == const $CopyWithPlaceholder()
          ? _value.sourceVersionId
          // ignore: cast_nullable_to_non_nullable
          : sourceVersionId as String,
    );
  }
}

extension $ImprovementDraftOutCopyWith on ImprovementDraftOut {
  /// Returns a callable class that can be used as follows: `instanceOfImprovementDraftOut.copyWith(...)` or like so:`instanceOfImprovementDraftOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ImprovementDraftOutCWProxy get copyWith =>
      _$ImprovementDraftOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImprovementDraftOut _$ImprovementDraftOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ImprovementDraftOut',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'ai_assisted',
        'dish_name',
        'id',
        'snapshot',
        'source_recipe_id',
        'source_version_id',
      ],
    );
    final val = ImprovementDraftOut(
      aiAssisted: $checkedConvert('ai_assisted', (v) => v as bool),
      dishName: $checkedConvert('dish_name', (v) => v as String),
      id: $checkedConvert('id', (v) => v as String),
      snapshot: $checkedConvert(
        'snapshot',
        (v) => RecipeSnapshot.fromJson(v as Map<String, dynamic>),
      ),
      sourceRecipeId: $checkedConvert('source_recipe_id', (v) => v as String),
      sourceVersionId: $checkedConvert('source_version_id', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'aiAssisted': 'ai_assisted',
    'dishName': 'dish_name',
    'sourceRecipeId': 'source_recipe_id',
    'sourceVersionId': 'source_version_id',
  },
);

Map<String, dynamic> _$ImprovementDraftOutToJson(
  ImprovementDraftOut instance,
) => <String, dynamic>{
  'ai_assisted': instance.aiAssisted,
  'dish_name': instance.dishName,
  'id': instance.id,
  'snapshot': instance.snapshot.toJson(),
  'source_recipe_id': instance.sourceRecipeId,
  'source_version_id': instance.sourceVersionId,
};
