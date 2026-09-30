//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'email_reauth_request.g.dart';

/// EmailReauthRequest
///
/// Properties:
/// * [email] 
/// * [code] 
@BuiltValue()
abstract class EmailReauthRequest implements Built<EmailReauthRequest, EmailReauthRequestBuilder> {
  @BuiltValueField(wireName: r'email')
  String get email;

  @BuiltValueField(wireName: r'code')
  String get code;

  EmailReauthRequest._();

  factory EmailReauthRequest([void updates(EmailReauthRequestBuilder b)]) = _$EmailReauthRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EmailReauthRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EmailReauthRequest> get serializer => _$EmailReauthRequestSerializer();
}

class _$EmailReauthRequestSerializer implements PrimitiveSerializer<EmailReauthRequest> {
  @override
  final Iterable<Type> types = const [EmailReauthRequest, _$EmailReauthRequest];

  @override
  final String wireName = r'EmailReauthRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EmailReauthRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'email';
    yield serializers.serialize(
      object.email,
      specifiedType: const FullType(String),
    );
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    EmailReauthRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EmailReauthRequestBuilder result,
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
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.code = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EmailReauthRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EmailReauthRequestBuilder();
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

