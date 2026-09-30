//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'identity_out.g.dart';

/// IdentityOut
///
/// Properties:
/// * [kind] 
/// * [email] 
/// * [createdAt] 
@BuiltValue()
abstract class IdentityOut implements Built<IdentityOut, IdentityOutBuilder> {
  @BuiltValueField(wireName: r'kind')
  IdentityOutKindEnum get kind;
  // enum kindEnum {  email,  apple,  phone,  wechat,  };

  @BuiltValueField(wireName: r'email')
  String? get email;

  @BuiltValueField(wireName: r'created_at')
  String get createdAt;

  IdentityOut._();

  factory IdentityOut([void updates(IdentityOutBuilder b)]) = _$IdentityOut;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(IdentityOutBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<IdentityOut> get serializer => _$IdentityOutSerializer();
}

class _$IdentityOutSerializer implements PrimitiveSerializer<IdentityOut> {
  @override
  final Iterable<Type> types = const [IdentityOut, _$IdentityOut];

  @override
  final String wireName = r'IdentityOut';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    IdentityOut object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'kind';
    yield serializers.serialize(
      object.kind,
      specifiedType: const FullType(IdentityOutKindEnum),
    );
    yield r'email';
    yield object.email == null ? null : serializers.serialize(
      object.email,
      specifiedType: const FullType.nullable(String),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    IdentityOut object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required IdentityOutBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'kind':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(IdentityOutKindEnum),
          ) as IdentityOutKindEnum;
          result.kind = valueDes;
          break;
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.email = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.createdAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  IdentityOut deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = IdentityOutBuilder();
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

class IdentityOutKindEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'email')
  static const IdentityOutKindEnum email = _$identityOutKindEnum_email;
  @BuiltValueEnumConst(wireName: r'apple')
  static const IdentityOutKindEnum apple = _$identityOutKindEnum_apple;
  @BuiltValueEnumConst(wireName: r'phone')
  static const IdentityOutKindEnum phone = _$identityOutKindEnum_phone;
  @BuiltValueEnumConst(wireName: r'wechat')
  static const IdentityOutKindEnum wechat = _$identityOutKindEnum_wechat;

  static Serializer<IdentityOutKindEnum> get serializer => _$identityOutKindEnumSerializer;

  const IdentityOutKindEnum._(String name): super(name);

  static BuiltSet<IdentityOutKindEnum> get values => _$identityOutKindEnumValues;
  static IdentityOutKindEnum valueOf(String name) => _$identityOutKindEnumValueOf(name);
}

