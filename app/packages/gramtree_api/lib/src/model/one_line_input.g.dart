// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'one_line_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OneLineInputCWProxy {
  OneLineInput text(String text);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `OneLineInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// OneLineInput(...).copyWith(id: 12, name: "My name")
  /// ````
  OneLineInput call({String text});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfOneLineInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfOneLineInput.copyWith.fieldName(...)`
class _$OneLineInputCWProxyImpl implements _$OneLineInputCWProxy {
  const _$OneLineInputCWProxyImpl(this._value);

  final OneLineInput _value;

  @override
  OneLineInput text(String text) => this(text: text);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `OneLineInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// OneLineInput(...).copyWith(id: 12, name: "My name")
  /// ````
  OneLineInput call({Object? text = const $CopyWithPlaceholder()}) {
    return OneLineInput(
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $OneLineInputCopyWith on OneLineInput {
  /// Returns a callable class that can be used as follows: `instanceOfOneLineInput.copyWith(...)` or like so:`instanceOfOneLineInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OneLineInputCWProxy get copyWith => _$OneLineInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OneLineInput _$OneLineInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OneLineInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['text']);
      final val = OneLineInput(
        text: $checkedConvert('text', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$OneLineInputToJson(OneLineInput instance) =>
    <String, dynamic>{'text': instance.text};
