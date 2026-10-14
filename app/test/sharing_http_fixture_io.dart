import 'dart:io';

import 'package:dio/dio.dart';

import 'helpers.dart';
import 'sharing_support.dart';

const _imagePath = '/s/$publicShareId/image';
const _foreignImagePath = '/snapshot-image';
const _redirectPath = '/redirected-image';

// All non-image routes retain their generated-model page fixtures. These paths
// alone reach Dio's unmodified IO adapter, including real redirect handling.
class _ImageTransportServer extends FakeServer {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if ({
      _imagePath,
      _foreignImagePath,
      _redirectPath,
    }.contains(options.uri.path)) {
      handler.next(options);
    } else {
      await super.onRequest(options, handler);
    }
  }
}

// Widget tests normally replace HttpClient with a rejecting client. Lift only
// that test harness restriction; never permit this fixture to contact the web.
class _LoopbackHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (_) => 'DIRECT';
    client.connectionFactory = (uri, proxyHost, proxyPort) {
      if (uri.host != InternetAddress.loopbackIPv4.address) {
        throw StateError(
          'Sharing transport fixtures may contact loopback only',
        );
      }
      return Socket.startConnect(uri.host, uri.port);
    };
    return client;
  }
}

class SharingImageHttpFixture {
  SharingImageHttpFixture._(this._api, this._foreign, this.redirect);

  static Future<SharingImageHttpFixture> start({required bool redirect}) async {
    final api = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    try {
      final foreign = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final fixture = SharingImageHttpFixture._(api, foreign, redirect);
      api.listen(fixture._serveApi);
      foreign.listen(fixture._serveForeign);
      return fixture;
    } catch (_) {
      await api.close(force: true);
      rethrow;
    }
  }

  final HttpServer _api;
  final HttpServer _foreign;
  final bool redirect;
  final FakeServer server = _ImageTransportServer();
  final imageRequests = <Recorded>[];
  final foreignRequests = <Recorded>[];

  String get apiBaseUrl => 'http://127.0.0.1:${_api.port}';
  String get foreignImageUrl =>
      'http://127.0.0.1:${_foreign.port}$_foreignImagePath';

  Future<T> withRealHttp<T>(Future<T> Function() action) =>
      HttpOverrides.runWithHttpOverrides(action, _LoopbackHttpOverrides());

  // Positive control: demonstrate this is a real followable 302, not a fake
  // interceptor that always rejects redirects regardless of production options.
  Future<List<int>> readImageWithDefaultRedirects() => withRealHttp(() async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('$apiBaseUrl$_imagePath'));
      final response = await request.close();
      return await response.fold<List<int>>(
        [],
        (bytes, chunk) => bytes..addAll(chunk),
      );
    } finally {
      client.close(force: true);
    }
  });

  Recorded _record(HttpRequest request) {
    final headers = <String, String>{};
    request.headers.forEach((name, values) => headers[name] = values.join(','));
    return Recorded(request.method, request.uri.path, null, headers);
  }

  Future<void> _serveApi(HttpRequest request) async {
    if (request.uri.path != _imagePath) {
      request.response.statusCode = HttpStatus.notFound;
    } else {
      imageRequests.add(_record(request));
      if (redirect) {
        request.response.statusCode = HttpStatus.found;
        request.response.headers.set(
          HttpHeaders.locationHeader,
          'http://127.0.0.1:${_foreign.port}$_redirectPath',
        );
      } else {
        request.response.headers.contentType = ContentType('image', 'png');
        request.response.add(testImageBytes);
      }
    }
    await request.response.close();
  }

  Future<void> _serveForeign(HttpRequest request) async {
    foreignRequests.add(_record(request));
    request.response.headers.contentType = ContentType('image', 'png');
    request.response.add(testImageBytes);
    await request.response.close();
  }

  Future<void> close() async {
    await _api.close(force: true);
    await _foreign.close(force: true);
  }
}
