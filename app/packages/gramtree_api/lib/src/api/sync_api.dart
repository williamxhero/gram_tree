//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';
import 'package:gramtree_api/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'package:gramtree_api/src/model/error_response.dart';
import 'package:gramtree_api/src/model/write_batch.dart';
import 'package:gramtree_api/src/model/write_batch_response.dart';

class SyncApi {
  final Dio _dio;

  const SyncApi(this._dio);

  /// 按账号上传登记式离线写入；原子幂等处理，未知依赖暂缓
  ///
  ///
  /// Parameters:
  /// * [writeBatch]
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
  /// Returns a [Future] containing a [Response] with a [WriteBatchResponse] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<WriteBatchResponse>> uploadWrites({
    required WriteBatch writeBatch,
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
    final _path = r'/v1/sync/writes';
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
      _bodyData = jsonEncode(writeBatch);
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

    WriteBatchResponse? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<WriteBatchResponse, WriteBatchResponse>(
              rawData,
              'WriteBatchResponse',
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

    return Response<WriteBatchResponse>(
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
