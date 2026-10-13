//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'health_checks.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HealthChecks {
  /// Returns a new [HealthChecks] instance.
  HealthChecks({
    required this.api,

    required this.database,

    required this.redis,
  });

  @JsonKey(name: r'api', required: true, includeIfNull: false)
  final HealthChecksApiEnum api;

  @JsonKey(name: r'database', required: true, includeIfNull: false)
  final HealthChecksDatabaseEnum database;

  @JsonKey(name: r'redis', required: true, includeIfNull: false)
  final HealthChecksRedisEnum redis;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthChecks &&
          other.api == api &&
          other.database == database &&
          other.redis == redis;

  @override
  int get hashCode => api.hashCode + database.hashCode + redis.hashCode;

  factory HealthChecks.fromJson(Map<String, dynamic> json) =>
      _$HealthChecksFromJson(json);

  Map<String, dynamic> toJson() => _$HealthChecksToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum HealthChecksApiEnum {
  @JsonValue(r'ok')
  ok(r'ok'),
  @JsonValue(r'fail')
  fail(r'fail');

  const HealthChecksApiEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum HealthChecksDatabaseEnum {
  @JsonValue(r'ok')
  ok(r'ok'),
  @JsonValue(r'fail')
  fail(r'fail');

  const HealthChecksDatabaseEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum HealthChecksRedisEnum {
  @JsonValue(r'ok')
  ok(r'ok'),
  @JsonValue(r'fail')
  fail(r'fail');

  const HealthChecksRedisEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
