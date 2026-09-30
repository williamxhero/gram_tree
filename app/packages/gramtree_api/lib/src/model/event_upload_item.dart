//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:gramtree_api/src/model/event_correlation_ids.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'event_upload_item.g.dart';

/// EventUploadItem
///
/// Properties:
/// * [id] - 客户端生成的事件 ID（UUID v4），全局唯一，按它去重
/// * [eventType] 
/// * [typeVersion] - 事件类型的版本号
/// * [deviceId] 
/// * [deviceTime] - 设备本地时间，必须带时区
/// * [appVersion] 
/// * [correlation] 
/// * [content] - 事件内容。用户 ID 只按登录状态填入，这里出现的任何 user_id 字段都不采信
@BuiltValue()
abstract class EventUploadItem implements Built<EventUploadItem, EventUploadItemBuilder> {
  /// 客户端生成的事件 ID（UUID v4），全局唯一，按它去重
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'event_type')
  String get eventType;

  /// 事件类型的版本号
  @BuiltValueField(wireName: r'type_version')
  int get typeVersion;

  @BuiltValueField(wireName: r'device_id')
  String get deviceId;

  /// 设备本地时间，必须带时区
  @BuiltValueField(wireName: r'device_time')
  DateTime get deviceTime;

  @BuiltValueField(wireName: r'app_version')
  String get appVersion;

  @BuiltValueField(wireName: r'correlation')
  EventCorrelationIds? get correlation;

  /// 事件内容。用户 ID 只按登录状态填入，这里出现的任何 user_id 字段都不采信
  @BuiltValueField(wireName: r'content')
  BuiltMap<String, JsonObject?>? get content;

  EventUploadItem._();

  factory EventUploadItem([void updates(EventUploadItemBuilder b)]) = _$EventUploadItem;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EventUploadItemBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EventUploadItem> get serializer => _$EventUploadItemSerializer();
}

class _$EventUploadItemSerializer implements PrimitiveSerializer<EventUploadItem> {
  @override
  final Iterable<Type> types = const [EventUploadItem, _$EventUploadItem];

  @override
  final String wireName = r'EventUploadItem';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EventUploadItem object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'event_type';
    yield serializers.serialize(
      object.eventType,
      specifiedType: const FullType(String),
    );
    yield r'type_version';
    yield serializers.serialize(
      object.typeVersion,
      specifiedType: const FullType(int),
    );
    yield r'device_id';
    yield serializers.serialize(
      object.deviceId,
      specifiedType: const FullType(String),
    );
    yield r'device_time';
    yield serializers.serialize(
      object.deviceTime,
      specifiedType: const FullType(DateTime),
    );
    yield r'app_version';
    yield serializers.serialize(
      object.appVersion,
      specifiedType: const FullType(String),
    );
    if (object.correlation != null) {
      yield r'correlation';
      yield serializers.serialize(
        object.correlation,
        specifiedType: const FullType(EventCorrelationIds),
      );
    }
    if (object.content != null) {
      yield r'content';
      yield serializers.serialize(
        object.content,
        specifiedType: const FullType(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    EventUploadItem object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EventUploadItemBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'event_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.eventType = valueDes;
          break;
        case r'type_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.typeVersion = valueDes;
          break;
        case r'device_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.deviceId = valueDes;
          break;
        case r'device_time':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.deviceTime = valueDes;
          break;
        case r'app_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.appVersion = valueDes;
          break;
        case r'correlation':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(EventCorrelationIds),
          ) as EventCorrelationIds;
          result.correlation.replace(valueDes);
          break;
        case r'content':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
          ) as BuiltMap<String, JsonObject?>;
          result.content.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EventUploadItem deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EventUploadItemBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

