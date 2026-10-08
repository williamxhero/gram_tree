//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/batch_step_advice.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'batch_advice.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BatchAdvice {
  /// Returns a new [BatchAdvice] instance.
  BatchAdvice({required this.basis, required this.risk, required this.steps});

  @JsonKey(name: r'basis', required: true, includeIfNull: false)
  final String basis;

  @JsonKey(name: r'risk', required: true, includeIfNull: false)
  final String risk;

  @JsonKey(name: r'steps', required: true, includeIfNull: false)
  final List<BatchStepAdvice> steps;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchAdvice &&
          other.basis == basis &&
          other.risk == risk &&
          other.steps == steps;

  @override
  int get hashCode => basis.hashCode + risk.hashCode + steps.hashCode;

  factory BatchAdvice.fromJson(Map<String, dynamic> json) =>
      _$BatchAdviceFromJson(json);

  Map<String, dynamic> toJson() => _$BatchAdviceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
