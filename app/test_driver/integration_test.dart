// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

// Print the reportData (e2e_step / e2e_error) so a failed CI run shows which
// step of the flow broke instead of only "test failed".
Future<void> _reportResponse(Map<String, dynamic>? data) async {
  print(
    'Integration response data:\n${const JsonEncoder.withIndent('  ').convert(data)}',
  );
  await writeResponseData(data);
}

Future<void> _grantBrowserClipboardPermission() async {
  if (Platform.environment['FLUTTER_WEB_TEST'] != 'true') return;
  final capabilities = jsonDecode(
    Platform.environment['DRIVER_SESSION_CAPABILITIES']!,
  ) as Map<String, dynamic>;
  if (capabilities['browserName'] != 'chrome') return;

  // WidgetTester taps are not browser user gestures. Grant the isolated test
  // origin permission before navigation so sharing uses the real clipboard.
  final driver = Uri.parse(Platform.environment['DRIVER_SESSION_URI']!);
  final session = Platform.environment['DRIVER_SESSION_ID']!;
  final origin = Uri.parse(Platform.environment['VM_SERVICE_URL']!).origin;
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.postUrl(
      driver.resolve('session/$session/goog/cdp/execute'),
    );
    request.headers.contentType = ContentType.json;
    final payload = utf8.encode(
      jsonEncode({
        'cmd': 'Browser.grantPermissions',
        'params': {
          'origin': origin,
          'permissions': ['clipboardReadWrite', 'clipboardSanitizedWrite'],
        },
      }),
    );
    // ChromeDriver does not parse chunked command bodies.
    request.contentLength = payload.length;
    request.add(payload);
    final response = await request.close().timeout(const Duration(seconds: 10));
    final body = jsonDecode(await utf8.decoder.bind(response).join()) as Map;
    if (response.statusCode != HttpStatus.ok) {
      throw StateError(
        'Browser clipboard permission failed: ${response.statusCode} '
        '${(body['value'] as Map?)?['message']}',
      );
    }
  } finally {
    client.close(force: true);
  }
}

Future<void> main() async {
  await _grantBrowserClipboardPermission();
  await integrationDriver(
    responseDataCallback: _reportResponse,
    writeResponseOnFailure: true,
  );
}
