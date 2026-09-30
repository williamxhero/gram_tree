//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'analytics_event_in.g.dart';

/// 只允许这些字段：事件类型、页面/入口标识、可选耗时、发生时间、设备 ID。  不含菜谱内容、口味档案、过敏和健康信息；也不接受用户 ID（服务端按登录状态填入）。
///
/// Properties:
/// * [id] - 客户端生成的 UUID v4，用于去重
/// * [eventType] 
/// * [target] - 页面或入口标识
/// * [durationMs] 
/// * [occurredAt] 
/// * [deviceId] 
@BuiltValue()
abstract class AnalyticsEventIn implements Built<AnalyticsEventIn, AnalyticsEventInBuilder> {
  /// 客户端生成的 UUID v4，用于去重
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'event_type')
  AnalyticsEventInEventTypeEnum get eventType;
  // enum eventTypeEnum {  page_view,  tap,  load_duration,  };

  /// 页面或入口标识
  @BuiltValueField(wireName: r'target')
  String get target;

  @BuiltValueField(wireName: r'duration_ms')
  int? get durationMs;

  @BuiltValueField(wireName: r'occurred_at')
  DateTime get occurredAt;

  @BuiltValueField(wireName: r'device_id')
  String? get deviceId;

  AnalyticsEventIn._();

  factory AnalyticsEventIn([void updates(AnalyticsEventInBuilder b)]) = _$AnalyticsEventIn;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AnalyticsEventInBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AnalyticsEventIn> get serializer => _$AnalyticsEventInSerializer();
}

class _$AnalyticsEventInSerializer implements PrimitiveSerializer<AnalyticsEventIn> {
  @override
  final Iterable<Type> types = const [AnalyticsEventIn, _$AnalyticsEventIn];

  @override
  final String wireName = r'AnalyticsEventIn';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AnalyticsEventIn object, {
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
      specifiedType: const FullType(AnalyticsEventInEventTypeEnum),
    );
    yield r'target';
    yield serializers.serialize(
      object.target,
      specifiedType: const FullType(String),
    );
    if (object.durationMs != null) {
      yield r'duration_ms';
      yield serializers.serialize(
        object.durationMs,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'occurred_at';
    yield serializers.serialize(
      object.occurredAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.deviceId != null) {
      yield r'device_id';
      yield serializers.serialize(
        object.deviceId,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    AnalyticsEventIn object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AnalyticsEventInBuilder result,
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
            specifiedType: const FullType(AnalyticsEventInEventTypeEnum),
          ) as AnalyticsEventInEventTypeEnum;
          result.eventType = valueDes;
          break;
        case r'target':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.target = valueDes;
          break;
        case r'duration_ms':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.durationMs = valueDes;
          break;
        case r'occurred_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.occurredAt = valueDes;
          break;
        case r'device_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.deviceId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AnalyticsEventIn deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AnalyticsEventInBuilder();
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

class AnalyticsEventInEventTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'page_view')
  static const AnalyticsEventInEventTypeEnum pageView = _$analyticsEventInEventTypeEnum_pageView;
  @BuiltValueEnumConst(wireName: r'tap')
  static const AnalyticsEventInEventTypeEnum tap = _$analyticsEventInEventTypeEnum_tap;
  @BuiltValueEnumConst(wireName: r'load_duration')
  static const AnalyticsEventInEventTypeEnum loadDuration = _$analyticsEventInEventTypeEnum_loadDuration;

  static Serializer<AnalyticsEventInEventTypeEnum> get serializer => _$analyticsEventInEventTypeEnumSerializer;

  const AnalyticsEventInEventTypeEnum._(String name): super(name);

  static BuiltSet<AnalyticsEventInEventTypeEnum> get values => _$analyticsEventInEventTypeEnumValues;
  static AnalyticsEventInEventTypeEnum valueOf(String name) => _$analyticsEventInEventTypeEnumValueOf(name);
}

