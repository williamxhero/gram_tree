//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'client_config.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ClientConfig {
  /// Returns a new [ClientConfig] instance.
  ClientConfig({

    required  this.features,

    required  this.params,
  });

  @JsonKey(
    
    name: r'features',
    required: true,
    includeIfNull: false,
  )


  final Map<String, bool> features;



  @JsonKey(
    
    name: r'params',
    required: true,
    includeIfNull: false,
  )


  final Object params;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ClientConfig &&
      other.features == features &&
      other.params == params;

    @override
    int get hashCode =>
        features.hashCode +
        params.hashCode;

  factory ClientConfig.fromJson(Map<String, dynamic> json) => _$ClientConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ClientConfigToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

