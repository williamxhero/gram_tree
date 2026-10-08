import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtree_api/gramtree_api.dart';


import 'helpers.dart';
import 'settings_test.dart' show openSettings;
import 'taste_profile_page_test.dart'
    show installProfile, profileFixture, openTaste;

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

void main() {
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
