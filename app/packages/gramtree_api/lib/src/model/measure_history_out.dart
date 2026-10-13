//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'measure_history_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MeasureHistoryOut {
  /// Returns a new [MeasureHistoryOut] instance.
  MeasureHistoryOut({
    required this.deviceTime,

    required this.field,

    required this.id,

    required this.newValue,

    required this.oldValue,

    required this.outcome,

    required this.writeId,
  });

  @JsonKey(name: r'device_time', required: true, includeIfNull: false)
  final String deviceTime;

  @JsonKey(name: r'field', required: true, includeIfNull: false)
  final String field;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'new_value', required: true, includeIfNull: true)
  final Object? newValue;

  @JsonKey(name: r'old_value', required: true, includeIfNull: true)
  final Object? oldValue;

  @JsonKey(name: r'outcome', required: true, includeIfNull: false)
  final MeasureHistoryOutOutcomeEnum outcome;

  @JsonKey(name: r'write_id', required: true, includeIfNull: false)
  final String writeId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasureHistoryOut &&
          other.deviceTime == deviceTime &&
          other.field == field &&
          other.id == id &&
          other.newValue == newValue &&
          other.oldValue == oldValue &&
          other.outcome == outcome &&
          other.writeId == writeId;

  @override
  int get hashCode =>
      deviceTime.hashCode +
      field.hashCode +
      id.hashCode +
      (newValue == null ? 0 : newValue.hashCode) +
      (oldValue == null ? 0 : oldValue.hashCode) +
      outcome.hashCode +
      writeId.hashCode;

  factory MeasureHistoryOut.fromJson(Map<String, dynamic> json) =>
      _$MeasureHistoryOutFromJson(json);

  Map<String, dynamic> toJson() => _$MeasureHistoryOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum MeasureHistoryOutOutcomeEnum {
  @JsonValue(r'won')
  won(r'won'),
  @JsonValue(r'lost')
  lost(r'lost'),
  @JsonValue(r'unchanged')
  unchanged(r'unchanged'),
  @JsonValue(r'tombstoned')
  tombstoned(r'tombstoned');

  const MeasureHistoryOutOutcomeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
