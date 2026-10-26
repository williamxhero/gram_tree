@TestOn('vm')
@Timeout(Duration(seconds: 90))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _target = 'integration_test/recipe_consequential_edit_test.dart';
const _sentinel = 'PRIVATE_ACTOR_TOKEN_COOKIE_QUERY_BODY_CONSOLE';
const _cleanupBudget = Duration(seconds: 10);

/// One deadline covers observing, exiting, and draining an owned host child.
/// This does not change the production driver's requestData timeout.
class _HostProcess {
  _HostProcess(
    this.process,
    this.audit, {
    this.budget = const Duration(seconds: 45),
    void Function(String)? onLine,
  }) {
    exitCode = process.exitCode.then((code) {
      exited = true;
      return code;
    });
    final stdoutDone = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) {
          lines.add(line);
          onLine?.call(line);
        });
    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .forEach(stderrText.write);
    _drained = Future.wait<void>([
      stdoutDone,
      stderrDone,
    ], eagerError: true).then((_) {});
  }

  final Process process;
  final File audit;
  final Duration budget;
  int? childExitCode;
  bool _supervisorTimedOut = false;
  bool _audited = false;
  final Stopwatch _clock = Stopwatch()..start();
  final lines = <String>[];
  final stderrText = StringBuffer();
  late final Future<int> exitCode;
  late final Future<void> _drained;
  Future<void>? _cleanup;
  bool exited = false;

  Future<T> _withinBudget<T>(Future<T> operation) async {
    final remaining = budget - _clock.elapsed;
    try {
      return await operation.timeout(
        remaining > Duration.zero ? remaining : Duration.zero,
      );
    } catch (_) {
      try {
        await dispose();
      } catch (_) {
        // Retain the original observation, timeout, or drain error.
      }
      rethrow;
    }
  }

  Future<void> observe(Future<void> observation) => _withinBudget(
    Future.any([
      observation,
      exitCode.then<void>((_) {
        throw StateError('Host child exited before the expected observation');
      }),
      _drained.then<void>((_) async {
        // Normal EOF can precede the exit notification. Do not terminate a
        // successfully exiting child just because its output closed first.
        await exitCode;
        throw StateError('Host output closed before the expected observation');
      }),
    ]),
  );

  Future<void> _readReport() async {
    final report =
        jsonDecode(await audit.readAsString()) as Map<String, dynamic>;
    if (report['reaped'] != true ||
        report['child_exit'] is! int ||
        report['child_pid'] is! int ||
        report['supervisor_pid'] is! int) {
      throw StateError('Host supervisor did not confirm child exit');
    }
    childExitCode = report['child_exit'] as int;
    _supervisorTimedOut = report['timed_out'] == true;
    if (!_audited) {
      _audited = true;
      // Only resource identity and status from this invocation's own Popen.
      // ignore: avoid_print
      print(
        jsonEncode({
          'event': 'host_fixture_audit',
          'supervisor_pid': report['supervisor_pid'],
          'child_pid': report['child_pid'],
          'child_exit': childExitCode,
          'supervisor_exit': await exitCode,
          'reaped': true,
          'timed_out': _supervisorTimedOut,
          'owner_stop': report['owner_stop'] == true,
        }),
      );
    }
  }

  Future<int> finish() async {
    await _withinBudget(exitCode);
    await _withinBudget(_drained);
    await _withinBudget(_readReport());
    if (_supervisorTimedOut) {
      throw TimeoutException('Host fixture budget expired');
    }
    return childExitCode!;
  }

  Future<void> dispose() => _cleanup ??= () async {
    await () async {
      if (!exited) {
        try {
          // EOF asks the supervisor to stop its own child. Dart Process.kill
          // can fall back to a PID on Windows, so it is never used here.
          await process.stdin.close();
        } catch (_) {
          // The supervisor may have exited before the pipe-close notification.
        }
      }
      await exitCode;
      await _drained;
      await _readReport();
    }().timeout(_cleanupBudget);
  }();
}

