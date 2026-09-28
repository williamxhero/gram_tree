// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_info.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CacheInfoCWProxy {
  CacheInfo dependsOn(Map<String, String>? dependsOn);

  CacheInfo ttlS(int ttlS);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CacheInfo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CacheInfo(...).copyWith(id: 12, name: "My name")
  /// ````
  CacheInfo call({Map<String, String>? dependsOn, int ttlS});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCacheInfo.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCacheInfo.copyWith.fieldName(...)`
class _$CacheInfoCWProxyImpl implements _$CacheInfoCWProxy {
  const _$CacheInfoCWProxyImpl(this._value);

  final CacheInfo _value;

  @override
  CacheInfo dependsOn(Map<String, String>? dependsOn) =>
      this(dependsOn: dependsOn);

  @override
  CacheInfo ttlS(int ttlS) => this(ttlS: ttlS);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CacheInfo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CacheInfo(...).copyWith(id: 12, name: "My name")
  /// ````
  CacheInfo call({
    Object? dependsOn = const $CopyWithPlaceholder(),
    Object? ttlS = const $CopyWithPlaceholder(),
  }) {
    return CacheInfo(
      dependsOn: dependsOn == const $CopyWithPlaceholder()
          ? _value.dependsOn
          // ignore: cast_nullable_to_non_nullable
          : dependsOn as Map<String, String>?,
      ttlS: ttlS == const $CopyWithPlaceholder()
          ? _value.ttlS
          // ignore: cast_nullable_to_non_nullable
          : ttlS as int,
    );
  }
}

extension $CacheInfoCopyWith on CacheInfo {
  /// Returns a callable class that can be used as follows: `instanceOfCacheInfo.copyWith(...)` or like so:`instanceOfCacheInfo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CacheInfoCWProxy get copyWith => _$CacheInfoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CacheInfo _$CacheInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CacheInfo', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['ttl_s']);
      final val = CacheInfo(
        dependsOn: $checkedConvert(
          'depends_on',
          (v) => (v as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ),
        ),
        ttlS: $checkedConvert('ttl_s', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'dependsOn': 'depends_on', 'ttlS': 'ttl_s'});

Map<String, dynamic> _$CacheInfoToJson(CacheInfo instance) => <String, dynamic>{
  'depends_on': ?instance.dependsOn,
  'ttl_s': instance.ttlS,
};
