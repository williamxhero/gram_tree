//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_detail.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'import_out.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ImportOut {
  /// Returns a new [ImportOut] instance.
  ImportOut({

     this.failedImages,

     this.fieldStates,

     this.importId,

     this.nextStep,

     this.reason,

     this.recipe,

     this.reproducibility,

    required  this.status,
  });

  @JsonKey(
    
    name: r'failed_images',
    required: false,
    includeIfNull: false,
  )


  final List<int>? failedImages;



  @JsonKey(
    
    name: r'field_states',
    required: false,
    includeIfNull: false,
  )


  final Map<String, String>? fieldStates;



  @JsonKey(
    
    name: r'import_id',
    required: false,
    includeIfNull: false,
  )


  final String? importId;



  @JsonKey(
    
    name: r'next_step',
    required: false,
    includeIfNull: false,
  )


  final String? nextStep;



  @JsonKey(
    
    name: r'reason',
    required: false,
    includeIfNull: false,
  )


  final String? reason;



  @JsonKey(
    
    name: r'recipe',
    required: false,
    includeIfNull: false,
  )


  final RecipeDetail? recipe;



  @JsonKey(
    
    name: r'reproducibility',
    required: false,
    includeIfNull: false,
  )


  final Object? reproducibility;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final String status;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ImportOut &&
      other.failedImages == failedImages &&
      other.fieldStates == fieldStates &&
      other.importId == importId &&
      other.nextStep == nextStep &&
      other.reason == reason &&
      other.recipe == recipe &&
      other.reproducibility == reproducibility &&
      other.status == status;

    @override
    int get hashCode =>
        failedImages.hashCode +
        fieldStates.hashCode +
        (importId == null ? 0 : importId.hashCode) +
        (nextStep == null ? 0 : nextStep.hashCode) +
        (reason == null ? 0 : reason.hashCode) +
        (recipe == null ? 0 : recipe.hashCode) +
        (reproducibility == null ? 0 : reproducibility.hashCode) +
        status.hashCode;

  factory ImportOut.fromJson(Map<String, dynamic> json) => _$ImportOutFromJson(json);

  Map<String, dynamic> toJson() => _$ImportOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

