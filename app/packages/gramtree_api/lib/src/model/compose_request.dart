//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'compose_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComposeRequest {
  /// Returns a new [ComposeRequest] instance.
  ComposeRequest({

    required  this.pageType,

    required  this.protocolVersion,

     this.supportedComponents,
  });

      /// 要哪个页面类型的组合，例如 today
  @JsonKey(
    
    name: r'page_type',
    required: true,
    includeIfNull: false,
  )


  final String pageType;



      /// App 自己实现的协议版本，例如 1.0
  @JsonKey(
    
    name: r'protocol_version',
    required: true,
    includeIfNull: false,
  )


  final String protocolVersion;



      /// App 已登记、认识的组件类型清单；服务端只会下发这里面的类型
  @JsonKey(
    
    name: r'supported_components',
    required: false,
    includeIfNull: false,
  )


  final List<String>? supportedComponents;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ComposeRequest &&
      other.pageType == pageType &&
      other.protocolVersion == protocolVersion &&
      other.supportedComponents == supportedComponents;

    @override
    int get hashCode =>
        pageType.hashCode +
        protocolVersion.hashCode +
        supportedComponents.hashCode;

  factory ComposeRequest.fromJson(Map<String, dynamic> json) => _$ComposeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ComposeRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

