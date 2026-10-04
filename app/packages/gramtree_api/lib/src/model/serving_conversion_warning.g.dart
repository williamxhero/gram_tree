// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serving_conversion_warning.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ServingConversionWarningCWProxy {
  ServingConversionWarning code(ServingConversionWarningCodeEnum code);

  ServingConversionWarning ingredientId(String? ingredientId);

  ServingConversionWarning message(String message);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ServingConversionWarning(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ServingConversionWarning(...).copyWith(id: 12, name: "My name")
  /// ````
  ServingConversionWarning call({
    ServingConversionWarningCodeEnum code,
    String? ingredientId,
    String message,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfServingConversionWarning.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfServingConversionWarning.copyWith.fieldName(...)`
class _$ServingConversionWarningCWProxyImpl
    implements _$ServingConversionWarningCWProxy {
  const _$ServingConversionWarningCWProxyImpl(this._value);

  final ServingConversionWarning _value;

  @override
  ServingConversionWarning code(ServingConversionWarningCodeEnum code) =>
      this(code: code);

  @override
  ServingConversionWarning ingredientId(String? ingredientId) =>
      this(ingredientId: ingredientId);

  @override
  ServingConversionWarning message(String message) => this(message: message);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ServingConversionWarning(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ServingConversionWarning(...).copyWith(id: 12, name: "My name")
  /// ````
  ServingConversionWarning call({
    Object? code = const $CopyWithPlaceholder(),
    Object? ingredientId = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
  }) {
    return ServingConversionWarning(
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as ServingConversionWarningCodeEnum,
      ingredientId: ingredientId == const $CopyWithPlaceholder()
          ? _value.ingredientId
          // ignore: cast_nullable_to_non_nullable
          : ingredientId as String?,
      message: message == const $CopyWithPlaceholder()
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
    );
  }
}

extension $ServingConversionWarningCopyWith on ServingConversionWarning {
  /// Returns a callable class that can be used as follows: `instanceOfServingConversionWarning.copyWith(...)` or like so:`instanceOfServingConversionWarning.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ServingConversionWarningCWProxy get copyWith =>
      _$ServingConversionWarningCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServingConversionWarning _$ServingConversionWarningFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ServingConversionWarning', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['code', 'message']);
  final val = ServingConversionWarning(
    code: $checkedConvert(
      'code',
      (v) => $enumDecode(_$ServingConversionWarningCodeEnumEnumMap, v),
    ),
    ingredientId: $checkedConvert('ingredient_id', (v) => v as String?),
    message: $checkedConvert('message', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'ingredientId': 'ingredient_id'});

Map<String, dynamic> _$ServingConversionWarningToJson(
  ServingConversionWarning instance,
) => <String, dynamic>{
  'code': _$ServingConversionWarningCodeEnumEnumMap[instance.code]!,
  'ingredient_id': ?instance.ingredientId,
  'message': instance.message,
};

const _$ServingConversionWarningCodeEnumEnumMap = {
  ServingConversionWarningCodeEnum.roundDeviation: 'round_deviation',
};
