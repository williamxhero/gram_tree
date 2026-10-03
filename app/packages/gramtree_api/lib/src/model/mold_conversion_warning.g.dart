// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mold_conversion_warning.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MoldConversionWarningCWProxy {
  MoldConversionWarning code(MoldConversionWarningCodeEnum code);

  MoldConversionWarning ingredientId(String? ingredientId);

  MoldConversionWarning message(String message);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MoldConversionWarning(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MoldConversionWarning(...).copyWith(id: 12, name: "My name")
  /// ````
  MoldConversionWarning call({
    MoldConversionWarningCodeEnum code,
    String? ingredientId,
    String message,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMoldConversionWarning.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMoldConversionWarning.copyWith.fieldName(...)`
class _$MoldConversionWarningCWProxyImpl
    implements _$MoldConversionWarningCWProxy {
  const _$MoldConversionWarningCWProxyImpl(this._value);

  final MoldConversionWarning _value;

  @override
  MoldConversionWarning code(MoldConversionWarningCodeEnum code) =>
      this(code: code);

  @override
  MoldConversionWarning ingredientId(String? ingredientId) =>
      this(ingredientId: ingredientId);

  @override
  MoldConversionWarning message(String message) => this(message: message);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MoldConversionWarning(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MoldConversionWarning(...).copyWith(id: 12, name: "My name")
  /// ````
  MoldConversionWarning call({
    Object? code = const $CopyWithPlaceholder(),
    Object? ingredientId = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
  }) {
    return MoldConversionWarning(
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as MoldConversionWarningCodeEnum,
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

extension $MoldConversionWarningCopyWith on MoldConversionWarning {
  /// Returns a callable class that can be used as follows: `instanceOfMoldConversionWarning.copyWith(...)` or like so:`instanceOfMoldConversionWarning.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MoldConversionWarningCWProxy get copyWith =>
      _$MoldConversionWarningCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoldConversionWarning _$MoldConversionWarningFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('MoldConversionWarning', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['code', 'message']);
  final val = MoldConversionWarning(
    code: $checkedConvert(
      'code',
      (v) => $enumDecode(_$MoldConversionWarningCodeEnumEnumMap, v),
    ),
    ingredientId: $checkedConvert('ingredient_id', (v) => v as String?),
    message: $checkedConvert('message', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'ingredientId': 'ingredient_id'});

Map<String, dynamic> _$MoldConversionWarningToJson(
  MoldConversionWarning instance,
) => <String, dynamic>{
  'code': _$MoldConversionWarningCodeEnumEnumMap[instance.code]!,
  'ingredient_id': ?instance.ingredientId,
  'message': instance.message,
};

const _$MoldConversionWarningCodeEnumEnumMap = {
  MoldConversionWarningCodeEnum.roundDeviation: 'round_deviation',
  MoldConversionWarningCodeEnum.donenessCheck: 'doneness_check',
};
