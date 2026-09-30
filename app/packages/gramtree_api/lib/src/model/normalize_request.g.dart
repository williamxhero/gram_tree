// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'normalize_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NormalizeRequestCWProxy {
  NormalizeRequest items(List<NormalizeItem> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NormalizeRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NormalizeRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  NormalizeRequest call({List<NormalizeItem> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfNormalizeRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfNormalizeRequest.copyWith.fieldName(...)`
class _$NormalizeRequestCWProxyImpl implements _$NormalizeRequestCWProxy {
  const _$NormalizeRequestCWProxyImpl(this._value);

  final NormalizeRequest _value;

  @override
  NormalizeRequest items(List<NormalizeItem> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NormalizeRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NormalizeRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  NormalizeRequest call({Object? items = const $CopyWithPlaceholder()}) {
    return NormalizeRequest(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<NormalizeItem>,
    );
  }
}

extension $NormalizeRequestCopyWith on NormalizeRequest {
  /// Returns a callable class that can be used as follows: `instanceOfNormalizeRequest.copyWith(...)` or like so:`instanceOfNormalizeRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NormalizeRequestCWProxy get copyWith => _$NormalizeRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NormalizeRequest _$NormalizeRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NormalizeRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = NormalizeRequest(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => NormalizeItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$NormalizeRequestToJson(NormalizeRequest instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
