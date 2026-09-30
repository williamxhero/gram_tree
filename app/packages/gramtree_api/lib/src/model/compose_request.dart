//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'compose_request.g.dart';

/// ComposeRequest
///
/// Properties:
/// * [pageType] - 要哪个页面类型的组合，例如 today
/// * [protocolVersion] - App 自己实现的协议版本，例如 1.0
/// * [supportedComponents] - App 已登记、认识的组件类型清单；服务端只会下发这里面的类型
@BuiltValue()
abstract class ComposeRequest implements Built<ComposeRequest, ComposeRequestBuilder> {
  /// 要哪个页面类型的组合，例如 today
  @BuiltValueField(wireName: r'page_type')
  String get pageType;

  /// App 自己实现的协议版本，例如 1.0
  @BuiltValueField(wireName: r'protocol_version')
  String get protocolVersion;

  /// App 已登记、认识的组件类型清单；服务端只会下发这里面的类型
  @BuiltValueField(wireName: r'supported_components')
  BuiltList<String>? get supportedComponents;

  ComposeRequest._();

  factory ComposeRequest([void updates(ComposeRequestBuilder b)]) = _$ComposeRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ComposeRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ComposeRequest> get serializer => _$ComposeRequestSerializer();
}

class _$ComposeRequestSerializer implements PrimitiveSerializer<ComposeRequest> {
  @override
  final Iterable<Type> types = const [ComposeRequest, _$ComposeRequest];

  @override
  final String wireName = r'ComposeRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ComposeRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'page_type';
    yield serializers.serialize(
      object.pageType,
      specifiedType: const FullType(String),
    );
    yield r'protocol_version';
    yield serializers.serialize(
      object.protocolVersion,
      specifiedType: const FullType(String),
    );
    if (object.supportedComponents != null) {
      yield r'supported_components';
      yield serializers.serialize(
        object.supportedComponents,
        specifiedType: const FullType(BuiltList, [FullType(String)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ComposeRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ComposeRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'page_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.pageType = valueDes;
          break;
        case r'protocol_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.protocolVersion = valueDes;
          break;
        case r'supported_components':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.supportedComponents.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ComposeRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ComposeRequestBuilder();
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

