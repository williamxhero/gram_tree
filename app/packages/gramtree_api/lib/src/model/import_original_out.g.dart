// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_original_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ImportOriginalOutCWProxy {
  ImportOriginalOut originalText(String originalText);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ImportOriginalOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ImportOriginalOut(...).copyWith(id: 12, name: "My name")
  /// ````
  ImportOriginalOut call({String originalText});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfImportOriginalOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfImportOriginalOut.copyWith.fieldName(...)`
class _$ImportOriginalOutCWProxyImpl implements _$ImportOriginalOutCWProxy {
  const _$ImportOriginalOutCWProxyImpl(this._value);

  final ImportOriginalOut _value;

  @override
  ImportOriginalOut originalText(String originalText) =>
      this(originalText: originalText);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ImportOriginalOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ImportOriginalOut(...).copyWith(id: 12, name: "My name")
  /// ````
  ImportOriginalOut call({
    Object? originalText = const $CopyWithPlaceholder(),
  }) {
    return ImportOriginalOut(
      originalText: originalText == const $CopyWithPlaceholder()
          ? _value.originalText
          // ignore: cast_nullable_to_non_nullable
          : originalText as String,
    );
  }
}

extension $ImportOriginalOutCopyWith on ImportOriginalOut {
  /// Returns a callable class that can be used as follows: `instanceOfImportOriginalOut.copyWith(...)` or like so:`instanceOfImportOriginalOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ImportOriginalOutCWProxy get copyWith =>
      _$ImportOriginalOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportOriginalOut _$ImportOriginalOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ImportOriginalOut', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['original_text']);
      final val = ImportOriginalOut(
        originalText: $checkedConvert('original_text', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'originalText': 'original_text'});

Map<String, dynamic> _$ImportOriginalOutToJson(ImportOriginalOut instance) =>
    <String, dynamic>{'original_text': instance.originalText};