Future<_HostProcess> _startHostProcess(
  String executable,
  List<String> arguments, {
  required Directory directory,
  Map<String, String>? environment,
  Duration budget = const Duration(seconds: 45),
  void Function(String)? onLine,
}) async {
  final supervisor = File('${directory.path}/supervisor.py');
  final audit = File('${directory.path}/supervisor.json');
  // Popen retains the child handle from CreateProcess on Windows. Termination
  // and wait use that handle, never OpenProcess/a historical PID. On POSIX the
  // supervisor remains the parent until wait has reaped its own child.
  await supervisor.writeAsString(r'''
import json
import os
import subprocess
import sys
import threading

budget = float(sys.argv[1])
audit = sys.argv[2]
child = subprocess.Popen(sys.argv[3:], stdin=subprocess.DEVNULL)
lock = threading.Lock()
owner_stop = threading.Event()

def stop_owned_child():
    with lock:
        if child.poll() is None:
            child.kill()

def watch_owner():
    os.read(sys.stdin.fileno(), 1)
    owner_stop.set()
    stop_owned_child()

threading.Thread(target=watch_owner, daemon=True).start()
timed_out = False
try:
    code = child.wait(timeout=budget)
except subprocess.TimeoutExpired:
    timed_out = True
    stop_owned_child()
    code = child.wait(timeout=10)
with open(audit, "w", encoding="utf-8") as output:
    json.dump({"supervisor_pid": os.getpid(), "child_pid": child.pid,
               "child_exit": code, "reaped": True, "timed_out": timed_out,
               "owner_stop": owner_stop.is_set()}, output)
''');
  final process = await Process.start(
    Platform.isWindows ? 'python' : 'python3',
    [
      '-u',
      supervisor.path,
      '${budget.inMilliseconds / 1000}',
      audit.path,
      executable,
      ...arguments,
    ],
    workingDirectory: directory.path,
    environment: environment,
  );
  return _HostProcess(process, audit, budget: budget, onLine: onLine);
}

Future<File> _dartExecutable() async {
  final configFile = File('.dart_tool/package_config.json').absolute;
  final config =
      jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
  final driverPackage = (config['packages'] as List)
      .cast<Map<String, dynamic>>()
      .singleWhere((package) => package['name'] == 'flutter_driver');
  final packageRoot = configFile.uri.resolve(
    driverPackage['rootUri'] as String,
  );
  final sdk = Directory.fromUri(packageRoot).parent.parent;
  return File(
    '${sdk.path}/bin/cache/dart-sdk/bin/dart${Platform.isWindows ? '.exe' : ''}',
  );
}

/// A real W3C endpoint and a separate Dart driver process, without Chrome.
/// Assertions observe its wire protocol, exit status, and allowlisted stdout.
class _DriverRun {
  _DriverRun(this.server, this.directory);

  final HttpServer server;
  final Directory directory;
  final events = <Map<String, dynamic>>[];
  final commands = <Map<String, dynamic>>[];
  final firstError = Completer<void>();
  final firstEmptyResult = Completer<void>();
  final releaseResult = Completer<void>();
  _HostProcess? _host;
  List<String> get lines => _host!.lines;
  StringBuffer get stderrText => _host!.stderrText;
  bool get exited => _host!.exited;
  int _reads = 0;
  bool _requested = false;

