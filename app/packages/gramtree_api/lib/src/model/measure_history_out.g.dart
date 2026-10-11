// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measure_history_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MeasureHistoryOutCWProxy {
  MeasureHistoryOut deviceTime(String deviceTime);

  MeasureHistoryOut field(String field);

  MeasureHistoryOut id(String id);

  MeasureHistoryOut newValue(Object? newValue);

  MeasureHistoryOut oldValue(Object? oldValue);

  MeasureHistoryOut outcome(MeasureHistoryOutOutcomeEnum outcome);

  MeasureHistoryOut writeId(String writeId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MeasureHistoryOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MeasureHistoryOut(...).copyWith(id: 12, name: "My name")
  /// ````
  MeasureHistoryOut call({
    String deviceTime,
    String field,
    String id,
    Object? newValue,
    Object? oldValue,
    MeasureHistoryOutOutcomeEnum outcome,
    String writeId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMeasureHistoryOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMeasureHistoryOut.copyWith.fieldName(...)`
class _$MeasureHistoryOutCWProxyImpl implements _$MeasureHistoryOutCWProxy {
  const _$MeasureHistoryOutCWProxyImpl(this._value);

  final MeasureHistoryOut _value;

  @override
  MeasureHistoryOut deviceTime(String deviceTime) =>
      this(deviceTime: deviceTime);

  @override
  MeasureHistoryOut field(String field) => this(field: field);

  @override
  MeasureHistoryOut id(String id) => this(id: id);

  @override
  MeasureHistoryOut newValue(Object? newValue) => this(newValue: newValue);

  @override
  MeasureHistoryOut oldValue(Object? oldValue) => this(oldValue: oldValue);

  @override
  MeasureHistoryOut outcome(MeasureHistoryOutOutcomeEnum outcome) =>
      this(outcome: outcome);

  @override
  MeasureHistoryOut writeId(String writeId) => this(writeId: writeId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MeasureHistoryOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MeasureHistoryOut(...).copyWith(id: 12, name: "My name")
  /// ````
  MeasureHistoryOut call({
    Object? deviceTime = const $CopyWithPlaceholder(),
    Object? field = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? newValue = const $CopyWithPlaceholder(),
    Object? oldValue = const $CopyWithPlaceholder(),
    Object? outcome = const $CopyWithPlaceholder(),
    Object? writeId = const $CopyWithPlaceholder(),
  }) {
    return MeasureHistoryOut(
      deviceTime: deviceTime == const $CopyWithPlaceholder()
          ? _value.deviceTime
          // ignore: cast_nullable_to_non_nullable
          : deviceTime as String,
      field: field == const $CopyWithPlaceholder()
          ? _value.field
          // ignore: cast_nullable_to_non_nullable
          : field as String,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      newValue: newValue == const $CopyWithPlaceholder()
          ? _value.newValue
          // ignore: cast_nullable_to_non_nullable
          : newValue as Object?,
      oldValue: oldValue == const $CopyWithPlaceholder()
          ? _value.oldValue
          // ignore: cast_nullable_to_non_nullable
          : oldValue as Object?,
      outcome: outcome == const $CopyWithPlaceholder()
          ? _value.outcome
          // ignore: cast_nullable_to_non_nullable
          : outcome as MeasureHistoryOutOutcomeEnum,
      writeId: writeId == const $CopyWithPlaceholder()
          ? _value.writeId
          // ignore: cast_nullable_to_non_nullable
          : writeId as String,
    );
  }
}

extension $MeasureHistoryOutCopyWith on MeasureHistoryOut {
  /// Returns a callable class that can be used as follows: `instanceOfMeasureHistoryOut.copyWith(...)` or like so:`instanceOfMeasureHistoryOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MeasureHistoryOutCWProxy get copyWith =>
      _$MeasureHistoryOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeasureHistoryOut _$MeasureHistoryOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'MeasureHistoryOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'device_time',
            'field',
            'id',
            'new_value',
            'old_value',
            'outcome',
            'write_id',
          ],
        );
        final val = MeasureHistoryOut(
          deviceTime: $checkedConvert('device_time', (v) => v as String),
          field: $checkedConvert('field', (v) => v as String),
          id: $checkedConvert('id', (v) => v as String),
          newValue: $checkedConvert('new_value', (v) => v),
          oldValue: $checkedConvert('old_value', (v) => v),
          outcome: $checkedConvert(
            'outcome',
            (v) => $enumDecode(_$MeasureHistoryOutOutcomeEnumEnumMap, v),
          ),
          writeId: $checkedConvert('write_id', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'deviceTime': 'device_time',
        'newValue': 'new_value',
        'oldValue': 'old_value',
        'writeId': 'write_id',
      },
    );

Map<String, dynamic> _$MeasureHistoryOutToJson(MeasureHistoryOut instance) =>
    <String, dynamic>{
      'device_time': instance.deviceTime,
      'field': instance.field,
      'id': instance.id,
      'new_value': instance.newValue,
      'old_value': instance.oldValue,
      'outcome': _$MeasureHistoryOutOutcomeEnumEnumMap[instance.outcome]!,
      'write_id': instance.writeId,
    };

const _$MeasureHistoryOutOutcomeEnumEnumMap = {
  MeasureHistoryOutOutcomeEnum.won: 'won',
  MeasureHistoryOutOutcomeEnum.lost: 'lost',
  MeasureHistoryOutOutcomeEnum.unchanged: 'unchanged',
  MeasureHistoryOutOutcomeEnum.tombstoned: 'tombstoned',
};
