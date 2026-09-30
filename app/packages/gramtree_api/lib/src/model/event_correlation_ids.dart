//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'event_correlation_ids.g.dart';

/// 关联 ID：都可以留空。这些字段名是所有事件类型统一使用的命名， 后面新增的关联类型也照这个模式加字段，不要另起一套命名。  这里只要求\"是字符串\"，不在 pydantic 层面强制 UUID v4 格式——格式是否合法放在 `gramtree.events.validation` 里按条判断，不合法的那一条被单独拒收 （原因码 `invalid_correlation_id`），不会拖累同一批里其它合格的事件。
///
/// Properties:
/// * [recipeVersionId] 
/// * [cookingRecordId] 
/// * [uiCompositionId] 
/// * [tasteProfileChangeId] 
/// * [planId] 
/// * [recommendationExposureId] 
/// * [suggestionId] 
@BuiltValue()
abstract class EventCorrelationIds implements Built<EventCorrelationIds, EventCorrelationIdsBuilder> {
  @BuiltValueField(wireName: r'recipe_version_id')
  String? get recipeVersionId;

  @BuiltValueField(wireName: r'cooking_record_id')
  String? get cookingRecordId;

  @BuiltValueField(wireName: r'ui_composition_id')
  String? get uiCompositionId;

  @BuiltValueField(wireName: r'taste_profile_change_id')
  String? get tasteProfileChangeId;

  @BuiltValueField(wireName: r'plan_id')
  String? get planId;

  @BuiltValueField(wireName: r'recommendation_exposure_id')
  String? get recommendationExposureId;

  @BuiltValueField(wireName: r'suggestion_id')
  String? get suggestionId;

  EventCorrelationIds._();

  factory EventCorrelationIds([void updates(EventCorrelationIdsBuilder b)]) = _$EventCorrelationIds;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EventCorrelationIdsBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EventCorrelationIds> get serializer => _$EventCorrelationIdsSerializer();
}

class _$EventCorrelationIdsSerializer implements PrimitiveSerializer<EventCorrelationIds> {
  @override
  final Iterable<Type> types = const [EventCorrelationIds, _$EventCorrelationIds];

  @override
  final String wireName = r'EventCorrelationIds';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EventCorrelationIds object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.recipeVersionId != null) {
      yield r'recipe_version_id';
      yield serializers.serialize(
        object.recipeVersionId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.cookingRecordId != null) {
      yield r'cooking_record_id';
      yield serializers.serialize(
        object.cookingRecordId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.uiCompositionId != null) {
      yield r'ui_composition_id';
      yield serializers.serialize(
        object.uiCompositionId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.tasteProfileChangeId != null) {
      yield r'taste_profile_change_id';
      yield serializers.serialize(
        object.tasteProfileChangeId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.planId != null) {
      yield r'plan_id';
      yield serializers.serialize(
        object.planId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.recommendationExposureId != null) {
      yield r'recommendation_exposure_id';
      yield serializers.serialize(
        object.recommendationExposureId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.suggestionId != null) {
      yield r'suggestion_id';
      yield serializers.serialize(
        object.suggestionId,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    EventCorrelationIds object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EventCorrelationIdsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'recipe_version_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.recipeVersionId = valueDes;
          break;
        case r'cooking_record_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.cookingRecordId = valueDes;
          break;
        case r'ui_composition_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.uiCompositionId = valueDes;
          break;
        case r'taste_profile_change_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.tasteProfileChangeId = valueDes;
          break;
        case r'plan_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.planId = valueDes;
          break;
        case r'recommendation_exposure_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.recommendationExposureId = valueDes;
          break;
        case r'suggestion_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.suggestionId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EventCorrelationIds deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EventCorrelationIdsBuilder();
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

