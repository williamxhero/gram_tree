//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'consent_record_input.g.dart';

/// ConsentRecordInput
///
/// Properties:
/// * [id] - 客户端生成的 UUID v4，重复上传按它去重
/// * [kind] 
/// * [version] 
/// * [action] 
/// * [occurredAt] 
/// * [deviceId] 
@BuiltValue()
abstract class ConsentRecordInput implements Built<ConsentRecordInput, ConsentRecordInputBuilder> {
  /// 客户端生成的 UUID v4，重复上传按它去重
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'kind')
  ConsentRecordInputKindEnum get kind;
  // enum kindEnum {  terms,  privacy,  sensitive_personal_info,  product_analytics,  };

  @BuiltValueField(wireName: r'version')
  String get version;

  @BuiltValueField(wireName: r'action')
  ConsentRecordInputActionEnum get action;
  // enum actionEnum {  agree,  withdraw,  };

  @BuiltValueField(wireName: r'occurred_at')
  DateTime get occurredAt;

  @BuiltValueField(wireName: r'device_id')
  String? get deviceId;

  ConsentRecordInput._();

  factory ConsentRecordInput([void updates(ConsentRecordInputBuilder b)]) = _$ConsentRecordInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ConsentRecordInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ConsentRecordInput> get serializer => _$ConsentRecordInputSerializer();
}

class _$ConsentRecordInputSerializer implements PrimitiveSerializer<ConsentRecordInput> {
  @override
  final Iterable<Type> types = const [ConsentRecordInput, _$ConsentRecordInput];

  @override
  final String wireName = r'ConsentRecordInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ConsentRecordInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'kind';
    yield serializers.serialize(
      object.kind,
      specifiedType: const FullType(ConsentRecordInputKindEnum),
    );
    yield r'version';
    yield serializers.serialize(
      object.version,
      specifiedType: const FullType(String),
    );
    yield r'action';
    yield serializers.serialize(
      object.action,
      specifiedType: const FullType(ConsentRecordInputActionEnum),
    );
    yield r'occurred_at';
    yield serializers.serialize(
      object.occurredAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.deviceId != null) {
      yield r'device_id';
      yield serializers.serialize(
        object.deviceId,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ConsentRecordInput object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ConsentRecordInputBuilder result,
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
        case r'kind':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ConsentRecordInputKindEnum),
          ) as ConsentRecordInputKindEnum;
          result.kind = valueDes;
          break;
        case r'version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.version = valueDes;
          break;
        case r'action':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ConsentRecordInputActionEnum),
          ) as ConsentRecordInputActionEnum;
          result.action = valueDes;
          break;
        case r'occurred_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.occurredAt = valueDes;
          break;
        case r'device_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.deviceId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ConsentRecordInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ConsentRecordInputBuilder();
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

class ConsentRecordInputKindEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'terms')
  static const ConsentRecordInputKindEnum terms = _$consentRecordInputKindEnum_terms;
  @BuiltValueEnumConst(wireName: r'privacy')
  static const ConsentRecordInputKindEnum privacy = _$consentRecordInputKindEnum_privacy;
  @BuiltValueEnumConst(wireName: r'sensitive_personal_info')
  static const ConsentRecordInputKindEnum sensitivePersonalInfo = _$consentRecordInputKindEnum_sensitivePersonalInfo;
  @BuiltValueEnumConst(wireName: r'product_analytics')
  static const ConsentRecordInputKindEnum productAnalytics = _$consentRecordInputKindEnum_productAnalytics;

  static Serializer<ConsentRecordInputKindEnum> get serializer => _$consentRecordInputKindEnumSerializer;

  const ConsentRecordInputKindEnum._(String name): super(name);

  static BuiltSet<ConsentRecordInputKindEnum> get values => _$consentRecordInputKindEnumValues;
  static ConsentRecordInputKindEnum valueOf(String name) => _$consentRecordInputKindEnumValueOf(name);
}

class ConsentRecordInputActionEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'agree')
  static const ConsentRecordInputActionEnum agree = _$consentRecordInputActionEnum_agree;
  @BuiltValueEnumConst(wireName: r'withdraw')
  static const ConsentRecordInputActionEnum withdraw = _$consentRecordInputActionEnum_withdraw;

  static Serializer<ConsentRecordInputActionEnum> get serializer => _$consentRecordInputActionEnumSerializer;

  const ConsentRecordInputActionEnum._(String name): super(name);

  static BuiltSet<ConsentRecordInputActionEnum> get values => _$consentRecordInputActionEnumValues;
  static ConsentRecordInputActionEnum valueOf(String name) => _$consentRecordInputActionEnumValueOf(name);
}

