import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'package:gram_tree/util/ids.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:gram_tree/events/fake_event_queue.dart';

import 'helpers.dart';
import 'settings_test.dart' show openSettings;
import 'taste_profile_page_test.dart'
    show installProfile, profileFixture, openTaste, signOut, pumpFrames;

const allergyPath = '/v1/me/taste-profile/allergies';
const categories = [
  '含麸质的谷物',
  '甲壳纲类动物',
  '鱼类',
  '蛋类',
  '花生',
  '大豆',
  '乳及乳制品',
  '坚果及其果仁',
];
AllergiesOut allergyFixture({
  String? consentId,
  List<String> selected = const [],
}) => AllergiesOut(
  consentId: consentId,
  consentVersion: 'allergies-v1',
  authorizationVersion: consentId == null ? 0 : 1,
  profileVersion: selected.isEmpty ? 1 : 2,
  availableCategories: categories,
  categories: selected,
  ingredients: const [],
);

Future<void> _withdraw(WidgetTester tester) async {
  await tapVisible(tester, find.byKey(const ValueKey('sensitive-withdraw')));
  await tapVisible(
    tester,
    find.byKey(const ValueKey('sensitive-withdraw-confirm')),
  );
}

Future<void> _loginOther(WidgetTester tester, FakeServer server) async {
  server.user = server.user.copyWith(id: newUuidV4(), nickname: '另一位味友');
  await tester.enterText(
    find.byKey(const ValueKey('login-email')),
    'other@example.com',
  );
  await tester.tap(find.text('发送验证码'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('code-input')), goodCode);
  await tester.pumpAndSettle();
}

class _UnavailableTelemetry extends FakeEventQueue {
  @override
  Future<void> enqueue(QueuedEvent event) async {
    if ((event.content?['intent'] as String?)?.startsWith('allergies_') ==
            true ||
        event.eventType == 'ui.why_panel_opened') {
      throw StateError('private-telemetry-failure');
    }
    return super.enqueue(event);
  }
}

