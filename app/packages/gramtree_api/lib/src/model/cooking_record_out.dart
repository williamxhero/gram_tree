//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cooking_record_out.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CookingRecordOut {
  /// Returns a new [CookingRecordOut] instance.
  CookingRecordOut({

    required  this.adjustments,

    required  this.clientId,

    required  this.countsAsCooked,

    required  this.createdAt,

    required  this.dishName,

    required  this.id,

    required  this.meal,

    required  this.occurredAt,

    required  this.recipeId,

    required  this.recipeVersionId,

    required  this.snapshot,

    required  this.source_,

    required  this.sourceContext,

    required  this.verification,
  });

  @JsonKey(
    
    name: r'adjustments',
    required: true,
    includeIfNull: false,
  )


  final List<Object> adjustments;



  @JsonKey(
    
    name: r'client_id',
    required: true,
    includeIfNull: false,
  )


  final String clientId;



  @JsonKey(
    
    name: r'counts_as_cooked',
    required: true,
    includeIfNull: false,
  )


  final bool countsAsCooked;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final String createdAt;



  @JsonKey(
    
    name: r'dish_name',
    required: true,
    includeIfNull: true,
  )


  final String? dishName;



  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'meal',
    required: true,
    includeIfNull: true,
  )


  final CookingRecordOutMealEnum? meal;



  @JsonKey(
    
    name: r'occurred_at',
    required: true,
    includeIfNull: false,
  )


  final String occurredAt;



  @JsonKey(
    
    name: r'recipe_id',
    required: true,
    includeIfNull: true,
  )


  final String? recipeId;



  @JsonKey(
    
    name: r'recipe_version_id',
    required: true,
    includeIfNull: true,
  )


  final String? recipeVersionId;



  @JsonKey(
    
    name: r'snapshot',
    required: true,
    includeIfNull: true,
  )


  final Object? snapshot;



  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final CookingRecordOutSource_Enum source_;



  @JsonKey(
    
    name: r'source_context',
    required: true,
    includeIfNull: false,
  )


  final Object sourceContext;



  @JsonKey(
    
    name: r'verification',
    required: true,
    includeIfNull: false,
  )


  final CookingRecordOutVerificationEnum verification;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CookingRecordOut &&
      other.adjustments == adjustments &&
      other.clientId == clientId &&
      other.countsAsCooked == countsAsCooked &&
      other.createdAt == createdAt &&
      other.dishName == dishName &&
      other.id == id &&
      other.meal == meal &&
      other.occurredAt == occurredAt &&
      other.recipeId == recipeId &&
      other.recipeVersionId == recipeVersionId &&
      other.snapshot == snapshot &&
      other.source_ == source_ &&
      other.sourceContext == sourceContext &&
      other.verification == verification;

    @override
    int get hashCode =>
        adjustments.hashCode +
        clientId.hashCode +
        countsAsCooked.hashCode +
        createdAt.hashCode +
        (dishName == null ? 0 : dishName.hashCode) +
        id.hashCode +
        (meal == null ? 0 : meal.hashCode) +
        occurredAt.hashCode +
        (recipeId == null ? 0 : recipeId.hashCode) +
        (recipeVersionId == null ? 0 : recipeVersionId.hashCode) +
        (snapshot == null ? 0 : snapshot.hashCode) +
        source_.hashCode +
        sourceContext.hashCode +
        verification.hashCode;

  factory CookingRecordOut.fromJson(Map<String, dynamic> json) => _$CookingRecordOutFromJson(json);

  Map<String, dynamic> toJson() => _$CookingRecordOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CookingRecordOutMealEnum {
@JsonValue(r'breakfast')
breakfast(r'breakfast'),
@JsonValue(r'lunch')
lunch(r'lunch'),
@JsonValue(r'dinner')
dinner(r'dinner'),
@JsonValue(r'snack')
snack(r'snack');

const CookingRecordOutMealEnum(this.value);

final String value;

@override
String toString() => value;
}



enum CookingRecordOutSource_Enum {
@JsonValue(r'cooking_session')
cookingSession(r'cooking_session'),
@JsonValue(r'recommendation')
recommendation(r'recommendation'),
@JsonValue(r'calendar')
calendar(r'calendar'),
@JsonValue(r'external_cooking')
externalCooking(r'external_cooking'),
@JsonValue(r'dining')
dining(r'dining');

const CookingRecordOutSource_Enum(this.value);

final String value;

@override
String toString() => value;
}



enum CookingRecordOutVerificationEnum {
@JsonValue(r'cooking_mode')
cookingMode(r'cooking_mode'),
@JsonValue(r'unverified')
unverified(r'unverified');

const CookingRecordOutVerificationEnum(this.value);

final String value;

@override
String toString() => value;
}


