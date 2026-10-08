// Standalone Android target: deliberately NOT named *_test.dart. The host
// installs one APK and force-stops the still-running seed, without clearing data.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show pid;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrintSynchronously;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/api/api_client.dart';
import 'package:gram_tree/app/app.dart';
import 'package:gram_tree/app/bootstrap.dart';
import 'package:gram_tree/app/router.dart';
import 'package:gram_tree/auth/auth_controller.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/config/app_config.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:gram_tree/network/reachability.dart';
import 'package:gram_tree/privacy/consent.dart';
import 'package:gram_tree/recipes/recipe_snapshot.dart';
import 'package:gram_tree/recipes/recipe_snapshot_provider.dart';
import 'package:gram_tree/storage/device_id.dart';
import 'package:gram_tree/storage/local_store.dart';
import 'package:gram_tree/ui_protocol/source_mark.dart';
import 'package:gramtree_api/gramtree_api.dart' show TokenPair;
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'event_pipeline_support.dart' show resetLocalAppState;

const _runId = String.fromEnvironment('PROCESS_DEATH_RUN_ID');
const _manifestKey = 'process_death_harness:$_runId';
const _whyType = 'ui.why_panel_opened';
const _ingredientId = 'restart-flour';

void _marker(String state) =>
    debugPrintSynchronously('GRAMTREE_PROCESS_DEATH $_runId $state pid=$pid');

String _sourceStack(String detail) {
  // Assertion reports contain expected/actual business payloads. Keep only
  // conventional stack frames with source locations, never their value dumps.
  final frame = RegExp(
    r'^#\d+\s+[A-Za-z0-9_.$<> ]+\s+\((?:package:|file:)[^()\s]+:\d+(?::\d+)?\)$',
  );
  return detail
      .split('\n')
      .map((line) => line.trim())
      .where(frame.hasMatch)
      .take(40)
      .join('\n');
}

void _diagnostic(String detail) {
  // Separate from protocol markers; keep each Android log entry and the whole
  // report bounded. Never print sessions, tokens, or request headers.
  final safe = detail
      .replaceAll(
        RegExp(r'''Bearer\s+[^\s,"']+''', caseSensitive: false),
        'Bearer [redacted]',
      )
      .replaceAll(
        RegExp(r'eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'),
        '[redacted JWT]',
      )
      .replaceAll(
        RegExp(
          r'''(?:access_token|refresh_token|authorization)\s*["']?\s*[:=]\s*[^\n]+''',
          caseSensitive: false,
        ),
        '[redacted auth field]',
      );
  for (final line in safe.split('\n').take(60)) {
    final bounded = line.length > 800 ? line.substring(0, 800) : line;
    debugPrintSynchronously(
      'GRAMTREE_PROCESS_DETAIL $_runId pid=$pid $bounded',
    );
  }
}

/// The existing simulated outage must affect health as well as business HTTP;
/// otherwise a live health poll would spuriously reset durable retry state.
/// Online checks still use the production HTTP probe against the real API.
class _OutageProbe implements ApiReachabilityProbe {
  _OutageProbe(this.offline, this.delegate);
  final bool Function() offline;
  final ApiReachabilityProbe delegate;
  @override
  Future<bool> check() => offline() ? Future.value(false) : delegate.check();
  @override
  void dispose() => delegate.dispose();
}

Map<String, dynamic> _entryJson(QueueEntry entry) => {
  'write': entry.write.toJson(),
  'sequence': entry.sequence,
  'state': entry.state.name,
  'attempts': entry.attempts,
  'reason': entry.reasonCode,
  'next_attempt_at': entry.nextAttemptAt?.toUtc().toIso8601String(),
  'result': entry.result,
  'business_record': entry.businessRecord,
  'confirmed_at': entry.confirmedAt?.toUtc().toIso8601String(),
};

