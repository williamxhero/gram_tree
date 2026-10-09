//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'write_envelope.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WriteEnvelope {
  /// Returns a new [WriteEnvelope] instance.
  WriteEnvelope({
    this.dependencies,

    required this.deviceTime,

    required this.formatVersion,

    required this.ownerId,

    required this.payload,

    required this.writeId,

    required this.writeType,
  });

  @JsonKey(name: r'dependencies', required: false, includeIfNull: false)
  final List<String>? dependencies;

  @JsonKey(name: r'device_time', required: true, includeIfNull: false)
  final DateTime deviceTime;

  /// Immutable envelope format, independent of business version
  @JsonKey(name: r'format_version', required: true, includeIfNull: false)
  final int formatVersion;

  /// Bound at local creation; must equal the authenticated account
  @JsonKey(name: r'owner_id', required: true, includeIfNull: false)
  final String ownerId;

  @JsonKey(name: r'payload', required: true, includeIfNull: false)
  final Object payload;

  /// UUID v4 delivery ID, not the referenced business resource ID
  @JsonKey(name: r'write_id', required: true, includeIfNull: false)
  final String writeId;

  @JsonKey(name: r'write_type', required: true, includeIfNull: false)
  final String writeType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WriteEnvelope &&
          other.dependencies == dependencies &&
          other.deviceTime == deviceTime &&
          other.formatVersion == formatVersion &&
          other.ownerId == ownerId &&
          other.payload == payload &&
          other.writeId == writeId &&
          other.writeType == writeType;

  @override
  int get hashCode =>
      dependencies.hashCode +
      deviceTime.hashCode +
      formatVersion.hashCode +
      ownerId.hashCode +
      payload.hashCode +
      writeId.hashCode +
      writeType.hashCode;

  factory WriteEnvelope.fromJson(Map<String, dynamic> json) =>
      _$WriteEnvelopeFromJson(json);

  Map<String, dynamic> toJson() => _$WriteEnvelopeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