  static Future<_DriverRun> start({
    bool enabled = true,
    String target = _target,
    String? errorKind,
    bool failExecution = false,
    bool testsPass = true,
    bool throwDiagnostic = false,
    bool throwCallback = false,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final directory = await Directory.systemTemp.createTemp('gramtree-w3c-');
    final run = _DriverRun(server, directory);
    addTearDown(run.dispose);
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      final params = body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(body) as Map<String, dynamic>;
      run.commands.add({
        'method': request.method,
        'path': request.uri.path,
        ...params,
      });
      Object? value;
      var status = HttpStatus.ok;
      final script = params['script'];
      if (script == r'return typeof(window.$flutterDriver)') {
        value = 'function';
      } else if (script is String &&
          script.startsWith(r'window.$flutterDriver(')) {
        run._requested = true;
        if (failExecution) {
          status = HttpStatus.notFound;
          value = {'error': 'invalid session id', 'message': _sentinel};
        }
      } else if (script == r'return $flutterDriverResult' && run._requested) {
        run._reads++;
        if (run._reads == 1 && errorKind != null) {
          status = errorKind == 'invalid session id'
              ? HttpStatus.notFound
              : HttpStatus.internalServerError;
          value = {
            'error': errorKind,
            'message': errorKind == 'unknown error'
                ? 'tab crashed $_sentinel'
                : _sentinel,
            'stacktrace': _sentinel,
            'data': {'url': 'https://example.invalid/?token=$_sentinel'},
          };
        } else if (run._reads <= 2) {
          if (!run.firstEmptyResult.isCompleted) {
            run.firstEmptyResult.complete();
          }
        } else {
          await run.releaseResult.future;
          value = jsonEncode({
            'isError': false,
            'response': {
              'message': jsonEncode({
                'result': testsPass.toString(),
                'failureDetails': testsPass
                    ? <String>[]
                    : [
                        jsonEncode({
                          'methodName': 'synthetic test',
                          'details': 'synthetic assertion',
                        }),
                      ],
                'data': {'e2e_step': 'synthetic_completed'},
              }),
            },
            'untrusted_extra': _sentinel,
          });
        }
      }
      request.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'value': value}));
      await request.response.close();
    });

    final packageConfig = File('.dart_tool/package_config.json').absolute;
    final driver = File('test_driver/integration_test.dart').absolute;
    final helper = File('test_driver/web_lifecycle_diagnostics.dart').absolute;
    final dart = await _dartExecutable();
    var entrypoint = driver;
    if (throwDiagnostic || throwCallback) {
      entrypoint = File('${directory.path}/driver.dart');
      await entrypoint.writeAsString('''
import 'dart:io';
import '${helper.uri}';
import 'package:integration_test/integration_test_driver.dart';
Future<void> main() async {
  Future<void> report(Map<String, dynamic>? data) async {
    ${throwCallback ? "throw StateError('CALLBACK_SENTINEL');" : ''}
  }
  ${enabled ? '''
  exit(await runDiagnosedIntegrationTest(
    responseDataCallback: report,
    emit: ${throwDiagnostic ? "(_) => throw StateError('$_sentinel')" : 'stdout.writeln'},
  ));''' : '''
  await integrationDriver(
    responseDataCallback: report,
    writeResponseOnFailure: true,
  );'''}
}
''');
    }
    run._host = await _startHostProcess(
      dart.path,
      ['--packages=${packageConfig.path}', entrypoint.path],
      directory: directory,
      environment: {
        'FLUTTER_TEST_OUTPUTS_DIR': '${directory.path}/outputs',
        'FLUTTER_WEB_TEST': 'true',
        'VM_SERVICE_URL': 'http://example.invalid/?token=$_sentinel',
        'DRIVER_SESSION_ID': _sentinel,
        'DRIVER_SESSION_URI': 'http://127.0.0.1:${server.port}/',
        'DRIVER_SESSION_SPEC': 'W3c',
        'DRIVER_SESSION_CAPABILITIES': jsonEncode({
          'browserName': 'chrome',
          'untrusted': _sentinel,
        }),
        'GRAMTREE_WEB_LIFECYCLE_DIAGNOSTICS': enabled ? '1' : '0',
        'GRAMTREE_WEB_LIFECYCLE_TARGET': target,
      },
      onLine: (line) {
        if (!line.startsWith('{"event":"web_driver_lifecycle",')) return;
        final event = jsonDecode(line) as Map<String, dynamic>;
        if (event['event'] != 'web_driver_lifecycle') return;
        run.events.add(event);
        if (event['stage'] == 'first_error' && !run.firstError.isCompleted) {
          run.firstError.complete();
        }
      },
    );
    return run;
  }

  Future<void> waitFor(Future<void> observation) => _host!.observe(observation);

  Future<int> finish() {
    if (!releaseResult.isCompleted) releaseResult.complete();
    return _host!.finish();
  }

  Future<void> dispose() async {
    if (!releaseResult.isCompleted) releaseResult.complete();
    try {
      await _host?.dispose();
    } finally {
      try {
        await server.close(force: true).timeout(_cleanupBudget);
      } finally {
        await directory.delete(recursive: true).timeout(_cleanupBudget);
      }
    }
  }
}

