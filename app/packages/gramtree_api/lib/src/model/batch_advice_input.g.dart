// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_advice_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BatchAdviceInputCWProxy {
  BatchAdviceInput targetServings(int targetServings);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BatchAdviceInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BatchAdviceInput(...).copyWith(id: 12, name: "My name")
  /// ````
  BatchAdviceInput call({int targetServings});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfBatchAdviceInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfBatchAdviceInput.copyWith.fieldName(...)`
class _$BatchAdviceInputCWProxyImpl implements _$BatchAdviceInputCWProxy {
  const _$BatchAdviceInputCWProxyImpl(this._value);

  final BatchAdviceInput _value;

  @override
  BatchAdviceInput targetServings(int targetServings) =>
      this(targetServings: targetServings);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BatchAdviceInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BatchAdviceInput(...).copyWith(id: 12, name: "My name")
  /// ````
  BatchAdviceInput call({
    Object? targetServings = const $CopyWithPlaceholder(),
  }) {
    return BatchAdviceInput(
      targetServings: targetServings == const $CopyWithPlaceholder()
          ? _value.targetServings
          // ignore: cast_nullable_to_non_nullable
          : targetServings as int,
    );
  }
}

extension $BatchAdviceInputCopyWith on BatchAdviceInput {
  /// Returns a callable class that can be used as follows: `instanceOfBatchAdviceInput.copyWith(...)` or like so:`instanceOfBatchAdviceInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BatchAdviceInputCWProxy get copyWith => _$BatchAdviceInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BatchAdviceInput _$BatchAdviceInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BatchAdviceInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['target_servings']);
      final val = BatchAdviceInput(
        targetServings: $checkedConvert(
          'target_servings',
          (v) => (v as num).toInt(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'targetServings': 'target_servings'});

Map<String, dynamic> _$BatchAdviceInputToJson(BatchAdviceInput instance) =>
    <String, dynamic>{'target_servings': instance.targetServings};
