// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personalized_step_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PersonalizedStepOutCWProxy {
  PersonalizedStepOut changed(bool? changed);

  PersonalizedStepOut cookware(String? cookware);

  PersonalizedStepOut id(String id);

  PersonalizedStepOut instruction(String instruction);

  PersonalizedStepOut originalInstruction(String originalInstruction);

  PersonalizedStepOut source_(PersonalizedStepOutSource_Enum source_);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PersonalizedStepOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PersonalizedStepOut(...).copyWith(id: 12, name: "My name")
  /// ````
  PersonalizedStepOut call({
    bool? changed,
    String? cookware,
    String id,
    String instruction,
    String originalInstruction,
    PersonalizedStepOutSource_Enum source_,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPersonalizedStepOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPersonalizedStepOut.copyWith.fieldName(...)`
class _$PersonalizedStepOutCWProxyImpl implements _$PersonalizedStepOutCWProxy {
  const _$PersonalizedStepOutCWProxyImpl(this._value);

  final PersonalizedStepOut _value;

  @override
  PersonalizedStepOut changed(bool? changed) => this(changed: changed);

  @override
  PersonalizedStepOut cookware(String? cookware) => this(cookware: cookware);

  @override
  PersonalizedStepOut id(String id) => this(id: id);

  @override
  PersonalizedStepOut instruction(String instruction) =>
      this(instruction: instruction);

  @override
  PersonalizedStepOut originalInstruction(String originalInstruction) =>
      this(originalInstruction: originalInstruction);

  @override
  PersonalizedStepOut source_(PersonalizedStepOutSource_Enum source_) =>
      this(source_: source_);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PersonalizedStepOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PersonalizedStepOut(...).copyWith(id: 12, name: "My name")
  /// ````
  PersonalizedStepOut call({
    Object? changed = const $CopyWithPlaceholder(),
    Object? cookware = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? instruction = const $CopyWithPlaceholder(),
    Object? originalInstruction = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
  }) {
    return PersonalizedStepOut(
      changed: changed == const $CopyWithPlaceholder()
          ? _value.changed
          // ignore: cast_nullable_to_non_nullable
          : changed as bool?,
      cookware: cookware == const $CopyWithPlaceholder()
          ? _value.cookware
          // ignore: cast_nullable_to_non_nullable
          : cookware as String?,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      instruction: instruction == const $CopyWithPlaceholder()
          ? _value.instruction
          // ignore: cast_nullable_to_non_nullable
          : instruction as String,
      originalInstruction: originalInstruction == const $CopyWithPlaceholder()
          ? _value.originalInstruction
          // ignore: cast_nullable_to_non_nullable
          : originalInstruction as String,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as PersonalizedStepOutSource_Enum,
    );
  }
}

extension $PersonalizedStepOutCopyWith on PersonalizedStepOut {
  /// Returns a callable class that can be used as follows: `instanceOfPersonalizedStepOut.copyWith(...)` or like so:`instanceOfPersonalizedStepOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PersonalizedStepOutCWProxy get copyWith =>
      _$PersonalizedStepOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalizedStepOut _$PersonalizedStepOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PersonalizedStepOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'instruction',
            'original_instruction',
            'source',
          ],
        );
        final val = PersonalizedStepOut(
          changed: $checkedConvert('changed', (v) => v as bool? ?? false),
          cookware: $checkedConvert('cookware', (v) => v as String?),
          id: $checkedConvert('id', (v) => v as String),
          instruction: $checkedConvert('instruction', (v) => v as String),
          originalInstruction: $checkedConvert(
            'original_instruction',
            (v) => v as String,
          ),
          source_: $checkedConvert(
            'source',
            (v) => $enumDecode(_$PersonalizedStepOutSource_EnumEnumMap, v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'originalInstruction': 'original_instruction',
        'source_': 'source',
      },
    );

Map<String, dynamic> _$PersonalizedStepOutToJson(
  PersonalizedStepOut instance,
) => <String, dynamic>{
  'changed': ?instance.changed,
  'cookware': ?instance.cookware,
  'id': instance.id,
  'instruction': instance.instruction,
  'original_instruction': instance.originalInstruction,
  'source': _$PersonalizedStepOutSource_EnumEnumMap[instance.source_]!,
};

const _$PersonalizedStepOutSource_EnumEnumMap = {
  PersonalizedStepOutSource_Enum.recipe: 'recipe',
  PersonalizedStepOutSource_Enum.aiEstimated: 'ai_estimated',
  PersonalizedStepOutSource_Enum.scenarioAdjusted: 'scenario_adjusted',
};
