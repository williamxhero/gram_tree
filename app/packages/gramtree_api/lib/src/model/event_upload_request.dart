//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:gramtree_api/src/model/event_upload_item.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'event_upload_request.g.dart';

/// EventUploadRequest
///
/// Properties:
/// * [events] 
@BuiltValue()
abstract class EventUploadRequest implements Built<EventUploadRequest, EventUploadRequestBuilder> {
  @BuiltValueField(wireName: r'events')
  BuiltList<EventUploadItem> get events;

  EventUploadRequest._();

  factory EventUploadRequest([void updates(EventUploadRequestBuilder b)]) = _$EventUploadRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EventUploadRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EventUploadRequest> get serializer => _$EventUploadRequestSerializer();
}

class _$EventUploadRequestSerializer implements PrimitiveSerializer<EventUploadRequest> {
  @override
  final Iterable<Type> types = const [EventUploadRequest, _$EventUploadRequest];

  @override
  final String wireName = r'EventUploadRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EventUploadRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'events';
    yield serializers.serialize(
      object.events,
      specifiedType: const FullType(BuiltList, [FullType(EventUploadItem)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    EventUploadRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EventUploadRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'events':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(EventUploadItem)]),
          ) as BuiltList<EventUploadItem>;
          result.events.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EventUploadRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EventUploadRequestBuilder();
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

