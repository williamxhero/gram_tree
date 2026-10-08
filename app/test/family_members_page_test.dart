import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';
import 'settings_test.dart' show openSettings;
import 'taste_profile_page_test.dart'
    show installProfile, profileFixture, openTaste, pumpFrames, signOut;

const familyPath = '/v1/me/taste-profile/family-members';
const familyAges = [
  'under_1',
  '1_to_3',
  '3_to_6',
  '6_to_12',
  '12_to_18',
  'adult',
  'elder',
];

const familyConsentId = '33333333-3333-4333-8333-333333333333';
const familyMemberId = '44444444-4444-4444-8444-444444444444';
const familyIngredientId = '55555555-5555-4555-8555-555555555555';
const familyChangeId = '77777777-7777-4777-8777-777777777777';

FamilyMembersOut familyFixture({
  String? consentId,
  List<FamilyMemberOut> members = const [],
}) => FamilyMembersOut.fromJson({
  'consent_id': consentId,
  'consent_version': 'allergies-v1',
  'authorization_version': consentId == null ? 0 : 1,
  'profile_version': 1,
  'available_age_bands': familyAges,
  'available_allergen_categories': ['花生', '乳及乳制品'],
  'members': members.map((member) => member.toJson()).toList(),
});

FamilyMemberOut memberFixture({
  String nickname = '孩子私密称呼',
  String age = '1_to_3',
  Map<String, num> flavors = const {'spicy': 0},
}) => FamilyMemberOut.fromJson({
  'id': familyMemberId,
  'nickname': nickname,
  'age_band': age,
  'flavors': flavors,
  'avoidances': [],
  'allergies': {'categories': [], 'ingredients': []},
  'source': 'manual',
});

TasteProfileChangeOut privateFamilyHistory(FamilyMemberOut member) =>
    TasteProfileChangeOut(
      id: familyChangeId,
      field: 'family_members.${member.id}',
      version: 2,
      oldValue: const {},
      newValue: {...member.toJson()}..remove('id'),
      reason: '你手动修改',
      source_: TasteProfileChangeOutSource_Enum.manual,
      status: TasteProfileChangeOutStatusEnum.active,
      createdAt: '2026-10-08T10:00:00Z',
    );

Future<void> chooseFamily(WidgetTester tester, String key, String label) async {
  await tapVisible(tester, find.byKey(ValueKey(key)));
  await tapVisible(tester, find.text(label).last);
}

Future<void> openFamily(WidgetTester tester) async {
  await openTaste(tester);
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('family-add')),
    300,
  );
  await tester.pumpAndSettle();
}

Future<void> tapFamilyPending(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await pumpFrames(tester);
  await tester.tap(finder);
  await pumpFrames(tester);
}

Future<void> openFamilyPending(WidgetTester tester) async {
  await openTaste(tester);
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('family-add')),
    300,
  );
  await pumpFrames(tester);
}

