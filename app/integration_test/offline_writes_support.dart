// Shared real-backend acceptance. Web uses an in-memory queue substitute;
// only process_death_harness.dart proves native on-disk restart persistence.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/api/api_client.dart';
import 'package:gram_tree/app/router.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:gram_tree/network/reachability.dart';
import 'package:integration_test/integration_test.dart';

import 'event_pipeline_support.dart' as support;

const editedInstruction = '搅拌均匀后静置 3 分钟';

void acceptanceStep(String step) {
  final binding = IntegrationTestWidgetsFlutterBinding.instance;
  binding.reportData = {...?binding.reportData, 'e2e_step': step};
}

Future<int> recipeSavedFactCount(Dio server, String token) async =>
    (await server.get<Map<String, dynamic>>(
          '/v1/dev/events/count',
          queryParameters: {'event_type': 'recipe.version_saved'},
          options: authorization(token),
        )).data!['count']
        as int;

/// Outage affects health too: real online health probes remain unchanged.
class AcceptanceOutageProbe implements ApiReachabilityProbe {
  AcceptanceOutageProbe(this.offline, this.delegate);
  final bool Function() offline;
  final ApiReachabilityProbe delegate;
  @override
  Future<bool> check() => offline() ? Future.value(false) : delegate.check();
  @override
  void dispose() => delegate.dispose();
}

Options authorization(String token) =>
    Options(headers: {'Authorization': 'Bearer $token'});

