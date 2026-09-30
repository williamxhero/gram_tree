//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'consent_record_output.g.dart';

/// ConsentRecordOutput
///
/// Properties:
/// * [id] - 客户端生成的 UUID v4，重复上传按它去重
/// * [kind] 
/// * [version] 
/// * [action] 
/// * [occurredAt] 
/// * [deviceId] 
@BuiltValue()
abstract class ConsentRecordOutput implements Built<ConsentRecordOutput, ConsentRecordOutputBuilder> {
  /// 客户端生成的 UUID v4，重复上传按它去重
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'kind')
  ConsentRecordOutputKindEnum get kind;
  // enum kindEnum {  terms,  privacy,  sensitive_personal_info,  product_analytics,  };

  @BuiltValueField(wireName: r'version')
  String get version;

  @BuiltValueField(wireName: r'action')
  ConsentRecordOutputActionEnum get action;
  // enum actionEnum {  agree,  withdraw,  };

  @BuiltValueField(wireName: r'occurred_at')
  String get occurredAt;

  @BuiltValueField(wireName: r'device_id')
  String? get deviceId;

  ConsentRecordOutput._();

  factory ConsentRecordOutput([void updates(ConsentRecordOutputBuilder b)]) = _$ConsentRecordOutput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ConsentRecordOutputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ConsentRecordOutput> get serializer => _$ConsentRecordOutputSerializer();
}

class _$ConsentRecordOutputSerializer implements PrimitiveSerializer<ConsentRecordOutput> {
  @override
  final Iterable<Type> types = const [ConsentRecordOutput, _$ConsentRecordOutput];

  @override
  final String wireName = r'ConsentRecordOutput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ConsentRecordOutput object, {
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
      specifiedType: const FullType(ConsentRecordOutputKindEnum),
    );
    yield r'version';
    yield serializers.serialize(
      object.version,
      specifiedType: const FullType(String),
    );
    yield r'action';
    yield serializers.serialize(
      object.action,
      specifiedType: const FullType(ConsentRecordOutputActionEnum),
    );
    yield r'occurred_at';
    yield serializers.serialize(
      object.occurredAt,
      specifiedType: const FullType(String),
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
    ConsentRecordOutput object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ConsentRecordOutputBuilder result,
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
            specifiedType: const FullType(ConsentRecordOutputKindEnum),
          ) as ConsentRecordOutputKindEnum;
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
            specifiedType: const FullType(ConsentRecordOutputActionEnum),
          ) as ConsentRecordOutputActionEnum;
          result.action = valueDes;
          break;
        case r'occurred_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
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
  ConsentRecordOutput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ConsentRecordOutputBuilder();
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

class ConsentRecordOutputKindEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'terms')
  static const ConsentRecordOutputKindEnum terms = _$consentRecordOutputKindEnum_terms;
  @BuiltValueEnumConst(wireName: r'privacy')
  static const ConsentRecordOutputKindEnum privacy = _$consentRecordOutputKindEnum_privacy;
  @BuiltValueEnumConst(wireName: r'sensitive_personal_info')
  static const ConsentRecordOutputKindEnum sensitivePersonalInfo = _$consentRecordOutputKindEnum_sensitivePersonalInfo;
  @BuiltValueEnumConst(wireName: r'product_analytics')
  static const ConsentRecordOutputKindEnum productAnalytics = _$consentRecordOutputKindEnum_productAnalytics;

  static Serializer<ConsentRecordOutputKindEnum> get serializer => _$consentRecordOutputKindEnumSerializer;

  const ConsentRecordOutputKindEnum._(String name): super(name);

  static BuiltSet<ConsentRecordOutputKindEnum> get values => _$consentRecordOutputKindEnumValues;
  static ConsentRecordOutputKindEnum valueOf(String name) => _$consentRecordOutputKindEnumValueOf(name);
}

class ConsentRecordOutputActionEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'agree')
  static const ConsentRecordOutputActionEnum agree = _$consentRecordOutputActionEnum_agree;
  @BuiltValueEnumConst(wireName: r'withdraw')
  static const ConsentRecordOutputActionEnum withdraw = _$consentRecordOutputActionEnum_withdraw;

  static Serializer<ConsentRecordOutputActionEnum> get serializer => _$consentRecordOutputActionEnumSerializer;

  const ConsentRecordOutputActionEnum._(String name): super(name);

  static BuiltSet<ConsentRecordOutputActionEnum> get values => _$consentRecordOutputActionEnumValues;
  static ConsentRecordOutputActionEnum valueOf(String name) => _$consentRecordOutputActionEnumValueOf(name);
}

