// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attribution_state_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AttributionStateOutCWProxy {
  AttributionStateOut attribution(AttributionOut attribution);

  AttributionStateOut reasonText(String reasonText);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttributionStateOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttributionStateOut(...).copyWith(id: 12, name: "My name")
  /// ````
  AttributionStateOut call({AttributionOut attribution, String reasonText});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAttributionStateOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAttributionStateOut.copyWith.fieldName(...)`
class _$AttributionStateOutCWProxyImpl implements _$AttributionStateOutCWProxy {
  const _$AttributionStateOutCWProxyImpl(this._value);

  final AttributionStateOut _value;

  @override
  AttributionStateOut attribution(AttributionOut attribution) =>
      this(attribution: attribution);

  @override
  AttributionStateOut reasonText(String reasonText) =>
      this(reasonText: reasonText);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttributionStateOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttributionStateOut(...).copyWith(id: 12, name: "My name")
  /// ````
  AttributionStateOut call({
    Object? attribution = const $CopyWithPlaceholder(),
    Object? reasonText = const $CopyWithPlaceholder(),
  }) {
    return AttributionStateOut(
      attribution: attribution == const $CopyWithPlaceholder()
          ? _value.attribution
          // ignore: cast_nullable_to_non_nullable
          : attribution as AttributionOut,
      reasonText: reasonText == const $CopyWithPlaceholder()
          ? _value.reasonText
          // ignore: cast_nullable_to_non_nullable
          : reasonText as String,
    );
  }
}

extension $AttributionStateOutCopyWith on AttributionStateOut {
  /// Returns a callable class that can be used as follows: `instanceOfAttributionStateOut.copyWith(...)` or like so:`instanceOfAttributionStateOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AttributionStateOutCWProxy get copyWith =>
      _$AttributionStateOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttributionStateOut _$AttributionStateOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AttributionStateOut', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['attribution', 'reason_text']);
      final val = AttributionStateOut(
        attribution: $checkedConvert(
          'attribution',
          (v) => AttributionOut.fromJson(v as Map<String, dynamic>),
        ),
        reasonText: $checkedConvert('reason_text', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'reasonText': 'reason_text'});

Map<String, dynamic> _$AttributionStateOutToJson(
  AttributionStateOut instance,
) => <String, dynamic>{
  'attribution': instance.attribution.toJson(),
  'reason_text': instance.reasonText,
};
