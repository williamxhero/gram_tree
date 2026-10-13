//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/taste_level.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'taste_scale.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TasteScale {
  /// Returns a new [TasteScale] instance.
  TasteScale({
    required this.default_,

    required this.levels,

    required this.maximum,

    required this.minimum,
  });

  @JsonKey(name: r'default', required: true, includeIfNull: false)
  final num default_;

  @JsonKey(name: r'levels', required: true, includeIfNull: false)
  final List<TasteLevel> levels;

  @JsonKey(name: r'maximum', required: true, includeIfNull: false)
  final num maximum;

  @JsonKey(name: r'minimum', required: true, includeIfNull: false)
  final num minimum;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TasteScale &&
          other.default_ == default_ &&
          other.levels == levels &&
          other.maximum == maximum &&
          other.minimum == minimum;

  @override
  int get hashCode =>
      default_.hashCode + levels.hashCode + maximum.hashCode + minimum.hashCode;

  factory TasteScale.fromJson(Map<String, dynamic> json) =>
      _$TasteScaleFromJson(json);

  Map<String, dynamic> toJson() => _$TasteScaleToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
