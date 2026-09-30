//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:gramtree_api/src/model/cache_info.dart';
import 'package:gramtree_api/src/model/component_descriptor.dart';
import 'package:gramtree_api/src/model/fallback_info.dart';
import 'package:gramtree_api/src/model/experiment_info.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'page_description.g.dart';

/// PageDescription
///
/// Properties:
/// * [protocol] - 协议版本，大版本.小版本，例如 1.0
/// * [pageType] 
/// * [compositionId] 
/// * [generatedAt] 
/// * [cache] 
/// * [experiment] 
/// * [fallback] 
/// * [components] 
@BuiltValue()
abstract class PageDescription implements Built<PageDescription, PageDescriptionBuilder> {
  /// 协议版本，大版本.小版本，例如 1.0
  @BuiltValueField(wireName: r'protocol')
  String get protocol;

  @BuiltValueField(wireName: r'page_type')
  String get pageType;

  @BuiltValueField(wireName: r'composition_id')
  String get compositionId;

  @BuiltValueField(wireName: r'generated_at')
  String get generatedAt;

  @BuiltValueField(wireName: r'cache')
  CacheInfo get cache;

  @BuiltValueField(wireName: r'experiment')
  ExperimentInfo? get experiment;

  @BuiltValueField(wireName: r'fallback')
  FallbackInfo? get fallback;

  @BuiltValueField(wireName: r'components')
  BuiltList<ComponentDescriptor>? get components;

  PageDescription._();

  factory PageDescription([void updates(PageDescriptionBuilder b)]) = _$PageDescription;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PageDescriptionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PageDescription> get serializer => _$PageDescriptionSerializer();
}

class _$PageDescriptionSerializer implements PrimitiveSerializer<PageDescription> {
  @override
  final Iterable<Type> types = const [PageDescription, _$PageDescription];

  @override
  final String wireName = r'PageDescription';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PageDescription object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'protocol';
    yield serializers.serialize(
      object.protocol,
      specifiedType: const FullType(String),
    );
    yield r'page_type';
    yield serializers.serialize(
      object.pageType,
      specifiedType: const FullType(String),
    );
    yield r'composition_id';
    yield serializers.serialize(
      object.compositionId,
      specifiedType: const FullType(String),
    );
    yield r'generated_at';
    yield serializers.serialize(
      object.generatedAt,
      specifiedType: const FullType(String),
    );
    yield r'cache';
    yield serializers.serialize(
      object.cache,
      specifiedType: const FullType(CacheInfo),
    );
    if (object.experiment != null) {
      yield r'experiment';
      yield serializers.serialize(
        object.experiment,
        specifiedType: const FullType.nullable(ExperimentInfo),
      );
    }
    if (object.fallback != null) {
      yield r'fallback';
      yield serializers.serialize(
        object.fallback,
        specifiedType: const FullType.nullable(FallbackInfo),
      );
    }
    if (object.components != null) {
      yield r'components';
      yield serializers.serialize(
        object.components,
        specifiedType: const FullType(BuiltList, [FullType(ComponentDescriptor)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PageDescription object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PageDescriptionBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'protocol':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.protocol = valueDes;
          break;
        case r'page_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.pageType = valueDes;
          break;
        case r'composition_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.compositionId = valueDes;
          break;
        case r'generated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.generatedAt = valueDes;
          break;
        case r'cache':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CacheInfo),
          ) as CacheInfo;
          result.cache.replace(valueDes);
          break;
        case r'experiment':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(ExperimentInfo),
          ) as ExperimentInfo?;
          if (valueDes == null) continue;
          result.experiment.replace(valueDes);
          break;
        case r'fallback':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(FallbackInfo),
          ) as FallbackInfo?;
          if (valueDes == null) continue;
          result.fallback.replace(valueDes);
          break;
        case r'components':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ComponentDescriptor)]),
          ) as BuiltList<ComponentDescriptor>;
          result.components.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PageDescription deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PageDescriptionBuilder();
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

