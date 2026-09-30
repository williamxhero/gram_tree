//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'email_code_request.g.dart';

/// EmailCodeRequest
///
/// Properties:
/// * [email] 
/// * [purpose] 
@BuiltValue()
abstract class EmailCodeRequest implements Built<EmailCodeRequest, EmailCodeRequestBuilder> {
  @BuiltValueField(wireName: r'email')
  String get email;

  @BuiltValueField(wireName: r'purpose')
  EmailCodeRequestPurposeEnum get purpose;
  // enum purposeEnum {  login,  bind,  reauth,  };

  EmailCodeRequest._();

  factory EmailCodeRequest([void updates(EmailCodeRequestBuilder b)]) = _$EmailCodeRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EmailCodeRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EmailCodeRequest> get serializer => _$EmailCodeRequestSerializer();
}

class _$EmailCodeRequestSerializer implements PrimitiveSerializer<EmailCodeRequest> {
  @override
  final Iterable<Type> types = const [EmailCodeRequest, _$EmailCodeRequest];

  @override
  final String wireName = r'EmailCodeRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EmailCodeRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'email';
    yield serializers.serialize(
      object.email,
      specifiedType: const FullType(String),
    );
    yield r'purpose';
    yield serializers.serialize(
      object.purpose,
      specifiedType: const FullType(EmailCodeRequestPurposeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    EmailCodeRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EmailCodeRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.email = valueDes;
          break;
        case r'purpose':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(EmailCodeRequestPurposeEnum),
          ) as EmailCodeRequestPurposeEnum;
          result.purpose = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EmailCodeRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EmailCodeRequestBuilder();
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

class EmailCodeRequestPurposeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'login')
  static const EmailCodeRequestPurposeEnum login = _$emailCodeRequestPurposeEnum_login;
  @BuiltValueEnumConst(wireName: r'bind')
  static const EmailCodeRequestPurposeEnum bind = _$emailCodeRequestPurposeEnum_bind;
  @BuiltValueEnumConst(wireName: r'reauth')
  static const EmailCodeRequestPurposeEnum reauth = _$emailCodeRequestPurposeEnum_reauth;

  static Serializer<EmailCodeRequestPurposeEnum> get serializer => _$emailCodeRequestPurposeEnumSerializer;

  const EmailCodeRequestPurposeEnum._(String name): super(name);

  static BuiltSet<EmailCodeRequestPurposeEnum> get values => _$emailCodeRequestPurposeEnumValues;
  static EmailCodeRequestPurposeEnum valueOf(String name) => _$emailCodeRequestPurposeEnumValueOf(name);
}

