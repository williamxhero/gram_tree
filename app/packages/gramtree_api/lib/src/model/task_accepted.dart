//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'task_accepted.g.dart';

/// TaskAccepted
///
/// Properties:
/// * [taskId] 
@BuiltValue()
abstract class TaskAccepted implements Built<TaskAccepted, TaskAcceptedBuilder> {
  @BuiltValueField(wireName: r'task_id')
  String get taskId;

  TaskAccepted._();

  factory TaskAccepted([void updates(TaskAcceptedBuilder b)]) = _$TaskAccepted;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TaskAcceptedBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TaskAccepted> get serializer => _$TaskAcceptedSerializer();
}

class _$TaskAcceptedSerializer implements PrimitiveSerializer<TaskAccepted> {
  @override
  final Iterable<Type> types = const [TaskAccepted, _$TaskAccepted];

  @override
  final String wireName = r'TaskAccepted';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TaskAccepted object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'task_id';
    yield serializers.serialize(
      object.taskId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TaskAccepted object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TaskAcceptedBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'task_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.taskId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TaskAccepted deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TaskAcceptedBuilder();
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

