// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ImportInputCWProxy {
  ImportInput imagesBase64(List<String>? imagesBase64);

  ImportInput sourceNote(String? sourceNote);

  ImportInput text(String? text);

  ImportInput url(String? url);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ImportInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ImportInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ImportInput call({
    List<String>? imagesBase64,
    String? sourceNote,
    String? text,
    String? url,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfImportInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfImportInput.copyWith.fieldName(...)`
class _$ImportInputCWProxyImpl implements _$ImportInputCWProxy {
  const _$ImportInputCWProxyImpl(this._value);

  final ImportInput _value;

  @override
  ImportInput imagesBase64(List<String>? imagesBase64) =>
      this(imagesBase64: imagesBase64);

  @override
  ImportInput sourceNote(String? sourceNote) => this(sourceNote: sourceNote);

  @override
  ImportInput text(String? text) => this(text: text);

  @override
  ImportInput url(String? url) => this(url: url);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ImportInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ImportInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ImportInput call({
    Object? imagesBase64 = const $CopyWithPlaceholder(),
    Object? sourceNote = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
  }) {
    return ImportInput(
      imagesBase64: imagesBase64 == const $CopyWithPlaceholder()
          ? _value.imagesBase64
          // ignore: cast_nullable_to_non_nullable
          : imagesBase64 as List<String>?,
      sourceNote: sourceNote == const $CopyWithPlaceholder()
          ? _value.sourceNote
          // ignore: cast_nullable_to_non_nullable
          : sourceNote as String?,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String?,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
    );
  }
}

extension $ImportInputCopyWith on ImportInput {
  /// Returns a callable class that can be used as follows: `instanceOfImportInput.copyWith(...)` or like so:`instanceOfImportInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ImportInputCWProxy get copyWith => _$ImportInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportInput _$ImportInputFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ImportInput',
  json,
  ($checkedConvert) {
    final val = ImportInput(
      imagesBase64: $checkedConvert(
        'images_base64',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      sourceNote: $checkedConvert('source_note', (v) => v as String?),
      text: $checkedConvert('text', (v) => v as String?),
      url: $checkedConvert('url', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'imagesBase64': 'images_base64',
    'sourceNote': 'source_note',
  },
);

Map<String, dynamic> _$ImportInputToJson(ImportInput instance) =>
    <String, dynamic>{
      'images_base64': ?instance.imagesBase64,
      'source_note': ?instance.sourceNote,
      'text': ?instance.text,
      'url': ?instance.url,
    };
