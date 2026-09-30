//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'component_reason.g.dart';

/// ComponentReason
///
/// Properties:
/// * [code] - 理由代码，例如 default
/// * [text] - 给人看的一句话说明
@BuiltValue()
abstract class ComponentReason implements Built<ComponentReason, ComponentReasonBuilder> {
  /// 理由代码，例如 default
  @BuiltValueField(wireName: r'code')
  String get code;

  /// 给人看的一句话说明
  @BuiltValueField(wireName: r'text')
  String get text;

  ComponentReason._();

  factory ComponentReason([void updates(ComponentReasonBuilder b)]) = _$ComponentReason;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ComponentReasonBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ComponentReason> get serializer => _$ComponentReasonSerializer();
}

class _$ComponentReasonSerializer implements PrimitiveSerializer<ComponentReason> {
  @override
  final Iterable<Type> types = const [ComponentReason, _$ComponentReason];

  @override
  final String wireName = r'ComponentReason';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ComponentReason object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(String),
    );
    yield r'text';
    yield serializers.serialize(
      object.text,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ComponentReason object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ComponentReasonBuilder result,
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
        case r'text':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.text = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ComponentReason deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ComponentReasonBuilder();
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

