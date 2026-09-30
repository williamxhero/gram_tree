//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:gramtree_api/src/model/rejection_reason.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'event_upload_result_item.g.dart';

/// EventUploadResultItem
///
/// Properties:
/// * [id] 
/// * [status] - accepted：已接收入库；duplicate：这个 ID 之前已经收到过，原记录未改动；rejected：没通过登记表校验，未入库，见 reason
/// * [reason] 
@BuiltValue()
abstract class EventUploadResultItem implements Built<EventUploadResultItem, EventUploadResultItemBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  /// accepted：已接收入库；duplicate：这个 ID 之前已经收到过，原记录未改动；rejected：没通过登记表校验，未入库，见 reason
  @BuiltValueField(wireName: r'status')
  EventUploadResultItemStatusEnum get status;
  // enum statusEnum {  accepted,  duplicate,  rejected,  };

  @BuiltValueField(wireName: r'reason')
  RejectionReason? get reason;

  EventUploadResultItem._();

  factory EventUploadResultItem([void updates(EventUploadResultItemBuilder b)]) = _$EventUploadResultItem;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EventUploadResultItemBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EventUploadResultItem> get serializer => _$EventUploadResultItemSerializer();
}

class _$EventUploadResultItemSerializer implements PrimitiveSerializer<EventUploadResultItem> {
  @override
  final Iterable<Type> types = const [EventUploadResultItem, _$EventUploadResultItem];

  @override
  final String wireName = r'EventUploadResultItem';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EventUploadResultItem object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(EventUploadResultItemStatusEnum),
    );
    if (object.reason != null) {
      yield r'reason';
      yield serializers.serialize(
        object.reason,
        specifiedType: const FullType.nullable(RejectionReason),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    EventUploadResultItem object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EventUploadResultItemBuilder result,
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
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(EventUploadResultItemStatusEnum),
          ) as EventUploadResultItemStatusEnum;
          result.status = valueDes;
          break;
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(RejectionReason),
          ) as RejectionReason?;
          if (valueDes == null) continue;
          result.reason.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EventUploadResultItem deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EventUploadResultItemBuilder();
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

class EventUploadResultItemStatusEnum extends EnumClass {

  /// accepted：已接收入库；duplicate：这个 ID 之前已经收到过，原记录未改动；rejected：没通过登记表校验，未入库，见 reason
  @BuiltValueEnumConst(wireName: r'accepted')
  static const EventUploadResultItemStatusEnum accepted = _$eventUploadResultItemStatusEnum_accepted;
  /// accepted：已接收入库；duplicate：这个 ID 之前已经收到过，原记录未改动；rejected：没通过登记表校验，未入库，见 reason
  @BuiltValueEnumConst(wireName: r'duplicate')
  static const EventUploadResultItemStatusEnum duplicate = _$eventUploadResultItemStatusEnum_duplicate;
  /// accepted：已接收入库；duplicate：这个 ID 之前已经收到过，原记录未改动；rejected：没通过登记表校验，未入库，见 reason
  @BuiltValueEnumConst(wireName: r'rejected')
  static const EventUploadResultItemStatusEnum rejected = _$eventUploadResultItemStatusEnum_rejected;

  static Serializer<EventUploadResultItemStatusEnum> get serializer => _$eventUploadResultItemStatusEnumSerializer;

  const EventUploadResultItemStatusEnum._(String name): super(name);

  static BuiltSet<EventUploadResultItemStatusEnum> get values => _$eventUploadResultItemStatusEnumValues;
  static EventUploadResultItemStatusEnum valueOf(String name) => _$eventUploadResultItemStatusEnumValueOf(name);
}

