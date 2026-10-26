// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publication_condition.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicationConditionCWProxy {
  PublicationCondition action(String action);

  PublicationCondition code(String code);

  PublicationCondition label(String label);

  PublicationCondition remainingCount(int? remainingCount);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicationCondition(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicationCondition(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicationCondition call({
    String action,
    String code,
    String label,
    int? remainingCount,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicationCondition.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicationCondition.copyWith.fieldName(...)`
class _$PublicationConditionCWProxyImpl
    implements _$PublicationConditionCWProxy {
  const _$PublicationConditionCWProxyImpl(this._value);

  final PublicationCondition _value;

  @override
  PublicationCondition action(String action) => this(action: action);

  @override
  PublicationCondition code(String code) => this(code: code);

  @override
  PublicationCondition label(String label) => this(label: label);

  @override
  PublicationCondition remainingCount(int? remainingCount) =>
      this(remainingCount: remainingCount);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicationCondition(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicationCondition(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicationCondition call({
    Object? action = const $CopyWithPlaceholder(),
    Object? code = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? remainingCount = const $CopyWithPlaceholder(),
  }) {
    return PublicationCondition(
      action: action == const $CopyWithPlaceholder()
          ? _value.action
          // ignore: cast_nullable_to_non_nullable
          : action as String,
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      remainingCount: remainingCount == const $CopyWithPlaceholder()
          ? _value.remainingCount
          // ignore: cast_nullable_to_non_nullable
          : remainingCount as int?,
    );
  }
}

extension $PublicationConditionCopyWith on PublicationCondition {
  /// Returns a callable class that can be used as follows: `instanceOfPublicationCondition.copyWith(...)` or like so:`instanceOfPublicationCondition.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicationConditionCWProxy get copyWith =>
      _$PublicationConditionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicationCondition _$PublicationConditionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PublicationCondition', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['action', 'code', 'label']);
  final val = PublicationCondition(
    action: $checkedConvert('action', (v) => v as String),
    code: $checkedConvert('code', (v) => v as String),
    label: $checkedConvert('label', (v) => v as String),
    remainingCount: $checkedConvert(
      'remaining_count',
      (v) => (v as num?)?.toInt(),
    ),
  );
  return val;
}, fieldKeyMap: const {'remainingCount': 'remaining_count'});

Map<String, dynamic> _$PublicationConditionToJson(
  PublicationCondition instance,
) => <String, dynamic>{
  'action': instance.action,
  'code': instance.code,
  'label': instance.label,
  'remaining_count': ?instance.remainingCount,
};
