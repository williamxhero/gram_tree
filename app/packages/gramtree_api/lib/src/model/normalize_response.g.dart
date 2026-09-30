// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'normalize_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NormalizeResponseCWProxy {
  NormalizeResponse results(List<NormalizeResultItem> results);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NormalizeResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NormalizeResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  NormalizeResponse call({List<NormalizeResultItem> results});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfNormalizeResponse.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfNormalizeResponse.copyWith.fieldName(...)`
class _$NormalizeResponseCWProxyImpl implements _$NormalizeResponseCWProxy {
  const _$NormalizeResponseCWProxyImpl(this._value);

  final NormalizeResponse _value;

  @override
  NormalizeResponse results(List<NormalizeResultItem> results) =>
      this(results: results);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NormalizeResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NormalizeResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  NormalizeResponse call({Object? results = const $CopyWithPlaceholder()}) {
    return NormalizeResponse(
      results: results == const $CopyWithPlaceholder()
          ? _value.results
          // ignore: cast_nullable_to_non_nullable
          : results as List<NormalizeResultItem>,
    );
  }
}

extension $NormalizeResponseCopyWith on NormalizeResponse {
  /// Returns a callable class that can be used as follows: `instanceOfNormalizeResponse.copyWith(...)` or like so:`instanceOfNormalizeResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NormalizeResponseCWProxy get copyWith =>
      _$NormalizeResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NormalizeResponse _$NormalizeResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NormalizeResponse', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['results']);
      final val = NormalizeResponse(
        results: $checkedConvert(
          'results',
          (v) => (v as List<dynamic>)
              .map(
                (e) => NormalizeResultItem.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$NormalizeResponseToJson(NormalizeResponse instance) =>
    <String, dynamic>{
      'results': instance.results.map((e) => e.toJson()).toList(),
    };
