//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'validation_error_loc_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ValidationErrorLocInner {
  /// Returns a new [ValidationErrorLocInner] instance.
  ValidationErrorLocInner({
  });



    @override
    bool operator ==(Object other) => identical(this, other) || other is ValidationErrorLocInner &&

    @override
    int get hashCode =>

  factory ValidationErrorLocInner.fromJson(Map<String, dynamic> json) => _$ValidationErrorLocInnerFromJson(json);

  Map<String, dynamic> toJson() => _$ValidationErrorLocInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

