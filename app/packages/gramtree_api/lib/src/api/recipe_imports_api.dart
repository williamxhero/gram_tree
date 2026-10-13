//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';
import 'package:gramtree_api/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'package:gramtree_api/src/model/http_validation_error.dart';
import 'package:gramtree_api/src/model/import_input.dart';
import 'package:gramtree_api/src/model/import_original_out.dart';
import 'package:gramtree_api/src/model/import_out.dart';

class RecipeImportsApi {
  final Dio _dio;

  const RecipeImportsApi(this._dio);

  /// Get Import Original
  ///
  ///
  /// Parameters:
  /// * [importId]
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
  /// Returns a [Future] containing a [Response] with a [ImportOriginalOut] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<ImportOriginalOut>> getImportOriginal({
    required String importId,
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
    final _path = r'/v1/recipe-imports/{import_id}/original'.replaceAll(
      '{'
      r'import_id'
      '}',
      importId.toString(),
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

    ImportOriginalOut? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<ImportOriginalOut, ImportOriginalOut>(
              rawData,
              'ImportOriginalOut',
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

    return Response<ImportOriginalOut>(
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

  /// Import Recipe
  ///
  ///
  /// Parameters:
  /// * [importInput]
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
  /// Returns a [Future] containing a [Response] with a [ImportOut] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<ImportOut>> importRecipe({
    required ImportInput importInput,
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
    final _path = r'/v1/recipe-imports';
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
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      _bodyData = jsonEncode(importInput);
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

    ImportOut? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<ImportOut, ImportOut>(
              rawData,
              'ImportOut',
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

    return Response<ImportOut>(
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
