import 'package:dio/dio.dart';

/// Keep this restart fixture on the frozen, read-only conversion branch. Fresh
/// accounts otherwise acquire a default taste profile and offline projection.
/// Only taste/profile availability is simulated; all other APIs remain real.
void installFrozenConversionFixture(Dio dio) {
  dio.interceptors.insert(
    0,
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final path = options.uri.path;
        final unavailable =
            (options.method == 'GET' && path == '/v1/me/taste-profile') ||
            (options.method == 'POST' &&
                RegExp(r'^/v1/recipes/[^/]+/personalized$').hasMatch(path));
        if (!unavailable) {
          handler.next(options);
          return;
        }
        // A missing endpoint must not mark the whole API as unreachable: health,
        // recipe conversion, composition and the real replay must still work.
        handler.reject(
          DioException(
            requestOptions: options,
            response: Response<void>(requestOptions: options, statusCode: 404),
            type: DioExceptionType.badResponse,
          ),
        );
      },
    ),
  );
}
