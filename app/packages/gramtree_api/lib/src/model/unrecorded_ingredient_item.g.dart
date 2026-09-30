// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unrecorded_ingredient_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UnrecordedIngredientItemCWProxy {
  UnrecordedIngredientItem firstSeenAt(String firstSeenAt);

  UnrecordedIngredientItem lastSeenAt(String lastSeenAt);

  UnrecordedIngredientItem name(String name);

  UnrecordedIngredientItem occurrenceCount(int occurrenceCount);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UnrecordedIngredientItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UnrecordedIngredientItem(...).copyWith(id: 12, name: "My name")
  /// ````
  UnrecordedIngredientItem call({
    String firstSeenAt,
    String lastSeenAt,
    String name,
    int occurrenceCount,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfUnrecordedIngredientItem.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfUnrecordedIngredientItem.copyWith.fieldName(...)`
class _$UnrecordedIngredientItemCWProxyImpl
    implements _$UnrecordedIngredientItemCWProxy {
  const _$UnrecordedIngredientItemCWProxyImpl(this._value);

  final UnrecordedIngredientItem _value;

  @override
  UnrecordedIngredientItem firstSeenAt(String firstSeenAt) =>
      this(firstSeenAt: firstSeenAt);

  @override
  UnrecordedIngredientItem lastSeenAt(String lastSeenAt) =>
      this(lastSeenAt: lastSeenAt);

  @override
  UnrecordedIngredientItem name(String name) => this(name: name);

  @override
  UnrecordedIngredientItem occurrenceCount(int occurrenceCount) =>
      this(occurrenceCount: occurrenceCount);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UnrecordedIngredientItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UnrecordedIngredientItem(...).copyWith(id: 12, name: "My name")
  /// ````
  UnrecordedIngredientItem call({
    Object? firstSeenAt = const $CopyWithPlaceholder(),
    Object? lastSeenAt = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? occurrenceCount = const $CopyWithPlaceholder(),
  }) {
    return UnrecordedIngredientItem(
      firstSeenAt: firstSeenAt == const $CopyWithPlaceholder()
          ? _value.firstSeenAt
          // ignore: cast_nullable_to_non_nullable
          : firstSeenAt as String,
      lastSeenAt: lastSeenAt == const $CopyWithPlaceholder()
          ? _value.lastSeenAt
          // ignore: cast_nullable_to_non_nullable
          : lastSeenAt as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      occurrenceCount: occurrenceCount == const $CopyWithPlaceholder()
          ? _value.occurrenceCount
          // ignore: cast_nullable_to_non_nullable
          : occurrenceCount as int,
    );
  }
}

extension $UnrecordedIngredientItemCopyWith on UnrecordedIngredientItem {
  /// Returns a callable class that can be used as follows: `instanceOfUnrecordedIngredientItem.copyWith(...)` or like so:`instanceOfUnrecordedIngredientItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UnrecordedIngredientItemCWProxy get copyWith =>
      _$UnrecordedIngredientItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnrecordedIngredientItem _$UnrecordedIngredientItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'UnrecordedIngredientItem',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'first_seen_at',
        'last_seen_at',
        'name',
        'occurrence_count',
      ],
    );
    final val = UnrecordedIngredientItem(
      firstSeenAt: $checkedConvert('first_seen_at', (v) => v as String),
      lastSeenAt: $checkedConvert('last_seen_at', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      occurrenceCount: $checkedConvert(
        'occurrence_count',
        (v) => (v as num).toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'firstSeenAt': 'first_seen_at',
    'lastSeenAt': 'last_seen_at',
    'occurrenceCount': 'occurrence_count',
  },
);

Map<String, dynamic> _$UnrecordedIngredientItemToJson(
  UnrecordedIngredientItem instance,
) => <String, dynamic>{
  'first_seen_at': instance.firstSeenAt,
  'last_seen_at': instance.lastSeenAt,
  'name': instance.name,
  'occurrence_count': instance.occurrenceCount,
};
