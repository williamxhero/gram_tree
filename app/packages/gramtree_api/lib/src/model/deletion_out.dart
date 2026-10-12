//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'deletion_out.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeletionOut {
  /// Returns a new [DeletionOut] instance.
  DeletionOut({

    required  this.deletionDueAt,

    required  this.status,
  });

  @JsonKey(
    
    name: r'deletion_due_at',
    required: true,
    includeIfNull: true,
  )


  final String? deletionDueAt;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final DeletionOutStatusEnum status;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeletionOut &&
      other.deletionDueAt == deletionDueAt &&
      other.status == status;

    @override
    int get hashCode =>
        (deletionDueAt == null ? 0 : deletionDueAt.hashCode) +
        status.hashCode;

  factory DeletionOut.fromJson(Map<String, dynamic> json) => _$DeletionOutFromJson(json);

  Map<String, dynamic> toJson() => _$DeletionOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum DeletionOutStatusEnum {
@JsonValue(r'active')
active(r'active'),
@JsonValue(r'deleting')
deleting(r'deleting'),
@JsonValue(r'deleted')
deleted(r'deleted');

const DeletionOutStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


