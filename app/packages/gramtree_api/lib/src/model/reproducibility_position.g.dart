// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reproducibility_position.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReproducibilityPositionCWProxy {
  ReproducibilityPosition collection(
    ReproducibilityPositionCollectionEnum collection,
  );

  ReproducibilityPosition end(int? end);

  ReproducibilityPosition field(String field);

  ReproducibilityPosition itemId(String? itemId);

  ReproducibilityPosition start(int? start);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReproducibilityPosition(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReproducibilityPosition(...).copyWith(id: 12, name: "My name")
  /// ````
  ReproducibilityPosition call({
    ReproducibilityPositionCollectionEnum collection,
    int? end,
    String field,
    String? itemId,
    int? start,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfReproducibilityPosition.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfReproducibilityPosition.copyWith.fieldName(...)`
class _$ReproducibilityPositionCWProxyImpl
    implements _$ReproducibilityPositionCWProxy {
  const _$ReproducibilityPositionCWProxyImpl(this._value);

  final ReproducibilityPosition _value;

  @override
  ReproducibilityPosition collection(
    ReproducibilityPositionCollectionEnum collection,
  ) => this(collection: collection);

  @override
  ReproducibilityPosition end(int? end) => this(end: end);

  @override
  ReproducibilityPosition field(String field) => this(field: field);

  @override
  ReproducibilityPosition itemId(String? itemId) => this(itemId: itemId);

  @override
  ReproducibilityPosition start(int? start) => this(start: start);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReproducibilityPosition(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReproducibilityPosition(...).copyWith(id: 12, name: "My name")
  /// ````
  ReproducibilityPosition call({
    Object? collection = const $CopyWithPlaceholder(),
    Object? end = const $CopyWithPlaceholder(),
    Object? field = const $CopyWithPlaceholder(),
    Object? itemId = const $CopyWithPlaceholder(),
    Object? start = const $CopyWithPlaceholder(),
  }) {
    return ReproducibilityPosition(
      collection: collection == const $CopyWithPlaceholder()
          ? _value.collection
          // ignore: cast_nullable_to_non_nullable
          : collection as ReproducibilityPositionCollectionEnum,
      end: end == const $CopyWithPlaceholder()
          ? _value.end
          // ignore: cast_nullable_to_non_nullable
          : end as int?,
      field: field == const $CopyWithPlaceholder()
          ? _value.field
          // ignore: cast_nullable_to_non_nullable
          : field as String,
      itemId: itemId == const $CopyWithPlaceholder()
          ? _value.itemId
          // ignore: cast_nullable_to_non_nullable
          : itemId as String?,
      start: start == const $CopyWithPlaceholder()
          ? _value.start
          // ignore: cast_nullable_to_non_nullable
          : start as int?,
    );
  }
}

extension $ReproducibilityPositionCopyWith on ReproducibilityPosition {
  /// Returns a callable class that can be used as follows: `instanceOfReproducibilityPosition.copyWith(...)` or like so:`instanceOfReproducibilityPosition.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReproducibilityPositionCWProxy get copyWith =>
      _$ReproducibilityPositionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReproducibilityPosition _$ReproducibilityPositionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ReproducibilityPosition', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['collection', 'field']);
  final val = ReproducibilityPosition(
    collection: $checkedConvert(
      'collection',
      (v) => $enumDecode(_$ReproducibilityPositionCollectionEnumEnumMap, v),
    ),
    end: $checkedConvert('end', (v) => (v as num?)?.toInt()),
    field: $checkedConvert('field', (v) => v as String),
    itemId: $checkedConvert('item_id', (v) => v as String?),
    start: $checkedConvert('start', (v) => (v as num?)?.toInt()),
  );
  return val;
}, fieldKeyMap: const {'itemId': 'item_id'});

Map<String, dynamic> _$ReproducibilityPositionToJson(
  ReproducibilityPosition instance,
) => <String, dynamic>{
  'collection':
      _$ReproducibilityPositionCollectionEnumEnumMap[instance.collection]!,
  'end': ?instance.end,
  'field': instance.field,
  'item_id': ?instance.itemId,
  'start': ?instance.start,
};

const _$ReproducibilityPositionCollectionEnumEnumMap = {
  ReproducibilityPositionCollectionEnum.ingredients: 'ingredients',
  ReproducibilityPositionCollectionEnum.steps: 'steps',
  ReproducibilityPositionCollectionEnum.snapshot: 'snapshot',
};
