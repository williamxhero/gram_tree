// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modification_operation.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ModificationOperationCWProxy {
  ModificationOperation after(Object? after);

  ModificationOperation before(Object? before);

  ModificationOperation confidence(num confidence);

  ModificationOperation dependsOn(List<String>? dependsOn);

  ModificationOperation field(String field);

  ModificationOperation id(String? id);

  ModificationOperation intent(String intent);

  ModificationOperation operationId(String operationId);

  ModificationOperation reason(String reason);

  ModificationOperation risk(String risk);

  ModificationOperation scope(List<String> scope);

  ModificationOperation type(ModificationOperationTypeEnum type);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModificationOperation(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModificationOperation(...).copyWith(id: 12, name: "My name")
  /// ````
  ModificationOperation call({
    Object? after,
    Object? before,
    num confidence,
    List<String>? dependsOn,
    String field,
    String? id,
    String intent,
    String operationId,
    String reason,
    String risk,
    List<String> scope,
    ModificationOperationTypeEnum type,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfModificationOperation.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfModificationOperation.copyWith.fieldName(...)`
class _$ModificationOperationCWProxyImpl
    implements _$ModificationOperationCWProxy {
  const _$ModificationOperationCWProxyImpl(this._value);

  final ModificationOperation _value;

  @override
  ModificationOperation after(Object? after) => this(after: after);

  @override
  ModificationOperation before(Object? before) => this(before: before);

  @override
  ModificationOperation confidence(num confidence) =>
      this(confidence: confidence);

  @override
  ModificationOperation dependsOn(List<String>? dependsOn) =>
      this(dependsOn: dependsOn);

  @override
  ModificationOperation field(String field) => this(field: field);

  @override
  ModificationOperation id(String? id) => this(id: id);

  @override
  ModificationOperation intent(String intent) => this(intent: intent);

  @override
  ModificationOperation operationId(String operationId) =>
      this(operationId: operationId);

  @override
  ModificationOperation reason(String reason) => this(reason: reason);

  @override
  ModificationOperation risk(String risk) => this(risk: risk);

  @override
  ModificationOperation scope(List<String> scope) => this(scope: scope);

  @override
  ModificationOperation type(ModificationOperationTypeEnum type) =>
      this(type: type);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModificationOperation(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModificationOperation(...).copyWith(id: 12, name: "My name")
  /// ````
  ModificationOperation call({
    Object? after = const $CopyWithPlaceholder(),
    Object? before = const $CopyWithPlaceholder(),
    Object? confidence = const $CopyWithPlaceholder(),
    Object? dependsOn = const $CopyWithPlaceholder(),
    Object? field = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? intent = const $CopyWithPlaceholder(),
    Object? operationId = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? risk = const $CopyWithPlaceholder(),
    Object? scope = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
  }) {
    return ModificationOperation(
      after: after == const $CopyWithPlaceholder()
          ? _value.after
          // ignore: cast_nullable_to_non_nullable
          : after as Object?,
      before: before == const $CopyWithPlaceholder()
          ? _value.before
          // ignore: cast_nullable_to_non_nullable
          : before as Object?,
      confidence: confidence == const $CopyWithPlaceholder()
          ? _value.confidence
          // ignore: cast_nullable_to_non_nullable
          : confidence as num,
      dependsOn: dependsOn == const $CopyWithPlaceholder()
          ? _value.dependsOn
          // ignore: cast_nullable_to_non_nullable
          : dependsOn as List<String>?,
      field: field == const $CopyWithPlaceholder()
          ? _value.field
          // ignore: cast_nullable_to_non_nullable
          : field as String,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String?,
      intent: intent == const $CopyWithPlaceholder()
          ? _value.intent
          // ignore: cast_nullable_to_non_nullable
          : intent as String,
      operationId: operationId == const $CopyWithPlaceholder()
          ? _value.operationId
          // ignore: cast_nullable_to_non_nullable
          : operationId as String,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
      risk: risk == const $CopyWithPlaceholder()
          ? _value.risk
          // ignore: cast_nullable_to_non_nullable
          : risk as String,
      scope: scope == const $CopyWithPlaceholder()
          ? _value.scope
          // ignore: cast_nullable_to_non_nullable
          : scope as List<String>,
      type: type == const $CopyWithPlaceholder()
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as ModificationOperationTypeEnum,
    );
  }
}

extension $ModificationOperationCopyWith on ModificationOperation {
  /// Returns a callable class that can be used as follows: `instanceOfModificationOperation.copyWith(...)` or like so:`instanceOfModificationOperation.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ModificationOperationCWProxy get copyWith =>
      _$ModificationOperationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModificationOperation _$ModificationOperationFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ModificationOperation',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'after',
        'before',
        'confidence',
        'field',
        'intent',
        'operation_id',
        'reason',
        'risk',
        'scope',
        'type',
      ],
    );
    final val = ModificationOperation(
      after: $checkedConvert('after', (v) => v),
      before: $checkedConvert('before', (v) => v),
      confidence: $checkedConvert('confidence', (v) => v as num),
      dependsOn: $checkedConvert(
        'depends_on',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      field: $checkedConvert('field', (v) => v as String),
      id: $checkedConvert('id', (v) => v as String?),
      intent: $checkedConvert('intent', (v) => v as String),
      operationId: $checkedConvert('operation_id', (v) => v as String),
      reason: $checkedConvert('reason', (v) => v as String),
      risk: $checkedConvert('risk', (v) => v as String),
      scope: $checkedConvert(
        'scope',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      type: $checkedConvert(
        'type',
        (v) => $enumDecode(_$ModificationOperationTypeEnumEnumMap, v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'dependsOn': 'depends_on', 'operationId': 'operation_id'},
);

Map<String, dynamic> _$ModificationOperationToJson(
  ModificationOperation instance,
) => <String, dynamic>{
  'after': instance.after,
  'before': instance.before,
  'confidence': instance.confidence,
  'depends_on': ?instance.dependsOn,
  'field': instance.field,
  'id': ?instance.id,
  'intent': instance.intent,
  'operation_id': instance.operationId,
  'reason': instance.reason,
  'risk': instance.risk,
  'scope': instance.scope,
  'type': _$ModificationOperationTypeEnumEnumMap[instance.type]!,
};

const _$ModificationOperationTypeEnumEnumMap = {
  ModificationOperationTypeEnum.changeStepField: 'change_step_field',
  ModificationOperationTypeEnum.changeStepDuration: 'change_step_duration',
  ModificationOperationTypeEnum.changeStepHeat: 'change_step_heat',
  ModificationOperationTypeEnum.changePreparation: 'change_preparation',
  ModificationOperationTypeEnum.changeDisplayName: 'change_display_name',
  ModificationOperationTypeEnum.changeRecipeInfo: 'change_recipe_info',
};
