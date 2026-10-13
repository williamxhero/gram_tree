// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'automation_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AutomationOutCWProxy {
  AutomationOut automaticLearning(bool automaticLearning);

  AutomationOut saveToTaste(bool saveToTaste);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AutomationOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AutomationOut(...).copyWith(id: 12, name: "My name")
  /// ````
  AutomationOut call({bool automaticLearning, bool saveToTaste});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAutomationOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAutomationOut.copyWith.fieldName(...)`
class _$AutomationOutCWProxyImpl implements _$AutomationOutCWProxy {
  const _$AutomationOutCWProxyImpl(this._value);

  final AutomationOut _value;

  @override
  AutomationOut automaticLearning(bool automaticLearning) =>
      this(automaticLearning: automaticLearning);

  @override
  AutomationOut saveToTaste(bool saveToTaste) => this(saveToTaste: saveToTaste);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AutomationOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AutomationOut(...).copyWith(id: 12, name: "My name")
  /// ````
  AutomationOut call({
    Object? automaticLearning = const $CopyWithPlaceholder(),
    Object? saveToTaste = const $CopyWithPlaceholder(),
  }) {
    return AutomationOut(
      automaticLearning: automaticLearning == const $CopyWithPlaceholder()
          ? _value.automaticLearning
          // ignore: cast_nullable_to_non_nullable
          : automaticLearning as bool,
      saveToTaste: saveToTaste == const $CopyWithPlaceholder()
          ? _value.saveToTaste
          // ignore: cast_nullable_to_non_nullable
          : saveToTaste as bool,
    );
  }
}

extension $AutomationOutCopyWith on AutomationOut {
  /// Returns a callable class that can be used as follows: `instanceOfAutomationOut.copyWith(...)` or like so:`instanceOfAutomationOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AutomationOutCWProxy get copyWith => _$AutomationOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AutomationOut _$AutomationOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AutomationOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['automatic_learning', 'save_to_taste'],
        );
        final val = AutomationOut(
          automaticLearning: $checkedConvert(
            'automatic_learning',
            (v) => v as bool,
          ),
          saveToTaste: $checkedConvert('save_to_taste', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'automaticLearning': 'automatic_learning',
        'saveToTaste': 'save_to_taste',
      },
    );

Map<String, dynamic> _$AutomationOutToJson(AutomationOut instance) =>
    <String, dynamic>{
      'automatic_learning': instance.automaticLearning,
      'save_to_taste': instance.saveToTaste,
    };
