//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_query.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SearchQuery {
  /// Returns a new [SearchQuery] instance.
  SearchQuery({

    required  this.query,
  });

  @JsonKey(
    
    name: r'query',
    required: true,
    includeIfNull: false,
  )


  final String query;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SearchQuery &&
      other.query == query;

    @override
    int get hashCode =>
        query.hashCode;

  factory SearchQuery.fromJson(Map<String, dynamic> json) => _$SearchQueryFromJson(json);

  Map<String, dynamic> toJson() => _$SearchQueryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

