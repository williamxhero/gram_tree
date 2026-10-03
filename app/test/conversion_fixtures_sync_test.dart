import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/conversion_cases.g.dart';

void main() {
  test('embedded conversion fixtures match the shared JSON tables', () {
    // The JSON files are the single source shared with the server tests; the
    // embedded copy only exists because rootBundle hangs on the web runner.
    for (final entry in embeddedConversionCases.entries) {
      expect(
        entry.value,
        File(entry.key).readAsStringSync(),
        reason: '${entry.key} changed: run tool/gen_conversion_fixtures.sh',
      );
    }
  }, skip: kIsWeb ? 'dart:io is unavailable in the browser' : false);
}