Future<void> loginFamilyAccount(
  WidgetTester tester,
  FakeServer server,
  UserOut user,
) async {
  server.user = user;
  await tester.enterText(
    find.byKey(const ValueKey('login-email')),
    'other@example.com',
  );
  await tester.tap(find.text('发送验证码'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('code-input')), goodCode);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'member deletion retains owner allergies and refetches shared authorization before owner save',
    (tester) async {
      final server = FakeServer();
      installProfile(server, () => profileFixture(saltyLevel: 1, manual: true));
      final member = memberFixture();
      var removed = false;
      var ownerCategories = <String>['花生'];
      AllergiesOut owner() => AllergiesOut(
        consentId: familyConsentId,
        consentVersion: 'allergies-v1',
        authorizationVersion: removed ? 2 : 1,
        profileVersion: 1,
        availableCategories: const ['花生', '乳及乳制品'],
        categories: ownerCategories,
        ingredients: const [],
      );
      server.on(
        'GET',
        familyPath,
        (_) => (
          200,
          familyFixture(
            consentId: familyConsentId,
            members: removed ? [] : [member],
          ).copyWith(authorizationVersion: removed ? 2 : 1).toJson(),
        ),
      );
      server.on(
        'GET',
        '/v1/me/taste-profile/allergies',
        (_) => (200, owner().toJson()),
      );
      server.on('PUT', '/v1/me/taste-profile/allergies', (request) {
        final body = request.body as Map;
        expect(body['authorization_version'], 2);
        expect(body['categories'], ['花生', '乳及乳制品']);
        ownerCategories = (body['categories'] as List).cast<String>();
        return (200, owner().toJson());
      });
      server.on('DELETE', '$familyPath/$familyMemberId', (_) {
        removed = true;
        return (204, null);
      });
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await openFamily(tester);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-delete-$familyMemberId')),
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-delete-confirm')),
      );
      expect(find.textContaining('孩子私密称呼'), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('allergies-edit')),
        -200,
      );
      expect(find.text('花生'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('allergies-edit')));
      expect(find.text('过敏信息单独同意'), findsNothing);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('allergy-category-乳及乳制品')),
      );
      await tapVisible(tester, find.byKey(const ValueKey('allergies-save')));
      expect(find.text('花生、乳及乳制品'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('taste-level-salty')),
        -300,
      );
      expect(find.text('咸 · 淡一点'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'delete between private history pages discards earlier identifiable rows after snapshot verification',
    (tester) async {
      final server = FakeServer();
      installProfile(server, () => profileFixture());
      final member = memberFixture();
      final laterPage = Completer<(int, Object?)>();
      var removed = false;
      var first = true;
      var started = false;
      server.on(
        'GET',
        familyPath,
        (_) => (
          200,
          familyFixture(
            consentId: familyConsentId,
            members: removed ? [] : [member],
          ).copyWith(profileVersion: removed ? 2 : 1).toJson(),
        ),
      );
      server.on('GET', '$familyPath/changes', (_) {
        if (removed) {
          return (200, PageTasteProfileChangeOut(items: const []).toJson());
        }
        if (first) {
          first = false;
          return (
            200,
            PageTasteProfileChangeOut(
              items: [privateFamilyHistory(member)],
              nextCursor: 'next',
            ).toJson(),
          );
        }
        started = true;
        return laterPage.future;
      });
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await openFamilyPending(tester);
      expect(started, isTrue);
      removed = true;
      laterPage.complete((
        200,
        PageTasteProfileChangeOut(items: const []).toJson(),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('孩子私密称呼'), findsNothing);
      expect(find.text('没有家庭成员私密修改历史'), findsOneWidget);
      expect(find.text('还没有家庭成员'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'session expiry from a guarded family chooser clears both nested private dialogs',
    (tester) async {
      final server = FakeServer();
      installProfile(server, () => profileFixture());
      final member = memberFixture();
      server.on(
        'GET',
        familyPath,
        (_) => (
          200,
          familyFixture(consentId: familyConsentId, members: [member]).toJson(),
        ),
      );
      server.on(
        'GET',
        '$familyPath/$familyMemberId',
        (_) => (200, member.toJson()),
      );
      server.on(
        'POST',
        '/v1/ingredients/search',
        (_) => FakeServer.error(
          401,
          'token_expired',
          'private-query-must-not-render',
        ),
      );
      server.on(
        'POST',
        '/v1/auth/refresh',
        (_) => FakeServer.error(
          401,
          'refresh_invalid',
          'private-refresh-must-not-render',
        ),
      );
      final env = TestEnv.signedIn(server: server);
      await pumpApp(tester, env: env);
      await openFamily(tester);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-edit-$familyMemberId')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('family-nickname')),
        '仍在编辑的私密称呼',
      );
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-allergy-add')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('taste-ingredient-search')),
        '过敏查询隐私',
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('taste-ingredient-search-submit')),
      );
      expect(find.text('登录味谱'), findsOneWidget);
      expect(find.byKey(const ValueKey('family-editor')), findsNothing);
      expect(
        find.byKey(const ValueKey('taste-ingredient-search')),
        findsNothing,
      );
      expect(find.textContaining('仍在编辑的私密称呼'), findsNothing);
      expect(find.textContaining('过敏查询隐私'), findsNothing);
      expect(
        find.textContaining('private-query-must-not-render'),
        findsNothing,
      );
      expect(server.calls('POST', '/v1/ingredients/search'), hasLength(1));
      expect(server.calls('POST', '/v1/auth/refresh'), hasLength(1));
      expect(jsonEncode(env.local.values), isNot(contains('仍在编辑的私密称呼')));
      expect(jsonEncode(env.local.values), isNot(contains('过敏查询隐私')));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'missing member alone cannot confirm deletion while later private history still identifies them',
    (tester) async {
      final server = FakeServer();
      installProfile(server, () => profileFixture());
      final member = memberFixture();
      var removed = false;
      var probing = false;
      var probePage = 0;
      server.on(
        'GET',
        familyPath,
        (_) => (
          200,
          familyFixture(
            consentId: familyConsentId,
            members: removed ? [] : [member],
          ).toJson(),
        ),
      );
      server.on('GET', '$familyPath/$familyMemberId', (_) {
        probing = true;
        return FakeServer.error(404, 'not_found', 'absent');
      });
      server.on('GET', '$familyPath/changes', (_) {
        if (probing) {
          probePage++;
          return (
            200,
            probePage.isOdd
                ? PageTasteProfileChangeOut(
                    items: const [],
                    nextCursor: 'next',
                  ).toJson()
                : PageTasteProfileChangeOut(
                    items: [privateFamilyHistory(member)],
                  ).toJson(),
          );
        }
        return (
          200,
          PageTasteProfileChangeOut(items: [privateFamilyHistory(member)])
              .toJson(),
        );
      });
      server.on('DELETE', '$familyPath/$familyMemberId', (_) {
        if (removed) return FakeServer.error(404, 'not_found', 'absent');
        removed = true;
        return FakeServer.error(503, 'response_lost', 'unconfirmed');
      });
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await openFamily(tester);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-delete-$familyMemberId')),
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-delete-confirm')),
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-delete-retry')),
      );
      expect(probePage, 2);
      expect(find.byKey(const ValueKey('family-delete-retry')), findsOneWidget);
      expect(find.text('删除尚未确认，信息已从本机内存清除；请重试'), findsOneWidget);
      expect(find.textContaining('孩子私密称呼'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets(
      '$brightness large-text family canonical avoidance and manual allergies never save free-form search or share private values',
      (tester) async {
        final server = FakeServer();
        installProfile(server, () => profileFixture());
        var current = memberFixture();
        server.on(
          'GET',
          familyPath,
          (_) => (
            200,
            familyFixture(
              consentId: familyConsentId,
              members: [current],
            ).toJson(),
          ),
        );
        server.on(
          'GET',
          '$familyPath/$familyMemberId',
          (_) => (200, current.toJson()),
        );
        server.on(
          'POST',
          '/v1/ingredients/search',
          (_) => (
            200,
            SearchResult(
              items: [
                SearchIngredientOut(
                  id: familyIngredientId,
                  standardName: '标准酱油',
                  matchedName: '别名',
                  aliases: const ['别名'],
                  category: '调料',
                  pinyin: 'jiangyou',
                  pinyinInitials: 'jy',
                  version: '1',
                ),
              ],
            ).toJson(),
          ),
        );
        server.on('PUT', '$familyPath/$familyMemberId', (request) {
          final body = request.body as Map;
          expect(body['avoidances'], [
            {'category': '蔬菜'},
            {'ingredient_id': familyIngredientId},
          ]);
          expect(body['allergies'], {
            'categories': ['花生'],
            'ingredient_ids': [familyIngredientId],
          });
          expect(jsonEncode(body), isNot(contains('自由文字不保存')));
          expect(jsonEncode(body), isNot(contains('别名')));
          current = current.copyWith(
            avoidances: [
              FamilyAvoidanceOut(category: '蔬菜', name: '蔬菜'),
              FamilyAvoidanceOut(
                ingredientId: familyIngredientId,
                name: '标准酱油',
              ),
            ],
            allergies: FamilyAllergiesOut(
              categories: const ['花生'],
              ingredients: [
                AllergyIngredientOut(
                  ingredientId: familyIngredientId,
                  name: '标准酱油',
                ),
              ],
            ),
          );
          return (200, current.toJson());
        });
        final env = TestEnv.signedIn(server: server);
        await pumpApp(tester, env: env, brightness: brightness, textScale: 1.6);
        await openFamily(tester);
        await tapVisible(
          tester,
          find.byKey(const ValueKey('family-edit-$familyMemberId')),
        );
        await tapVisible(
          tester,
          find.byKey(const ValueKey('family-avoidance-add')),
        );
        await tester.enterText(
          find.byKey(const ValueKey('taste-ingredient-search')),
          '自由文字不保存',
        );
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('taste-preference-save')),
              )
              .onPressed,
          isNull,
        );
        await chooseFamily(tester, 'taste-preference-category', '蔬菜');
        await tapVisible(
          tester,
          find.byKey(const ValueKey('taste-preference-save')),
        );
        await tapVisible(
          tester,
          find.byKey(const ValueKey('family-avoidance-add')),
        );
        await tester.enterText(
          find.byKey(const ValueKey('taste-ingredient-search')),
          '别名',
        );
        await tapVisible(
          tester,
          find.byKey(const ValueKey('taste-ingredient-search-submit')),
        );
        await tapVisible(
          tester,
          find.byKey(const ValueKey('taste-search-$familyIngredientId')),
        );
        await tapVisible(
          tester,
          find.byKey(const ValueKey('taste-preference-save')),
        );
        await tapVisible(
          tester,
          find.byKey(const ValueKey('family-allergy-category-花生')),
        );
        await tapVisible(
          tester,
          find.byKey(const ValueKey('family-allergy-add')),
        );
        expect(
          find.byKey(const ValueKey('taste-preference-category')),
          findsNothing,
        );
        await tester.enterText(
          find.byKey(const ValueKey('taste-ingredient-search')),
          '别名',
        );
        await tapVisible(
          tester,
          find.byKey(const ValueKey('taste-ingredient-search-submit')),
        );
        await tapVisible(
          tester,
          find.byKey(const ValueKey('taste-search-$familyIngredientId')),
        );
        await tapVisible(
          tester,
          find.byKey(const ValueKey('taste-preference-save')),
        );
        await tapVisible(tester, find.byKey(const ValueKey('family-save')));
        await tapVisible(
          tester,
          find.byKey(const ValueKey('family-view-$familyMemberId')),
        );
        final detail = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('手动过敏（不会自动推断） · 花生'),
        );
        expect(detail, findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.textContaining('忌口 · 蔬菜'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.textContaining('标准酱油'),
          ),
          findsOneWidget,
        );
        await tapVisible(
          tester,
          find.byKey(const ValueKey('family-detail-close')),
        );
        final persisted = jsonEncode([
          env.local.values,
          env.secure.values,
          server.calls('POST', '/v1/events/upload').map((r) => r.body).toList(),
        ]);
        for (final private in ['孩子私密称呼', '标准酱油', '自由文字不保存', '别名']) {
          expect(persisted, isNot(contains(private)));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'committed delete with lost response is confirmed on retry only after member and identifying history are absent',
    (tester) async {
      final server = FakeServer();
      installProfile(server, () => profileFixture());
      final old = memberFixture();
      var removed = false;
      server.on(
        'GET',
        familyPath,
        (_) => (
          200,
          familyFixture(
            consentId: familyConsentId,
            members: removed ? [] : [old],
          ).toJson(),
        ),
      );
      server.on(
        'GET',
        '$familyPath/$familyMemberId',
        (_) => removed
            ? FakeServer.error(404, 'not_found', 'absent')
            : (200, old.toJson()),
      );
      server.on(
        'GET',
        '$familyPath/changes',
        (_) => (
          200,
          PageTasteProfileChangeOut(
            items: removed ? [] : [privateFamilyHistory(old)],
          ).toJson(),
        ),
      );
      server.on('DELETE', '$familyPath/$familyMemberId', (_) {
        if (removed) return FakeServer.error(404, 'not_found', 'absent');
        removed = true;
        return FakeServer.error(503, 'response_lost', 'unconfirmed');
      });
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await openFamily(tester);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-delete-$familyMemberId')),
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-delete-confirm')),
      );
      expect(find.textContaining('孩子私密称呼'), findsNothing);
      expect(find.byKey(const ValueKey('family-delete-retry')), findsOneWidget);
      final historyReads = server.calls('GET', '$familyPath/changes').length;
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-delete-retry')),
      );
      expect(server.calls('GET', '$familyPath/$familyMemberId'), isNotEmpty);
      expect(
        server.calls('GET', '$familyPath/changes').length,
        greaterThan(historyReads),
      );
      expect(find.byKey(const ValueKey('family-delete-retry')), findsNothing);
      expect(find.text('删除尚未确认，信息已从本机内存清除；请重试'), findsNothing);
      expect(find.text('还没有家庭成员'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final operation in ['history', 'detail', 'edit', 'save']) {
    testWidgets(
      'privacy withdrawal clears owner and family including late $operation and keeps ordinary taste',
      (tester) async {
        final server = FakeServer();
        installProfile(
          server,
          () => profileFixture(saltyLevel: 1, manual: true),
        );
        final old = memberFixture();
        final pending = Completer<(int, Object?)>();
        var started = false;
        var withdrawn = false;
        server.on(
          'GET',
          familyPath,
          (_) => (
            200,
            familyFixture(
              consentId: withdrawn ? null : familyConsentId,
              members: withdrawn ? [] : [old],
            ).toJson(),
          ),
        );
        server.on(
          'GET',
          '/v1/me/taste-profile/allergies',
          (_) => (
            200,
            AllergiesOut(
              consentId: withdrawn ? null : familyConsentId,
              consentVersion: 'allergies-v1',
              authorizationVersion: withdrawn ? 2 : 1,
              profileVersion: 1,
              availableCategories: const ['花生'],
              categories: withdrawn ? [] : ['花生'],
              ingredients: const [],
            ).toJson(),
          ),
        );
        server.on('GET', '$familyPath/changes', (_) {
          if (operation == 'history' && !started) {
            started = true;
            return pending.future;
          }
          return (
            200,
            PageTasteProfileChangeOut(
              items: withdrawn ? [] : [privateFamilyHistory(old)],
            ).toJson(),
          );
        });
        server.on('GET', '$familyPath/$familyMemberId', (_) {
          if (operation == 'detail' || operation == 'edit') {
            started = true;
            return pending.future;
          }
          return (200, old.toJson());
        });
        server.on('PUT', '$familyPath/$familyMemberId', (_) {
          started = true;
          return pending.future;
        });
        server.on('POST', '/v1/me/consents', (request) {
          final records = ((request.body as Map)['records'] as List)
              .cast<Map>();
          if (records.any(
            (r) =>
                r['kind'] == 'sensitive_personal_info' &&
                r['action'] == 'withdraw',
          )) {
            withdrawn = true;
          }
          return (204, null);
        });
        await pumpApp(tester, env: TestEnv.signedIn(server: server));
        await openFamilyPending(tester);
        if (operation == 'detail') {
          await tapFamilyPending(tester, 'family-view-$familyMemberId');
          await tapFamilyPending(tester, 'family-detail-close');
        } else if (operation == 'edit' || operation == 'save') {
          await tapFamilyPending(tester, 'family-edit-$familyMemberId');
          if (operation == 'save') {
            await tapFamilyPending(tester, 'family-save');
          }
          await tapFamilyPending(tester, 'family-editor-cancel');
        }
        expect(started, isTrue);
        await goBack(tester);
        await openSettings(tester);
        await tapVisible(
          tester,
          find.byKey(const ValueKey('sensitive-withdraw')),
        );
        await tapVisible(
          tester,
          find.byKey(const ValueKey('sensitive-withdraw-confirm')),
        );
        expect(find.text('敏感同意已撤回，过敏、家庭成员及私密历史已删除'), findsOneWidget);
        pending.complete((
          200,
          operation == 'history'
              ? PageTasteProfileChangeOut(items: [privateFamilyHistory(old)])
                    .toJson()
              : old.toJson(),
        ));
        await tester.pumpAndSettle();
        await goBack(tester);
        await openTaste(tester);
        expect(find.text('咸 · 淡一点'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('allergies-edit')),
          300,
        );
        await tester.pumpAndSettle();
        expect(find.text('尚未填写本人过敏'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('family-add')),
          200,
        );
        await tester.pumpAndSettle();
        expect(find.text('还没有家庭成员'), findsOneWidget);
        expect(find.text('没有家庭成员私密修改历史'), findsOneWidget);
        expect(find.textContaining('孩子私密称呼'), findsNothing);
        expect(find.byKey(const ValueKey('why-panel')), findsNothing);
        expect(find.byKey(const ValueKey('family-editor')), findsNothing);
        await tapVisible(tester, find.byKey(const ValueKey('family-add')));
        expect(find.text('家庭成员信息单独同意'), findsOneWidget);
        await tapVisible(
          tester,
          find.byKey(const ValueKey('family-consent-refuse')),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'withdrawal does not claim success while the server still has family information',
    (tester) async {
      final server = FakeServer();
      server.on(
        'GET',
        familyPath,
        (_) => (
          200,
          familyFixture(
            consentId: familyConsentId,
            members: [memberFixture()],
          ).toJson(),
        ),
      );
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await openSettings(tester);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('sensitive-withdraw')),
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('sensitive-withdraw-confirm')),
      );
      expect(find.text('撤回尚未确认，请联网后重试；普通口味不受影响'), findsOneWidget);
      expect(find.text('敏感同意已撤回，过敏、家庭成员及私密历史已删除'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  for (final operation in ['list', 'history', 'detail', 'edit', 'save']) {
    testWidgets('A to B to A ignores late family $operation replies', (
      tester,
    ) async {
      final server = FakeServer();
      final original = server.user;
      installProfile(server, () => profileFixture());
      final pending = Completer<(int, Object?)>();
      final old = memberFixture();
      var started = false;
      var fresh = false;
      server.on('GET', familyPath, (_) {
        if (operation == 'list' && !started) {
          started = true;
          return pending.future;
        }
        return (
          200,
          familyFixture(
            consentId: fresh ? null : familyConsentId,
            members: fresh ? [] : [old],
          ).toJson(),
        );
      });
      server.on('GET', '$familyPath/changes', (_) {
        if (operation == 'history' && !started) {
          started = true;
          return pending.future;
        }
        return (200, PageTasteProfileChangeOut(items: const []).toJson());
      });
      server.on('GET', '$familyPath/$familyMemberId', (_) {
        if (operation == 'detail' || operation == 'edit') {
          started = true;
          return pending.future;
        }
        return (200, old.toJson());
      });
      server.on('PUT', '$familyPath/$familyMemberId', (_) {
        started = true;
        return pending.future;
      });
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await openFamilyPending(tester);
      if (operation == 'detail') {
        await tapFamilyPending(tester, 'family-view-$familyMemberId');
        await tapFamilyPending(tester, 'family-detail-close');
      } else if (operation == 'edit' || operation == 'save') {
        await tapFamilyPending(tester, 'family-edit-$familyMemberId');
        if (operation == 'save') await tapFamilyPending(tester, 'family-save');
        await tapFamilyPending(tester, 'family-editor-cancel');
      }
      expect(started, isTrue);
      fresh = true;
      await signOut(tester);
      final other = original.copyWith(
        id: '88888888-8888-4888-8888-888888888888',
        nickname: '另一位味友',
      );
      await loginFamilyAccount(tester, server, other);
      await openTaste(tester);
      await signOut(tester);
      await loginFamilyAccount(tester, server, original);
      await openFamily(tester);
      pending.complete((
        200,
        operation == 'list'
            ? familyFixture(consentId: familyConsentId, members: [old]).toJson()
            : operation == 'history'
            ? PageTasteProfileChangeOut(items: [privateFamilyHistory(old)])
                  .toJson()
            : old.toJson(),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('孩子私密称呼'), findsNothing);
      expect(find.text('还没有家庭成员'), findsOneWidget);
      expect(find.text('没有家庭成员私密修改历史'), findsOneWidget);
      expect(find.byKey(const ValueKey('why-panel')), findsNothing);
      expect(find.byKey(const ValueKey('family-editor')), findsNothing);
      await tapVisible(tester, find.byKey(const ValueKey('family-add')));
      expect(find.text('家庭成员信息单独同意'), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-consent-refuse')),
      );
      expect(tester.takeException(), isNull);
    });
  }
  for (final operation in ['history', 'detail', 'edit', 'save']) {
    testWidgets(
      'delete evicts family immediately and rejects late $operation even when first delete fails',
      (tester) async {
        final server = FakeServer();
        installProfile(server, () => profileFixture());
        final old = memberFixture();
        final pending = Completer<(int, Object?)>();
        var started = false;
        var removed = false;
        var attempts = 0;
        server.on(
          'GET',
          familyPath,
          (_) => (
            200,
            familyFixture(
              consentId: familyConsentId,
              members: removed ? [] : [old],
            ).toJson(),
          ),
        );
        server.on('GET', '$familyPath/changes', (_) {
          if (operation == 'history' && !started) {
            started = true;
            return pending.future;
          }
          return (
            200,
            PageTasteProfileChangeOut(
              items: removed ? [] : [privateFamilyHistory(old)],
            ).toJson(),
          );
        });
        server.on('GET', '$familyPath/$familyMemberId', (_) {
          if (operation == 'detail' || operation == 'edit') {
            started = true;
            return pending.future;
          }
          return (200, old.toJson());
        });
        server.on('PUT', '$familyPath/$familyMemberId', (_) {
          started = true;
          return pending.future;
        });
        server.on('DELETE', '$familyPath/$familyMemberId', (_) {
          attempts++;
          if (attempts == 1) {
            return FakeServer.error(
              503,
              'unavailable',
              'must not display private raw error',
            );
          }
          removed = true;
          return (204, null);
        });
        await pumpApp(tester, env: TestEnv.signedIn(server: server));
        await openFamilyPending(tester);
        if (operation == 'detail') {
          await tapFamilyPending(tester, 'family-view-$familyMemberId');
          await tapFamilyPending(tester, 'family-detail-close');
        } else if (operation == 'edit' || operation == 'save') {
          await tapFamilyPending(tester, 'family-edit-$familyMemberId');
          if (operation == 'save') {
            await tapFamilyPending(tester, 'family-save');
          }
          await tapFamilyPending(tester, 'family-editor-cancel');
        }
        expect(started, isTrue);
        await tapFamilyPending(tester, 'family-delete-$familyMemberId');
        await tapFamilyPending(tester, 'family-delete-confirm');
        expect(find.textContaining('孩子私密称呼'), findsNothing);
        expect(find.text('删除尚未确认，信息已从本机内存清除；请重试'), findsOneWidget);
        expect(find.textContaining('must not display'), findsNothing);
        pending.complete((
          200,
          operation == 'history'
              ? PageTasteProfileChangeOut(items: [privateFamilyHistory(old)])
                    .toJson()
              : old.toJson(),
        ));
        await tester.pumpAndSettle();
        expect(find.textContaining('孩子私密称呼'), findsNothing);
        expect(find.text('没有家庭成员私密修改历史'), findsOneWidget);
        await tapVisible(
          tester,
          find.byKey(const ValueKey('family-delete-retry')),
        );
        expect(find.byKey(const ValueKey('family-delete-retry')), findsNothing);
        expect(
          server.calls('DELETE', '$familyPath/$familyMemberId'),
          hasLength(2),
        );
        await goBack(tester);
        await openFamily(tester);
        expect(find.text('还没有家庭成员'), findsOneWidget);
        expect(find.textContaining('孩子私密称呼'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'changed authorization between family pages fails closed without exposing earlier private rows',
    (tester) async {
      final server = FakeServer();
      installProfile(server, () => profileFixture());
      var page = 0;
      server.on('GET', familyPath, (_) {
        page++;
        return (
          200,
          page.isOdd
              ? familyFixture(
                  consentId: familyConsentId,
                  members: [memberFixture()],
                ).copyWith(nextCursor: 'next').toJson()
              : familyFixture().copyWith(authorizationVersion: 2).toJson(),
        );
      });
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await openFamily(tester);
      expect(server.calls('GET', familyPath), hasLength(2));
      expect(find.textContaining('孩子私密称呼'), findsNothing);
      expect(find.text('家庭信息暂不可用；仍可在设置撤回同意'), findsOneWidget);
      expect(server.calls('GET', '$familyPath/changes'), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'first family disclosure reuses existing sensitive receipt and refusal preserves owner allergies',
    (tester) async {
      final server = FakeServer();
      installProfile(server, () => profileFixture());
      server.on(
        'GET',
        familyPath,
        (_) => (200, familyFixture(consentId: familyConsentId).toJson()),
      );
      server.on(
        'GET',
        '/v1/me/taste-profile/allergies',
        (_) => (
          200,
          AllergiesOut(
            consentId: familyConsentId,
            consentVersion: 'allergies-v1',
            authorizationVersion: 1,
            profileVersion: 1,
            availableCategories: const ['花生'],
            categories: const ['花生'],
            ingredients: const [],
          ).toJson(),
        ),
      );
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await openFamily(tester);
      await tapVisible(tester, find.byKey(const ValueKey('family-add')));
      expect(find.text('家庭成员信息单独同意'), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-consent-refuse')),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('allergies-edit')),
        -200,
      );
      expect(find.text('花生'), findsOneWidget);
      expect(server.calls('POST', familyPath), isEmpty);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('family-add')),
        200,
      );
      await tapVisible(tester, find.byKey(const ValueKey('family-add')));
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-consent-agree')),
      );
      expect(find.byKey(const ValueKey('family-editor')), findsOneWidget);
      expect(
        server
            .calls('POST', '/v1/me/consents')
            .where(
              (r) => jsonEncode(r.body).contains('sensitive_personal_info'),
            ),
        isEmpty,
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-editor-cancel')),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('allergies-edit')),
        -200,
      );
      expect(find.text('花生'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'family grant, seven age labels, sparse no-chili CRUD and guarded Why reopen correctly',
    (tester) async {
      final server = FakeServer();
      installProfile(server, () => profileFixture());
      String? consent;
      FamilyMemberOut? member;
      final history = <TasteProfileChangeOut>[];
      server.on(
        'GET',
        familyPath,
        (_) => (
          200,
          familyFixture(
            consentId: consent,
            members: [if (member != null) member!],
          ).toJson(),
        ),
      );
      server.on(
        'GET',
        '$familyPath/changes',
        (_) => (200, PageTasteProfileChangeOut(items: history).toJson()),
      );
      server.on(
        'GET',
        '$familyPath/$familyMemberId',
        (_) => (200, member!.toJson()),
      );
      server.on('POST', '/v1/me/consents', (request) {
        final records = ((request.body as Map)['records'] as List).cast<Map>();
        for (final record in records) {
          if (record['kind'] == 'sensitive_personal_info') {
            consent = record['id'] as String;
          }
        }
        return (204, null);
      });
      (int, Object?) save(Recorded request) {
        final body = request.body as Map;
        expect(
          body.keys,
          unorderedEquals([
            'consent_id',
            'authorization_version',
            'nickname',
            'age_band',
            'flavors',
            'avoidances',
            'allergies',
          ]),
        );
        expect(body['consent_id'], consent);
        expect(body['authorization_version'], 1);
        member = FamilyMemberOut.fromJson({
          'id': familyMemberId,
          'nickname': body['nickname'],
          'age_band': body['age_band'],
          'flavors': body['flavors'],
          'avoidances': [
            for (final target in body['avoidances'] as List)
              {...target as Map, 'name': target['category'] ?? '标准酱油'},
          ],
          'allergies': {
            'categories': (body['allergies'] as Map)['categories'],
            'ingredients': [
              for (final id
                  in (body['allergies'] as Map)['ingredient_ids'] as List)
                {'ingredient_id': id, 'name': '标准酱油'},
            ],
          },
          'source': 'manual',
        });
        history.clear();
        history.add(privateFamilyHistory(member!));
        return (request.method == 'POST' ? 201 : 200, member!.toJson());
      }

      server.on('POST', familyPath, save);
      server.on('PUT', '$familyPath/$familyMemberId', save);
      server.on('DELETE', '$familyPath/$familyMemberId', (_) {
        member = null;
        history.clear();
        return (204, null);
      });
      final env = TestEnv.signedIn(server: server);
      await pumpApp(tester, env: env);
      await openFamily(tester);
      await tapVisible(tester, find.byKey(const ValueKey('family-add')));
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-consent-agree')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('family-nickname')),
        '孩子私密称呼',
      );
      for (final label in [
        '1 岁以下',
        '1～3 岁',
        '3～6 岁',
        '6～12 岁',
        '12～18 岁',
        '成人',
        '老人',
      ]) {
        await chooseFamily(tester, 'family-age-band', label);
      }
      await chooseFamily(tester, 'family-age-band', '1～3 岁');
      await chooseFamily(tester, 'family-flavor-spicy', '不吃辣');
      await tapVisible(tester, find.byKey(const ValueKey('family-save')));
      expect((server.calls('POST', familyPath).single.body as Map)['flavors'], {
        'spicy': 0,
      });
      expect(member!.allergies.categories, isEmpty);
      expect(member!.allergies.ingredients, isEmpty);
      expect(find.text('孩子私密称呼 · 1～3 岁'), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-view-$familyMemberId')),
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('辣 · 不吃辣'),
        ),
        findsOneWidget,
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-detail-close')),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('family-why-$familyChangeId')),
        200,
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-why-$familyChangeId')),
      );
      expect(find.byKey(const ValueKey('why-panel')), findsOneWidget);
      expect(find.text('家庭成员手动填写'), findsOneWidget);
      expect(find.textContaining('孩子私密称呼'), findsWidgets);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      await goBack(tester);
      await openFamily(tester);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-edit-$familyMemberId')),
      );
      expect(find.text('家庭成员信息单独同意'), findsNothing);
      expect(find.widgetWithText(TextField, '孩子私密称呼'), findsOneWidget);
      await chooseFamily(tester, 'family-age-band', '6～12 岁');
      await chooseFamily(tester, 'family-flavor-spicy', '标准（不单独记录）');
      await tapVisible(tester, find.byKey(const ValueKey('family-save')));
      expect(
        (server.calls('PUT', '$familyPath/$familyMemberId').single.body
            as Map)['flavors'],
        isEmpty,
      );
      expect(find.text('孩子私密称呼 · 6～12 岁'), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-delete-$familyMemberId')),
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-delete-confirm')),
      );
      expect(find.textContaining('孩子私密称呼'), findsNothing);
      expect(find.text('没有家庭成员私密修改历史'), findsOneWidget);
      await goBack(tester);
      await openFamily(tester);
      expect(find.text('还没有家庭成员'), findsOneWidget);
      expect(
        server
            .calls('POST', '/v1/me/consents')
            .where(
              (r) => jsonEncode(r.body).contains('sensitive_personal_info'),
            ),
        hasLength(1),
      );
      expect(jsonEncode(env.local.values), isNot(contains('孩子私密称呼')));
      expect(jsonEncode(env.secure.values), isNot(contains('孩子私密称呼')));
      expect(
        jsonEncode(
          server.calls('POST', '/v1/events/upload').map((r) => r.body).toList(),
        ),
        isNot(contains('孩子私密称呼')),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'family consent explains child protection; refusal leaves ordinary taste intact',
    (tester) async {
      final server = FakeServer();
      installProfile(server, () => profileFixture());
      server.on('GET', familyPath, (_) => (200, familyFixture().toJson()));
      final env = TestEnv.signedIn(server: server);
      await pumpApp(tester, env: env);
      await openFamily(tester);
      await tapVisible(tester, find.byKey(const ValueKey('family-add')));
      expect(find.text('家庭成员信息单独同意'), findsOneWidget);
      expect(find.textContaining('不满十四周岁'), findsOneWidget);
      expect(find.textContaining('不收集真实姓名、生日或照片'), findsOneWidget);
      expect(find.textContaining('加密'), findsOneWidget);
      expect(find.textContaining('不代表同意外部 AI'), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('family-consent-refuse')),
      );
      expect(server.calls('POST', familyPath), isEmpty);
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
      expect(tester.takeException(), isNull);
    },
  );
}
