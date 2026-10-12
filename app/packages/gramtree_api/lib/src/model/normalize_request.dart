//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/normalize_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'normalize_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NormalizeRequest {
  /// Returns a new [NormalizeRequest] instance.
  NormalizeRequest({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<NormalizeItem> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is NormalizeRequest &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory NormalizeRequest.fromJson(Map<String, dynamic> json) => _$NormalizeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$NormalizeRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

