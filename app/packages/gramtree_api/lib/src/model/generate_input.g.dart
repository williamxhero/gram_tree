// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generate_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GenerateInputCWProxy {
  GenerateInput cookware(String? cookware);

  GenerateInput servings(int? servings);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GenerateInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GenerateInput(...).copyWith(id: 12, name: "My name")
  /// ````
  GenerateInput call({String? cookware, int? servings});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGenerateInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGenerateInput.copyWith.fieldName(...)`
class _$GenerateInputCWProxyImpl implements _$GenerateInputCWProxy {
  const _$GenerateInputCWProxyImpl(this._value);

  final GenerateInput _value;

  @override
  GenerateInput cookware(String? cookware) => this(cookware: cookware);

  @override
  GenerateInput servings(int? servings) => this(servings: servings);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GenerateInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GenerateInput(...).copyWith(id: 12, name: "My name")
  /// ````
  GenerateInput call({
    Object? cookware = const $CopyWithPlaceholder(),
    Object? servings = const $CopyWithPlaceholder(),
  }) {
    return GenerateInput(
      cookware: cookware == const $CopyWithPlaceholder()
          ? _value.cookware
          // ignore: cast_nullable_to_non_nullable
          : cookware as String?,
      servings: servings == const $CopyWithPlaceholder()
          ? _value.servings
          // ignore: cast_nullable_to_non_nullable
          : servings as int?,
    );
  }
}

extension $GenerateInputCopyWith on GenerateInput {
  /// Returns a callable class that can be used as follows: `instanceOfGenerateInput.copyWith(...)` or like so:`instanceOfGenerateInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GenerateInputCWProxy get copyWith => _$GenerateInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenerateInput _$GenerateInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GenerateInput', json, ($checkedConvert) {
      final val = GenerateInput(
        cookware: $checkedConvert('cookware', (v) => v as String?),
        servings: $checkedConvert('servings', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$GenerateInputToJson(GenerateInput instance) =>
    <String, dynamic>{
      'cookware': ?instance.cookware,
      'servings': ?instance.servings,
    };
