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

  TasteProfileChangeOut origin(TasteProfileChangeOutOriginEnum origin);

  TasteProfileChangeOut reason(String reason);

  TasteProfileChangeOut revertedAt(String? revertedAt);

  TasteProfileChangeOut source_(String source_);

  TasteProfileChangeOut sourceRecordIds(List<String>? sourceRecordIds);

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
    TasteProfileChangeOutOriginEnum origin,
    String reason,
    String? revertedAt,
    String source_,
    List<String>? sourceRecordIds,
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
  TasteProfileChangeOut origin(TasteProfileChangeOutOriginEnum origin) =>
      this(origin: origin);

  @override
  TasteProfileChangeOut reason(String reason) => this(reason: reason);

  @override
  TasteProfileChangeOut revertedAt(String? revertedAt) =>
      this(revertedAt: revertedAt);

  @override
  TasteProfileChangeOut source_(String source_) => this(source_: source_);

  @override
  TasteProfileChangeOut sourceRecordIds(List<String>? sourceRecordIds) =>
      this(sourceRecordIds: sourceRecordIds);

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
    Object? origin = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? revertedAt = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? sourceRecordIds = const $CopyWithPlaceholder(),
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
      origin: origin == const $CopyWithPlaceholder()
          ? _value.origin
          // ignore: cast_nullable_to_non_nullable
          : origin as TasteProfileChangeOutOriginEnum,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
      revertedAt: revertedAt == const $CopyWithPlaceholder()
          ? _value.revertedAt
          // ignore: cast_nullable_to_non_nullable
          : revertedAt as String?,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as String,
      sourceRecordIds: sourceRecordIds == const $CopyWithPlaceholder()
          ? _value.sourceRecordIds
          // ignore: cast_nullable_to_non_nullable
          : sourceRecordIds as List<String>?,
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
        'origin',
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
      origin: $checkedConvert(
        'origin',
        (v) => $enumDecode(_$TasteProfileChangeOutOriginEnumEnumMap, v),
      ),
      reason: $checkedConvert('reason', (v) => v as String),
      revertedAt: $checkedConvert('reverted_at', (v) => v as String?),
      source_: $checkedConvert('source', (v) => v as String),
      sourceRecordIds: $checkedConvert(
        'source_record_ids',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
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
    'revertedAt': 'reverted_at',
    'source_': 'source',
    'sourceRecordIds': 'source_record_ids',
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
  'origin': _$TasteProfileChangeOutOriginEnumEnumMap[instance.origin]!,
  'reason': instance.reason,
  'reverted_at': ?instance.revertedAt,
  'source': instance.source_,
  'source_record_ids': ?instance.sourceRecordIds,
  'status': _$TasteProfileChangeOutStatusEnumEnumMap[instance.status]!,
  'version': instance.version,
};

const _$TasteProfileChangeOutOriginEnumEnumMap = {
  TasteProfileChangeOutOriginEnum.manual: 'manual',
  TasteProfileChangeOutOriginEnum.auto: 'auto',
  TasteProfileChangeOutOriginEnum.explicitSave: 'explicit_save',
};

const _$TasteProfileChangeOutStatusEnumEnumMap = {
  TasteProfileChangeOutStatusEnum.active: 'active',
  TasteProfileChangeOutStatusEnum.reverted: 'reverted',
  TasteProfileChangeOutStatusEnum.pending: 'pending',
  TasteProfileChangeOutStatusEnum.confirmed: 'confirmed',
};
