//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/cache_info.dart';
import 'package:gramtree_api/src/model/component_descriptor.dart';
import 'package:gramtree_api/src/model/fallback_info.dart';
import 'package:gramtree_api/src/model/experiment_info.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'page_description.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PageDescription {
  /// Returns a new [PageDescription] instance.
  PageDescription({

    required  this.cache,

     this.components,

    required  this.compositionId,

     this.experiment,

     this.fallback,

    required  this.generatedAt,

    required  this.pageType,

    required  this.protocol,
  });

  @JsonKey(
    
    name: r'cache',
    required: true,
    includeIfNull: false,
  )


  final CacheInfo cache;



  @JsonKey(
    
    name: r'components',
    required: false,
    includeIfNull: false,
  )


  final List<ComponentDescriptor>? components;



  @JsonKey(
    
    name: r'composition_id',
    required: true,
    includeIfNull: false,
  )


  final String compositionId;



  @JsonKey(
    
    name: r'experiment',
    required: false,
    includeIfNull: false,
  )


  final ExperimentInfo? experiment;



  @JsonKey(
    
    name: r'fallback',
    required: false,
    includeIfNull: false,
  )


  final FallbackInfo? fallback;



  @JsonKey(
    
    name: r'generated_at',
    required: true,
    includeIfNull: false,
  )


  final String generatedAt;



  @JsonKey(
    
    name: r'page_type',
    required: true,
    includeIfNull: false,
  )


  final String pageType;



      /// 协议版本，大版本.小版本，例如 1.0
  @JsonKey(
    
    name: r'protocol',
    required: true,
    includeIfNull: false,
  )


  final String protocol;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PageDescription &&
      other.cache == cache &&
      other.components == components &&
      other.compositionId == compositionId &&
      other.experiment == experiment &&
      other.fallback == fallback &&
      other.generatedAt == generatedAt &&
      other.pageType == pageType &&
      other.protocol == protocol;

    @override
    int get hashCode =>
        cache.hashCode +
        components.hashCode +
        compositionId.hashCode +
        (experiment == null ? 0 : experiment.hashCode) +
        (fallback == null ? 0 : fallback.hashCode) +
        generatedAt.hashCode +
        pageType.hashCode +
        protocol.hashCode;

  factory PageDescription.fromJson(Map<String, dynamic> json) => _$PageDescriptionFromJson(json);

  Map<String, dynamic> toJson() => _$PageDescriptionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

