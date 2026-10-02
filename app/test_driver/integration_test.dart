// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:integration_test/integration_test_driver.dart';

Future<void> _reportResponse(Map<String, dynamic>? data) async {
  print(
    'Integration response data:\n${const JsonEncoder.withIndent('  ').convert(data)}',
  );
  await writeResponseData(data);
}

Future<void> main() => integrationDriver(
  responseDataCallback: _reportResponse,
  writeResponseOnFailure: true,
);