void _expectSafeEvents(_DriverRun run) {
  const keys = {
    'event',
    'stage',
    'target',
    'elapsed_ms',
    'commands',
    'result_reads',
    'empty_results',
    'errors',
    'result_ready',
    'error_kind',
    'first_error_ms',
    'first_session_loss_ms',
    'outcome',
  };
  for (final event in run.events) {
    expect(event.keys.every(keys.contains), isTrue);
    expect(event['target'], 'recipe_consequential_edit_test.dart');
    expect(event['elapsed_ms'], isNonNegative);
  }
  final encoded = jsonEncode(run.events);
  expect(encoded.contains(_sentinel), isFalse);
  expect(encoded.contains('example.invalid'), isFalse);
  expect(encoded.contains('request_data'), isFalse);
  expect(encoded.contains('session/'), isFalse);
}

Future<({int exitCode, List<List<String>> calls})> _runWebScript({
  String? diagnosticOverride,
  int flutterExit = 0,
}) async {
  final directory = await Directory.systemTemp.createTemp('gramtree-web-cli-');
  addTearDown(() => directory.delete(recursive: true).timeout(_cleanupBudget));
  final callsFile = File('${directory.path}/calls');
  final serverLog = File('${directory.path}/empty-server.log');
  await serverLog.writeAsString('');
  final script = File('../tool/web_test.sh').absolute;
  final bash = Platform.isWindows
      ? r'C:\Program Files\Git\bin\bash.exe'
      : '/usr/bin/bash';
  // Exported shell functions replace external commands at the CLI boundary.
  // No Flutter, browser, HTTP server, or existing backend is launched.
  final host = await _startHostProcess(
    bash,
    [
      '--noprofile',
      '--norc',
      '-c',
      r'''
fake_flutter() {
  printf '%s\0' "$GRAMTREE_WEB_LIFECYCLE_DIAGNOSTICS" \
    "$GRAMTREE_WEB_LIFECYCLE_TARGET" "$@" '__GRAMTREE_END__' >> "$FAKE_CALLS"
  return "$FAKE_FLUTTER_EXIT"
}
fake_chromedriver() { return 0; }
curl() { return 0; }
export -f fake_flutter fake_chromedriver curl
export FLUTTER=fake_flutter CHROMEDRIVER=fake_chromedriver
source "$0" "$@"
''',
      script.path.replaceAll('\\', '/'),
      'integration_test/app_test.dart',
      _target,
    ],
    directory: directory,
    environment: {
      'FAKE_CALLS': callsFile.path.replaceAll('\\', '/'),
      'FAKE_FLUTTER_EXIT': '$flutterExit',
      'GRAMTREE_E2E_SERVER': 'external',
      'GRAMTREE_E2E_LOG_FILE': serverLog.path.replaceAll('\\', '/'),
      'GRAMTREE_WEB_LIFECYCLE_DIAGNOSTICS': diagnosticOverride ?? '',
      'CHROMEDRIVER_LOG': '${directory.path}/driver.log'.replaceAll('\\', '/'),
      'CHROMEDRIVER_PORT': '4444',
      'CHROME_EXECUTABLE': '',
      'API_BASE_URL': 'http://127.0.0.1:1',
      'REACHABILITY_TEST_URL': 'http://127.0.0.1:2',
    },
  );
  addTearDown(host.dispose);
  final code = await host.finish();
  final calls = <List<String>>[];
  var current = <String>[];
  for (final token in (await callsFile.readAsString()).split('\u0000')) {
    if (token == '__GRAMTREE_END__') {
      calls.add(current);
      current = [];
    } else {
      current.add(token);
    }
  }
  expect(current, ['']);
  return (exitCode: code, calls: calls);
}

