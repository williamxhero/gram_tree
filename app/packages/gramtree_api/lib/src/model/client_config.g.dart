// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ClientConfigCWProxy {
  ClientConfig features(Map<String, bool> features);

  ClientConfig params(Map<String, Object> params);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ClientConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ClientConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  ClientConfig call({Map<String, bool> features, Map<String, Object> params});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfClientConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfClientConfig.copyWith.fieldName(...)`
class _$ClientConfigCWProxyImpl implements _$ClientConfigCWProxy {
  const _$ClientConfigCWProxyImpl(this._value);

  final ClientConfig _value;

  @override
  ClientConfig features(Map<String, bool> features) => this(features: features);

  @override
  ClientConfig params(Map<String, Object> params) => this(params: params);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ClientConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ClientConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  ClientConfig call({
    Object? features = const $CopyWithPlaceholder(),
    Object? params = const $CopyWithPlaceholder(),
  }) {
    return ClientConfig(
      features: features == const $CopyWithPlaceholder()
          ? _value.features
          // ignore: cast_nullable_to_non_nullable
          : features as Map<String, bool>,
      params: params == const $CopyWithPlaceholder()
          ? _value.params
          // ignore: cast_nullable_to_non_nullable
          : params as Map<String, Object>,
    );
  }
}

extension $ClientConfigCopyWith on ClientConfig {
  /// Returns a callable class that can be used as follows: `instanceOfClientConfig.copyWith(...)` or like so:`instanceOfClientConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ClientConfigCWProxy get copyWith => _$ClientConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientConfig _$ClientConfigFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ClientConfig', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['features', 'params']);
      final val = ClientConfig(
        features: $checkedConvert(
          'features',
          (v) => Map<String, bool>.from(v as Map),
        ),
        params: $checkedConvert(
          'params',
          (v) => (v as Map<String, dynamic>).map(
            (k, e) => MapEntry(k, e as Object),
          ),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ClientConfigToJson(ClientConfig instance) =>
    <String, dynamic>{'features': instance.features, 'params': instance.params};
