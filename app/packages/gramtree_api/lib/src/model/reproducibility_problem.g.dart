// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reproducibility_problem.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReproducibilityProblemCWProxy {
  ReproducibilityProblem id(String id);

  ReproducibilityProblem message(String message);

  ReproducibilityProblem original(String? original);

  ReproducibilityProblem position(ReproducibilityPosition position);

  ReproducibilityProblem status(ReproducibilityProblemStatusEnum status);

  ReproducibilityProblem type(ReproducibilityProblemTypeEnum type);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReproducibilityProblem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReproducibilityProblem(...).copyWith(id: 12, name: "My name")
  /// ````
  ReproducibilityProblem call({
    String id,
    String message,
    String? original,
    ReproducibilityPosition position,
    ReproducibilityProblemStatusEnum status,
    ReproducibilityProblemTypeEnum type,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfReproducibilityProblem.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfReproducibilityProblem.copyWith.fieldName(...)`
class _$ReproducibilityProblemCWProxyImpl
    implements _$ReproducibilityProblemCWProxy {
  const _$ReproducibilityProblemCWProxyImpl(this._value);

  final ReproducibilityProblem _value;

  @override
  ReproducibilityProblem id(String id) => this(id: id);

  @override
  ReproducibilityProblem message(String message) => this(message: message);

  @override
  ReproducibilityProblem original(String? original) => this(original: original);

  @override
  ReproducibilityProblem position(ReproducibilityPosition position) =>
      this(position: position);

  @override
  ReproducibilityProblem status(ReproducibilityProblemStatusEnum status) =>
      this(status: status);

  @override
  ReproducibilityProblem type(ReproducibilityProblemTypeEnum type) =>
      this(type: type);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReproducibilityProblem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReproducibilityProblem(...).copyWith(id: 12, name: "My name")
  /// ````
  ReproducibilityProblem call({
    Object? id = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
    Object? original = const $CopyWithPlaceholder(),
    Object? position = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
  }) {
    return ReproducibilityProblem(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      message: message == const $CopyWithPlaceholder()
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
      original: original == const $CopyWithPlaceholder()
          ? _value.original
          // ignore: cast_nullable_to_non_nullable
          : original as String?,
      position: position == const $CopyWithPlaceholder()
          ? _value.position
          // ignore: cast_nullable_to_non_nullable
          : position as ReproducibilityPosition,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as ReproducibilityProblemStatusEnum,
      type: type == const $CopyWithPlaceholder()
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as ReproducibilityProblemTypeEnum,
    );
  }
}

extension $ReproducibilityProblemCopyWith on ReproducibilityProblem {
  /// Returns a callable class that can be used as follows: `instanceOfReproducibilityProblem.copyWith(...)` or like so:`instanceOfReproducibilityProblem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReproducibilityProblemCWProxy get copyWith =>
      _$ReproducibilityProblemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReproducibilityProblem _$ReproducibilityProblemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ReproducibilityProblem', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'message', 'position', 'status', 'type'],
  );
  final val = ReproducibilityProblem(
    id: $checkedConvert('id', (v) => v as String),
    message: $checkedConvert('message', (v) => v as String),
    original: $checkedConvert('original', (v) => v as String?),
    position: $checkedConvert(
      'position',
      (v) => ReproducibilityPosition.fromJson(v as Map<String, dynamic>),
    ),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$ReproducibilityProblemStatusEnumEnumMap, v),
    ),
    type: $checkedConvert(
      'type',
      (v) => $enumDecode(_$ReproducibilityProblemTypeEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$ReproducibilityProblemToJson(
  ReproducibilityProblem instance,
) => <String, dynamic>{
  'id': instance.id,
  'message': instance.message,
  'original': ?instance.original,
  'position': instance.position.toJson(),
  'status': _$ReproducibilityProblemStatusEnumEnumMap[instance.status]!,
  'type': _$ReproducibilityProblemTypeEnumEnumMap[instance.type]!,
};

const _$ReproducibilityProblemStatusEnumEnumMap = {
  ReproducibilityProblemStatusEnum.unresolved: 'unresolved',
  ReproducibilityProblemStatusEnum.ignored: 'ignored',
  ReproducibilityProblemStatusEnum.resolved: 'resolved',
};

const _$ReproducibilityProblemTypeEnumEnumMap = {
  ReproducibilityProblemTypeEnum.ambiguous: 'ambiguous',
  ReproducibilityProblemTypeEnum.missing: 'missing',
};
