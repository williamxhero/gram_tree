//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';
import 'package:gramtree_api/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'package:gramtree_api/src/model/error_response.dart';
import 'package:gramtree_api/src/model/public_recipe_projection.dart';
import 'package:gramtree_api/src/model/recipe_share_link.dart';
import 'package:gramtree_api/src/model/recipe_share_target.dart';
import 'package:gramtree_api/src/model/share_complaint_input.dart';
import 'package:gramtree_api/src/model/share_complaint_receipt.dart';

class RecipeSharingApi {
  final Dio _dio;

  const RecipeSharingApi(this._dio);

  /// Create Recipe Share
  ///
  ///
  /// Parameters:
  /// * [recipeId]
  /// * [xRequestSignature] - HMAC-SHA256 请求签名
  /// * [xRequestTimestamp] - Unix 秒时间戳
  /// * [xRequestNonce] - 每次请求唯一的随机数
  /// * [xDeviceID] - 登录时的设备安装 ID
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [RecipeShareLink] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<RecipeShareLink>> createRecipeShare({
    required String recipeId,
    String? xRequestSignature,
    String? xRequestTimestamp,
    String? xRequestNonce,
    String? xDeviceID,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/recipes/{recipe_id}/share'.replaceAll(
      '{'
      r'recipe_id'
      '}',
      recipeId.toString(),
    );
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        r'X-Request-Signature': xRequestSignature,
        r'X-Request-Timestamp': xRequestTimestamp,
        r'X-Request-Nonce': xRequestNonce,
        r'X-Device-ID': xDeviceID,
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {'type': 'http', 'scheme': 'bearer', 'name': 'HTTPBearer'},
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    RecipeShareLink? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<RecipeShareLink, RecipeShareLink>(
              rawData,
              'RecipeShareLink',
              growable: true,
            );
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<RecipeShareLink>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Get Recipe Share Preview
  ///
  ///
  /// Parameters:
  /// * [recipeId]
  /// * [xRequestSignature] - HMAC-SHA256 请求签名
  /// * [xRequestTimestamp] - Unix 秒时间戳
  /// * [xRequestNonce] - 每次请求唯一的随机数
  /// * [xDeviceID] - 登录时的设备安装 ID
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [PublicRecipeProjection] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<PublicRecipeProjection>> getRecipeSharePreview({
    required String recipeId,
    String? xRequestSignature,
    String? xRequestTimestamp,
    String? xRequestNonce,
    String? xDeviceID,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/recipes/{recipe_id}/share-preview'.replaceAll(
      '{'
      r'recipe_id'
      '}',
      recipeId.toString(),
    );
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{
        r'X-Request-Signature': xRequestSignature,
        r'X-Request-Timestamp': xRequestTimestamp,
        r'X-Request-Nonce': xRequestNonce,
        r'X-Device-ID': xDeviceID,
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {'type': 'http', 'scheme': 'bearer', 'name': 'HTTPBearer'},
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    PublicRecipeProjection? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<PublicRecipeProjection, PublicRecipeProjection>(
              rawData,
              'PublicRecipeProjection',
              growable: true,
            );
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<PublicRecipeProjection>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Resolve Recipe Share
  ///
  ///
  /// Parameters:
  /// * [shareId]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [RecipeShareTarget] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<RecipeShareTarget>> resolveRecipeShare({
    required String shareId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/shares/{share_id}'.replaceAll(
      '{'
      r'share_id'
      '}',
      shareId.toString(),
    );
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{...?headers},
      extra: <String, dynamic>{'secure': <Map<String, String>>[], ...?extra},
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    RecipeShareTarget? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<RecipeShareTarget, RecipeShareTarget>(
              rawData,
              'RecipeShareTarget',
              growable: true,
            );
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<RecipeShareTarget>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Submit Recipe Share Complaint
  ///
  ///
  /// Parameters:
  /// * [shareId]
  /// * [shareComplaintInput]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [ShareComplaintReceipt] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<ShareComplaintReceipt>> submitRecipeShareComplaint({
    required String shareId,
    required ShareComplaintInput shareComplaintInput,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/shares/{share_id}/complaints'.replaceAll(
      '{'
      r'share_id'
      '}',
      shareId.toString(),
    );
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{...?headers},
      extra: <String, dynamic>{'secure': <Map<String, String>>[], ...?extra},
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      _bodyData = jsonEncode(shareComplaintInput);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _options.compose(_dio.options, _path),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    ShareComplaintReceipt? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<ShareComplaintReceipt, ShareComplaintReceipt>(
              rawData,
              'ShareComplaintReceipt',
              growable: true,
            );
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<ShareComplaintReceipt>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }
}
