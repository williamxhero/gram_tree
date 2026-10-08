//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/reproducibility_position.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reproducibility_problem.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReproducibilityProblem {
  /// Returns a new [ReproducibilityProblem] instance.
  ReproducibilityProblem({
    required this.id,

    required this.message,

    this.original,

    required this.position,

    required this.status,

    required this.type,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'message', required: true, includeIfNull: false)
  final String message;

  @JsonKey(name: r'original', required: false, includeIfNull: false)
  final String? original;

  @JsonKey(name: r'position', required: true, includeIfNull: false)
  final ReproducibilityPosition position;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final ReproducibilityProblemStatusEnum status;

  @JsonKey(name: r'type', required: true, includeIfNull: false)
  final ReproducibilityProblemTypeEnum type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReproducibilityProblem &&
          other.id == id &&
          other.message == message &&
          other.original == original &&
          other.position == position &&
          other.status == status &&
          other.type == type;

  @override
  int get hashCode =>
      id.hashCode +
      message.hashCode +
      (original == null ? 0 : original.hashCode) +
      position.hashCode +
      status.hashCode +
      type.hashCode;

  factory ReproducibilityProblem.fromJson(Map<String, dynamic> json) =>
      _$ReproducibilityProblemFromJson(json);

  Map<String, dynamic> toJson() => _$ReproducibilityProblemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ReproducibilityProblemStatusEnum {
  @JsonValue(r'unresolved')
  unresolved(r'unresolved'),
  @JsonValue(r'ignored')
  ignored(r'ignored'),
  @JsonValue(r'resolved')
  resolved(r'resolved');

  const ReproducibilityProblemStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum ReproducibilityProblemTypeEnum {
  @JsonValue(r'ambiguous')
  ambiguous(r'ambiguous'),
  @JsonValue(r'missing')
  missing(r'missing');

  const ReproducibilityProblemTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
