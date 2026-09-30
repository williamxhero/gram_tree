//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/allergens_attribute.dart';
import 'package:gramtree_api/src/model/flavor_attribute.dart';
import 'package:gramtree_api/src/model/text_attribute.dart';
import 'package:gramtree_api/src/model/count_units_attribute.dart';
import 'package:gramtree_api/src/model/nutrition_attribute.dart';
import 'package:gramtree_api/src/model/purchase_units_attribute.dart';
import 'package:gramtree_api/src/model/storage_attribute.dart';
import 'package:gramtree_api/src/model/bool_attribute.dart';
import 'package:gramtree_api/src/model/density_attribute.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ingredient_attributes.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class IngredientAttributes {
  /// Returns a new [IngredientAttributes] instance.
  IngredientAttributes({

     this.allergens,

     this.baseUnit,

     this.countUnits,

     this.density,

     this.flavor,

     this.functional,

     this.marketZone,

     this.nutrition,

     this.pantryStaple,

     this.purchaseUnits,

     this.scaling,

     this.storage,
  });

  @JsonKey(
    
    name: r'allergens',
    required: false,
    includeIfNull: false,
  )


  final AllergensAttribute? allergens;



  @JsonKey(
    
    name: r'base_unit',
    required: false,
    includeIfNull: false,
  )


  final TextAttribute? baseUnit;



  @JsonKey(
    
    name: r'count_units',
    required: false,
    includeIfNull: false,
  )


  final CountUnitsAttribute? countUnits;



  @JsonKey(
    
    name: r'density',
    required: false,
    includeIfNull: false,
  )


  final DensityAttribute? density;



  @JsonKey(
    
    name: r'flavor',
    required: false,
    includeIfNull: false,
  )


  final FlavorAttribute? flavor;



  @JsonKey(
    
    name: r'functional',
    required: false,
    includeIfNull: false,
  )


  final BoolAttribute? functional;



  @JsonKey(
    
    name: r'market_zone',
    required: false,
    includeIfNull: false,
  )


  final TextAttribute? marketZone;



  @JsonKey(
    
    name: r'nutrition',
    required: false,
    includeIfNull: false,
  )


  final NutritionAttribute? nutrition;



  @JsonKey(
    
    name: r'pantry_staple',
    required: false,
    includeIfNull: false,
  )


  final BoolAttribute? pantryStaple;



  @JsonKey(
    
    name: r'purchase_units',
    required: false,
    includeIfNull: false,
  )


  final PurchaseUnitsAttribute? purchaseUnits;



  @JsonKey(
    
    name: r'scaling',
    required: false,
    includeIfNull: false,
  )


  final TextAttribute? scaling;



  @JsonKey(
    
    name: r'storage',
    required: false,
    includeIfNull: false,
  )


  final StorageAttribute? storage;





    @override
    bool operator ==(Object other) => identical(this, other) || other is IngredientAttributes &&
      other.allergens == allergens &&
      other.baseUnit == baseUnit &&
      other.countUnits == countUnits &&
      other.density == density &&
      other.flavor == flavor &&
      other.functional == functional &&
      other.marketZone == marketZone &&
      other.nutrition == nutrition &&
      other.pantryStaple == pantryStaple &&
      other.purchaseUnits == purchaseUnits &&
      other.scaling == scaling &&
      other.storage == storage;

    @override
    int get hashCode =>
        (allergens == null ? 0 : allergens.hashCode) +
        (baseUnit == null ? 0 : baseUnit.hashCode) +
        (countUnits == null ? 0 : countUnits.hashCode) +
        (density == null ? 0 : density.hashCode) +
        (flavor == null ? 0 : flavor.hashCode) +
        (functional == null ? 0 : functional.hashCode) +
        (marketZone == null ? 0 : marketZone.hashCode) +
        (nutrition == null ? 0 : nutrition.hashCode) +
        (pantryStaple == null ? 0 : pantryStaple.hashCode) +
        (purchaseUnits == null ? 0 : purchaseUnits.hashCode) +
        (scaling == null ? 0 : scaling.hashCode) +
        (storage == null ? 0 : storage.hashCode);

  factory IngredientAttributes.fromJson(Map<String, dynamic> json) => _$IngredientAttributesFromJson(json);

  Map<String, dynamic> toJson() => _$IngredientAttributesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

