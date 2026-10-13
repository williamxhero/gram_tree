//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';
import 'package:gramtree_api/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'package:gramtree_api/src/model/automation_out.dart';
import 'package:gramtree_api/src/model/cooking_constraints.dart';
import 'package:gramtree_api/src/model/cooking_constraints_out.dart';
import 'package:gramtree_api/src/model/error_response.dart';
import 'package:gramtree_api/src/model/field_lock_write.dart';
import 'package:gramtree_api/src/model/learning_run_out.dart';
import 'package:gramtree_api/src/model/page_taste_profile_change_out.dart';
import 'package:gramtree_api/src/model/taste_change_status_out.dart';
import 'package:gramtree_api/src/model/taste_profile_change_out.dart';
import 'package:gramtree_api/src/model/taste_profile_out.dart';
import 'package:gramtree_api/src/model/taste_profile_patch.dart';

class TasteProfileApi {
  final Dio _dio;

  const TasteProfileApi(this._dio);

  /// Change Facts
  ///
  ///
  /// Parameters:
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
  /// Returns a [Future] containing a [Response] with a [TasteChangeStatusOut] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<TasteChangeStatusOut>> changeFacts({
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
    final _path = r'/v1/me/taste-profile/change-facts';
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

    TasteChangeStatusOut? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<TasteChangeStatusOut, TasteChangeStatusOut>(
              rawData,
              'TasteChangeStatusOut',
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

    return Response<TasteChangeStatusOut>(
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

  /// Confirm Change
  ///
  ///
  /// Parameters:
  /// * [changeId]
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
  /// Returns a [Future] containing a [Response] with a [TasteProfileChangeOut] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<TasteProfileChangeOut>> confirmChange({
    required String changeId,
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
    final _path = r'/v1/me/taste-profile/changes/{change_id}/confirm'
        .replaceAll(
          '{'
          r'change_id'
          '}',
          changeId.toString(),
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

    TasteProfileChangeOut? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<TasteProfileChangeOut, TasteProfileChangeOut>(
              rawData,
              'TasteProfileChangeOut',
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

    return Response<TasteProfileChangeOut>(
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

  /// Get Automation
  ///
  ///
  /// Parameters:
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
  /// Returns a [Future] containing a [Response] with a [AutomationOut] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<AutomationOut>> getAutomation({
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
    final _path = r'/v1/me/taste-profile/automation';
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

    AutomationOut? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<AutomationOut, AutomationOut>(
              rawData,
              'AutomationOut',
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

    return Response<AutomationOut>(
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

  /// Get Cooking Constraints
  ///
  ///
  /// Parameters:
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
  /// Returns a [Future] containing a [Response] with a [CookingConstraintsOut] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<CookingConstraintsOut>> getCookingConstraints({
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
    final _path = r'/v1/me/taste-profile/cooking-constraints';
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

    CookingConstraintsOut? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<CookingConstraintsOut, CookingConstraintsOut>(
              rawData,
              'CookingConstraintsOut',
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

    return Response<CookingConstraintsOut>(
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

  /// Get Taste Profile
  ///
  ///
  /// Parameters:
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
  /// Returns a [Future] containing a [Response] with a [TasteProfileOut] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<TasteProfileOut>> getTasteProfile({
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
    final _path = r'/v1/me/taste-profile';
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

    TasteProfileOut? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<TasteProfileOut, TasteProfileOut>(
              rawData,
              'TasteProfileOut',
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

    return Response<TasteProfileOut>(
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

  /// Get Taste Profile Change
  ///
  ///
  /// Parameters:
  /// * [changeId]
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
  /// Returns a [Future] containing a [Response] with a [TasteProfileChangeOut] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<TasteProfileChangeOut>> getTasteProfileChange({
    required String changeId,
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
    final _path = r'/v1/me/taste-profile/changes/{change_id}'.replaceAll(
      '{'
      r'change_id'
      '}',
      changeId.toString(),
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

    TasteProfileChangeOut? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<TasteProfileChangeOut, TasteProfileChangeOut>(
              rawData,
              'TasteProfileChangeOut',
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

    return Response<TasteProfileChangeOut>(
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

  /// List Pending Changes
  ///
  ///
  /// Parameters:
  /// * [cursor] - 上一页返回的 next_cursor
  /// * [limit] - 每页条数，上限见配置项 api.page_size_max
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
  /// Returns a [Future] containing a [Response] with a [PageTasteProfileChangeOut] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<PageTasteProfileChangeOut>> listPendingChanges({
    String? cursor,
    int? limit = 20,
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
    final _path = r'/v1/me/taste-profile/changes/pending';
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

    final _queryParameters = <String, dynamic>{
      r'cursor': cursor,
      if (limit != null) r'limit': limit,
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    PageTasteProfileChangeOut? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<PageTasteProfileChangeOut, PageTasteProfileChangeOut>(
              rawData,
              'PageTasteProfileChangeOut',
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

    return Response<PageTasteProfileChangeOut>(
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

  /// List Taste Profile Changes
  ///
  ///
  /// Parameters:
  /// * [cursor] - 上一页返回的 next_cursor
  /// * [limit] - 每页条数，上限见配置项 api.page_size_max
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
  /// Returns a [Future] containing a [Response] with a [PageTasteProfileChangeOut] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<PageTasteProfileChangeOut>> listTasteProfileChanges({
    String? cursor,
    int? limit = 20,
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
    final _path = r'/v1/me/taste-profile/changes';
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

    final _queryParameters = <String, dynamic>{
      r'cursor': cursor,
      if (limit != null) r'limit': limit,
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    PageTasteProfileChangeOut? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<PageTasteProfileChangeOut, PageTasteProfileChangeOut>(
              rawData,
              'PageTasteProfileChangeOut',
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

    return Response<PageTasteProfileChangeOut>(
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

  /// Replace Cooking Constraints
  /// Replace cooking settings; an empty object clears them.  Omitted fields use empty defaults.
  ///
  /// Parameters:
  /// * [cookingConstraints]
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
  /// Returns a [Future] containing a [Response] with a [CookingConstraintsOut] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<CookingConstraintsOut>> replaceCookingConstraints({
    required CookingConstraints cookingConstraints,
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
    final _path = r'/v1/me/taste-profile/cooking-constraints';
    final _options = Options(
      method: r'PUT',
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
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      _bodyData = jsonEncode(cookingConstraints);
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

    CookingConstraintsOut? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<CookingConstraintsOut, CookingConstraintsOut>(
              rawData,
              'CookingConstraintsOut',
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

    return Response<CookingConstraintsOut>(
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

  /// Reset Taste Profile
  ///
  ///
  /// Parameters:
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
  /// Returns a [Future] containing a [Response] with a [TasteProfileOut] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<TasteProfileOut>> resetTasteProfile({
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
    final _path = r'/v1/me/taste-profile/reset';
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

    TasteProfileOut? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<TasteProfileOut, TasteProfileOut>(
              rawData,
              'TasteProfileOut',
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

    return Response<TasteProfileOut>(
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

  /// Revert Change
  ///
  ///
  /// Parameters:
  /// * [changeId]
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
  /// Returns a [Future] containing a [Response] with a [TasteProfileChangeOut] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<TasteProfileChangeOut>> revertChange({
    required String changeId,
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
    final _path = r'/v1/me/taste-profile/changes/{change_id}/revert'.replaceAll(
      '{'
      r'change_id'
      '}',
      changeId.toString(),
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

    TasteProfileChangeOut? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<TasteProfileChangeOut, TasteProfileChangeOut>(
              rawData,
              'TasteProfileChangeOut',
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

    return Response<TasteProfileChangeOut>(
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

  /// Run Learning
  ///
  ///
  /// Parameters:
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
  /// Returns a [Future] containing a [Response] with a [LearningRunOut] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<LearningRunOut>> runLearning({
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
    final _path = r'/v1/me/taste-profile/learning/run';
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

    LearningRunOut? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<LearningRunOut, LearningRunOut>(
              rawData,
              'LearningRunOut',
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

    return Response<LearningRunOut>(
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

  /// Save To Taste
  ///
  ///
  /// Parameters:
  /// * [recordId]
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
  /// Returns a [Future] containing a [Response] with a [List<TasteProfileChangeOut>] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<List<TasteProfileChangeOut>>> saveToTaste({
    required String recordId,
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
    final _path = r'/v1/me/taste-profile/records/{record_id}/save-to-taste'
        .replaceAll(
          '{'
          r'record_id'
          '}',
          recordId.toString(),
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

    List<TasteProfileChangeOut>? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<List<TasteProfileChangeOut>, TasteProfileChangeOut>(
              rawData,
              'List<TasteProfileChangeOut>',
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

    return Response<List<TasteProfileChangeOut>>(
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

  /// Set Field Lock
  ///
  ///
  /// Parameters:
  /// * [fieldLockWrite]
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
  /// Returns a [Future] containing a [Response] with a [AutomationOut] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<AutomationOut>> setFieldLock({
    required FieldLockWrite fieldLockWrite,
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
    final _path = r'/v1/me/taste-profile/locks';
    final _options = Options(
      method: r'PUT',
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
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      _bodyData = jsonEncode(fieldLockWrite);
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

    AutomationOut? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<AutomationOut, AutomationOut>(
              rawData,
              'AutomationOut',
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

    return Response<AutomationOut>(
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

  /// Update Taste Profile
  ///
  ///
  /// Parameters:
  /// * [tasteProfilePatch]
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
  /// Returns a [Future] containing a [Response] with a [TasteProfileOut] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<TasteProfileOut>> updateTasteProfile({
    required TasteProfilePatch tasteProfilePatch,
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
    final _path = r'/v1/me/taste-profile';
    final _options = Options(
      method: r'PATCH',
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
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      _bodyData = jsonEncode(tasteProfilePatch);
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

    TasteProfileOut? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<TasteProfileOut, TasteProfileOut>(
              rawData,
              'TasteProfileOut',
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

    return Response<TasteProfileOut>(
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