Map<String, dynamic> retainedEntry(QueueEntry entry) => {
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

Future<void> revealAcceptance(WidgetTester tester, Finder finder) async {
  tester.testTextInput.hide();
  await tester.pump();
  final editor = find.byKey(const ValueKey('recipe-editor-content'));
  final scrollable = editor.evaluate().isNotEmpty
      ? find.descendant(of: editor, matching: find.byType(Scrollable)).first
      : find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first;
  // Use the established recipe helper's lazy-row/gutter scrolling approach.
  Offset origin() {
    final rect = tester.getRect(scrollable);
    return Offset(rect.left + 10, rect.center.dy);
  }

  for (var i = 0; i < 12; i++) {
    await tester.dragFrom(origin(), const Offset(0, 500));
    await tester.pump(const Duration(milliseconds: 50));
  }
  for (var i = 0; i < 60 && finder.evaluate().isEmpty; i++) {
    await tester.dragFrom(origin(), const Offset(0, -250));
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await support.settle(tester);
  expect(finder.hitTestable(), findsOneWidget);
}

Future<void> goAcceptance(
  WidgetTester tester,
  ProviderContainer container,
  String path,
) async {
  acceptanceStep('navigate $path');
  container.read(routerProvider).go(path);
  await support.settle(tester);
}

Future<Map<String, dynamic>> seedAcceptanceRecipe(
  Dio server,
  String token,
) async => (await server.post<Map<String, dynamic>>(
  '/v1/recipes',
  options: authorization(token),
  data: {
    'dish_name': '离线手工修改验收',
    'snapshot': {
      'format_version': 1,
      'servings': 2,
      'total_time_seconds': 60,
      'active_time_seconds': 60,
      'ingredients': [
        {
          'id': 'ingredient-1',
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
          'id': 'step-1',
          'instruction': '搅拌均匀',
          'ingredient_ids': ['ingredient-1'],
          'duration_seconds': 60,
          'unattended': false,
          'depends_on': <String>[],
        },
      ],
    },
  },
)).data!;

Future<Map<String, dynamic>> seedOfflineBusinessWrites(
  WidgetTester tester,
  ProviderContainer container,
  Dio server, {
  required String recipeId,
  required String versionId,
  required String stepId,
  required String email,
}) async {
  acceptanceStep('seed business baselines');
  final token = support.accessTokenOf(container);
  final factBaseline = await recipeSavedFactCount(server, token);
  final baseline = (await server.get<Map<String, dynamic>>(
    '/v1/recipes/$recipeId/versions/$versionId',
    options: authorization(token),
  )).data!;
  final measure = (await server.post<Map<String, dynamic>>(
    '/v1/me/measures',
    options: authorization(token),
    data: {'name': '验收量勺', 'kind': 'spoon', 'capacity_ml': 15},
  )).data!;
  final measureId = measure['id'] as String;
  await goAcceptance(tester, container, '/me/measures');
  await support.waitFor(tester, find.byKey(ValueKey('measure-$measureId')));
  await goAcceptance(
    tester,
    container,
    '/recipes/$recipeId/edit?versionId=$versionId',
  );
  await support.waitFor(
    tester,
    find.byKey(const ValueKey('recipe-editor-content')),
  );
  final instruction = find.byKey(
    ValueKey(
      stepId == 'step-1'
          ? 'recipe-step-instruction'
          : 'recipe-step-instruction-$stepId',
    ),
  );
  await revealAcceptance(tester, instruction);
  container.read(offlineSimulationProvider.notifier).set(true);
  await container.read(apiReachabilityProvider.notifier).check();
  await tester.enterText(instruction, editedInstruction);
  final save = find.byKey(const ValueKey('save-recipe-button'));
  await revealAcceptance(tester, save);
  await tester.tap(save);
  await support.waitFor(
    tester,
    find.byKey(const ValueKey('offline-recipe-status')),
  );
  expect(find.text('待同步'), findsWidgets);
  expect(find.text(editedInstruction), findsOneWidget);

  await goAcceptance(tester, container, '/me/measures');
  await support.waitFor(tester, find.byKey(ValueKey('measure-$measureId')));
  await tester.tap(find.text('验收量勺'));
  await support.waitFor(tester, find.byKey(const ValueKey('measure-capacity')));
  await tester.enterText(find.byKey(const ValueKey('measure-capacity')), '22');
  await tester.tap(find.byKey(const ValueKey('measure-save')));
  await support.waitFor(tester, find.textContaining('22'));
  expect(find.text('待同步'), findsWidgets);
  final queue = container.read(eventQueueProvider);
  final owner = container.read(sessionStoreProvider).current!.user.id;
  List<QueueEntry> business = [];
  await support.waitUntil(tester, () async {
    business = (await queue.entries(ownerId: owner))
        .where(
          (entry) =>
              entry.write.writeType == 'recipe_version.save' ||
              entry.write.writeType == 'personal_measure.change',
        )
        .toList();
    return business.length == 2 &&
        business.every(
          (entry) =>
              entry.state == WriteState.pending &&
              entry.attempts > 0 &&
              entry.reasonCode == 'network_or_server_failure' &&
              entry.nextAttemptAt != null &&
              entry.nextAttemptAt!.isAfter(
                DateTime.now().toUtc().add(const Duration(seconds: 3)),
              ),
        );
  });
  final recipeWrite = business.singleWhere(
    (e) => e.write.writeType == 'recipe_version.save',
  );
  expect(recipeWrite.write.payload['baseline_version_id'], versionId);
  expect(recipeWrite.businessRecord, isNotNull);
  final manifest = {
    'owner': owner,
    'email': email,
    'recipe_id': recipeId,
    'version_id': versionId,
    'step_id': stepId,
    'baseline': baseline,
    'fact_baseline': factBaseline,
    'measure_id': measureId,
    'candidate_id': recipeWrite.write.payload['candidate_version_id'],
    'entries': business.map(retainedEntry).toList(),
  };
  // Independent HTTP observer remains online during the app's outage.
  await assertBusinessServerState(server, token, manifest, confirmed: false);
  return jsonDecode(jsonEncode(manifest)) as Map<String, dynamic>;
}

Future<void> assertBusinessServerState(
  Dio server,
  String token,
  Map<String, dynamic> manifest, {
  required bool confirmed,
}) async {
  acceptanceStep(
    confirmed
        ? 'verify authoritative version, fact and history'
        : 'verify offline writes absent from server',
  );
  expect(
    await recipeSavedFactCount(server, token),
    (manifest['fact_baseline'] as int) + (confirmed ? 1 : 0),
  );
  final recipeId = manifest['recipe_id'];
  final original = (await server.get<Map<String, dynamic>>(
    '/v1/recipes/$recipeId/versions/${manifest['version_id']}',
    options: authorization(token),
  )).data!;
  expect(
    (original['version'] as Map)['snapshot'],
    (manifest['baseline'] as Map)['version']['snapshot'],
  );
  final versions =
      (await server.get<Map<String, dynamic>>(
            '/v1/recipes/$recipeId/versions',
            options: authorization(token),
          )).data!['items']
          as List;
  expect(versions, hasLength(confirmed ? 2 : 1));
  if (confirmed) {
    final candidate = (await server.get<Map<String, dynamic>>(
      '/v1/recipes/$recipeId/versions/${manifest['candidate_id']}',
      options: authorization(token),
    )).data!;
    expect((candidate['version'] as Map)['version_number'], 2);
    expect(
      ((candidate['version'] as Map)['snapshot']['steps'] as List)
          .single['instruction'],
      editedInstruction,
    );
  }
  final measure = (await server.get<Map<String, dynamic>>(
    '/v1/me/measures/${manifest['measure_id']}',
    options: authorization(token),
  )).data!;
  expect(measure['capacity_ml'], confirmed ? 22 : 15);
  final history =
      (await server.get<Map<String, dynamic>>(
            '/v1/me/measures/${manifest['measure_id']}/history',
            options: authorization(token),
          )).data!['items']
          as List;
  final entries = (manifest['entries'] as List).cast<Map>();
  final measureWrite = entries.singleWhere(
    (e) => (e['write'] as Map)['write_type'] == 'personal_measure.change',
  );
  final changes = history
      .where(
        (row) => row['write_id'] == (measureWrite['write'] as Map)['write_id'],
      )
      .toList();
  expect(changes, hasLength(confirmed ? 1 : 0));
  if (confirmed) {
    expect(changes.single['field'], 'capacity_ml');
    expect(changes.single['new_value'], 22);
    expect(changes.single['outcome'], 'won');
  }
}

Future<void> showRestoredOfflineBusiness(
  WidgetTester tester,
  ProviderContainer container,
  Map<String, dynamic> manifest,
) async {
  await goAcceptance(tester, container, '/recipes/${manifest['recipe_id']}');
  await support.waitFor(
    tester,
    find.byKey(const ValueKey('offline-recipe-status')),
  );
  expect(find.text(editedInstruction), findsOneWidget);
  expect(find.text('待同步'), findsWidgets);
  await goAcceptance(tester, container, '/me/measures');
  await support.waitFor(
    tester,
    find.byKey(ValueKey('measure-${manifest['measure_id']}')),
  );
  expect(find.textContaining('22'), findsWidgets);
  expect(find.text('待同步'), findsWidgets);
  await tester.tap(
    find.byKey(ValueKey('measure-history-${manifest['measure_id']}')),
  );
  await support.waitFor(tester, find.textContaining('容量（毫升）'));
  expect(find.textContaining('待同步'), findsWidgets);
  await tester.tap(find.text('关闭'));
  await support.settle(tester);
}

Future<void> loginAcceptance(WidgetTester tester, String email) async {
  await support.waitFor(tester, find.byKey(const ValueKey('login-email')));
  await tester.enterText(find.byKey(const ValueKey('login-email')), email);
  acceptanceStep('request login code');
  await support.tapText(tester, '发送验证码');
  final codeInput = find.byKey(const ValueKey('code-input'));
  final cooldown = find.textContaining('秒后可以重新发送');
  await support.waitUntil(
    tester,
    () => codeInput.evaluate().isNotEmpty || cooldown.evaluate().isNotEmpty,
    tries: 100,
    step: const Duration(milliseconds: 100),
  );
  if (cooldown.evaluate().isNotEmpty) {
    final message = tester.widget<Text>(cooldown).data!;
    final seconds = int.parse(
      RegExp(r'(\d+) 秒后可以重新发送').firstMatch(message)!.group(1)!,
    );
    expect(seconds, inInclusiveRange(1, 60));
    acceptanceStep('wait advertised server OTP cooldown before A relogin');
    // Pumped Flutter time cannot expire Redis's real-clock rate limit. Model
    // the user's explicit cooldown, without bypassing auth or broadening waits.
    await tester.runAsync(
      () => Future<void>.delayed(Duration(seconds: seconds + 1)),
    );
    await support.settle(tester);
    // A route transition can finish while real time advances; never issue a
    // second request if the preceding user request already opened verification.
    if (codeInput.evaluate().isEmpty) {
      await support.tapText(tester, '发送验证码');
    }
  }
  await support.waitFor(tester, codeInput);
  await tester.enterText(
    find.byKey(const ValueKey('code-input')),
    await support.latestEmailCode(email),
  );
  await support.waitFor(
    tester,
    find.byKey(const ValueKey('primary-create-button')),
  );
}

/// Public retry and logout dialog, then A/B/A. No synthetic queue mutation.
Future<void> retryAndSwitchAccounts(
  WidgetTester tester,
  ProviderContainer container,
  Map<String, dynamic> manifest,
) async {
  final queue = container.read(eventQueueProvider);
  final owner = manifest['owner'] as String;
  final originals = (manifest['entries'] as List).cast<Map>();
  await goAcceptance(tester, container, '/me/sync');
  final count = find.byKey(const ValueKey('sync-unfinished-count'));
  await support.waitFor(tester, count);
  final retry = find.byKey(const ValueKey('sync-manual-retry'));
  await revealAcceptance(tester, retry);
  expect(tester.widget<FilledButton>(retry).onPressed, isNotNull);
  acceptanceStep('manual offline retry preserves writes and fresh budgets');
  await tester.tap(retry);
  await support.waitUntil(tester, () async {
    final entries = await queue.entries(ownerId: owner);
    final recipe = entries.singleWhere(
      (e) => e.write.writeType == 'recipe_version.save',
    );
    final measure = entries.singleWhere(
      (e) => e.write.writeType == 'personal_measure.change',
    );
    // A manual retry resets both budgets. After the first transport failure the
    // uploader deliberately leaves later fresh writes unattempted during outage.
    return recipe.state == WriteState.pending &&
        recipe.attempts > 0 &&
        recipe.reasonCode == 'network_or_server_failure' &&
        recipe.nextAttemptAt != null &&
        measure.state == WriteState.pending &&
        measure.attempts == 0 &&
        measure.reasonCode == null &&
        measure.nextAttemptAt == null &&
        tester.widget<FilledButton>(retry).onPressed != null;
  });
  final retained = await queue.entries(ownerId: owner);
  for (final before in originals) {
    final now = retained.singleWhere(
      (e) => e.write.id == (before['write'] as Map)['write_id'],
    );
    expect(now.write.toJson(), before['write']);
    expect(now.sequence, before['sequence']);
    expect(now.businessRecord, before['business_record']);
    expect(now.result, isNull);
    expect(now.confirmedAt, isNull);
  }
  final pendingCount = retained.where((e) => e.needsSync).length;
  expect(pendingCount, greaterThanOrEqualTo(2));
  expect(tester.widget<Text>(count).data, '未完成 $pendingCount 条');
  await goAcceptance(tester, container, '/me/settings');
  await revealAcceptance(tester, find.text('退出登录'));
  await tester.tap(find.text('退出登录'));
  await support.waitFor(tester, find.text('还有 $pendingCount 条内容未同步'));
  expect(find.textContaining('其他账号无法查看或上传'), findsOneWidget);
  await tester.tap(find.text('取消'));
  await support.settle(tester);
  expect(container.read(sessionStoreProvider).current!.user.id, owner);
  await tester.tap(find.text('退出登录'));
  await support.waitFor(tester, find.byType(AlertDialog));
  await tester.tap(
    find.descendant(of: find.byType(AlertDialog), matching: find.text('退出登录')),
  );
  await support.waitFor(tester, find.byKey(const ValueKey('login-email')));
  expect(container.read(sessionStoreProvider).current, isNull);
  await support.waitUntil(
    tester,
    () async =>
        (await queue.entries(ownerId: owner))
            .where((e) => e.needsSync)
            .every((e) => e.state == WriteState.loginPaused),
  );
  final paused = await queue.entries(ownerId: owner);
  expect(paused, hasLength(retained.length));
  for (final before in retained) {
    final now = paused.singleWhere((e) => e.write.id == before.write.id);
    expect(now.write.toJson(), before.write.toJson());
    expect(now.sequence, before.sequence);
    expect(now.businessRecord, before.businessRecord);
    expect(now.result, before.result);
    expect(now.confirmedAt, before.confirmedAt);
    if (before.needsSync) {
      expect(now.state, WriteState.loginPaused);
      expect(now.reasonCode, 'login_required');
      expect(now.attempts, before.attempts);
    } else {
      expect(retainedEntry(now), retainedEntry(before));
    }
  }
  container.read(offlineSimulationProvider.notifier).set(false);
  final emailB =
      'offline-owner-b-${DateTime.now().microsecondsSinceEpoch}@example.com';
  await loginAcceptance(tester, emailB);
  final ownerB = container.read(sessionStoreProvider).current!.user.id;
  expect(ownerB, isNot(owner));
  await goAcceptance(tester, container, '/me/sync');
  await support.waitFor(tester, count);
  for (final before in originals) {
    expect(
      find.byKey(ValueKey('sync-item-${(before['write'] as Map)['write_id']}')),
      findsNothing,
    );
  }
  await goAcceptance(tester, container, '/recipes');
  await support.waitFor(tester, find.text('还没有菜谱'));
  expect(find.text(editedInstruction), findsNothing);
  await goAcceptance(tester, container, '/me/measures');
  await support.waitFor(tester, find.byKey(const ValueKey('measure-add')));
  expect(find.text('验收量勺'), findsNothing);
  expect(
    (await queue.entries(ownerId: owner)).map(retainedEntry).toList(),
    paused.map(retainedEntry).toList(),
  );
  await goAcceptance(tester, container, '/me/settings');
  await revealAcceptance(tester, find.text('退出登录'));
  await tester.tap(find.text('退出登录'));
  await support.waitFor(tester, find.byType(AlertDialog));
  await tester.tap(
    find.descendant(of: find.byType(AlertDialog), matching: find.text('退出登录')),
  );
  await loginAcceptance(tester, manifest['email'] as String);
  expect(container.read(sessionStoreProvider).current!.user.id, owner);
}

Future<void> replayAndVerifyBusiness(
  WidgetTester tester,
  ProviderContainer container,
  Dio server,
  Map<String, dynamic> manifest,
) async {
  final queue = container.read(eventQueueProvider);
  final owner = manifest['owner'] as String;
  final originals = (manifest['entries'] as List).cast<Map>();
  container.read(offlineSimulationProvider.notifier).set(false);
  await support.waitUntil(tester, () async {
    final current = await queue.entries(ownerId: owner);
    return originals.every(
      (before) => current.any(
        (now) =>
            now.write.id == (before['write'] as Map)['write_id'] &&
            now.state == WriteState.confirmed,
      ),
    );
  });
  final current = await queue.entries(ownerId: owner);
  for (final before in originals) {
    final now = current.singleWhere(
      (e) => e.write.id == (before['write'] as Map)['write_id'],
    );
    expect(now.write.toJson(), before['write']);
    expect(now.sequence, before['sequence']);
    expect(now.result, isNotNull);
    expect(now.confirmedAt, isNotNull);
  }
  final token = support.accessTokenOf(container);
  await assertBusinessServerState(server, token, manifest, confirmed: true);
  final replay =
      (await server.post<Map<String, dynamic>>(
            '/v1/sync/writes',
            options: authorization(token),
            data: {
              'writes': [for (final before in originals) before['write']],
            },
          )).data!['results']
          as List;
  expect(replay, hasLength(2));
  expect(
    replay.map((r) => r['write_id']).toSet(),
    originals.map((e) => (e['write'] as Map)['write_id']).toSet(),
  );
  for (final result in replay) {
    expect(result['status'], 'already_processed');
    expect(
      result['result'],
      current.singleWhere((e) => e.write.id == result['write_id']).result,
    );
  }
  await assertBusinessServerState(server, token, manifest, confirmed: true);
  await goAcceptance(
    tester,
    container,
    '/recipes/${manifest['recipe_id']}/history',
  );
  await support.waitFor(tester, find.byKey(const ValueKey('recipe-version-2')));
  expect(find.byKey(const ValueKey('recipe-version-1')), findsOneWidget);
  expect(find.byKey(const ValueKey('recipe-version-2')), findsOneWidget);
  expect(find.byKey(const ValueKey('recipe-version-3')), findsNothing);
  await goAcceptance(tester, container, '/me/measures');
  await support.waitFor(
    tester,
    find.byKey(ValueKey('measure-${manifest['measure_id']}')),
  );
  expect(find.textContaining('22'), findsWidgets);
  expect(find.text('待同步'), findsNothing);
  await tester.tap(
    find.byKey(ValueKey('measure-history-${manifest['measure_id']}')),
  );
  await support.waitFor(tester, find.textContaining('已生效'));
  expect(find.textContaining('15'), findsWidgets);
  expect(find.textContaining('22'), findsWidgets);
  await tester.tap(find.text('关闭'));
  await support.settle(tester);
  expect(tester.takeException(), isNull);
}
