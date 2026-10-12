//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'import_input.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ImportInput {
  /// Returns a new [ImportInput] instance.
  ImportInput({

     this.imagesBase64,

     this.sourceNote,

     this.text,

     this.url,
  });

  @JsonKey(
    
    name: r'images_base64',
    required: false,
    includeIfNull: false,
  )


  final List<String>? imagesBase64;



  @JsonKey(
    
    name: r'source_note',
    required: false,
    includeIfNull: false,
  )


  final String? sourceNote;



  @JsonKey(
    
    name: r'text',
    required: false,
    includeIfNull: false,
  )


  final String? text;



  @JsonKey(
    
    name: r'url',
    required: false,
    includeIfNull: false,
  )


  final String? url;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ImportInput &&
      other.imagesBase64 == imagesBase64 &&
      other.sourceNote == sourceNote &&
      other.text == text &&
      other.url == url;

    @override
    int get hashCode =>
        imagesBase64.hashCode +
        (sourceNote == null ? 0 : sourceNote.hashCode) +
        (text == null ? 0 : text.hashCode) +
        (url == null ? 0 : url.hashCode);

  factory ImportInput.fromJson(Map<String, dynamic> json) => _$ImportInputFromJson(json);

  Map<String, dynamic> toJson() => _$ImportInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

