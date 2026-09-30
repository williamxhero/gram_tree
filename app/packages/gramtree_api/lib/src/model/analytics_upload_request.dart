//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/analytics_event_in.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'analytics_upload_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AnalyticsUploadRequest {
  /// Returns a new [AnalyticsUploadRequest] instance.
  AnalyticsUploadRequest({

    required  this.events,
  });

  @JsonKey(
    
    name: r'events',
    required: true,
    includeIfNull: false,
  )


  final List<AnalyticsEventIn> events;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AnalyticsUploadRequest &&
      other.events == events;

    @override
    int get hashCode =>
        events.hashCode;

  factory AnalyticsUploadRequest.fromJson(Map<String, dynamic> json) => _$AnalyticsUploadRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyticsUploadRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

