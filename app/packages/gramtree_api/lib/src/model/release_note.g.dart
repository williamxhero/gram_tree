// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'release_note.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReleaseNoteCWProxy {
  ReleaseNote changelog(String changelog);

  ReleaseNote version(String version);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReleaseNote(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReleaseNote(...).copyWith(id: 12, name: "My name")
  /// ````
  ReleaseNote call({String changelog, String version});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfReleaseNote.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfReleaseNote.copyWith.fieldName(...)`
class _$ReleaseNoteCWProxyImpl implements _$ReleaseNoteCWProxy {
  const _$ReleaseNoteCWProxyImpl(this._value);

  final ReleaseNote _value;

  @override
  ReleaseNote changelog(String changelog) => this(changelog: changelog);

  @override
  ReleaseNote version(String version) => this(version: version);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReleaseNote(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReleaseNote(...).copyWith(id: 12, name: "My name")
  /// ````
  ReleaseNote call({
    Object? changelog = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
  }) {
    return ReleaseNote(
      changelog: changelog == const $CopyWithPlaceholder()
          ? _value.changelog
          // ignore: cast_nullable_to_non_nullable
          : changelog as String,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as String,
    );
  }
}

extension $ReleaseNoteCopyWith on ReleaseNote {
  /// Returns a callable class that can be used as follows: `instanceOfReleaseNote.copyWith(...)` or like so:`instanceOfReleaseNote.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReleaseNoteCWProxy get copyWith => _$ReleaseNoteCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReleaseNote _$ReleaseNoteFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReleaseNote', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['changelog', 'version']);
      final val = ReleaseNote(
        changelog: $checkedConvert('changelog', (v) => v as String),
        version: $checkedConvert('version', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ReleaseNoteToJson(ReleaseNote instance) =>
    <String, dynamic>{
      'changelog': instance.changelog,
      'version': instance.version,
    };
