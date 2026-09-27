// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletionOutCWProxy {
  DeletionOut deletionDueAt(String? deletionDueAt);

  DeletionOut status(DeletionOutStatusEnum status);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DeletionOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DeletionOut(...).copyWith(id: 12, name: "My name")
  /// ````
  DeletionOut call({String? deletionDueAt, DeletionOutStatusEnum status});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDeletionOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDeletionOut.copyWith.fieldName(...)`
class _$DeletionOutCWProxyImpl implements _$DeletionOutCWProxy {
  const _$DeletionOutCWProxyImpl(this._value);

  final DeletionOut _value;

  @override
  DeletionOut deletionDueAt(String? deletionDueAt) =>
      this(deletionDueAt: deletionDueAt);

  @override
  DeletionOut status(DeletionOutStatusEnum status) => this(status: status);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DeletionOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DeletionOut(...).copyWith(id: 12, name: "My name")
  /// ````
  DeletionOut call({
    Object? deletionDueAt = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return DeletionOut(
      deletionDueAt: deletionDueAt == const $CopyWithPlaceholder()
          ? _value.deletionDueAt
          // ignore: cast_nullable_to_non_nullable
          : deletionDueAt as String?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as DeletionOutStatusEnum,
    );
  }
}

extension $DeletionOutCopyWith on DeletionOut {
  /// Returns a callable class that can be used as follows: `instanceOfDeletionOut.copyWith(...)` or like so:`instanceOfDeletionOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletionOutCWProxy get copyWith => _$DeletionOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletionOut _$DeletionOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletionOut', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deletion_due_at', 'status']);
      final val = DeletionOut(
        deletionDueAt: $checkedConvert('deletion_due_at', (v) => v as String?),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$DeletionOutStatusEnumEnumMap, v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'deletionDueAt': 'deletion_due_at'});

Map<String, dynamic> _$DeletionOutToJson(DeletionOut instance) =>
    <String, dynamic>{
      'deletion_due_at': instance.deletionDueAt,
      'status': _$DeletionOutStatusEnumEnumMap[instance.status]!,
    };

const _$DeletionOutStatusEnumEnumMap = {
  DeletionOutStatusEnum.active: 'active',
  DeletionOutStatusEnum.deleting: 'deleting',
  DeletionOutStatusEnum.deleted: 'deleted',
};
