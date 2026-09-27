// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_upload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ConsentUploadCWProxy {
  ConsentUpload records(List<ConsentRecordInput> records);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ConsentUpload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ConsentUpload(...).copyWith(id: 12, name: "My name")
  /// ````
  ConsentUpload call({List<ConsentRecordInput> records});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfConsentUpload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfConsentUpload.copyWith.fieldName(...)`
class _$ConsentUploadCWProxyImpl implements _$ConsentUploadCWProxy {
  const _$ConsentUploadCWProxyImpl(this._value);

  final ConsentUpload _value;

  @override
  ConsentUpload records(List<ConsentRecordInput> records) =>
      this(records: records);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ConsentUpload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ConsentUpload(...).copyWith(id: 12, name: "My name")
  /// ````
  ConsentUpload call({Object? records = const $CopyWithPlaceholder()}) {
    return ConsentUpload(
      records: records == const $CopyWithPlaceholder()
          ? _value.records
          // ignore: cast_nullable_to_non_nullable
          : records as List<ConsentRecordInput>,
    );
  }
}

extension $ConsentUploadCopyWith on ConsentUpload {
  /// Returns a callable class that can be used as follows: `instanceOfConsentUpload.copyWith(...)` or like so:`instanceOfConsentUpload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ConsentUploadCWProxy get copyWith => _$ConsentUploadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConsentUpload _$ConsentUploadFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ConsentUpload', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['records']);
      final val = ConsentUpload(
        records: $checkedConvert(
          'records',
          (v) => (v as List<dynamic>)
              .map(
                (e) => ConsentRecordInput.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ConsentUploadToJson(ConsentUpload instance) =>
    <String, dynamic>{
      'records': instance.records.map((e) => e.toJson()).toList(),
    };
