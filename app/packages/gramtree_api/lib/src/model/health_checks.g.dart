// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_checks.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HealthChecksCWProxy {
  HealthChecks api(HealthChecksApiEnum api);

  HealthChecks database(HealthChecksDatabaseEnum database);

  HealthChecks redis(HealthChecksRedisEnum redis);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HealthChecks(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HealthChecks(...).copyWith(id: 12, name: "My name")
  /// ````
  HealthChecks call({
    HealthChecksApiEnum api,
    HealthChecksDatabaseEnum database,
    HealthChecksRedisEnum redis,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHealthChecks.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHealthChecks.copyWith.fieldName(...)`
class _$HealthChecksCWProxyImpl implements _$HealthChecksCWProxy {
  const _$HealthChecksCWProxyImpl(this._value);

  final HealthChecks _value;

  @override
  HealthChecks api(HealthChecksApiEnum api) => this(api: api);

  @override
  HealthChecks database(HealthChecksDatabaseEnum database) =>
      this(database: database);

  @override
  HealthChecks redis(HealthChecksRedisEnum redis) => this(redis: redis);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HealthChecks(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HealthChecks(...).copyWith(id: 12, name: "My name")
  /// ````
  HealthChecks call({
    Object? api = const $CopyWithPlaceholder(),
    Object? database = const $CopyWithPlaceholder(),
    Object? redis = const $CopyWithPlaceholder(),
  }) {
    return HealthChecks(
      api: api == const $CopyWithPlaceholder()
          ? _value.api
          // ignore: cast_nullable_to_non_nullable
          : api as HealthChecksApiEnum,
      database: database == const $CopyWithPlaceholder()
          ? _value.database
          // ignore: cast_nullable_to_non_nullable
          : database as HealthChecksDatabaseEnum,
      redis: redis == const $CopyWithPlaceholder()
          ? _value.redis
          // ignore: cast_nullable_to_non_nullable
          : redis as HealthChecksRedisEnum,
    );
  }
}

extension $HealthChecksCopyWith on HealthChecks {
  /// Returns a callable class that can be used as follows: `instanceOfHealthChecks.copyWith(...)` or like so:`instanceOfHealthChecks.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HealthChecksCWProxy get copyWith => _$HealthChecksCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthChecks _$HealthChecksFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HealthChecks', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['api', 'database', 'redis']);
      final val = HealthChecks(
        api: $checkedConvert(
          'api',
          (v) => $enumDecode(_$HealthChecksApiEnumEnumMap, v),
        ),
        database: $checkedConvert(
          'database',
          (v) => $enumDecode(_$HealthChecksDatabaseEnumEnumMap, v),
        ),
        redis: $checkedConvert(
          'redis',
          (v) => $enumDecode(_$HealthChecksRedisEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$HealthChecksToJson(HealthChecks instance) =>
    <String, dynamic>{
      'api': _$HealthChecksApiEnumEnumMap[instance.api]!,
      'database': _$HealthChecksDatabaseEnumEnumMap[instance.database]!,
      'redis': _$HealthChecksRedisEnumEnumMap[instance.redis]!,
    };

const _$HealthChecksApiEnumEnumMap = {
  HealthChecksApiEnum.ok: 'ok',
  HealthChecksApiEnum.fail: 'fail',
};

const _$HealthChecksDatabaseEnumEnumMap = {
  HealthChecksDatabaseEnum.ok: 'ok',
  HealthChecksDatabaseEnum.fail: 'fail',
};

const _$HealthChecksRedisEnumEnumMap = {
  HealthChecksRedisEnum.ok: 'ok',
  HealthChecksRedisEnum.fail: 'fail',
};
