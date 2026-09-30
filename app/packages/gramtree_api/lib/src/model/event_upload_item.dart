//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/event_correlation_ids.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_upload_item.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EventUploadItem {
  /// Returns a new [EventUploadItem] instance.
  EventUploadItem({

    required  this.appVersion,

     this.content,

     this.correlation,

    required  this.deviceId,

    required  this.deviceTime,

    required  this.eventType,

    required  this.id,

    required  this.typeVersion,
  });

  @JsonKey(
    
    name: r'app_version',
    required: true,
    includeIfNull: false,
  )


  final String appVersion;



      /// 事件内容。用户 ID 只按登录状态填入，这里出现的任何 user_id 字段都不采信
  @JsonKey(
    
    name: r'content',
    required: false,
    includeIfNull: false,
  )


  final Object? content;



  @JsonKey(
    
    name: r'correlation',
    required: false,
    includeIfNull: false,
  )


  final EventCorrelationIds? correlation;



  @JsonKey(
    
    name: r'device_id',
    required: true,
    includeIfNull: false,
  )


  final String deviceId;



      /// 设备本地时间，必须带时区
  @JsonKey(
    
    name: r'device_time',
    required: true,
    includeIfNull: false,
  )


  final DateTime deviceTime;



  @JsonKey(
    
    name: r'event_type',
    required: true,
    includeIfNull: false,
  )


  final String eventType;



      /// 客户端生成的事件 ID（UUID v4），全局唯一，按它去重
  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



      /// 事件类型的版本号
          // minimum: 1
  @JsonKey(
    
    name: r'type_version',
    required: true,
    includeIfNull: false,
  )


  final int typeVersion;





    @override
    bool operator ==(Object other) => identical(this, other) || other is EventUploadItem &&
      other.appVersion == appVersion &&
      other.content == content &&
      other.correlation == correlation &&
      other.deviceId == deviceId &&
      other.deviceTime == deviceTime &&
      other.eventType == eventType &&
      other.id == id &&
      other.typeVersion == typeVersion;

    @override
    int get hashCode =>
        appVersion.hashCode +
        content.hashCode +
        correlation.hashCode +
        deviceId.hashCode +
        deviceTime.hashCode +
        eventType.hashCode +
        id.hashCode +
        typeVersion.hashCode;

  factory EventUploadItem.fromJson(Map<String, dynamic> json) => _$EventUploadItemFromJson(json);

  Map<String, dynamic> toJson() => _$EventUploadItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

