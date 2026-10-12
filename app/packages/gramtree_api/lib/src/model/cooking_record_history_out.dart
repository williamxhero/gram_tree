//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/cooking_record_revision_out.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cooking_record_history_out.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CookingRecordHistoryOut {
  /// Returns a new [CookingRecordHistoryOut] instance.
  CookingRecordHistoryOut({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<CookingRecordRevisionOut> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CookingRecordHistoryOut &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory CookingRecordHistoryOut.fromJson(Map<String, dynamic> json) => _$CookingRecordHistoryOutFromJson(json);

  Map<String, dynamic> toJson() => _$CookingRecordHistoryOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

