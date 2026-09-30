//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:gramtree_api/src/model/action_descriptor.dart';
import 'package:gramtree_api/src/model/component_reason.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'component_descriptor.g.dart';

/// ComponentDescriptor
///
/// Properties:
/// * [type] - 组件类型名，必须是 App 声明支持的组件
/// * [id] - 这份描述里的组件实例 ID
/// * [detail] 
/// * [data] - 组件数据，形状由该 type 的组件 Schema 定义
/// * [actions] 
/// * [reason] 
/// * [required_] - 是否是必显组件
@BuiltValue()
abstract class ComponentDescriptor implements Built<ComponentDescriptor, ComponentDescriptorBuilder> {
  /// 组件类型名，必须是 App 声明支持的组件
  @BuiltValueField(wireName: r'type')
  String get type;

  /// 这份描述里的组件实例 ID
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'detail')
  ComponentDescriptorDetailEnum get detail;
  // enum detailEnum {  brief,  standard,  detailed,  };

  /// 组件数据，形状由该 type 的组件 Schema 定义
  @BuiltValueField(wireName: r'data')
  BuiltMap<String, JsonObject?> get data;

  @BuiltValueField(wireName: r'actions')
  BuiltList<ActionDescriptor>? get actions;

  @BuiltValueField(wireName: r'reason')
  ComponentReason get reason;

  /// 是否是必显组件
  @BuiltValueField(wireName: r'required')
  bool? get required_;

  ComponentDescriptor._();

  factory ComponentDescriptor([void updates(ComponentDescriptorBuilder b)]) = _$ComponentDescriptor;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ComponentDescriptorBuilder b) => b
      ..required_ = false;

  @BuiltValueSerializer(custom: true)
  static Serializer<ComponentDescriptor> get serializer => _$ComponentDescriptorSerializer();
}

class _$ComponentDescriptorSerializer implements PrimitiveSerializer<ComponentDescriptor> {
  @override
  final Iterable<Type> types = const [ComponentDescriptor, _$ComponentDescriptor];

  @override
  final String wireName = r'ComponentDescriptor';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ComponentDescriptor object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(String),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'detail';
    yield serializers.serialize(
      object.detail,
      specifiedType: const FullType(ComponentDescriptorDetailEnum),
    );
    yield r'data';
    yield serializers.serialize(
      object.data,
      specifiedType: const FullType(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
    );
    if (object.actions != null) {
      yield r'actions';
      yield serializers.serialize(
        object.actions,
        specifiedType: const FullType(BuiltList, [FullType(ActionDescriptor)]),
      );
    }
    yield r'reason';
    yield serializers.serialize(
      object.reason,
      specifiedType: const FullType(ComponentReason),
    );
    if (object.required_ != null) {
      yield r'required';
      yield serializers.serialize(
        object.required_,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ComponentDescriptor object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ComponentDescriptorBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.type = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'detail':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ComponentDescriptorDetailEnum),
          ) as ComponentDescriptorDetailEnum;
          result.detail = valueDes;
          break;
        case r'data':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
          ) as BuiltMap<String, JsonObject?>;
          result.data.replace(valueDes);
          break;
        case r'actions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ActionDescriptor)]),
          ) as BuiltList<ActionDescriptor>;
          result.actions.replace(valueDes);
          break;
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ComponentReason),
          ) as ComponentReason;
          result.reason.replace(valueDes);
          break;
        case r'required':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.required_ = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ComponentDescriptor deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ComponentDescriptorBuilder();
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

class ComponentDescriptorDetailEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'brief')
  static const ComponentDescriptorDetailEnum brief = _$componentDescriptorDetailEnum_brief;
  @BuiltValueEnumConst(wireName: r'standard')
  static const ComponentDescriptorDetailEnum standard = _$componentDescriptorDetailEnum_standard;
  @BuiltValueEnumConst(wireName: r'detailed')
  static const ComponentDescriptorDetailEnum detailed = _$componentDescriptorDetailEnum_detailed;

  static Serializer<ComponentDescriptorDetailEnum> get serializer => _$componentDescriptorDetailEnumSerializer;

  const ComponentDescriptorDetailEnum._(String name): super(name);

  static BuiltSet<ComponentDescriptorDetailEnum> get values => _$componentDescriptorDetailEnumValues;
  static ComponentDescriptorDetailEnum valueOf(String name) => _$componentDescriptorDetailEnumValueOf(name);
}

