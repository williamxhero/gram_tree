//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'import_original_out.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ImportOriginalOut {
  /// Returns a new [ImportOriginalOut] instance.
  ImportOriginalOut({

    required  this.originalText,
  });

  @JsonKey(
    
    name: r'original_text',
    required: true,
    includeIfNull: false,
  )


  final String originalText;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ImportOriginalOut &&
      other.originalText == originalText;

    @override
    int get hashCode =>
        originalText.hashCode;

  factory ImportOriginalOut.fromJson(Map<String, dynamic> json) => _$ImportOriginalOutFromJson(json);

  Map<String, dynamic> toJson() => _$ImportOriginalOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

