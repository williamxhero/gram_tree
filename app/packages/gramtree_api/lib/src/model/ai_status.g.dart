// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_status.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AIStatusCWProxy {
  AIStatus available(bool available);

  AIStatus reason(String? reason);

  AIStatus remaining(int remaining);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AIStatus(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AIStatus(...).copyWith(id: 12, name: "My name")
  /// ````
  AIStatus call({bool available, String? reason, int remaining});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAIStatus.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAIStatus.copyWith.fieldName(...)`
class _$AIStatusCWProxyImpl implements _$AIStatusCWProxy {
  const _$AIStatusCWProxyImpl(this._value);

  final AIStatus _value;

  @override
  AIStatus available(bool available) => this(available: available);

  @override
  AIStatus reason(String? reason) => this(reason: reason);

  @override
  AIStatus remaining(int remaining) => this(remaining: remaining);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AIStatus(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AIStatus(...).copyWith(id: 12, name: "My name")
  /// ````
  AIStatus call({
    Object? available = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? remaining = const $CopyWithPlaceholder(),
  }) {
    return AIStatus(
      available: available == const $CopyWithPlaceholder()
          ? _value.available
          // ignore: cast_nullable_to_non_nullable
          : available as bool,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String?,
      remaining: remaining == const $CopyWithPlaceholder()
          ? _value.remaining
          // ignore: cast_nullable_to_non_nullable
          : remaining as int,
    );
  }
}

extension $AIStatusCopyWith on AIStatus {
  /// Returns a callable class that can be used as follows: `instanceOfAIStatus.copyWith(...)` or like so:`instanceOfAIStatus.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AIStatusCWProxy get copyWith => _$AIStatusCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AIStatus _$AIStatusFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AIStatus', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['available', 'remaining']);
      final val = AIStatus(
        available: $checkedConvert('available', (v) => v as bool),
        reason: $checkedConvert('reason', (v) => v as String?),
        remaining: $checkedConvert('remaining', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$AIStatusToJson(AIStatus instance) => <String, dynamic>{
  'available': instance.available,
  'reason': ?instance.reason,
  'remaining': instance.remaining,
};
