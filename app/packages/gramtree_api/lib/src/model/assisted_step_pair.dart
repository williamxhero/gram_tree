//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/source_basis.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'assisted_step_pair.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AssistedStepPair {
  /// Returns a new [AssistedStepPair] instance.
  AssistedStepPair({
    required this.afterStepId,

    required this.alignment,

    required this.basis,

    required this.beforeStepId,

    required this.confidence,

    required this.sourceType,
  });

  @JsonKey(name: r'after_step_id', required: true, includeIfNull: false)
  final String afterStepId;

  @JsonKey(name: r'alignment', required: true, includeIfNull: false)
  final AssistedStepPairAlignmentEnum alignment;

  @JsonKey(name: r'basis', required: true, includeIfNull: false)
  final SourceBasis basis;

  @JsonKey(name: r'before_step_id', required: true, includeIfNull: false)
  final String beforeStepId;

  // minimum: 0.0
  // maximum: 1.0
  @JsonKey(name: r'confidence', required: true, includeIfNull: false)
  final num confidence;

  @JsonKey(name: r'source_type', required: true, includeIfNull: false)
  final AssistedStepPairSourceTypeEnum sourceType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistedStepPair &&
          other.afterStepId == afterStepId &&
          other.alignment == alignment &&
          other.basis == basis &&
          other.beforeStepId == beforeStepId &&
          other.confidence == confidence &&
          other.sourceType == sourceType;

  @override
  int get hashCode =>
      afterStepId.hashCode +
      alignment.hashCode +
      basis.hashCode +
      beforeStepId.hashCode +
      confidence.hashCode +
      sourceType.hashCode;

  factory AssistedStepPair.fromJson(Map<String, dynamic> json) =>
      _$AssistedStepPairFromJson(json);

  Map<String, dynamic> toJson() => _$AssistedStepPairToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AssistedStepPairAlignmentEnum {
  @JsonValue(r'ai_assisted')
  aiAssisted(r'ai_assisted');

  const AssistedStepPairAlignmentEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AssistedStepPairSourceTypeEnum {
  @JsonValue(r'ai_estimated')
  aiEstimated(r'ai_estimated');

  const AssistedStepPairSourceTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
