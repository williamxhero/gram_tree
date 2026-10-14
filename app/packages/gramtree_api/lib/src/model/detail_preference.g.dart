// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detail_preference.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DetailPreferenceCWProxy {
  DetailPreference detail(DetailPreferenceDetailEnum detail);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DetailPreference(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DetailPreference(...).copyWith(id: 12, name: "My name")
  /// ````
  DetailPreference call({DetailPreferenceDetailEnum detail});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDetailPreference.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDetailPreference.copyWith.fieldName(...)`
class _$DetailPreferenceCWProxyImpl implements _$DetailPreferenceCWProxy {
  const _$DetailPreferenceCWProxyImpl(this._value);

  final DetailPreference _value;

  @override
  DetailPreference detail(DetailPreferenceDetailEnum detail) =>
      this(detail: detail);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DetailPreference(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DetailPreference(...).copyWith(id: 12, name: "My name")
  /// ````
  DetailPreference call({Object? detail = const $CopyWithPlaceholder()}) {
    return DetailPreference(
      detail: detail == const $CopyWithPlaceholder()
          ? _value.detail
          // ignore: cast_nullable_to_non_nullable
          : detail as DetailPreferenceDetailEnum,
    );
  }
}

extension $DetailPreferenceCopyWith on DetailPreference {
  /// Returns a callable class that can be used as follows: `instanceOfDetailPreference.copyWith(...)` or like so:`instanceOfDetailPreference.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DetailPreferenceCWProxy get copyWith => _$DetailPreferenceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DetailPreference _$DetailPreferenceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DetailPreference', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['detail']);
      final val = DetailPreference(
        detail: $checkedConvert(
          'detail',
          (v) => $enumDecode(_$DetailPreferenceDetailEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DetailPreferenceToJson(DetailPreference instance) =>
    <String, dynamic>{
      'detail': _$DetailPreferenceDetailEnumEnumMap[instance.detail]!,
    };

const _$DetailPreferenceDetailEnumEnumMap = {
  DetailPreferenceDetailEnum.auto: 'auto',
  DetailPreferenceDetailEnum.brief: 'brief',
  DetailPreferenceDetailEnum.detailed: 'detailed',
};
