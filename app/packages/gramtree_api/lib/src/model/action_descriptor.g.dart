// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_descriptor.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ActionDescriptorCWProxy {
  ActionDescriptor intent(String intent);

  ActionDescriptor params(Object? params);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ActionDescriptor(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ActionDescriptor(...).copyWith(id: 12, name: "My name")
  /// ````
  ActionDescriptor call({String intent, Object? params});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfActionDescriptor.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfActionDescriptor.copyWith.fieldName(...)`
class _$ActionDescriptorCWProxyImpl implements _$ActionDescriptorCWProxy {
  const _$ActionDescriptorCWProxyImpl(this._value);

  final ActionDescriptor _value;

  @override
  ActionDescriptor intent(String intent) => this(intent: intent);

  @override
  ActionDescriptor params(Object? params) => this(params: params);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ActionDescriptor(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ActionDescriptor(...).copyWith(id: 12, name: "My name")
  /// ````
  ActionDescriptor call({
    Object? intent = const $CopyWithPlaceholder(),
    Object? params = const $CopyWithPlaceholder(),
  }) {
    return ActionDescriptor(
      intent: intent == const $CopyWithPlaceholder()
          ? _value.intent
          // ignore: cast_nullable_to_non_nullable
          : intent as String,
      params: params == const $CopyWithPlaceholder()
          ? _value.params
          // ignore: cast_nullable_to_non_nullable
          : params as Object?,
    );
  }
}

extension $ActionDescriptorCopyWith on ActionDescriptor {
  /// Returns a callable class that can be used as follows: `instanceOfActionDescriptor.copyWith(...)` or like so:`instanceOfActionDescriptor.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ActionDescriptorCWProxy get copyWith => _$ActionDescriptorCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionDescriptor _$ActionDescriptorFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ActionDescriptor', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['intent']);
      final val = ActionDescriptor(
        intent: $checkedConvert('intent', (v) => v as String),
        params: $checkedConvert('params', (v) => v),
      );
      return val;
    });

Map<String, dynamic> _$ActionDescriptorToJson(ActionDescriptor instance) =>
    <String, dynamic>{'intent': instance.intent, 'params': ?instance.params};
