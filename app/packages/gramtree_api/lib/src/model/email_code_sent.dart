//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'email_code_sent.g.dart';

/// EmailCodeSent
///
/// Properties:
/// * [resendAfterSeconds] 
/// * [expiresInSeconds] 
@BuiltValue()
abstract class EmailCodeSent implements Built<EmailCodeSent, EmailCodeSentBuilder> {
  @BuiltValueField(wireName: r'resend_after_seconds')
  int get resendAfterSeconds;

  @BuiltValueField(wireName: r'expires_in_seconds')
  int get expiresInSeconds;

  EmailCodeSent._();

  factory EmailCodeSent([void updates(EmailCodeSentBuilder b)]) = _$EmailCodeSent;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EmailCodeSentBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EmailCodeSent> get serializer => _$EmailCodeSentSerializer();
}

class _$EmailCodeSentSerializer implements PrimitiveSerializer<EmailCodeSent> {
  @override
  final Iterable<Type> types = const [EmailCodeSent, _$EmailCodeSent];

  @override
  final String wireName = r'EmailCodeSent';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EmailCodeSent object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'resend_after_seconds';
    yield serializers.serialize(
      object.resendAfterSeconds,
      specifiedType: const FullType(int),
    );
    yield r'expires_in_seconds';
    yield serializers.serialize(
      object.expiresInSeconds,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    EmailCodeSent object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EmailCodeSentBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'resend_after_seconds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.resendAfterSeconds = valueDes;
          break;
        case r'expires_in_seconds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.expiresInSeconds = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EmailCodeSent deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EmailCodeSentBuilder();
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

