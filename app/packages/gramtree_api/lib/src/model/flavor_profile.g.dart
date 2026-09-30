// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flavor_profile.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FlavorProfileCWProxy {
  FlavorProfile numbing(int? numbing);

  FlavorProfile oily(int? oily);

  FlavorProfile salty(int? salty);

  FlavorProfile sour(int? sour);

  FlavorProfile spicy(int? spicy);

  FlavorProfile sweet(int? sweet);

  FlavorProfile umami(int? umami);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FlavorProfile(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FlavorProfile(...).copyWith(id: 12, name: "My name")
  /// ````
  FlavorProfile call({
    int? numbing,
    int? oily,
    int? salty,
    int? sour,
    int? spicy,
    int? sweet,
    int? umami,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfFlavorProfile.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfFlavorProfile.copyWith.fieldName(...)`
class _$FlavorProfileCWProxyImpl implements _$FlavorProfileCWProxy {
  const _$FlavorProfileCWProxyImpl(this._value);

  final FlavorProfile _value;

  @override
  FlavorProfile numbing(int? numbing) => this(numbing: numbing);

  @override
  FlavorProfile oily(int? oily) => this(oily: oily);

  @override
  FlavorProfile salty(int? salty) => this(salty: salty);

  @override
  FlavorProfile sour(int? sour) => this(sour: sour);

  @override
  FlavorProfile spicy(int? spicy) => this(spicy: spicy);

  @override
  FlavorProfile sweet(int? sweet) => this(sweet: sweet);

  @override
  FlavorProfile umami(int? umami) => this(umami: umami);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FlavorProfile(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FlavorProfile(...).copyWith(id: 12, name: "My name")
  /// ````
  FlavorProfile call({
    Object? numbing = const $CopyWithPlaceholder(),
    Object? oily = const $CopyWithPlaceholder(),
    Object? salty = const $CopyWithPlaceholder(),
    Object? sour = const $CopyWithPlaceholder(),
    Object? spicy = const $CopyWithPlaceholder(),
    Object? sweet = const $CopyWithPlaceholder(),
    Object? umami = const $CopyWithPlaceholder(),
  }) {
    return FlavorProfile(
      numbing: numbing == const $CopyWithPlaceholder()
          ? _value.numbing
          // ignore: cast_nullable_to_non_nullable
          : numbing as int?,
      oily: oily == const $CopyWithPlaceholder()
          ? _value.oily
          // ignore: cast_nullable_to_non_nullable
          : oily as int?,
      salty: salty == const $CopyWithPlaceholder()
          ? _value.salty
          // ignore: cast_nullable_to_non_nullable
          : salty as int?,
      sour: sour == const $CopyWithPlaceholder()
          ? _value.sour
          // ignore: cast_nullable_to_non_nullable
          : sour as int?,
      spicy: spicy == const $CopyWithPlaceholder()
          ? _value.spicy
          // ignore: cast_nullable_to_non_nullable
          : spicy as int?,
      sweet: sweet == const $CopyWithPlaceholder()
          ? _value.sweet
          // ignore: cast_nullable_to_non_nullable
          : sweet as int?,
      umami: umami == const $CopyWithPlaceholder()
          ? _value.umami
          // ignore: cast_nullable_to_non_nullable
          : umami as int?,
    );
  }
}

extension $FlavorProfileCopyWith on FlavorProfile {
  /// Returns a callable class that can be used as follows: `instanceOfFlavorProfile.copyWith(...)` or like so:`instanceOfFlavorProfile.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FlavorProfileCWProxy get copyWith => _$FlavorProfileCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlavorProfile _$FlavorProfileFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FlavorProfile', json, ($checkedConvert) {
      final val = FlavorProfile(
        numbing: $checkedConvert('numbing', (v) => (v as num?)?.toInt() ?? 0),
        oily: $checkedConvert('oily', (v) => (v as num?)?.toInt() ?? 0),
        salty: $checkedConvert('salty', (v) => (v as num?)?.toInt() ?? 0),
        sour: $checkedConvert('sour', (v) => (v as num?)?.toInt() ?? 0),
        spicy: $checkedConvert('spicy', (v) => (v as num?)?.toInt() ?? 0),
        sweet: $checkedConvert('sweet', (v) => (v as num?)?.toInt() ?? 0),
        umami: $checkedConvert('umami', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$FlavorProfileToJson(FlavorProfile instance) =>
    <String, dynamic>{
      'numbing': ?instance.numbing,
      'oily': ?instance.oily,
      'salty': ?instance.salty,
      'sour': ?instance.sour,
      'spicy': ?instance.spicy,
      'sweet': ?instance.sweet,
      'umami': ?instance.umami,
    };
