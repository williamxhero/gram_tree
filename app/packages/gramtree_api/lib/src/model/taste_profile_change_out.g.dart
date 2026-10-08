// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'taste_profile_change_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TasteProfileChangeOutCWProxy {
  TasteProfileChangeOut createdAt(String createdAt);

  TasteProfileChangeOut field(String field);

  TasteProfileChangeOut id(String id);

  TasteProfileChangeOut newValue(Object newValue);

  TasteProfileChangeOut oldValue(Object oldValue);

  TasteProfileChangeOut reason(String reason);

  TasteProfileChangeOut source_(TasteProfileChangeOutSource_Enum source_);

  TasteProfileChangeOut status(TasteProfileChangeOutStatusEnum status);

  TasteProfileChangeOut version(int version);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TasteProfileChangeOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TasteProfileChangeOut(...).copyWith(id: 12, name: "My name")
  /// ````
  TasteProfileChangeOut call({
    String createdAt,
    String field,
    String id,
    Object newValue,
    Object oldValue,
    String reason,
    TasteProfileChangeOutSource_Enum source_,
    TasteProfileChangeOutStatusEnum status,
    int version,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTasteProfileChangeOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTasteProfileChangeOut.copyWith.fieldName(...)`
class _$TasteProfileChangeOutCWProxyImpl
    implements _$TasteProfileChangeOutCWProxy {
  const _$TasteProfileChangeOutCWProxyImpl(this._value);

  final TasteProfileChangeOut _value;

  @override
  TasteProfileChangeOut createdAt(String createdAt) =>
      this(createdAt: createdAt);

  @override
  TasteProfileChangeOut field(String field) => this(field: field);

  @override
  TasteProfileChangeOut id(String id) => this(id: id);

  @override
  TasteProfileChangeOut newValue(Object newValue) => this(newValue: newValue);

  @override
  TasteProfileChangeOut oldValue(Object oldValue) => this(oldValue: oldValue);

  @override
  TasteProfileChangeOut reason(String reason) => this(reason: reason);

  @override
  TasteProfileChangeOut source_(TasteProfileChangeOutSource_Enum source_) =>
      this(source_: source_);

  @override
  TasteProfileChangeOut status(TasteProfileChangeOutStatusEnum status) =>
      this(status: status);

  @override
  TasteProfileChangeOut version(int version) => this(version: version);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TasteProfileChangeOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TasteProfileChangeOut(...).copyWith(id: 12, name: "My name")
  /// ````
  TasteProfileChangeOut call({
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? field = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? newValue = const $CopyWithPlaceholder(),
    Object? oldValue = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
  }) {
    return TasteProfileChangeOut(
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as String,
      field: field == const $CopyWithPlaceholder()
          ? _value.field
          // ignore: cast_nullable_to_non_nullable
          : field as String,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      newValue: newValue == const $CopyWithPlaceholder()
          ? _value.newValue
          // ignore: cast_nullable_to_non_nullable
          : newValue as Object,
      oldValue: oldValue == const $CopyWithPlaceholder()
          ? _value.oldValue
          // ignore: cast_nullable_to_non_nullable
          : oldValue as Object,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as TasteProfileChangeOutSource_Enum,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as TasteProfileChangeOutStatusEnum,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
    );
  }
}

extension $TasteProfileChangeOutCopyWith on TasteProfileChangeOut {
  /// Returns a callable class that can be used as follows: `instanceOfTasteProfileChangeOut.copyWith(...)` or like so:`instanceOfTasteProfileChangeOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TasteProfileChangeOutCWProxy get copyWith =>
      _$TasteProfileChangeOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TasteProfileChangeOut _$TasteProfileChangeOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'TasteProfileChangeOut',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'created_at',
        'field',
        'id',
        'new_value',
        'old_value',
        'reason',
        'source',
        'status',
        'version',
      ],
    );
    final val = TasteProfileChangeOut(
      createdAt: $checkedConvert('created_at', (v) => v as String),
      field: $checkedConvert('field', (v) => v as String),
      id: $checkedConvert('id', (v) => v as String),
      newValue: $checkedConvert('new_value', (v) => v as Object),
      oldValue: $checkedConvert('old_value', (v) => v as Object),
      reason: $checkedConvert('reason', (v) => v as String),
      source_: $checkedConvert(
        'source',
        (v) => $enumDecode(_$TasteProfileChangeOutSource_EnumEnumMap, v),
      ),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$TasteProfileChangeOutStatusEnumEnumMap, v),
      ),
      version: $checkedConvert('version', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'createdAt': 'created_at',
    'newValue': 'new_value',
    'oldValue': 'old_value',
    'source_': 'source',
  },
);

Map<String, dynamic> _$TasteProfileChangeOutToJson(
  TasteProfileChangeOut instance,
) => <String, dynamic>{
  'created_at': instance.createdAt,
  'field': instance.field,
  'id': instance.id,
  'new_value': instance.newValue,
  'old_value': instance.oldValue,
  'reason': instance.reason,
  'source': _$TasteProfileChangeOutSource_EnumEnumMap[instance.source_]!,
  'status': _$TasteProfileChangeOutStatusEnumEnumMap[instance.status]!,
  'version': instance.version,
};

const _$TasteProfileChangeOutSource_EnumEnumMap = {
  TasteProfileChangeOutSource_Enum.manual: 'manual',
};

const _$TasteProfileChangeOutStatusEnumEnumMap = {
  TasteProfileChangeOutStatusEnum.active: 'active',
  TasteProfileChangeOutStatusEnum.reverted: 'reverted',
};
