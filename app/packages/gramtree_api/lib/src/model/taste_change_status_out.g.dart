// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'taste_change_status_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TasteChangeStatusOutCWProxy {
  TasteChangeStatusOut autoChanges(int autoChanges);

  TasteChangeStatusOut autoReverted(int autoReverted);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TasteChangeStatusOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TasteChangeStatusOut(...).copyWith(id: 12, name: "My name")
  /// ````
  TasteChangeStatusOut call({int autoChanges, int autoReverted});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTasteChangeStatusOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTasteChangeStatusOut.copyWith.fieldName(...)`
class _$TasteChangeStatusOutCWProxyImpl
    implements _$TasteChangeStatusOutCWProxy {
  const _$TasteChangeStatusOutCWProxyImpl(this._value);

  final TasteChangeStatusOut _value;

  @override
  TasteChangeStatusOut autoChanges(int autoChanges) =>
      this(autoChanges: autoChanges);

  @override
  TasteChangeStatusOut autoReverted(int autoReverted) =>
      this(autoReverted: autoReverted);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TasteChangeStatusOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TasteChangeStatusOut(...).copyWith(id: 12, name: "My name")
  /// ````
  TasteChangeStatusOut call({
    Object? autoChanges = const $CopyWithPlaceholder(),
    Object? autoReverted = const $CopyWithPlaceholder(),
  }) {
    return TasteChangeStatusOut(
      autoChanges: autoChanges == const $CopyWithPlaceholder()
          ? _value.autoChanges
          // ignore: cast_nullable_to_non_nullable
          : autoChanges as int,
      autoReverted: autoReverted == const $CopyWithPlaceholder()
          ? _value.autoReverted
          // ignore: cast_nullable_to_non_nullable
          : autoReverted as int,
    );
  }
}

extension $TasteChangeStatusOutCopyWith on TasteChangeStatusOut {
  /// Returns a callable class that can be used as follows: `instanceOfTasteChangeStatusOut.copyWith(...)` or like so:`instanceOfTasteChangeStatusOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TasteChangeStatusOutCWProxy get copyWith =>
      _$TasteChangeStatusOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TasteChangeStatusOut _$TasteChangeStatusOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'TasteChangeStatusOut',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['auto_changes', 'auto_reverted']);
    final val = TasteChangeStatusOut(
      autoChanges: $checkedConvert('auto_changes', (v) => (v as num).toInt()),
      autoReverted: $checkedConvert('auto_reverted', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'autoChanges': 'auto_changes',
    'autoReverted': 'auto_reverted',
  },
);

Map<String, dynamic> _$TasteChangeStatusOutToJson(
  TasteChangeStatusOut instance,
) => <String, dynamic>{
  'auto_changes': instance.autoChanges,
  'auto_reverted': instance.autoReverted,
};
