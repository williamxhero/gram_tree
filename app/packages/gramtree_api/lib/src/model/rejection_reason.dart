//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'rejection_reason.g.dart';

/// RejectionReason
///
/// Properties:
/// * [code] - 程序可判断的拒收原因代码：unknown_event_type / unsupported_version / invalid_content / invalid_correlation_id
/// * [message] - 给人看的一句话说明，不包含事件内容本身
@BuiltValue()
abstract class RejectionReason implements Built<RejectionReason, RejectionReasonBuilder> {
  /// 程序可判断的拒收原因代码：unknown_event_type / unsupported_version / invalid_content / invalid_correlation_id
  @BuiltValueField(wireName: r'code')
  String get code;

  /// 给人看的一句话说明，不包含事件内容本身
  @BuiltValueField(wireName: r'message')
  String get message;

  RejectionReason._();

  factory RejectionReason([void updates(RejectionReasonBuilder b)]) = _$RejectionReason;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RejectionReasonBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RejectionReason> get serializer => _$RejectionReasonSerializer();
}

class _$RejectionReasonSerializer implements PrimitiveSerializer<RejectionReason> {
  @override
  final Iterable<Type> types = const [RejectionReason, _$RejectionReason];

  @override
  final String wireName = r'RejectionReason';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RejectionReason object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(String),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RejectionReason object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RejectionReasonBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.code = valueDes;
          break;
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.message = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RejectionReason deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RejectionReasonBuilder();
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