void main() {
  testWidgets(
    'optional telemetry failure cannot block confirmed sensitive withdrawal',
    (tester) async {
      final server = FakeServer();
      var withdrawn = false;
      server.on(
        'GET',
        allergyPath,
        (_) => (
          200,
          allergyFixture(
            consentId: withdrawn ? null : newUuidV4(),
            selected: withdrawn ? [] : ['花生'],
          ).toJson(),
        ),
      );
      server.on('POST', '/v1/me/consents', (r) {
        if (jsonEncode(r.body).contains('sensitive_personal_info'))
          withdrawn = true;
        return (204, null);
      });
      final base = TestEnv.signedIn(server: server);
      await pumpApp(
        tester,
        env: TestEnv(
          server: server,
          local: base.local,
          secure: base.secure,
          eventQueue: _UnavailableTelemetry(),
        ),
      );
      await openSettings(tester);
      await _withdraw(tester);
      expect(withdrawn, isTrue);
      expect(find.text('敏感同意已撤回，过敏及私密历史已删除'), findsOneWidget);
      expect(find.textContaining('private-telemetry-failure'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'canonical ingredient add/remove and guarded private history use the shared Why panel',
    (tester) async {
      final server = FakeServer();
      installProfile(server, () => profileFixture());
      final grant = newUuidV4();
      final ingredientId = newUuidV4();
      final changeId = newUuidV4();
      var current = allergyFixture(consentId: grant);
      final history = <TasteProfileChangeOut>[];
      server.on('GET', allergyPath, (_) => (200, current.toJson()));
      server.on(
        'GET',
        '$allergyPath/changes',
        (_) => (200, PageTasteProfileChangeOut(items: history).toJson()),
      );
      server.on(
        'POST',
        '/v1/ingredients/search',
        (_) => (
          200,
          SearchResult(
            items: [
              SearchIngredientOut(
                id: ingredientId,
                standardName: '标准酱油',
                matchedName: '别名',
                aliases: const ['别名'],
                category: '调味品',
                pinyin: 'jiangyou',
                pinyinInitials: 'jy',
                version: '1',
              ),
            ],
          ).toJson(),
        ),
      );
      server.on('PUT', allergyPath, (r) {
        final body = r.body as Map;
        expect(
          body.keys,
          unorderedEquals([
            'consent_id',
            'authorization_version',
            'categories',
            'ingredient_ids',
          ]),
        );
        final before = {
          'categories': current.categories,
          'ingredients': current.ingredients.map((i) => i.toJson()).toList(),
        };
        current = current.copyWith(
          categories: (body['categories'] as List).cast<String>(),
          ingredients: [
            for (final id in body['ingredient_ids'] as List)
              AllergyIngredientOut(ingredientId: id as String, name: '标准酱油'),
          ],
        );
        history.add(
          TasteProfileChangeOut(
            id: history.isEmpty ? changeId : newUuidV4(),
            field: 'allergies',
            version: history.length + 2,
            oldValue: before,
            newValue: {
              'categories': current.categories,
              'ingredients': current.ingredients
                  .map((i) => i.toJson())
                  .toList(),
            },
            reason: '你手动修改',
            source_: TasteProfileChangeOutSource_Enum.manual,
            status: TasteProfileChangeOutStatusEnum.active,
            createdAt: '2026-10-08T10:00:00Z',
          ),
        );
        return (200, current.toJson());
      });
      final env = TestEnv.signedIn(server: server);
      await pumpApp(tester, env: env);
      await openTaste(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('allergies-edit')),
        300,
      );
      await tapVisible(tester, find.byKey(const ValueKey('allergies-edit')));
      expect(find.text('过敏信息单独同意'), findsNothing);
      await tester.ensureVisible(find.byKey(const ValueKey('allergy-search')));
      await tester.enterText(
        find.byKey(const ValueKey('allergy-search')),
        '自由文字不保存',
      );
      await tester.tap(find.byKey(const ValueKey('allergies-save')));
      await tester.pumpAndSettle();
      expect(
        (server.calls('PUT', allergyPath).last.body as Map)['ingredient_ids'],
        isEmpty,
      );
      await tapVisible(tester, find.byKey(const ValueKey('allergies-edit')));
      await tester.ensureVisible(find.byKey(const ValueKey('allergy-search')));
      await tester.enterText(
        find.byKey(const ValueKey('allergy-search')),
        '别名',
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('allergy-search-submit')),
      );
      await tapVisible(
        tester,
        find.byKey(ValueKey('allergy-result-$ingredientId')),
      );
      await tester.tap(find.byKey(const ValueKey('allergies-save')));
      await tester.pumpAndSettle();
      expect(
        (server.calls('PUT', allergyPath).last.body as Map)['ingredient_ids'],
        [ingredientId],
      );
      expect(find.text('标准酱油'), findsOneWidget);
      final why = find.byKey(ValueKey('allergy-why-${history.last.id}'));
      await tester.scrollUntilVisible(why, 200);
      await tapVisible(tester, why);
      expect(find.byKey(const ValueKey('why-panel')), findsOneWidget);
      expect(find.text('本人手动填写'), findsOneWidget);
      expect(find.textContaining('标准酱油'), findsWidgets);
      expect(find.text('这次不用'), findsNothing);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('allergies-edit')));
      await tapVisible(
        tester,
        find.byKey(ValueKey('allergy-delete-$ingredientId')),
      );
      await tester.tap(find.byKey(const ValueKey('allergies-save')));
      await tester.pumpAndSettle();
      expect(find.text('尚未填写本人过敏'), findsOneWidget);
      expect(find.text('标准酱油 → 未填写'), findsOneWidget);
      expect(jsonEncode(env.local.values), isNot(contains('标准酱油')));
      final uploads = jsonEncode(
        server.calls('POST', '/v1/events/upload').map((r) => r.body).toList(),
      );
      expect(uploads, isNot(contains('标准酱油')));
      expect(uploads, isNot(contains('自由文字不保存')));
      final events = server
          .calls('POST', '/v1/events/upload')
          .expand((r) => ((r.body as Map)['events'] as List).cast<Map>())
          .toList();
      final whyEvents = events.where(
        (e) => e['event_type'] == 'ui.why_panel_opened',
      );
      expect(whyEvents, hasLength(1));
      expect(whyEvents.single['content'], {
        'component_id': 'allergies_history',
        'source_type': 'author_filled',
      });
      for (final event in events.where(
        (e) =>
            e['event_type'] == 'ui.component_action' ||
            e['event_type'] == 'ui.why_panel_opened',
      )) {
        expect(event['correlation'], anyOf(isNull, isEmpty));
      }
    },
  );
  testWidgets(
    'an expired sensitive receipt never retries under a switched account',
    (tester) async {
      final server = FakeServer();
      installProfile(server, () => profileFixture());
      final pending = Completer<(int, Object?)>();
      var seen = false;
      server.on('POST', '/v1/me/consents', (r) {
        if (jsonEncode(r.body).contains('sensitive_personal_info') && !seen) {
          seen = true;
          return pending.future;
        }
        return (204, null);
      });
      final env = TestEnv.signedIn(server: server);
      await pumpApp(tester, env: env);
      await openTaste(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('allergies-edit')),
        300,
      );
      await tapVisible(tester, find.byKey(const ValueKey('allergies-edit')));
      await tapVisible(tester, find.byKey(const ValueKey('allergies-agree')));
      expect(seen, isTrue);
      await signOut(tester);
      await _loginOther(tester, server);
      pending.complete(FakeServer.error(401, 'token_expired', 'expired'));
      await tester.pumpAndSettle();
      final receipts = server
          .calls('POST', '/v1/me/consents')
          .where((r) => jsonEncode(r.body).contains('sensitive_personal_info'))
          .toList();
      expect(receipts, hasLength(1));
      expect(receipts.single.headers['Authorization'], 'Bearer access-0');
      await openTaste(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('allergies-edit')),
        300,
      );
      await tapVisible(tester, find.byKey(const ValueKey('allergies-edit')));
      expect(find.text('过敏信息单独同意'), findsOneWidget);
      expect(
        env.local.getString('consent_records'),
        isNot(contains('sensitive_personal_info')),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'key-failed reads never block withdrawal; failure is honest and retry verifies empty',
    (tester) async {
      final server = FakeServer();
      installProfile(server, () => profileFixture(saltyLevel: 1, manual: true));
      var withdrawn = false;
      var fail = true;
      server.on(
        'GET',
        allergyPath,
        (_) => withdrawn
            ? (200, allergyFixture().toJson())
            : FakeServer.error(503, 'sensitive_key_unavailable', 'private'),
      );
      server.on('POST', '/v1/me/consents', (r) {
        final records = ((r.body as Map)['records'] as List).cast<Map>();
        if (records.any(
          (record) =>
              record['kind'] == 'sensitive_personal_info' &&
              record['action'] == 'withdraw',
        )) {
          if (fail) return FakeServer.error(503, 'unavailable', 'private');
          withdrawn = true;
        }
        return (204, null);
      });
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await openTaste(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('allergies-edit')),
        300,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('仍可在设置撤回同意'), findsOneWidget);
      await goBack(tester);
      await openSettings(tester);
      await _withdraw(tester);
      expect(find.text('撤回尚未确认，请联网后重试；普通口味不受影响'), findsOneWidget);
      expect(find.text('敏感同意已撤回，过敏及私密历史已删除'), findsNothing);
      fail = false;
      await _withdraw(tester);
      expect(find.text('敏感同意已撤回，过敏及私密历史已删除'), findsOneWidget);
      await goBack(tester);
      await openTaste(tester);
      expect(find.text('咸 · 淡一点'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('allergies-edit')),
        300,
      );
      expect(find.text('尚未填写本人过敏'), findsOneWidget);
      expect(find.text('没有私密修改历史'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('allergies-edit')));
      expect(find.text('过敏信息单独同意'), findsOneWidget);
    },
  );
  testWidgets(
    'refusal leaves ordinary tastes usable; explicit grant then manual category save',
    (tester) async {
      final server = FakeServer();
      installProfile(server, () => profileFixture());
      var current = allergyFixture();
      server.on('GET', allergyPath, (_) => (200, current.toJson()));
      server.on(
        'GET',
        '$allergyPath/changes',
        (_) => (200, PageTasteProfileChangeOut(items: const []).toJson()),
      );
      server.on('POST', '/v1/me/consents', (request) {
        final records = ((request.body as Map)['records'] as List).cast<Map>();
        for (final record in records) {
          if (record['kind'] == 'sensitive_personal_info') {
            current = allergyFixture(
              consentId: record['action'] == 'agree'
                  ? record['id'] as String
                  : null,
            );
          }
        }
        return (204, null);
      });
      server.on('PUT', allergyPath, (request) {
        final body = request.body as Map;
        expect(body['consent_id'], current.consentId);
        expect(body['authorization_version'], 1);
        current = allergyFixture(
          consentId: current.consentId,
          selected: (body['categories'] as List).cast<String>(),
        );
        return (200, current.toJson());
      });
      final env = TestEnv.signedIn(server: server);
      await pumpApp(tester, env: env);
      await openTaste(tester);
      final edit = find.byKey(const ValueKey('allergies-edit'));
      await tester.scrollUntilVisible(edit, 300);
      await tapVisible(tester, edit);
      expect(find.text('过敏信息单独同意'), findsOneWidget);
      expect(find.textContaining('不代表同意外部 AI'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('allergies-refuse')));
      await tester.pumpAndSettle();
      expect(server.calls('PUT', allergyPath), isEmpty);
      expect(
        server
            .calls('POST', '/v1/me/consents')
            .where(
              (r) => jsonEncode(r.body).contains('sensitive_personal_info'),
            ),
        isEmpty,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('taste-level-salty')),
        -300,
      );
      expect(find.text('咸 · 标准'), findsOneWidget);
      await tester.scrollUntilVisible(edit, 300);
      await tapVisible(tester, edit);
      await tester.tap(find.byKey(const ValueKey('allergies-agree')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('allergy-category-花生')));
      await tester.tap(find.byKey(const ValueKey('allergies-save')));
      await tester.pumpAndSettle();
      expect(find.text('花生'), findsOneWidget);
      expect(server.calls('PUT', allergyPath).length, 1);
      expect(
        env.local.getString('consent_records'),
        isNot(contains('sensitive_personal_info')),
      );
      await goBack(tester);
      await openTaste(tester);
      await tester.scrollUntilVisible(edit, 300);
      expect(find.text('花生'), findsOneWidget);
      await tapVisible(tester, edit);
      expect(find.text('过敏信息单独同意'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('allergy-category-花生')));
      await tester.tap(find.byKey(const ValueKey('allergies-save')));
      await tester.pumpAndSettle();
      expect(find.text('尚未填写本人过敏'), findsOneWidget);
    },
  );
}
