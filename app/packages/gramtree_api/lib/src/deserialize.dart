import 'package:gramtree_api/src/model/action_descriptor.dart';
import 'package:gramtree_api/src/model/allergens_attribute.dart';
import 'package:gramtree_api/src/model/analytics_event_in.dart';
import 'package:gramtree_api/src/model/analytics_upload_request.dart';
import 'package:gramtree_api/src/model/apple_login_request.dart';
import 'package:gramtree_api/src/model/apple_reauth_request.dart';
import 'package:gramtree_api/src/model/bind_apple_request.dart';
import 'package:gramtree_api/src/model/bind_email_request.dart';
import 'package:gramtree_api/src/model/bool_attribute.dart';
import 'package:gramtree_api/src/model/cache_info.dart';
import 'package:gramtree_api/src/model/changes_response.dart';
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
import 'package:gramtree_api/src/model/profile_update.dart';
import 'package:gramtree_api/src/model/purchase_unit.dart';
import 'package:gramtree_api/src/model/purchase_units_attribute.dart';
import 'package:gramtree_api/src/model/refresh_request.dart';
import 'package:gramtree_api/src/model/rejection_reason.dart';
import 'package:gramtree_api/src/model/search_query.dart';
import 'package:gramtree_api/src/model/search_result.dart';
import 'package:gramtree_api/src/model/skip_adjustment_request.dart';
import 'package:gramtree_api/src/model/skip_adjustment_result.dart';
import 'package:gramtree_api/src/model/source_basis.dart';
import 'package:gramtree_api/src/model/sourced_value.dart';
import 'package:gramtree_api/src/model/storage_advice.dart';
import 'package:gramtree_api/src/model/storage_attribute.dart';
import 'package:gramtree_api/src/model/text_attribute.dart';
import 'package:gramtree_api/src/model/token_pair.dart';
import 'package:gramtree_api/src/model/user_out.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

  ReturnType deserialize<ReturnType, BaseType>(dynamic value, String targetType, {bool growable= true}) {
      switch (targetType) {
        case 'String':
          return '$value' as ReturnType;
        case 'int':
          return (value is int ? value : int.parse('$value')) as ReturnType;
        case 'bool':
          if (value is bool) {
            return value as ReturnType;
          }
          final valueString = '$value'.toLowerCase();
          return (valueString == 'true' || valueString == '1') as ReturnType;
        case 'double':
          return (value is double ? value : double.parse('$value')) as ReturnType;
        case 'ActionDescriptor':
          return ActionDescriptor.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AllergensAttribute':
          return AllergensAttribute.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AnalyticsEventIn':
          return AnalyticsEventIn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AnalyticsUploadRequest':
          return AnalyticsUploadRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AppleLoginRequest':
          return AppleLoginRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AppleReauthRequest':
          return AppleReauthRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AttributeStatus':
          
          
        case 'BindAppleRequest':
          return BindAppleRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BindEmailRequest':
          return BindEmailRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BoolAttribute':
          return BoolAttribute.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CacheInfo':
          return CacheInfo.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ChangesResponse':
          return ChangesResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ClientConfig':
          return ClientConfig.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComponentDescriptor':
          return ComponentDescriptor.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComponentReason':
          return ComponentReason.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComposeRequest':
          return ComposeRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ConsentRecordInput':
          return ConsentRecordInput.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ConsentRecordOutput':
          return ConsentRecordOutput.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ConsentUpload':
          return ConsentUpload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CountUnit':
          return CountUnit.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CountUnitsAttribute':
          return CountUnitsAttribute.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletionOut':
          return DeletionOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DensityAttribute':
          return DensityAttribute.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'EmailCodeRequest':
          return EmailCodeRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'EmailCodeSent':
          return EmailCodeSent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'EmailLoginRequest':
          return EmailLoginRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'EmailReauthRequest':
          return EmailReauthRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ErrorBody':
          return ErrorBody.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ErrorResponse':
          return ErrorResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'EventCorrelationIds':
          return EventCorrelationIds.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'EventUploadItem':
          return EventUploadItem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'EventUploadRequest':
          return EventUploadRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'EventUploadResponse':
          return EventUploadResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'EventUploadResultItem':
          return EventUploadResultItem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ExperimentInfo':
          return ExperimentInfo.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'FallbackInfo':
          return FallbackInfo.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'FlavorAttribute':
          return FlavorAttribute.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'FlavorProfile':
          return FlavorProfile.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'HealthChecks':
          return HealthChecks.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'HealthResponse':
          return HealthResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'IdentityOut':
          return IdentityOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'IngredientAttributes':
          return IngredientAttributes.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'IngredientDetail':
          return IngredientDetail.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'IngredientOut':
          return IngredientOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'NormalizeCandidate':
          return NormalizeCandidate.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'NormalizeItem':
          return NormalizeItem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'NormalizeRequest':
          return NormalizeRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'NormalizeResponse':
          return NormalizeResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'NormalizeResultItem':
          return NormalizeResultItem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Nutrition':
          return Nutrition.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'NutritionAttribute':
          return NutritionAttribute.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PageDescription':
          return PageDescription.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProfileUpdate':
          return ProfileUpdate.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PurchaseUnit':
          return PurchaseUnit.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PurchaseUnitsAttribute':
          return PurchaseUnitsAttribute.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RefreshRequest':
          return RefreshRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RejectionReason':
          return RejectionReason.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SearchQuery':
          return SearchQuery.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SearchResult':
          return SearchResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SkipAdjustmentRequest':
          return SkipAdjustmentRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SkipAdjustmentResult':
          return SkipAdjustmentResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SourceBasis':
          return SourceBasis.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SourcedValue':
          return SourcedValue.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'StorageAdvice':
          return StorageAdvice.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'StorageAttribute':
          return StorageAttribute.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TextAttribute':
          return TextAttribute.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TokenPair':
          return TokenPair.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UserOut':
          return UserOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        default:
          RegExpMatch? match;

          if (value is List && (match = _regList.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toList(growable: growable) as ReturnType;
          }
          if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toSet() as ReturnType;
          }
          if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
            targetType = match![1]!.trim(); // ignore: parameter_assignments
            return Map<String, BaseType>.fromIterables(
              value.keys as Iterable<String>,
              value.values.map((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable)),
            ) as ReturnType;
          }
          break;
    }
    throw Exception('Cannot deserialize');
  }