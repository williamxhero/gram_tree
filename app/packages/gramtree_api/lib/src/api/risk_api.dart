//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';
import 'package:gramtree_api/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'package:gramtree_api/src/model/captcha_verification.dart';
import 'package:gramtree_api/src/model/captcha_verification_out.dart';
import 'package:gramtree_api/src/model/error_response.dart';

class RiskApi {
  final Dio _dio;

  const RiskApi(this._dio);

  /// 完成访问安全验证
  ///
  ///
  /// Parameters:
  /// * [captchaVerification]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [CaptchaVerificationOut] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<CaptchaVerificationOut>> verifyCaptcha({
    required CaptchaVerification captchaVerification,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/risk/captcha';
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{...?headers},
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
      _bodyData = jsonEncode(captchaVerification);
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

    CaptchaVerificationOut? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<CaptchaVerificationOut, CaptchaVerificationOut>(
              rawData,
              'CaptchaVerificationOut',
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

    return Response<CaptchaVerificationOut>(
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