Future<void> _until(
  WidgetTester tester,
  FutureOr<bool> Function() predicate, {
  String reason = 'condition',
  FutureOr<void> Function()? onTimeout,
}) async {
  _diagnostic('Waiting for $reason');
  for (var i = 0; i < 300; i++) {
    if (await predicate()) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (onTimeout != null) await onTimeout();
  _diagnostic('Timed out waiting for $reason');
  fail('Timed out waiting for $reason');
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  tester.testTextInput.hide();
  await tester.pump();
  final body = find.byKey(const ValueKey('recipe-detail-content'));
  // Public lazy-list key, not screen coordinates or private scroll controllers.
  for (var i = 0; i < 12; i++) {
    await tester.drag(body, const Offset(0, 500));
    await tester.pump(const Duration(milliseconds: 50));
  }
  for (var i = 0; i < 60 && finder.evaluate().isEmpty; i++) {
    await tester.drag(body, const Offset(0, -250));
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
}

Future<int> _count(Dio server, String token, String device) async {
  final response = await server.get<Map<String, dynamic>>(
    '/v1/dev/events/count',
    queryParameters: {'event_type': _whyType, 'device_id': device},
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data!['count'] as int;
}

Future<String> _seedAccountAndRecipe(
  ProviderContainer container,
  Dio server,
) async {
  final email = 'process-death-$_runId@example.com';
  await server.post(
    '/v1/auth/email/code',
    data: {'email': email, 'purpose': 'login'},
  );
  final code = await server.get<Map<String, dynamic>>(
    '/v1/dev/latest-email-code',
    queryParameters: {'email': email},
  );
  final login = await server.post<Map<String, dynamic>>(
    '/v1/auth/email/login',
    data: {'email': email, 'code': code.data!['code']},
  );
  // Persist through the actual Android secure-storage/session boundary.
  await container
      .read(sessionStoreProvider)
      .save(TokenPair.fromJson(login.data!));
  await container.read(consentProvider.notifier).agree();
  final token = container.read(sessionStoreProvider).current!.accessToken;
  final recipe = await server.post<Map<String, dynamic>>(
    '/v1/recipes',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
    data: {
      'dish_name': '进程重启面粉用量',
      'snapshot': {
        'format_version': 1,
        'servings': 2,
        'total_time_seconds': 60,
        'active_time_seconds': 60,
        'ingredients': [
          {
            'id': _ingredientId,
            'display_name': '面粉',
            'quantity': 100,
            'unit': 'g',
            'scaling_mode': 'proportional',
            'optional': false,
            'functional': false,
          },
        ],
        'steps': [
          {
            'id': 'mix',
            'instruction': '搅拌均匀',
            'ingredient_ids': [_ingredientId],
            'duration_seconds': 60,
            'unattended': false,
            'depends_on': <String>[],
          },
        ],
      },
    },
  );
  final data = recipe.data!;
  return '/recipes/${data['id']}/versions/${(data['version'] as Map)['id']}';
}

Future<void> _seed(
  WidgetTester tester,
  ProviderContainer container,
  Dio server,
) async {
  final path = await _seedAccountAndRecipe(container, server);
  await container.read(authProvider.future);
  container.read(routerProvider).go(path);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GramTreeApp()),
  );
  await _until(
    tester,
    () => find
        .byKey(const ValueKey('recipe-detail-content'))
        .evaluate()
        .isNotEmpty,
    reason: 'recipe detail mounted',
  );
  final increase = find.byKey(const ValueKey('recipe-serving-increase'));
  await _reveal(tester, increase);
  await tester.tap(increase);
  await tester.pumpAndSettle();
  final amount = find.byKey(
    const ValueKey('recipe-ingredient-amount-$_ingredientId'),
  );
  await _reveal(tester, amount);
  expect(tester.widget<Text>(amount).textSpan!.toPlainText(), '150 克');

  final snapshots = container.read(recipeSnapshotStoreProvider)!;
  final parts = path.split('/');
  FrozenRecipeSnapshot? frozen;
  await _until(tester, () async {
    frozen = await snapshots.read(parts[2], versionId: parts[4]);
    return frozen?.inputs['target_servings'] == 3 &&
        frozen?.render?['contract'] != null;
  }, reason: 'durable non-default snapshot');
  final queue = container.read(eventQueueProvider);
  final session = container.read(sessionStoreProvider).current!;
  final owner = session.user.id;
  final device = container.read(deviceIdProvider);
  await _until(
    tester,
    () async =>
        (await queue.entries(ownerId: owner))
            .every((e) => e.state == WriteState.confirmed),
    reason: 'online seed quiescence',
  );
  final baseline = await _count(server, session.accessToken, device);
  expect(baseline, 0);
  container.read(offlineSimulationProvider.notifier).set(true);
  await container.read(apiReachabilityProvider.notifier).check();
  final source = find.byKey(
    const ValueKey('recipe-source-mark-$_ingredientId'),
  );
  for (var i = 0; i < 2; i++) {
    await _reveal(tester, source);
    await tester.tap(source);
    await _until(
      tester,
      () => find.byKey(const ValueKey('why-panel')).evaluate().isNotEmpty,
      reason: 'seed WhyPanel ${i + 1} opened',
    );
    expect(find.text('原来：100 g'), findsOneWidget);
    expect(find.text('现在：150 克'), findsOneWidget);
    expect(find.textContaining('比例换算'), findsWidgets);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  }
  List<QueueEntry> entries = [];
  // Transport failures retain pending work with durable backoff. Deferred is
  // reserved for business/dependency responses, not the offline Dio exception.
  await _until(
    tester,
    () async {
      entries = await queue.entries(ownerId: owner);
      final writes = entries
          .where((e) => e.write.eventType == _whyType)
          .toList();
      return writes.length == 2 &&
          writes.every(
            (e) =>
                e.state == WriteState.pending &&
                e.reasonCode == 'network_or_server_failure' &&
                e.attempts > 0 &&
                e.nextAttemptAt != null &&
                e.nextAttemptAt!.isAfter(
                  DateTime.now().toUtc().add(const Duration(seconds: 3)),
                ),
          );
    },
    reason: 'two durable offline SourceMark writes and retry metadata',
    onTimeout: () => _diagnostic(
      'Queue retry states at ${DateTime.now().toUtc().toIso8601String()}: '
      '${jsonEncode([
        for (final entry in entries) {'id': entry.write.id, 'type': entry.write.eventType, 'state': entry.state.name, 'attempts': entry.attempts, 'reason': entry.reasonCode, 'next_attempt_at': entry.nextAttemptAt?.toUtc().toIso8601String()},
      ])}',
    ),
  );
  expect(await _count(server, session.accessToken, device), baseline);
  // Drain the snapshot store's serialized persistence tail after the page has
  // entered offline mode; do not retain an earlier local-render capture while
  // the authoritative display contract is still completing.
  frozen = await snapshots.read(parts[2], versionId: parts[4]);
  expect(frozen!.inputs['target_servings'], 3);
  expect(frozen!.render?['contract'], isNotNull);
  final manifest = {
    'run_id': _runId,
    'seed_pid': pid,
    'owner': owner,
    'device': device,
    'path': path,
    'snapshot': frozen!.toJson(),
    'entries': entries.map(_entryJson).toList(),
    'baseline': baseline,
    'write_ids': entries
        .where((e) => e.write.eventType == _whyType)
        .map((e) => e.write.id)
        .toList(),
  };
  // This awaited fence is last: ready never means an enqueue/save was merely
  // scheduled. The host kills us while this test is still alive and pumping.
  await container
      .read(localStoreProvider)
      .setString(_manifestKey, jsonEncode(manifest));
  _marker('SEED_READY');
  while (true) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _restore(
  WidgetTester tester,
  ProviderContainer container,
  Dio server,
  Map<String, dynamic> manifest,
) async {
  expect(manifest['run_id'], _runId);
  expect(pid, isNot(manifest['seed_pid']));
  final session = await container.read(sessionStoreProvider).load();
  expect(session, isNotNull);
  expect(session!.user.id, manifest['owner']);
  expect(container.read(deviceIdProvider), manifest['device']);
  final queue = container.read(eventQueueProvider);
  final owner = session.user.id;
  // No auth controller/root widget has been created yet: automatic upload cannot
  // repair missing/corrupt state before these persistence assertions observe it.
  final restored = await queue.entries(ownerId: owner);
  expect(restored.map(_entryJson).toList(), manifest['entries']);
  final path = manifest['path'] as String;
  final parts = path.split('/');
  final snapshots = RecipeSnapshotStore(
    container.read(localStoreProvider),
    accountId: owner,
  );
  final frozen = await snapshots.read(parts[2], versionId: parts[4]);
  expect(frozen, isNotNull);
  expect(frozen!.toJson(), manifest['snapshot']);
  expect(frozen.versionId, parts[4]);
  expect(frozen.dependencies['recipe_version'], parts[4]);
  expect(frozen.inputs['scale_mode'], 'servings');
  expect(frozen.inputs['target_servings'], 3);
  expect((frozen.render!['serving'] as Map)['target_servings'], 3);
  expect(
    ((frozen.render!['serving'] as Map)['ingredients'] as List)
        .single['display_quantity'],
    150,
  );
  _marker('RESTORE_DURABLE');

  container.read(offlineSimulationProvider.notifier).set(true);
  await container.read(authProvider.future);
  container.read(routerProvider).go(path);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GramTreeApp()),
  );
  await _until(
    tester,
    () => find
        .byKey(const ValueKey('recipe-detail-content'))
        .evaluate()
        .isNotEmpty,
    reason: 'recipe detail mounted',
  );
  await _reveal(tester, find.textContaining('离线快照 · 第 1 版'));
  await _reveal(tester, find.textContaining('已保存 3 份的用量与换算结果；离线只读'));
  final amount = find.byKey(
    const ValueKey('recipe-ingredient-amount-$_ingredientId'),
  );
  await _reveal(tester, amount);
  expect(tester.widget<Text>(amount).textSpan!.toPlainText(), '150 克');
  final source = find.byKey(
    const ValueKey('recipe-source-mark-$_ingredientId'),
  );
  await _reveal(tester, source);
  // Observe the rendered provenance without generating an extra why-open write;
  // the replay must contain exactly the two IDs created before process death.
  expect(
    find.descendant(of: source, matching: find.text('按场景调整')),
    findsOneWidget,
  );
  final mark = tester.widget<SourceMark>(source);
  expect(mark.value, '150 克');
  expect(mark.originalValue, '100 g');
  expect(mark.basisText, contains('比例换算'));
  expect(mark.feedbackEnabled, isFalse);
  expect(find.byKey(const ValueKey('recipe-serving-control')), findsNothing);
  expect(find.byKey(const ValueKey('recipe-measure-picker')), findsNothing);
  expect(find.byKey(const ValueKey('recipe-display-mode-base')), findsNothing);
  expect(
    (await snapshots.read(parts[2], versionId: parts[4]))!.toJson(),
    manifest['snapshot'],
  );
  expect(
    await _count(server, session.accessToken, manifest['device'] as String),
    manifest['baseline'],
  );
  _marker('RESTORE_OFFLINE');

  // ONLY the existing root listener receives this network-regain seam. No
  // uploader, manual retry, recorder, or reconstructed write is invoked here.
  container.read(offlineSimulationProvider.notifier).set(false);
  final ids = List<String>.from(manifest['write_ids'] as List);
  await _until(tester, () async {
    final entries = await queue.entries(ownerId: owner);
    return ids.every(
      (id) => entries.any(
        (e) => e.write.id == id && e.state == WriteState.confirmed,
      ),
    );
  }, reason: 'root-triggered automatic replay');
  final after = await queue.entries(ownerId: owner);
  expect(after.length, restored.length);
  for (final before in restored) {
    final now = after.singleWhere((e) => e.write.id == before.write.id);
    expect(now.write.toJson(), before.write.toJson());
    expect(now.sequence, before.sequence);
    expect(now.businessRecord, before.businessRecord);
    expect(now.state, WriteState.confirmed);
    expect(now.result, isNotNull);
    expect(now.confirmedAt, isNotNull);
  }
  final expectedCount = (manifest['baseline'] as int) + ids.length;
  expect(
    await _count(server, session.accessToken, manifest['device'] as String),
    expectedCount,
  );
  final replay = await server.post<Map<String, dynamic>>(
    '/v1/sync/writes',
    data: {
      'writes': [
        for (final entry in restored)
          if (ids.contains(entry.write.id)) entry.write.toJson(),
      ],
    },
    options: Options(
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    ),
  );
  final results = (replay.data!['results'] as List).cast<Map>();
  expect(results.length, ids.length);
  expect(results.map((r) => r['write_id']).toSet(), ids.toSet());
  expect(results.every((r) => r['status'] == 'already_processed'), isTrue);
  for (final result in results) {
    expect(
      result['result'],
      after.singleWhere((e) => e.write.id == result['write_id']).result,
    );
  }
  expect(
    await _count(server, session.accessToken, manifest['device'] as String),
    expectedCount,
  );
  expect(tester.takeException(), isNull);

  // Only after proving the original exact +2/replay contract, exercise the
  // restored read-only provenance visibly. Opening it is a real new observation
  // and must be accounted for, not suppressed or folded into the old writes.
  container.read(offlineSimulationProvider.notifier).set(true);
  await container.read(apiReachabilityProvider.notifier).check();
  await _reveal(tester, find.textContaining('离线快照 · 第 1 版'));
  await _reveal(tester, source);
  await tester.tap(source);
  final panel = find.byKey(const ValueKey('why-panel'));
  await _until(tester, () => panel.evaluate().isNotEmpty);
  expect(
    find.descendant(of: panel, matching: find.text('原来：100 g')).hitTestable(),
    findsOneWidget,
  );
  expect(
    find.descendant(of: panel, matching: find.text('现在：150 克')).hitTestable(),
    findsOneWidget,
  );
  expect(
    find
        .descendant(of: panel, matching: find.textContaining('比例换算'))
        .hitTestable(),
    findsOneWidget,
  );
  expect(
    find.descendant(of: panel, matching: find.byType(OutlinedButton)),
    findsNothing,
  );
  expect(find.text('这次不用'), findsNothing);
  expect(find.text('以后别这样'), findsNothing);
  expect(find.byKey(const ValueKey('recipe-serving-control')), findsNothing);
  final originalIds = after.map((e) => e.write.id).toSet();
  QueueEntry? observation;
  await _until(tester, () async {
    final fresh = (await queue.entries(ownerId: owner))
        .where((e) => !originalIds.contains(e.write.id))
        .toList();
    if (fresh.length != 1) return false;
    observation = fresh.single;
    return observation!.write.eventType == _whyType &&
        observation!.state == WriteState.pending &&
        observation!.reasonCode == 'network_or_server_failure' &&
        observation!.attempts > 0 &&
        observation!.nextAttemptAt != null;
  }, reason: 'new restored WhyPanel observation durably queued offline');
  expect(observation!.write.ownerId, owner);
  expect(observation!.write.deviceId, manifest['device']);
  expect(ids, isNot(contains(observation!.write.id)));
  final withObservation = await queue.entries(ownerId: owner);
  expect(withObservation.length, after.length + 1);
  for (final original in after) {
    expect(
      _entryJson(
        withObservation.singleWhere((e) => e.write.id == original.write.id),
      ),
      _entryJson(original),
    );
  }
  expect(
    await _count(server, session.accessToken, manifest['device'] as String),
    expectedCount,
  );
  expect(
    (await snapshots.read(parts[2], versionId: parts[4]))!.toJson(),
    manifest['snapshot'],
  );
  container.read(offlineSimulationProvider.notifier).set(false);
  await _until(tester, () async {
    final entries = await queue.entries(ownerId: owner);
    return entries.any(
      (e) =>
          e.write.id == observation!.write.id &&
          e.state == WriteState.confirmed,
    );
  }, reason: 'root-triggered replay of the new WhyPanel observation');
  final finalEntries = await queue.entries(ownerId: owner);
  for (final original in after) {
    expect(
      _entryJson(
        finalEntries.singleWhere((e) => e.write.id == original.write.id),
      ),
      _entryJson(original),
    );
  }
  expect(
    await _count(server, session.accessToken, manifest['device'] as String),
    expectedCount + 1,
  );
  await tester.tapAt(const Offset(10, 10));
  await tester.pumpAndSettle();
  expect(panel, findsNothing);
  expect(tester.takeException(), isNull);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  var restoredSuccessfully = false;
  _marker('BOOT');
  unawaited(
    binding.allTestsPassed.future.then((passed) {
      if (passed &&
          restoredSuccessfully &&
          binding.reportData?['verified'] == true) {
        _marker('PASSED');
      } else {
        _diagnostic(
          'Binding completed: passed=$passed restored=$restoredSuccessfully '
          'phase=${binding.reportData?['phase']}',
        );
        for (final failure in binding.failureMethodsDetails.take(2)) {
          _diagnostic('Framework failure in ${failure.methodName}');
          _diagnostic(_sourceStack(failure.details ?? ''));
        }
        _marker('FAILED');
      }
    }),
  );
  testWidgets('Android OS restart preserves frozen view and exact replay IDs', (
    tester,
  ) async {
    expect(
      _runId,
      isNotEmpty,
      reason: 'Use tool/android_process_death_test.py',
    );
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_manifestKey);
      if (raw == null) await resetLocalAppState();
      final container = ProviderContainer(
        overrides: [
          ...await bootstrapOverrides(),
          apiReachabilityProbeProvider.overrideWith((ref) {
            final probe = _OutageProbe(
              () => ref.read(offlineSimulationProvider),
              HttpApiReachabilityProbe(AppConfig.fromEnvironment().apiBaseUrl),
            );
            ref.onDispose(probe.dispose);
            return probe;
          }),
        ],
      );
      addTearDown(container.dispose);
      final server = Dio(
        BaseOptions(
          baseUrl: AppConfig.fromEnvironment().apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      addTearDown(() => server.close(force: true));
      if (raw == null) {
        binding.reportData = {'run_id': _runId, 'phase': 'seed'};
        await _seed(tester, container, server);
      } else {
        binding.reportData = {'run_id': _runId, 'phase': 'restore'};
        await _restore(
          tester,
          container,
          server,
          jsonDecode(raw) as Map<String, dynamic>,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        restoredSuccessfully = true;
        binding.reportData = {...?binding.reportData, 'verified': true};
      }
    } catch (error, stack) {
      // Do not serialize Dio request/response objects or auth headers. The host
      // consumes FAILED immediately, so synchronous details must precede it.
      final detail = error is DioException
          ? 'DioException type=${error.type.name} '
                'status=${error.response?.statusCode}'
          : error.runtimeType.toString();
      final sourceStack = _sourceStack(stack.toString());
      binding.reportData = {
        ...?binding.reportData,
        'error': detail,
        'stack': sourceStack,
      };
      _diagnostic(
        'phase=${binding.reportData?['phase']} $detail\n$sourceStack',
      );
      _marker('FAILED');
      rethrow;
    }
  }, timeout: const Timeout(Duration(minutes: 4)));
}
