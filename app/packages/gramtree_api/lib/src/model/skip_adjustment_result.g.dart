// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skip_adjustment_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SkipAdjustmentResultCWProxy {
  SkipAdjustmentResult componentId(String componentId);

  SkipAdjustmentResult source_(SourcedValue source_);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SkipAdjustmentResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SkipAdjustmentResult(...).copyWith(id: 12, name: "My name")
  /// ````
  SkipAdjustmentResult call({String componentId, SourcedValue source_});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSkipAdjustmentResult.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSkipAdjustmentResult.copyWith.fieldName(...)`
class _$SkipAdjustmentResultCWProxyImpl
    implements _$SkipAdjustmentResultCWProxy {
  const _$SkipAdjustmentResultCWProxyImpl(this._value);

  final SkipAdjustmentResult _value;

  @override
  SkipAdjustmentResult componentId(String componentId) =>
      this(componentId: componentId);

  @override
  SkipAdjustmentResult source_(SourcedValue source_) => this(source_: source_);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SkipAdjustmentResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SkipAdjustmentResult(...).copyWith(id: 12, name: "My name")
  /// ````
  SkipAdjustmentResult call({
    Object? componentId = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
  }) {
    return SkipAdjustmentResult(
      componentId: componentId == const $CopyWithPlaceholder()
          ? _value.componentId
          // ignore: cast_nullable_to_non_nullable
          : componentId as String,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as SourcedValue,
    );
  }
}

extension $SkipAdjustmentResultCopyWith on SkipAdjustmentResult {
  /// Returns a callable class that can be used as follows: `instanceOfSkipAdjustmentResult.copyWith(...)` or like so:`instanceOfSkipAdjustmentResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SkipAdjustmentResultCWProxy get copyWith =>
      _$SkipAdjustmentResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkipAdjustmentResult _$SkipAdjustmentResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SkipAdjustmentResult', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['component_id', 'source']);
  final val = SkipAdjustmentResult(
    componentId: $checkedConvert('component_id', (v) => v as String),
    source_: $checkedConvert(
      'source',
      (v) => SourcedValue.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
}, fieldKeyMap: const {'componentId': 'component_id', 'source_': 'source'});

Map<String, dynamic> _$SkipAdjustmentResultToJson(
  SkipAdjustmentResult instance,
) => <String, dynamic>{
  'component_id': instance.componentId,
  'source': instance.source_.toJson(),
};
