//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'normalize_candidate.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NormalizeCandidate {
  /// Returns a new [NormalizeCandidate] instance.
  NormalizeCandidate({

    required  this.ingredientId,

    required  this.standardName,
  });

  @JsonKey(
    
    name: r'ingredient_id',
    required: true,
    includeIfNull: false,
  )


  final String ingredientId;



  @JsonKey(
    
    name: r'standard_name',
    required: true,
    includeIfNull: false,
  )


  final String standardName;





    @override
    bool operator ==(Object other) => identical(this, other) || other is NormalizeCandidate &&
      other.ingredientId == ingredientId &&
      other.standardName == standardName;

    @override
    int get hashCode =>
        ingredientId.hashCode +
        standardName.hashCode;

  factory NormalizeCandidate.fromJson(Map<String, dynamic> json) => _$NormalizeCandidateFromJson(json);

  Map<String, dynamic> toJson() => _$NormalizeCandidateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

