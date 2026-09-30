// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HealthResponseCWProxy {
  HealthResponse checks(HealthChecks checks);

  HealthResponse status(HealthResponseStatusEnum status);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HealthResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HealthResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  HealthResponse call({HealthChecks checks, HealthResponseStatusEnum status});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHealthResponse.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHealthResponse.copyWith.fieldName(...)`
class _$HealthResponseCWProxyImpl implements _$HealthResponseCWProxy {
  const _$HealthResponseCWProxyImpl(this._value);

  final HealthResponse _value;

  @override
  HealthResponse checks(HealthChecks checks) => this(checks: checks);

  @override
  HealthResponse status(HealthResponseStatusEnum status) =>
      this(status: status);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HealthResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HealthResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  HealthResponse call({
    Object? checks = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return HealthResponse(
      checks: checks == const $CopyWithPlaceholder()
          ? _value.checks
          // ignore: cast_nullable_to_non_nullable
          : checks as HealthChecks,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as HealthResponseStatusEnum,
    );
  }
}

extension $HealthResponseCopyWith on HealthResponse {
  /// Returns a callable class that can be used as follows: `instanceOfHealthResponse.copyWith(...)` or like so:`instanceOfHealthResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HealthResponseCWProxy get copyWith => _$HealthResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthResponse _$HealthResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HealthResponse', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['checks', 'status']);
      final val = HealthResponse(
        checks: $checkedConvert(
          'checks',
          (v) => HealthChecks.fromJson(v as Map<String, dynamic>),
        ),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$HealthResponseStatusEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$HealthResponseToJson(HealthResponse instance) =>
    <String, dynamic>{
      'checks': instance.checks.toJson(),
      'status': _$HealthResponseStatusEnumEnumMap[instance.status]!,
    };

const _$HealthResponseStatusEnumEnumMap = {
  HealthResponseStatusEnum.ok: 'ok',
  HealthResponseStatusEnum.unhealthy: 'unhealthy',
};
