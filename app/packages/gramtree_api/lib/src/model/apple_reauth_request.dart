//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'apple_reauth_request.g.dart';

/// AppleReauthRequest
///
/// Properties:
/// * [identityToken] 
@BuiltValue()
abstract class AppleReauthRequest implements Built<AppleReauthRequest, AppleReauthRequestBuilder> {
  @BuiltValueField(wireName: r'identity_token')
  String get identityToken;

  AppleReauthRequest._();

  factory AppleReauthRequest([void updates(AppleReauthRequestBuilder b)]) = _$AppleReauthRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AppleReauthRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AppleReauthRequest> get serializer => _$AppleReauthRequestSerializer();
}

class _$AppleReauthRequestSerializer implements PrimitiveSerializer<AppleReauthRequest> {
  @override
  final Iterable<Type> types = const [AppleReauthRequest, _$AppleReauthRequest];

  @override
  final String wireName = r'AppleReauthRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AppleReauthRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'identity_token';
    yield serializers.serialize(
      object.identityToken,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AppleReauthRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AppleReauthRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'identity_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.identityToken = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AppleReauthRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AppleReauthRequestBuilder();
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

