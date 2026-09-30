// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'changes_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ChangesResponseCWProxy {
  ChangesResponse added(List<IngredientDetail> added);

  ChangesResponse currentVersion(String currentVersion);

  ChangesResponse merged(List<MergeRelation> merged);

  ChangesResponse modified(List<IngredientDetail> modified);

  ChangesResponse releases(List<ReleaseNote> releases);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ChangesResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ChangesResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  ChangesResponse call({
    List<IngredientDetail> added,
    String currentVersion,
    List<MergeRelation> merged,
    List<IngredientDetail> modified,
    List<ReleaseNote> releases,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfChangesResponse.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfChangesResponse.copyWith.fieldName(...)`
class _$ChangesResponseCWProxyImpl implements _$ChangesResponseCWProxy {
  const _$ChangesResponseCWProxyImpl(this._value);

  final ChangesResponse _value;

  @override
  ChangesResponse added(List<IngredientDetail> added) => this(added: added);

  @override
  ChangesResponse currentVersion(String currentVersion) =>
      this(currentVersion: currentVersion);

  @override
  ChangesResponse merged(List<MergeRelation> merged) => this(merged: merged);

  @override
  ChangesResponse modified(List<IngredientDetail> modified) =>
      this(modified: modified);

  @override
  ChangesResponse releases(List<ReleaseNote> releases) =>
      this(releases: releases);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ChangesResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ChangesResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  ChangesResponse call({
    Object? added = const $CopyWithPlaceholder(),
    Object? currentVersion = const $CopyWithPlaceholder(),
    Object? merged = const $CopyWithPlaceholder(),
    Object? modified = const $CopyWithPlaceholder(),
    Object? releases = const $CopyWithPlaceholder(),
  }) {
    return ChangesResponse(
      added: added == const $CopyWithPlaceholder()
          ? _value.added
          // ignore: cast_nullable_to_non_nullable
          : added as List<IngredientDetail>,
      currentVersion: currentVersion == const $CopyWithPlaceholder()
          ? _value.currentVersion
          // ignore: cast_nullable_to_non_nullable
          : currentVersion as String,
      merged: merged == const $CopyWithPlaceholder()
          ? _value.merged
          // ignore: cast_nullable_to_non_nullable
          : merged as List<MergeRelation>,
      modified: modified == const $CopyWithPlaceholder()
          ? _value.modified
          // ignore: cast_nullable_to_non_nullable
          : modified as List<IngredientDetail>,
      releases: releases == const $CopyWithPlaceholder()
          ? _value.releases
          // ignore: cast_nullable_to_non_nullable
          : releases as List<ReleaseNote>,
    );
  }
}

extension $ChangesResponseCopyWith on ChangesResponse {
  /// Returns a callable class that can be used as follows: `instanceOfChangesResponse.copyWith(...)` or like so:`instanceOfChangesResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ChangesResponseCWProxy get copyWith => _$ChangesResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChangesResponse _$ChangesResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ChangesResponse', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'added',
          'current_version',
          'merged',
          'modified',
          'releases',
        ],
      );
      final val = ChangesResponse(
        added: $checkedConvert(
          'added',
          (v) => (v as List<dynamic>)
              .map((e) => IngredientDetail.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        currentVersion: $checkedConvert('current_version', (v) => v as String),
        merged: $checkedConvert(
          'merged',
          (v) => (v as List<dynamic>)
              .map((e) => MergeRelation.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        modified: $checkedConvert(
          'modified',
          (v) => (v as List<dynamic>)
              .map((e) => IngredientDetail.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        releases: $checkedConvert(
          'releases',
          (v) => (v as List<dynamic>)
              .map((e) => ReleaseNote.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'currentVersion': 'current_version'});

Map<String, dynamic> _$ChangesResponseToJson(ChangesResponse instance) =>
    <String, dynamic>{
      'added': instance.added.map((e) => e.toJson()).toList(),
      'current_version': instance.currentVersion,
      'merged': instance.merged.map((e) => e.toJson()).toList(),
      'modified': instance.modified.map((e) => e.toJson()).toList(),
      'releases': instance.releases.map((e) => e.toJson()).toList(),
    };
