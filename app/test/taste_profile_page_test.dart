import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';

const tastePath = '/v1/me/taste-profile';
const flavorKeys = [
  'salty',
  'sweet',
  'sour',
  'spicy',
  'numbing',
  'umami',
  'oily',
];

TasteProfileOut profileFixture({int saltyLevel = 2, bool manual = false}) {
  final levels = [
    TasteLevel(coefficient: 0.5, label: '淡很多'),
    TasteLevel(coefficient: 0.75, label: '淡一点'),
    TasteLevel(coefficient: 1, label: '标准'),
    TasteLevel(coefficient: 1.25, label: '重一点'),
    TasteLevel(coefficient: 1.5, label: '重很多'),
  ];
  return TasteProfileOut(
    id: '11111111-1111-4111-8111-111111111111',
    version: manual ? 2 : 1,
    scale: TasteScale(default_: 1, minimum: 0.5, maximum: 1.5, levels: levels),
    localCuisines: const [],
    flavors: {
      for (final key in flavorKeys)
        key: TasteFlavorOut(
          coefficient: levels[key == 'salty' ? saltyLevel : 2].coefficient,
          label: levels[key == 'salty' ? saltyLevel : 2].label,
          level: key == 'salty' ? saltyLevel : 2,
          confidence: manual && key == 'salty'
              ? TasteFlavorOutConfidenceEnum.high
              : TasteFlavorOutConfidenceEnum.low,
          confidenceText: manual && key == 'salty'
              ? '把握高：你手动设置'
              : '把握低：暂用标准，还不了解你的口味',
        ),
    },
  );
}

void installProfile(FakeServer server, TasteProfileOut Function() current) {
  server.on('GET', tastePath, (_) => (200, current().toJson()));
  server.on(
    'GET',
    '$tastePath/changes',
    (_) => (200, PageTasteProfileChangeOut(items: const []).toJson()),
  );
}

Future<void> openTaste(WidgetTester tester) async {
  await tester.tap(find.text('我的'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('taste-profile-entry')));
  await tester.pumpAndSettle();
}

TasteProfileChangeOut historyFixture() => TasteProfileChangeOut(
  id: '22222222-2222-4222-8222-222222222222',
  version: 2,
  field: 'flavors.salty',
  oldValue: {'coefficient': 1.0, 'confidence': 'low'},
  newValue: {'coefficient': 0.75, 'confidence': 'high'},
  reason: '你手动修改',
  source_: TasteProfileChangeOutSource_Enum.manual,
  status: TasteProfileChangeOutStatusEnum.active,
  createdAt: '2026-10-08T10:00:00Z',
);

Future<void> chooseSalty(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('taste-level-salty')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('淡一点').last);
  await tester.pumpAndSettle();
}

Future<void> pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> signOut(WidgetTester tester) async {
  await goBack(tester);
  await tester.scrollUntilVisible(find.text('设置'), 300);
  await tapVisible(tester, find.text('设置'));
  await tapVisible(tester, find.text('退出登录'));
  await tester.tap(find.widgetWithText(FilledButton, '退出登录'));
  await tester.pumpAndSettle();
  expect(find.text('登录味谱'), findsOneWidget);
}

Future<void> openHistoryWhy(WidgetTester tester) async {
  final why = find.byKey(ValueKey('taste-history-why-${historyFixture().id}'));
  await tester.scrollUntilVisible(why, 350);
  await tapVisible(tester, why);
}

void installHistory(FakeServer server) {
  installProfile(server, () => profileFixture(saltyLevel: 1, manual: true));
  server.on(
    'GET',
    '$tastePath/changes',
    (_) => (200, PageTasteProfileChangeOut(items: [historyFixture()]).toJson()),
  );
}

