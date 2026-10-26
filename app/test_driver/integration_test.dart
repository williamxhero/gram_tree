// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

import 'web_lifecycle_diagnostics.dart';

// Print the reportData (e2e_step / e2e_error) so a failed CI run shows which
// step of the flow broke instead of only "test failed".
Future<void> _reportResponse(Map<String, dynamic>? data) async {
  print(
    'Integration response data:\n${const JsonEncoder.withIndent('  ').convert(data)}',
  );
  await writeResponseData(data);
}

Future<void> main() async {
  if (webLifecycleDiagnosticsEnabled(Platform.environment)) {
    exit(
      await runDiagnosedIntegrationTest(
        responseDataCallback: _reportResponse,
        emit: stdout.writeln,
      ),
    );
  }
  await integrationDriver(
    responseDataCallback: _reportResponse,
    writeResponseOnFailure: true,
  );
}
