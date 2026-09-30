//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'fallback_info.g.dart';

/// FallbackInfo
///
/// Properties:
/// * [reasonCode] 
@BuiltValue()
abstract class FallbackInfo implements Built<FallbackInfo, FallbackInfoBuilder> {
  @BuiltValueField(wireName: r'reason_code')
  FallbackInfoReasonCodeEnum get reasonCode;
  // enum reasonCodeEnum {  unknown_major,  unknown_component,  illegal_action,  invalid_data,  missing_required,  server_error,  timeout,  };

  FallbackInfo._();

  factory FallbackInfo([void updates(FallbackInfoBuilder b)]) = _$FallbackInfo;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FallbackInfoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FallbackInfo> get serializer => _$FallbackInfoSerializer();
}

class _$FallbackInfoSerializer implements PrimitiveSerializer<FallbackInfo> {
  @override
  final Iterable<Type> types = const [FallbackInfo, _$FallbackInfo];

  @override
  final String wireName = r'FallbackInfo';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FallbackInfo object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'reason_code';
    yield serializers.serialize(
      object.reasonCode,
      specifiedType: const FullType(FallbackInfoReasonCodeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FallbackInfo object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FallbackInfoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'reason_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(FallbackInfoReasonCodeEnum),
          ) as FallbackInfoReasonCodeEnum;
          result.reasonCode = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FallbackInfo deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FallbackInfoBuilder();
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

class FallbackInfoReasonCodeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'unknown_major')
  static const FallbackInfoReasonCodeEnum unknownMajor = _$fallbackInfoReasonCodeEnum_unknownMajor;
  @BuiltValueEnumConst(wireName: r'unknown_component')
  static const FallbackInfoReasonCodeEnum unknownComponent = _$fallbackInfoReasonCodeEnum_unknownComponent;
  @BuiltValueEnumConst(wireName: r'illegal_action')
  static const FallbackInfoReasonCodeEnum illegalAction = _$fallbackInfoReasonCodeEnum_illegalAction;
  @BuiltValueEnumConst(wireName: r'invalid_data')
  static const FallbackInfoReasonCodeEnum invalidData = _$fallbackInfoReasonCodeEnum_invalidData;
  @BuiltValueEnumConst(wireName: r'missing_required')
  static const FallbackInfoReasonCodeEnum missingRequired = _$fallbackInfoReasonCodeEnum_missingRequired;
  @BuiltValueEnumConst(wireName: r'server_error')
  static const FallbackInfoReasonCodeEnum serverError = _$fallbackInfoReasonCodeEnum_serverError;
  @BuiltValueEnumConst(wireName: r'timeout')
  static const FallbackInfoReasonCodeEnum timeout = _$fallbackInfoReasonCodeEnum_timeout;

  static Serializer<FallbackInfoReasonCodeEnum> get serializer => _$fallbackInfoReasonCodeEnumSerializer;

  const FallbackInfoReasonCodeEnum._(String name): super(name);

  static BuiltSet<FallbackInfoReasonCodeEnum> get values => _$fallbackInfoReasonCodeEnumValues;
  static FallbackInfoReasonCodeEnum valueOf(String name) => _$fallbackInfoReasonCodeEnumValueOf(name);
}

