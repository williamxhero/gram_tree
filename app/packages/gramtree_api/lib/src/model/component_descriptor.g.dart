// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'component_descriptor.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComponentDescriptorCWProxy {
  ComponentDescriptor actions(List<ActionDescriptor>? actions);

  ComponentDescriptor data(Object data);

  ComponentDescriptor detail(ComponentDescriptorDetailEnum detail);

  ComponentDescriptor id(String id);

  ComponentDescriptor reason(ComponentReason reason);

  ComponentDescriptor required_(bool? required_);

  ComponentDescriptor type(String type);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComponentDescriptor(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComponentDescriptor(...).copyWith(id: 12, name: "My name")
  /// ````
  ComponentDescriptor call({
    List<ActionDescriptor>? actions,
    Object data,
    ComponentDescriptorDetailEnum detail,
    String id,
    ComponentReason reason,
    bool? required_,
    String type,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfComponentDescriptor.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfComponentDescriptor.copyWith.fieldName(...)`
class _$ComponentDescriptorCWProxyImpl implements _$ComponentDescriptorCWProxy {
  const _$ComponentDescriptorCWProxyImpl(this._value);

  final ComponentDescriptor _value;

  @override
  ComponentDescriptor actions(List<ActionDescriptor>? actions) =>
      this(actions: actions);

  @override
  ComponentDescriptor data(Object data) => this(data: data);

  @override
  ComponentDescriptor detail(ComponentDescriptorDetailEnum detail) =>
      this(detail: detail);

  @override
  ComponentDescriptor id(String id) => this(id: id);

  @override
  ComponentDescriptor reason(ComponentReason reason) => this(reason: reason);

  @override
  ComponentDescriptor required_(bool? required_) => this(required_: required_);

  @override
  ComponentDescriptor type(String type) => this(type: type);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComponentDescriptor(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComponentDescriptor(...).copyWith(id: 12, name: "My name")
  /// ````
  ComponentDescriptor call({
    Object? actions = const $CopyWithPlaceholder(),
    Object? data = const $CopyWithPlaceholder(),
    Object? detail = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? required_ = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
  }) {
    return ComponentDescriptor(
      actions: actions == const $CopyWithPlaceholder()
          ? _value.actions
          // ignore: cast_nullable_to_non_nullable
          : actions as List<ActionDescriptor>?,
      data: data == const $CopyWithPlaceholder()
          ? _value.data
          // ignore: cast_nullable_to_non_nullable
          : data as Object,
      detail: detail == const $CopyWithPlaceholder()
          ? _value.detail
          // ignore: cast_nullable_to_non_nullable
          : detail as ComponentDescriptorDetailEnum,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as ComponentReason,
      required_: required_ == const $CopyWithPlaceholder()
          ? _value.required_
          // ignore: cast_nullable_to_non_nullable
          : required_ as bool?,
      type: type == const $CopyWithPlaceholder()
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as String,
    );
  }
}

extension $ComponentDescriptorCopyWith on ComponentDescriptor {
  /// Returns a callable class that can be used as follows: `instanceOfComponentDescriptor.copyWith(...)` or like so:`instanceOfComponentDescriptor.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComponentDescriptorCWProxy get copyWith =>
      _$ComponentDescriptorCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComponentDescriptor _$ComponentDescriptorFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ComponentDescriptor', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['data', 'detail', 'id', 'reason', 'type'],
      );
      final val = ComponentDescriptor(
        actions: $checkedConvert(
          'actions',
          (v) => (v as List<dynamic>?)
              ?.map((e) => ActionDescriptor.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        data: $checkedConvert('data', (v) => v as Object),
        detail: $checkedConvert(
          'detail',
          (v) => $enumDecode(_$ComponentDescriptorDetailEnumEnumMap, v),
        ),
        id: $checkedConvert('id', (v) => v as String),
        reason: $checkedConvert(
          'reason',
          (v) => ComponentReason.fromJson(v as Map<String, dynamic>),
        ),
        required_: $checkedConvert('required', (v) => v as bool? ?? false),
        type: $checkedConvert('type', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'required_': 'required'});

Map<String, dynamic> _$ComponentDescriptorToJson(
  ComponentDescriptor instance,
) => <String, dynamic>{
  'actions': ?instance.actions?.map((e) => e.toJson()).toList(),
  'data': instance.data,
  'detail': _$ComponentDescriptorDetailEnumEnumMap[instance.detail]!,
  'id': instance.id,
  'reason': instance.reason.toJson(),
  'required': ?instance.required_,
  'type': instance.type,
};

const _$ComponentDescriptorDetailEnumEnumMap = {
  ComponentDescriptorDetailEnum.brief: 'brief',
  ComponentDescriptorDetailEnum.standard: 'standard',
  ComponentDescriptorDetailEnum.detailed: 'detailed',
};