Future<_HostProcess> _startProcessFixture(String program) async {
  final directory = await Directory.systemTemp.createTemp('gramtree-host-');
  addTearDown(() => directory.delete(recursive: true).timeout(_cleanupBudget));
  final entrypoint = File('${directory.path}/main.dart');
  await entrypoint.writeAsString(program);
  final dart = await _dartExecutable();
  final host = await _startHostProcess(
    dart.path,
    [entrypoint.path],
    directory: directory,
    budget: const Duration(seconds: 5),
  );
  addTearDown(host.dispose);
  return host;
}

void _expectOriginalDriveArguments(List<String> call, String target) {
  expect(call.sublist(2), [
    'drive',
    '--timeout=300',
    '--profile',
    '--no-web-resources-cdn',
    '--driver=test_driver/integration_test.dart',
    '--driver-port=4444',
    '--target=$target',
    '-d',
    'web-server',
    '--browser-name=chrome',
    '--headless',
    '--driver-port=4444',
    '--dart-define=APP_ENV=dev',
    '--dart-define=API_BASE_URL=http://127.0.0.1:1',
    '--dart-define=REACHABILITY_TEST_URL=http://127.0.0.1:2',
  ]);
}

void main() {
  test(
    'host fixture reports an early child exit and drains its output',
    () async {
      final host = await _startProcessFixture(
        "import 'dart:io'; void main() => exit(7);",
      );
      await expectLater(
        host.observe(Completer<void>().future),
        throwsA(isA<StateError>()),
      );
      expect(host.exited, isTrue);
      expect(await host.finish(), 7);
    },
  );

  test('host budget terminates and awaits only its stalled child', () async {
    final host = await _startProcessFixture('''
import 'dart:async';
import 'dart:io';
void main() {
  stdout.writeln('host_ready');
  Timer.periodic(const Duration(hours: 1), (_) {});
}
''');
    await expectLater(host.finish(), throwsA(isA<TimeoutException>()));
    expect(host.lines, contains('host_ready'));
    expect(host.exited, isTrue);
    expect(host.childExitCode, isNot(0));
    expect(await host.process.exitCode.timeout(_cleanupBudget), 0);
  });

  test('standard script scopes diagnostics to the one target without changing argv', () async {
    final result = await _runWebScript();
    expect(result.exitCode, 0);
    expect(result.calls, hasLength(2));
    expect(result.calls[0].take(2), ['0', 'integration_test/app_test.dart']);
    expect(result.calls[1].take(2), ['1', _target]);
    _expectOriginalDriveArguments(
      result.calls[0],
      'integration_test/app_test.dart',
    );
    _expectOriginalDriveArguments(result.calls[1], _target);
  });

  test(
    'script explicit 0 opts out and a failed target is not retried',
    () async {
      final optedOut = await _runWebScript(diagnosticOverride: '0');
      expect(optedOut.exitCode, 0);
      expect(optedOut.calls, hasLength(2));
      expect(optedOut.calls.map((call) => call.first), ['0', '0']);
      final failed = await _runWebScript(flutterExit: 7);
      expect(failed.exitCode, 1);
      expect(failed.calls, hasLength(2));
      expect(failed.calls.map((call) => call[1]), [
        'integration_test/app_test.dart',
        _target,
      ]);
      _expectOriginalDriveArguments(failed.calls[1], _target);
    },
  );

  test('first reading 404 is emitted before the SDK wait finishes', () async {
    final run = await _DriverRun.start(errorKind: 'invalid session id');
    await run.waitFor(run.firstError.future);
    expect(run.exited, isFalse);
    expect(run.events.first['error_kind'], 'invalid_session');
    expect(run.events.first['result_ready'], isFalse);
    expect(await run.finish(), 0);
    expect(
      run.events.where((event) => event['stage'] == 'first_session_loss'),
      hasLength(1),
    );
    _expectSafeEvents(run);
  });

  test(
    'null polling then completion preserves simple protocol and exit',
    () async {
      final run = await _DriverRun.start();
      await run.waitFor(run.firstEmptyResult.future);
      expect(run.exited, isFalse);
      expect(await run.finish(), 0);
      expect(run.lines, contains('All tests passed.'));
      final finished = run.events.last;
      expect(finished['stage'], 'finished');
      expect(finished['outcome'], 'passed');
      expect(finished['result_ready'], isTrue);
      expect(finished['empty_results'], greaterThan(0));
      expect(finished['errors'], 0);
      final request = run.commands.singleWhere(
        (command) =>
            command['script'] is String &&
            (command['script'] as String).startsWith(r'window.$flutterDriver('),
      );
      expect(
        request['script'],
        r'''window.$flutterDriver('{"command":"request_data","timeout":"1200000"}')''',
      );
      expect(
        run.commands.where((command) => command['method'] == 'DELETE'),
        isEmpty,
      );
      _expectSafeEvents(run);
    },
  );

  test(
    'tab crash is classified without copying error or result bodies',
    () async {
      final run = await _DriverRun.start(errorKind: 'unknown error');
      await run.waitFor(run.firstError.future);
      expect(run.events.first['error_kind'], 'tab_crashed');
      expect(await run.finish(), 0);
      _expectSafeEvents(run);
    },
  );

  test(
    'default and nonallowlisted targets retain the original runner',
    () async {
      for (final options in [
        (enabled: false, target: _target),
        (enabled: true, target: 'integration_test/app_test.dart'),
        (enabled: true, target: _sentinel),
      ]) {
        final run = await _DriverRun.start(
          enabled: options.enabled,
          target: options.target,
        );
        expect(await run.finish(), 0);
        expect(run.events, isEmpty);
        expect(run.lines, contains('All tests passed.'));
      }
    },
  );

  test('business failure preserves callback and nonzero exit', () async {
    for (final enabled in [false, true]) {
      final run = await _DriverRun.start(enabled: enabled, testsPass: false);
      expect(await run.finish(), 1);
      expect(run.lines.join('\n'), contains('synthetic assertion'));
      expect(run.lines.join('\n'), contains('synthetic_completed'));
      _expectSafeEvents(run);
    }
  });

  test('diagnostic output failure cannot change the successful exit', () async {
    final run = await _DriverRun.start(throwDiagnostic: true);
    expect(await run.finish(), 0);
    expect(run.events, isEmpty);
    expect(run.lines, contains('All tests passed.'));
    expect(run.lines.join('\n').contains(_sentinel), isFalse);
  });

  test(
    'diagnostic failure preserves original driver exception and exit',
    () async {
      final original = await _DriverRun.start(
        enabled: false,
        failExecution: true,
      );
      final diagnosed = await _DriverRun.start(
        failExecution: true,
        throwDiagnostic: true,
      );
      final originalExit = await original.finish();
      expect(originalExit, isNot(0));
      expect(await diagnosed.finish(), originalExit);
      for (final run in [original, diagnosed]) {
        expect(
          run.stderrText.toString(),
          contains('Original error: InvalidSessionIdException (404)'),
        );
        expect(run.lines.join('\n').contains(_sentinel), isFalse);
      }
    },
  );

  test('callback exception retains the original exception and exit', () async {
    final original = await _DriverRun.start(
      enabled: false,
      throwCallback: true,
    );
    final diagnosed = await _DriverRun.start(throwCallback: true);
    final originalExit = await original.finish();
    expect(originalExit, isNot(0));
    expect(await diagnosed.finish(), originalExit);
    for (final run in [original, diagnosed]) {
      expect(run.stderrText.toString(), contains('CALLBACK_SENTINEL'));
      _expectSafeEvents(run);
    }
  });
}
