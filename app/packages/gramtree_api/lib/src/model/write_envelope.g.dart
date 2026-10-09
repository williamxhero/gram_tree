// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'write_envelope.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WriteEnvelopeCWProxy {
  WriteEnvelope dependencies(List<String>? dependencies);

  WriteEnvelope deviceTime(DateTime deviceTime);

  WriteEnvelope formatVersion(int formatVersion);

  WriteEnvelope ownerId(String ownerId);

  WriteEnvelope payload(Object payload);

  WriteEnvelope writeId(String writeId);

  WriteEnvelope writeType(String writeType);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `WriteEnvelope(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// WriteEnvelope(...).copyWith(id: 12, name: "My name")
  /// ````
  WriteEnvelope call({
    List<String>? dependencies,
    DateTime deviceTime,
    int formatVersion,
    String ownerId,
    Object payload,
    String writeId,
    String writeType,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfWriteEnvelope.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfWriteEnvelope.copyWith.fieldName(...)`
class _$WriteEnvelopeCWProxyImpl implements _$WriteEnvelopeCWProxy {
  const _$WriteEnvelopeCWProxyImpl(this._value);

  final WriteEnvelope _value;

  @override
  WriteEnvelope dependencies(List<String>? dependencies) =>
      this(dependencies: dependencies);

  @override
  WriteEnvelope deviceTime(DateTime deviceTime) => this(deviceTime: deviceTime);

  @override
  WriteEnvelope formatVersion(int formatVersion) =>
      this(formatVersion: formatVersion);

  @override
  WriteEnvelope ownerId(String ownerId) => this(ownerId: ownerId);

  @override
  WriteEnvelope payload(Object payload) => this(payload: payload);

  @override
  WriteEnvelope writeId(String writeId) => this(writeId: writeId);

  @override
  WriteEnvelope writeType(String writeType) => this(writeType: writeType);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `WriteEnvelope(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// WriteEnvelope(...).copyWith(id: 12, name: "My name")
  /// ````
  WriteEnvelope call({
    Object? dependencies = const $CopyWithPlaceholder(),
    Object? deviceTime = const $CopyWithPlaceholder(),
    Object? formatVersion = const $CopyWithPlaceholder(),
    Object? ownerId = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
    Object? writeId = const $CopyWithPlaceholder(),
    Object? writeType = const $CopyWithPlaceholder(),
  }) {
    return WriteEnvelope(
      dependencies: dependencies == const $CopyWithPlaceholder()
          ? _value.dependencies
          // ignore: cast_nullable_to_non_nullable
          : dependencies as List<String>?,
      deviceTime: deviceTime == const $CopyWithPlaceholder()
          ? _value.deviceTime
          // ignore: cast_nullable_to_non_nullable
          : deviceTime as DateTime,
      formatVersion: formatVersion == const $CopyWithPlaceholder()
          ? _value.formatVersion
          // ignore: cast_nullable_to_non_nullable
          : formatVersion as int,
      ownerId: ownerId == const $CopyWithPlaceholder()
          ? _value.ownerId
          // ignore: cast_nullable_to_non_nullable
          : ownerId as String,
      payload: payload == const $CopyWithPlaceholder()
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as Object,
      writeId: writeId == const $CopyWithPlaceholder()
          ? _value.writeId
          // ignore: cast_nullable_to_non_nullable
          : writeId as String,
      writeType: writeType == const $CopyWithPlaceholder()
          ? _value.writeType
          // ignore: cast_nullable_to_non_nullable
          : writeType as String,
    );
  }
}

extension $WriteEnvelopeCopyWith on WriteEnvelope {
  /// Returns a callable class that can be used as follows: `instanceOfWriteEnvelope.copyWith(...)` or like so:`instanceOfWriteEnvelope.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WriteEnvelopeCWProxy get copyWith => _$WriteEnvelopeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WriteEnvelope _$WriteEnvelopeFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'WriteEnvelope',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'device_time',
            'format_version',
            'owner_id',
            'payload',
            'write_id',
            'write_type',
          ],
        );
        final val = WriteEnvelope(
          dependencies: $checkedConvert(
            'dependencies',
            (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
          ),
          deviceTime: $checkedConvert(
            'device_time',
            (v) => DateTime.parse(v as String),
          ),
          formatVersion: $checkedConvert(
            'format_version',
            (v) => (v as num).toInt(),
          ),
          ownerId: $checkedConvert('owner_id', (v) => v as String),
          payload: $checkedConvert('payload', (v) => v as Object),
          writeId: $checkedConvert('write_id', (v) => v as String),
          writeType: $checkedConvert('write_type', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'deviceTime': 'device_time',
        'formatVersion': 'format_version',
        'ownerId': 'owner_id',
        'writeId': 'write_id',
        'writeType': 'write_type',
      },
    );

Map<String, dynamic> _$WriteEnvelopeToJson(WriteEnvelope instance) =>
    <String, dynamic>{
      'dependencies': ?instance.dependencies,
      'device_time': instance.deviceTime.toIso8601String(),
      'format_version': instance.formatVersion,
      'owner_id': instance.ownerId,
      'payload': instance.payload,
      'write_id': instance.writeId,
      'write_type': instance.writeType,
    };
