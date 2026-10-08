// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'taste_profile_patch.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TasteProfilePatchCWProxy {
  TasteProfilePatch flavors(Map<String, num> flavors);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TasteProfilePatch(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TasteProfilePatch(...).copyWith(id: 12, name: "My name")
  /// ````
  TasteProfilePatch call({Map<String, num> flavors});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTasteProfilePatch.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTasteProfilePatch.copyWith.fieldName(...)`
class _$TasteProfilePatchCWProxyImpl implements _$TasteProfilePatchCWProxy {
  const _$TasteProfilePatchCWProxyImpl(this._value);

  final TasteProfilePatch _value;

  @override
  TasteProfilePatch flavors(Map<String, num> flavors) => this(flavors: flavors);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TasteProfilePatch(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TasteProfilePatch(...).copyWith(id: 12, name: "My name")
  /// ````
  TasteProfilePatch call({Object? flavors = const $CopyWithPlaceholder()}) {
    return TasteProfilePatch(
      flavors: flavors == const $CopyWithPlaceholder()
          ? _value.flavors
          // ignore: cast_nullable_to_non_nullable
          : flavors as Map<String, num>,
    );
  }
}

extension $TasteProfilePatchCopyWith on TasteProfilePatch {
  /// Returns a callable class that can be used as follows: `instanceOfTasteProfilePatch.copyWith(...)` or like so:`instanceOfTasteProfilePatch.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TasteProfilePatchCWProxy get copyWith =>
      _$TasteProfilePatchCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TasteProfilePatch _$TasteProfilePatchFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TasteProfilePatch', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['flavors']);
      final val = TasteProfilePatch(
        flavors: $checkedConvert(
          'flavors',
          (v) => Map<String, num>.from(v as Map),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TasteProfilePatchToJson(TasteProfilePatch instance) =>
    <String, dynamic>{'flavors': instance.flavors};
