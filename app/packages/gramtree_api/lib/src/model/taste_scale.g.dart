// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'taste_scale.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TasteScaleCWProxy {
  TasteScale default_(num default_);

  TasteScale levels(List<TasteLevel> levels);

  TasteScale maximum(num maximum);

  TasteScale minimum(num minimum);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TasteScale(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TasteScale(...).copyWith(id: 12, name: "My name")
  /// ````
  TasteScale call({
    num default_,
    List<TasteLevel> levels,
    num maximum,
    num minimum,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTasteScale.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTasteScale.copyWith.fieldName(...)`
class _$TasteScaleCWProxyImpl implements _$TasteScaleCWProxy {
  const _$TasteScaleCWProxyImpl(this._value);

  final TasteScale _value;

  @override
  TasteScale default_(num default_) => this(default_: default_);

  @override
  TasteScale levels(List<TasteLevel> levels) => this(levels: levels);

  @override
  TasteScale maximum(num maximum) => this(maximum: maximum);

  @override
  TasteScale minimum(num minimum) => this(minimum: minimum);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TasteScale(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TasteScale(...).copyWith(id: 12, name: "My name")
  /// ````
  TasteScale call({
    Object? default_ = const $CopyWithPlaceholder(),
    Object? levels = const $CopyWithPlaceholder(),
    Object? maximum = const $CopyWithPlaceholder(),
    Object? minimum = const $CopyWithPlaceholder(),
  }) {
    return TasteScale(
      default_: default_ == const $CopyWithPlaceholder()
          ? _value.default_
          // ignore: cast_nullable_to_non_nullable
          : default_ as num,
      levels: levels == const $CopyWithPlaceholder()
          ? _value.levels
          // ignore: cast_nullable_to_non_nullable
          : levels as List<TasteLevel>,
      maximum: maximum == const $CopyWithPlaceholder()
          ? _value.maximum
          // ignore: cast_nullable_to_non_nullable
          : maximum as num,
      minimum: minimum == const $CopyWithPlaceholder()
          ? _value.minimum
          // ignore: cast_nullable_to_non_nullable
          : minimum as num,
    );
  }
}

extension $TasteScaleCopyWith on TasteScale {
  /// Returns a callable class that can be used as follows: `instanceOfTasteScale.copyWith(...)` or like so:`instanceOfTasteScale.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TasteScaleCWProxy get copyWith => _$TasteScaleCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TasteScale _$TasteScaleFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TasteScale', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['default', 'levels', 'maximum', 'minimum'],
      );
      final val = TasteScale(
        default_: $checkedConvert('default', (v) => v as num),
        levels: $checkedConvert(
          'levels',
          (v) => (v as List<dynamic>)
              .map((e) => TasteLevel.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        maximum: $checkedConvert('maximum', (v) => v as num),
        minimum: $checkedConvert('minimum', (v) => v as num),
      );
      return val;
    }, fieldKeyMap: const {'default_': 'default'});

Map<String, dynamic> _$TasteScaleToJson(TasteScale instance) =>
    <String, dynamic>{
      'default': instance.default_,
      'levels': instance.levels.map((e) => e.toJson()).toList(),
      'maximum': instance.maximum,
      'minimum': instance.minimum,
    };
