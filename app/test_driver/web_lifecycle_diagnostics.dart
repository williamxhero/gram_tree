// The simple-driver protocol below is adapted from Flutter's
// packages/integration_test/lib/integration_test_driver.dart.
// Copyright 2014 The Flutter Authors. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
// * Neither the name of Google Inc. nor the names of its contributors may be
//   used to endorse or promote products derived from this software without
//   specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

// This host-only driver retains the simple adapter's CLI messages.
// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/common.dart';
import 'package:integration_test/integration_test_driver.dart';

bool webLifecycleDiagnosticsEnabled(Map<String, String> environment) =>
    environment['FLUTTER_WEB_TEST'] == 'true' &&
    environment['GRAMTREE_WEB_LIFECYCLE_DIAGNOSTICS'] == '1' &&
    environment['GRAMTREE_WEB_LIFECYCLE_TARGET'] ==
        'integration_test/recipe_consequential_edit_test.dart';

/// An opt-in equivalent of the SDK simple adapter, not the extended handshake.
/// Returning the code lets the entrypoint retain exit(0)/exit(1), while a
/// transport or callback exception still escapes with its original stack.
Future<int> runDiagnosedIntegrationTest({
  required ResponseDataCallback responseDataCallback,
  required void Function(String) emit,
}) async {
  final diagnostics = _WebLifecycleDiagnostics(emit);
  // Raw FlutterDriver command files can contain reportData. The passive
  // listener below is the only new diagnostic output in this opt-in path.
  final driver = await FlutterDriver.connect(logCommunicationToFile: false);
  var outcome = 'driver_exception';
  try {
    diagnostics.attach(driver);
    final jsonResult = await driver.requestData(
      null,
      timeout: const Duration(minutes: 20),
    );
    final response = Response.fromJson(jsonResult);
    await driver.close();

    if (response.allTestsPassed) {
      print('All tests passed.');
      await responseDataCallback(response.data);
      outcome = 'passed';
      return 0;
    }
    print('Failure Details:\n${response.formattedFailureDetails}');
    await responseDataCallback(response.data);
    outcome = 'tests_failed';
    return 1;
  } finally {
    diagnostics.finish(outcome);
  }
}

class _WebLifecycleDiagnostics {
  _WebLifecycleDiagnostics(this.emit);

  final void Function(String) emit;
  final Stopwatch _clock = Stopwatch()..start();
  int _commands = 0;
  int _resultReads = 0;
  int _emptyResults = 0;
  int _errors = 0;
  int? _firstErrorMs;
  int? _firstSessionLossMs;
  bool _resultReady = false;

  void attach(FlutterDriver driver) {
    try {
      driver.webDriver.addEventListener((event) async {
        // Never stringify the event: it contains raw URLs, arguments, response
        // data, and exceptions. Only inspect this fixed SDK polling command.
        try {
          _commands++;
          final rawParams = event.params;
          // webdriver 3.x exposes the request body as encoded JSON, not a Map.
          final params = rawParams is String
              ? jsonDecode(rawParams)
              : rawParams;
          final isResultRead =
              params is Map &&
              params['script'] == r'return $flutterDriverResult';
          if (isResultRead) _resultReads++;
          final Object? error = event.exception;
          if (error != null) {
            _errors++;
            final kind = _errorKind(error);
            if (_firstErrorMs == null) {
              _firstErrorMs = _clock.elapsedMilliseconds;
              _write('first_error', errorKind: kind);
            }
            if (kind == 'invalid_session' && _firstSessionLossMs == null) {
              _firstSessionLossMs = _clock.elapsedMilliseconds;
              _write('first_session_loss', errorKind: kind);
            }
          } else if (isResultRead) {
            if (event.result == null) {
              _emptyResults++;
            } else {
              _resultReady = true;
            }
          }
        } catch (_) {
          // Observer failures must not be rethrown through the WebDriver
          // request client's finally block and replace the real test error.
          _write('unavailable');
        }
      });
    } catch (_) {
      _write('unavailable');
    }
  }

  String _errorKind(Object error) {
    // These are fixed library type names, not exception messages. Unknown
    // names are never copied into output.
    switch (error.runtimeType.toString()) {
      case 'InvalidSessionIdException':
        return 'invalid_session';
      case 'NoSuchWindowException':
        return 'no_such_window';
      case 'SocketException':
      case 'HttpException':
        return 'transport_error';
      case 'UnknownException':
        // W3C has no dedicated tab-crash error code. Classify this known
        // message in memory, but never emit any part of it.
        final Object? message = (error as dynamic).message;
        if (message is String && message.startsWith('tab crashed')) {
          return 'tab_crashed';
        }
    }
    return 'webdriver_error';
  }

  void finish(String outcome) => _write('finished', outcome: outcome);

  void _write(String stage, {String? errorKind, String? outcome}) {
    try {
      emit(
        jsonEncode({
          'event': 'web_driver_lifecycle',
          'stage': stage,
          'target': 'recipe_consequential_edit_test.dart',
          'elapsed_ms': _clock.elapsedMilliseconds,
          'commands': _commands,
          'result_reads': _resultReads,
          'empty_results': _emptyResults,
          'errors': _errors,
          'result_ready': _resultReady,
          'error_kind': ?errorKind,
          if (_firstErrorMs != null) 'first_error_ms': _firstErrorMs,
          if (_firstSessionLossMs != null)
            'first_session_loss_ms': _firstSessionLossMs,
          'outcome': ?outcome,
        }),
      );
    } catch (_) {
      // Even a broken stdout sink cannot change the test verdict or exception.
    }
  }
}