void main() {
  testWidgets(
    'history why telemetry uses a generic identifier without private IDs',
    (tester) async {
      final server = FakeServer();
      installHistory(server);
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await openTaste(tester);
      await openHistoryWhy(tester);
      final opened = server
          .calls('POST', '/v1/sync/writes')
          .expand(
            (request) => ((request.body as Map)['writes'] as List).cast<Map>(),
          )
          .map((write) {
            expect(write['write_type'], 'experience.event');
            expect(write['owner_id'], server.user.id);
            return write['payload'] as Map;
          })
          .where((event) => event['event_type'] == 'ui.why_panel_opened')
          .toList();
      expect(opened, hasLength(1));
      expect(opened.single['content'], {
        'component_id': 'taste-history',
        'source_type': 'author_filled',
      });
      // The durable experience-event schema represents no linked IDs as {}.
      expect(opened.single['correlation'], <String, dynamic>{});
      final telemetry = jsonEncode(opened.single['content']);
      for (final privateId in [
        profileFixture().id,
        historyFixture().id,
        server.user.id,
      ]) {
        expect(telemetry, isNot(contains(privateId)));
      }
    },
  );

  testWidgets('history timestamp uses themed number typography', (
    tester,
  ) async {
    final server = FakeServer();
    installHistory(server);
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await openTaste(tester);
    final why = find.byKey(
      ValueKey('taste-history-why-${historyFixture().id}'),
    );
    await tester.scrollUntilVisible(why, 350);
    final context = tester.element(why);
    final local = MaterialLocalizations.of(context);
    final date = DateTime.parse(historyFixture().createdAt).toLocal();
    final time =
        '${local.formatShortDate(date)} ${local.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
    final expected = GramTreeColors.of(context)
        .numberStyle(Theme.of(context).textTheme.bodyMedium!);
    expect(tester.widget<Text>(find.text(time)).style, expected);
  });

  for (final brightness in Brightness.values) {
    testWidgets('manual history WhyPanel stays neutral in $brightness', (
      tester,
    ) async {
      final server = FakeServer();
      installHistory(server);
      await pumpApp(
        tester,
        env: TestEnv.signedIn(server: server),
        brightness: brightness,
      );
      await openTaste(tester);
      await openHistoryWhy(tester);
      final current = find.text('现在：咸 · 淡一点');
      expect(current, findsOneWidget);
      final context = tester.element(current);
      final style = tester.widget<Text>(current).style!;
      expect(style.color, Theme.of(context).textTheme.bodyMedium!.color);
      expect(style.color, isNot(GramTreeColors.of(context).accent));
      expect(find.text('原来：咸 · 标准'), findsOneWidget);
      expect(find.text('这次不用'), findsNothing);
      expect(find.text('以后别这样'), findsNothing);
    });
  }
  testWidgets(
    'configured levels drive requests, history labels and read-only local cuisines',
    (tester) async {
      final server = FakeServer();
      final base = profileFixture();
      final levels = [
        for (var i = 0; i < 5; i++)
          TasteLevel(coefficient: i + 2, label: base.scale.levels[i].label),
      ];
      var current = base.copyWith(
        scale: TasteScale(minimum: 2, maximum: 6, default_: 4, levels: levels),
        flavors: {
          for (final entry in base.flavors.entries)
            entry.key: entry.value.copyWith(coefficient: 4),
        },
        localCuisines: [
          LocalCuisineOut(cuisine: '川菜', adjustments: {'spicy': 5}),
        ],
      );
      installProfile(server, () => current);
      server.on('PATCH', tastePath, (request) {
        expect(request.body, {
          'flavors': {'salty': 3},
        });
        current = current.copyWith(
          flavors: {
            ...current.flavors,
            'salty': current.flavors['salty']!.copyWith(
              coefficient: 3,
              level: 1,
              label: '淡一点',
              confidence: TasteFlavorOutConfidenceEnum.high,
              confidenceText: '把握高：你手动设置',
            ),
          },
        );
        return (200, current.toJson());
      });
      server.on(
        'GET',
        '$tastePath/changes',
        (_) => (
          200,
          PageTasteProfileChangeOut(
            items: [
              historyFixture().copyWith(
                oldValue: {'coefficient': 4},
                newValue: {'coefficient': 3},
              ),
            ],
          ).toJson(),
        ),
      );
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await openTaste(tester);
      await chooseSalty(tester);
      expect(find.text('咸 · 淡一点'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('川菜'), 350);
      expect(find.text('辣 · 重一点'), findsOneWidget);
      expect(find.text('菜系对应的味型调整只读显示，暂不提供学习或编辑。'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('咸：标准 → 淡一点'), 350);
      expect(find.text('咸：标准 → 淡一点'), findsOneWidget);
      expect(find.text('3'), findsNothing);
    },
  );
  testWidgets(
    'read and history failures can retry; failed edits keep honest defaults',
    (tester) async {
      final server = FakeServer();
      var readFails = true;
      var historyFails = true;
      installProfile(server, () => profileFixture());
      server.on(
        'GET',
        tastePath,
        (_) => readFails
            ? FakeServer.error(503, 'unavailable', '档案暂不可用')
            : (200, profileFixture().toJson()),
      );
      server.on(
        'GET',
        '$tastePath/changes',
        (_) => historyFails
            ? FakeServer.error(503, 'unavailable', '历史暂不可用')
            : (
                200,
                PageTasteProfileChangeOut(items: [historyFixture()]).toJson(),
              ),
      );
      server.on(
        'PATCH',
        tastePath,
        (_) => FakeServer.error(503, 'unavailable', '保存暂不可用'),
      );
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await openTaste(tester);
      expect(find.text('档案暂不可用'), findsOneWidget);
      expect(find.byKey(const ValueKey('taste-level-salty')), findsNothing);
      readFails = false;
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      await chooseSalty(tester);
      expect(find.text('保存暂不可用'), findsOneWidget);
      expect(find.text('咸 · 标准'), findsOneWidget);
      expect(find.text('把握高：你手动设置'), findsNothing);
      await tester.scrollUntilVisible(find.text('历史暂不可用'), 350);
      historyFails = false;
      // Let the failed-save snackbar leave the bottom retry button unobstructed.
      await tester.pump(const Duration(seconds: 4));
      await tapVisible(tester, find.text('重试'));
      expect(find.text('咸：标准 → 淡一点'), findsOneWidget);
    },
  );

  for (final pendingOperation in ['read', 'write']) {
    testWidgets(
      'late $pendingOperation and history cannot leak across sign-out/account switch',
      (tester) async {
        final server = FakeServer();
        final pending = Completer<(int, Object?)>();
        final pendingHistory = Completer<(int, Object?)>();
        var firstRead = true;
        var firstHistory = true;
        installProfile(server, () => profileFixture());
        if (pendingOperation == 'read') {
          server.on('GET', tastePath, (_) {
            if (firstRead) {
              firstRead = false;
              return pending.future;
            }
            return (200, profileFixture().toJson());
          });
          server.on('GET', '$tastePath/changes', (_) {
            if (firstHistory) {
              firstHistory = false;
              return pendingHistory.future;
            }
            return (200, PageTasteProfileChangeOut(items: const []).toJson());
          });
        } else {
          server.on('PATCH', tastePath, (_) => pending.future);
        }
        await pumpApp(tester, env: TestEnv.signedIn(server: server));
        await tester.tap(find.text('我的'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('taste-profile-entry')));
        await pumpFrames(tester);
        if (pendingOperation == 'write') await chooseSalty(tester);
        expect(
          server.calls(pendingOperation == 'read' ? 'GET' : 'PATCH', tastePath),
          hasLength(1),
        );
        await signOut(tester);
        expect(find.text('咸 · 淡一点'), findsNothing);
        server.user = server.user.copyWith(
          id: '33333333-3333-4333-8333-333333333333',
          nickname: '另一位味友',
        );
        await tester.enterText(
          find.byKey(const ValueKey('login-email')),
          'other@example.com',
        );
        await tester.tap(find.text('发送验证码'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('code-input')),
          goodCode,
        );
        await tester.pumpAndSettle();
        await openTaste(tester);
        expect(find.text('咸 · 标准'), findsOneWidget);
        pending.complete((
          200,
          profileFixture(saltyLevel: 1, manual: true).toJson(),
        ));
        if (pendingOperation == 'read') {
          pendingHistory.complete((
            200,
            PageTasteProfileChangeOut(items: [historyFixture()]).toJson(),
          ));
        }
        await tester.pumpAndSettle();
        expect(find.text('咸 · 标准'), findsOneWidget);
        expect(find.text('把握高：你手动设置'), findsNothing);
        expect(server.calls('GET', tastePath), hasLength(2));
        await tester.scrollUntilVisible(find.text('还没有修改记录'), 350);
        expect(find.text('咸：标准 → 淡一点'), findsNothing);
        expect(find.text('还没有修改记录'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final brightness in Brightness.values) {
    for (final textScale in [1.3, 1.6]) {
      testWidgets(
        '$brightness at $textScale keeps levels and read-only history usable',
        (tester) async {
          final server = FakeServer();
          installProfile(server, () => profileFixture());
          server.on(
            'GET',
            '$tastePath/changes',
            (_) => (
              200,
              PageTasteProfileChangeOut(items: [historyFixture()]).toJson(),
            ),
          );
          await pumpApp(
            tester,
            env: TestEnv.signedIn(server: server),
            brightness: brightness,
            textScale: textScale,
          );
          await openTaste(tester);
          await tester.tap(find.byKey(const ValueKey('taste-level-salty')));
          await tester.pumpAndSettle();
          for (final label in ['淡很多', '淡一点', '标准', '重一点', '重很多']) {
            expect(find.text(label), findsWidgets);
          }
          await tester.tapAt(const Offset(5, 5));
          await tester.pumpAndSettle();
          final why = find.byKey(
            ValueKey('taste-history-why-${historyFixture().id}'),
          );
          await tester.scrollUntilVisible(why, 350);
          await tapVisible(tester, why);
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('why-panel')), findsOneWidget);
          expect(find.text('0.75'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'five levels save, survive reopening, expose read-only why/history and reset',
    (tester) async {
      final server = FakeServer();
      var current = profileFixture();
      var modified = false;
      installProfile(server, () => current);
      server.on('PATCH', tastePath, (request) {
        expect(request.body, {
          'flavors': {'salty': 0.75},
        });
        modified = true;
        current = profileFixture(saltyLevel: 1, manual: true);
        return (200, current.toJson());
      });
      server.on(
        'GET',
        '$tastePath/changes',
        (_) => (
          200,
          PageTasteProfileChangeOut(items: modified ? [historyFixture()] : [])
              .toJson(),
        ),
      );
      server.on('POST', '$tastePath/reset', (_) {
        current = profileFixture();
        return (200, current.toJson());
      });
      final env = TestEnv.signedIn(server: server);
      await pumpApp(tester, env: env);
      await openTaste(tester);
      await chooseSalty(tester);
      expect(find.text('咸 · 淡一点'), findsOneWidget);
      expect(find.text('把握高：你手动设置'), findsOneWidget);
      await goBack(tester);
      await tester.tap(find.byKey(const ValueKey('taste-profile-entry')));
      await tester.pumpAndSettle();
      expect(find.text('咸 · 淡一点'), findsOneWidget);
      final why = find.byKey(
        ValueKey('taste-history-why-${historyFixture().id}'),
      );
      await tester.scrollUntilVisible(why, 350);
      expect(find.text('咸：标准 → 淡一点'), findsOneWidget);
      await tapVisible(tester, why);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('why-panel')), findsOneWidget);
      expect(find.textContaining('你手动修改'), findsWidgets);
      expect(find.text('这次不用'), findsNothing);
      expect(find.text('以后别这样'), findsNothing);
      expect(find.text('0.75'), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('taste-reset')),
        -350,
      );
      await tester.tap(find.byKey(const ValueKey('taste-reset')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('taste-reset-confirm')));
      await tester.pumpAndSettle();
      await goBack(tester);
      await tester.tap(find.byKey(const ValueKey('taste-profile-entry')));
      await tester.pumpAndSettle();
      expect(find.text('咸 · 标准'), findsOneWidget);
      expect(find.text('把握高：你手动设置'), findsNothing);
      expect(find.text('把握低：暂用标准，还不了解你的口味'), findsWidgets);
      expect(server.calls('POST', '$tastePath/reset'), hasLength(1));
    },
  );
  testWidgets(
    'my taste shows honest defaults and read-only empty local preferences',
    (tester) async {
      final server = FakeServer();
      installProfile(server, () => profileFixture());
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await openTaste(tester);
      expect(find.text('我的口味'), findsOneWidget);
      expect(find.byKey(const ValueKey('taste-level-salty')), findsOneWidget);
      expect(find.text('把握低：暂用标准，还不了解你的口味'), findsWidgets);
      expect(find.text('1.0'), findsNothing);
      await tester.scrollUntilVisible(find.text('还没有菜系局部偏好'), 350);
      expect(find.text('还没有菜系局部偏好'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('还没有修改记录'), 350);
      expect(find.text('还没有修改记录'), findsOneWidget);
    },
  );
}
