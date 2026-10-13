// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quantification_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$QuantificationInputCWProxy {
  QuantificationInput baseVersionId(String baseVersionId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `QuantificationInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// QuantificationInput(...).copyWith(id: 12, name: "My name")
  /// ````
  QuantificationInput call({String baseVersionId});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfQuantificationInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfQuantificationInput.copyWith.fieldName(...)`
class _$QuantificationInputCWProxyImpl implements _$QuantificationInputCWProxy {
  const _$QuantificationInputCWProxyImpl(this._value);

  final QuantificationInput _value;

  @override
  QuantificationInput baseVersionId(String baseVersionId) =>
      this(baseVersionId: baseVersionId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `QuantificationInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// QuantificationInput(...).copyWith(id: 12, name: "My name")
  /// ````
  QuantificationInput call({
    Object? baseVersionId = const $CopyWithPlaceholder(),
  }) {
    return QuantificationInput(
      baseVersionId: baseVersionId == const $CopyWithPlaceholder()
          ? _value.baseVersionId
          // ignore: cast_nullable_to_non_nullable
          : baseVersionId as String,
    );
  }
}

extension $QuantificationInputCopyWith on QuantificationInput {
  /// Returns a callable class that can be used as follows: `instanceOfQuantificationInput.copyWith(...)` or like so:`instanceOfQuantificationInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$QuantificationInputCWProxy get copyWith =>
      _$QuantificationInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuantificationInput _$QuantificationInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('QuantificationInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['base_version_id']);
      final val = QuantificationInput(
        baseVersionId: $checkedConvert('base_version_id', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'baseVersionId': 'base_version_id'});

Map<String, dynamic> _$QuantificationInputToJson(
  QuantificationInput instance,
) => <String, dynamic>{'base_version_id': instance.baseVersionId};
