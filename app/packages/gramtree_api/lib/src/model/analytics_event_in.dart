//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'analytics_event_in.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AnalyticsEventIn {
  /// Returns a new [AnalyticsEventIn] instance.
  AnalyticsEventIn({

     this.deviceId,

     this.durationMs,

    required  this.eventType,

    required  this.id,

    required  this.occurredAt,

    required  this.target,
  });

  @JsonKey(
    
    name: r'device_id',
    required: false,
    includeIfNull: false,
  )


  final String? deviceId;



          // minimum: 0
          // maximum: 600000
  @JsonKey(
    
    name: r'duration_ms',
    required: false,
    includeIfNull: false,
  )


  final int? durationMs;



  @JsonKey(
    
    name: r'event_type',
    required: true,
    includeIfNull: false,
  )


  final AnalyticsEventInEventTypeEnum eventType;



      /// 客户端生成的 UUID v4，用于去重
  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'occurred_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime occurredAt;



      /// 页面或入口标识
  @JsonKey(
    
    name: r'target',
    required: true,
    includeIfNull: false,
  )


  final String target;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AnalyticsEventIn &&
      other.deviceId == deviceId &&
      other.durationMs == durationMs &&
      other.eventType == eventType &&
      other.id == id &&
      other.occurredAt == occurredAt &&
      other.target == target;

    @override
    int get hashCode =>
        (deviceId == null ? 0 : deviceId.hashCode) +
        (durationMs == null ? 0 : durationMs.hashCode) +
        eventType.hashCode +
        id.hashCode +
        occurredAt.hashCode +
        target.hashCode;

  factory AnalyticsEventIn.fromJson(Map<String, dynamic> json) => _$AnalyticsEventInFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyticsEventInToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum AnalyticsEventInEventTypeEnum {
@JsonValue(r'page_view')
pageView(r'page_view'),
@JsonValue(r'tap')
tap(r'tap'),
@JsonValue(r'load_duration')
loadDuration(r'load_duration');

const AnalyticsEventInEventTypeEnum(this.value);

final String value;

@override
String toString() => value;
}


