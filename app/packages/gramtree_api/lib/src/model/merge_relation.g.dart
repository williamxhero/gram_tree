// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merge_relation.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MergeRelationCWProxy {
  MergeRelation fromId(String fromId);

  MergeRelation toId(String toId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MergeRelation(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MergeRelation(...).copyWith(id: 12, name: "My name")
  /// ````
  MergeRelation call({String fromId, String toId});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMergeRelation.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMergeRelation.copyWith.fieldName(...)`
class _$MergeRelationCWProxyImpl implements _$MergeRelationCWProxy {
  const _$MergeRelationCWProxyImpl(this._value);

  final MergeRelation _value;

  @override
  MergeRelation fromId(String fromId) => this(fromId: fromId);

  @override
  MergeRelation toId(String toId) => this(toId: toId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MergeRelation(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MergeRelation(...).copyWith(id: 12, name: "My name")
  /// ````
  MergeRelation call({
    Object? fromId = const $CopyWithPlaceholder(),
    Object? toId = const $CopyWithPlaceholder(),
  }) {
    return MergeRelation(
      fromId: fromId == const $CopyWithPlaceholder()
          ? _value.fromId
          // ignore: cast_nullable_to_non_nullable
          : fromId as String,
      toId: toId == const $CopyWithPlaceholder()
          ? _value.toId
          // ignore: cast_nullable_to_non_nullable
          : toId as String,
    );
  }
}

extension $MergeRelationCopyWith on MergeRelation {
  /// Returns a callable class that can be used as follows: `instanceOfMergeRelation.copyWith(...)` or like so:`instanceOfMergeRelation.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MergeRelationCWProxy get copyWith => _$MergeRelationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MergeRelation _$MergeRelationFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MergeRelation', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['from_id', 'to_id']);
      final val = MergeRelation(
        fromId: $checkedConvert('from_id', (v) => v as String),
        toId: $checkedConvert('to_id', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'fromId': 'from_id', 'toId': 'to_id'});

Map<String, dynamic> _$MergeRelationToJson(MergeRelation instance) =>
    <String, dynamic>{'from_id': instance.fromId, 'to_id': instance.toId};
