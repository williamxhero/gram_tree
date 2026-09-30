//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:gramtree_api/src/date_serializer.dart';
import 'package:gramtree_api/src/model/date.dart';

import 'package:gramtree_api/src/model/action_descriptor.dart';
import 'package:gramtree_api/src/model/allergens_attribute.dart';
import 'package:gramtree_api/src/model/analytics_event_in.dart';
import 'package:gramtree_api/src/model/analytics_upload_request.dart';
import 'package:gramtree_api/src/model/apple_login_request.dart';
import 'package:gramtree_api/src/model/apple_reauth_request.dart';
import 'package:gramtree_api/src/model/attribute_status.dart';
import 'package:gramtree_api/src/model/bind_apple_request.dart';
import 'package:gramtree_api/src/model/bind_email_request.dart';
import 'package:gramtree_api/src/model/bool_attribute.dart';
import 'package:gramtree_api/src/model/cache_info.dart';
import 'package:gramtree_api/src/model/client_config.dart';
import 'package:gramtree_api/src/model/component_descriptor.dart';
import 'package:gramtree_api/src/model/component_reason.dart';
import 'package:gramtree_api/src/model/compose_request.dart';
import 'package:gramtree_api/src/model/consent_record_input.dart';
import 'package:gramtree_api/src/model/consent_record_output.dart';
import 'package:gramtree_api/src/model/consent_upload.dart';
import 'package:gramtree_api/src/model/count_unit.dart';
import 'package:gramtree_api/src/model/count_units_attribute.dart';
import 'package:gramtree_api/src/model/deletion_out.dart';
import 'package:gramtree_api/src/model/density_attribute.dart';
import 'package:gramtree_api/src/model/email_code_request.dart';
import 'package:gramtree_api/src/model/email_code_sent.dart';
import 'package:gramtree_api/src/model/email_login_request.dart';
import 'package:gramtree_api/src/model/email_reauth_request.dart';
import 'package:gramtree_api/src/model/error_body.dart';
import 'package:gramtree_api/src/model/error_response.dart';
import 'package:gramtree_api/src/model/event_correlation_ids.dart';
import 'package:gramtree_api/src/model/event_upload_item.dart';
import 'package:gramtree_api/src/model/event_upload_request.dart';
import 'package:gramtree_api/src/model/event_upload_response.dart';
import 'package:gramtree_api/src/model/event_upload_result_item.dart';
import 'package:gramtree_api/src/model/experiment_info.dart';
import 'package:gramtree_api/src/model/fallback_info.dart';
import 'package:gramtree_api/src/model/flavor_attribute.dart';
import 'package:gramtree_api/src/model/flavor_profile.dart';
import 'package:gramtree_api/src/model/health_checks.dart';
import 'package:gramtree_api/src/model/health_response.dart';
import 'package:gramtree_api/src/model/heartbeat_out.dart';
import 'package:gramtree_api/src/model/identity_out.dart';
import 'package:gramtree_api/src/model/ingredient_attributes.dart';
import 'package:gramtree_api/src/model/ingredient_detail.dart';
import 'package:gramtree_api/src/model/ingredient_out.dart';
import 'package:gramtree_api/src/model/normalize_candidate.dart';
import 'package:gramtree_api/src/model/normalize_item.dart';
import 'package:gramtree_api/src/model/normalize_request.dart';
import 'package:gramtree_api/src/model/normalize_response.dart';
import 'package:gramtree_api/src/model/normalize_result_item.dart';
import 'package:gramtree_api/src/model/nutrition.dart';
import 'package:gramtree_api/src/model/nutrition_attribute.dart';
import 'package:gramtree_api/src/model/page_description.dart';
import 'package:gramtree_api/src/model/page_sample_out.dart';
import 'package:gramtree_api/src/model/profile_update.dart';
import 'package:gramtree_api/src/model/purchase_unit.dart';
import 'package:gramtree_api/src/model/purchase_units_attribute.dart';
import 'package:gramtree_api/src/model/refresh_request.dart';
import 'package:gramtree_api/src/model/rejection_reason.dart';
import 'package:gramtree_api/src/model/sample_create.dart';
import 'package:gramtree_api/src/model/sample_out.dart';
import 'package:gramtree_api/src/model/search_query.dart';
import 'package:gramtree_api/src/model/search_result.dart';
import 'package:gramtree_api/src/model/skip_adjustment_request.dart';
import 'package:gramtree_api/src/model/skip_adjustment_result.dart';
import 'package:gramtree_api/src/model/source_basis.dart';
import 'package:gramtree_api/src/model/sourced_value.dart';
import 'package:gramtree_api/src/model/storage_advice.dart';
import 'package:gramtree_api/src/model/storage_attribute.dart';
import 'package:gramtree_api/src/model/task_accepted.dart';
import 'package:gramtree_api/src/model/text_attribute.dart';
import 'package:gramtree_api/src/model/token_pair.dart';
import 'package:gramtree_api/src/model/user_out.dart';

part 'serializers.g.dart';

@SerializersFor([
  ActionDescriptor,
  AllergensAttribute,
  AnalyticsEventIn,
  AnalyticsUploadRequest,
  AppleLoginRequest,
  AppleReauthRequest,
  AttributeStatus,
  BindAppleRequest,
  BindEmailRequest,
  BoolAttribute,
  CacheInfo,
  ClientConfig,
  ComponentDescriptor,
  ComponentReason,
  ComposeRequest,
  ConsentRecordInput,
  ConsentRecordOutput,
  ConsentUpload,
  CountUnit,
  CountUnitsAttribute,
  DeletionOut,
  DensityAttribute,
  EmailCodeRequest,
  EmailCodeSent,
  EmailLoginRequest,
  EmailReauthRequest,
  ErrorBody,
  ErrorResponse,
  EventCorrelationIds,
  EventUploadItem,
  EventUploadRequest,
  EventUploadResponse,
  EventUploadResultItem,
  ExperimentInfo,
  FallbackInfo,
  FlavorAttribute,
  FlavorProfile,
  HealthChecks,
  HealthResponse,
  HeartbeatOut,
  IdentityOut,
  IngredientAttributes,
  IngredientDetail,
  IngredientOut,
  NormalizeCandidate,
  NormalizeItem,
  NormalizeRequest,
  NormalizeResponse,
  NormalizeResultItem,
  Nutrition,
  NutritionAttribute,
  PageDescription,
  PageSampleOut,
  ProfileUpdate,
  PurchaseUnit,
  PurchaseUnitsAttribute,
  RefreshRequest,
  RejectionReason,
  SampleCreate,
  SampleOut,
  SearchQuery,
  SearchResult,
  SkipAdjustmentRequest,
  SkipAdjustmentResult,
  SourceBasis,
  SourcedValue,
  StorageAdvice,
  StorageAttribute,
  TaskAccepted,
  TextAttribute,
  TokenPair,
  UserOut,
])
Serializers serializers = (_$serializers.toBuilder()
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ConsentRecordOutput)]),
        () => ListBuilder<ConsentRecordOutput>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(IdentityOut)]),
        () => ListBuilder<IdentityOut>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(HeartbeatOut)]),
        () => ListBuilder<HeartbeatOut>(),
      )
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer()))
    .build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
