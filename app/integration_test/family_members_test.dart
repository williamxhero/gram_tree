import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/config/app_config.dart';
import 'package:gram_tree/main.dart' as app;
import 'package:gramtree_api/gramtree_api.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final server = Dio(
    BaseOptions(baseUrl: AppConfig.fromEnvironment().apiBaseUrl),
  );

  final api = GramtreeApi(dio: server, interceptors: const []);
  final familyApi = api.getFamilyMembersApi();
  const familyPath = '/v1/me/taste-profile/family-members';

  Future<Map<String, dynamic>> loginApi(String email) async {
    final device = {'X-Device-ID': 'family-probe-$email'};
    await api.getAuthApi().sendEmailCode(
      emailCodeRequest: EmailCodeRequest(
        email: email,
        purpose: EmailCodeRequestPurposeEnum.login,
      ),
      headers: device,
    );
    final code = await server.get(
      '/v1/dev/latest-email-code',
      queryParameters: {'email': email},
    );
    final response = await api.getAuthApi().emailLogin(
      emailLoginRequest: EmailLoginRequest(
        email: email,
        code: code.data['code'] as String,
      ),
      headers: device,
    );
    return {'Authorization': 'Bearer ${response.data!.accessToken}'};
  }

  Future<void> expectStatus(
    Future<dynamic> Function() request,
    int expected,
  ) async {
    int? status;
    try {
      await request();
    } on DioException catch (error) {
      // Do not print the exception: it may contain decrypted sensitive data.
      status = error.response?.statusCode;
    }
    expect(status, expected);
  }

  void expectAbsent(Object value, Iterable<String> forbidden) {
    final encoded = jsonEncode(value);
    for (final text in forbidden) {
      expect(
        encoded.contains(text),
        isFalse,
        reason: 'Deleted sensitive data must not remain in a public response',
      );
    }
  }

  Finder key(String value) => find.byKey(ValueKey(value));
  Finder detailText(String value) => find.descendant(
    of: find.byType(AlertDialog).last,
    matching: find.textContaining(value),
  );
  Finder keyed(String prefix) => find.byWidgetPredicate(
    (widget) =>
        widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value.startsWith(prefix),
  );

  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 300 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsWidgets);
    await tester.pumpAndSettle();
  }

  Future<void> reveal(
    WidgetTester tester,
    Finder finder, [
    double delta = 300,
  ]) async {
    await tester.scrollUntilVisible(
      finder,
      delta,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openProfile(WidgetTester tester) async {
    final entry = key('taste-profile-entry');
    await reveal(tester, entry, -300);
    await tester.tap(entry);
    await waitFor(tester, key('taste-profile-content'));
  }

  Future<void> reopen(WidgetTester tester) async {
    // A saved value can also appear behind an editor; wait for its dismissal.
    await waitFor(tester, key('taste-profile-content').hitTestable());
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    await openProfile(tester);
    await reveal(tester, key('family-add'));
  }

  testWidgets('家庭成员单独同意、七种年龄、简单偏好、私密历史、删除与撤回重开', (tester) async {
    // Never collect page text, raw responses, errors or screenshots as diagnostics.
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);
    await app.main();
    await waitFor(tester, key('consent-agree'));
    await tester.tap(key('consent-agree'));
    await waitFor(tester, key('login-email'));
    final email =
        'family-e2e-${DateTime.now().microsecondsSinceEpoch}@example.com';
    await tester.enterText(key('login-email'), email);
    await tester.tap(find.text('发送验证码'));
    await waitFor(tester, key('code-input'));
    final code = await server.get(
      '/v1/dev/latest-email-code',
      queryParameters: {'email': email},
    );
    await tester.enterText(key('code-input'), code.data['code'] as String);
    await waitFor(tester, find.text('先添加一道你常做的菜'));
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await openProfile(tester);
    await tester.tap(key('taste-level-salty'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('淡一点').last);
    await waitFor(tester, find.text('咸 · 淡一点'));

    await reveal(tester, key('family-add'));
    await tester.tap(key('family-add'));
    await waitFor(tester, key('family-consent-refuse'));
    expect(find.text('家庭成员信息单独同意'), findsOneWidget);
    expect(find.textContaining('不满十四周岁'), findsOneWidget);
    expect(find.textContaining('不收集真实姓名、生日或照片'), findsOneWidget);
    expect(find.textContaining('加密'), findsOneWidget);
    expect(find.textContaining('不代表同意外部 AI'), findsOneWidget);
    await tap(tester, key('family-consent-refuse'));
    expect(key('family-editor'), findsNothing);
    expect(keyed('family-view-'), findsNothing);
    await reveal(tester, key('taste-level-salty'), -300);
    expect(find.text('咸 · 淡一点'), findsOneWidget);

    final owner = await loginApi(email);
    final refused = (await familyApi.listFamilyMembers(headers: owner)).data!;
    expect(refused.consentId, isNull);
    expect(refused.members, isEmpty);
    await expectStatus(
      () => familyApi.createFamilyMember(
        familyMemberWrite: FamilyMemberWrite(
          consentId: '00000000-0000-4000-8000-000000000099',
          authorizationVersion: refused.authorizationVersion,
          nickname: '未授权成员',
          ageBand: FamilyMemberWriteAgeBandEnum.n1to3,
        ),
        headers: owner,
      ),
      403,
    );

    await reveal(tester, key('family-add'));
    await tester.tap(key('family-add'));
    await waitFor(tester, key('family-consent-agree'));
    await tap(tester, key('family-consent-agree'));
    await waitFor(tester, key('family-nickname'));
    await tester.enterText(key('family-nickname'), '孩子');
    const ages = ['1 岁以下', '1～3 岁', '3～6 岁', '6～12 岁', '12～18 岁', '成人', '老人'];
    for (final age in ages) {
      await tap(tester, key('family-age-band'));
      for (final label in ages) {
        expect(find.text(label), findsWidgets);
      }
      await tap(tester, find.text(age).last);
      expect(
        find.descendant(of: key('family-age-band'), matching: find.text(age)),
        findsOneWidget,
      );
    }
    await tap(tester, key('family-age-band'));
    await tap(tester, find.text('1～3 岁').last);
    await tap(tester, key('family-flavor-spicy'));
    await tap(tester, find.text('不吃辣').last);
    await tap(tester, key('family-avoidance-add'));
    await waitFor(tester, key('taste-preference-category'));
    await tap(tester, key('taste-preference-category'));
    await tap(tester, find.text('蔬菜').last);
    await tap(tester, key('taste-preference-save'));
    await waitFor(tester, key('family-nickname'));
    await tap(tester, key('family-avoidance-add'));
    await waitFor(tester, key('taste-ingredient-search'));
    await tester.enterText(key('taste-ingredient-search'), '测试酱油');
    await tap(tester, key('taste-ingredient-search-submit'));
    await waitFor(tester, keyed('taste-search-'));
    await tap(tester, keyed('taste-search-').first);
    await tap(tester, key('taste-preference-save'));
    await waitFor(tester, key('family-nickname'));
    await tap(tester, key('family-allergy-category-花生'));
    await tap(tester, key('family-allergy-add'));
    await waitFor(tester, key('taste-ingredient-search'));
    await tester.enterText(key('taste-ingredient-search'), '测试酱油');
    await tap(tester, key('taste-ingredient-search-submit'));
    await waitFor(tester, keyed('taste-search-'));
    await tap(tester, keyed('taste-search-').first);
    await tap(tester, key('taste-preference-save'));
    await waitFor(tester, key('family-nickname'));
    await tap(tester, key('family-save'));
    await waitFor(tester, find.text('孩子 · 1～3 岁'));
    await reopen(tester);
    await waitFor(tester, find.text('孩子 · 1～3 岁'));
    expect(find.text('孩子 · 1～3 岁'), findsOneWidget);
    final firstView = keyed('family-view-');
    expect(firstView, findsOneWidget);
    final firstId = (tester.widget(firstView).key! as ValueKey<String>).value
        .substring('family-view-'.length);
    final firstSaved = (await familyApi.getFamilyMember(
      memberId: firstId,
      headers: owner,
    )).data!.toJson();
    expect(firstSaved['nickname'] == '孩子', isTrue);
    expect(firstSaved['age_band'] == '1_to_3', isTrue);
    expect((firstSaved['flavors'] as Map).length, 1);
    expect((firstSaved['flavors'] as Map)['spicy'] == 0, isTrue);
    final avoidances = firstSaved['avoidances'] as List;
    expect(avoidances.length, 2);
    expect(avoidances.any((entry) => entry['category'] == '蔬菜'), isTrue);
    expect(
      avoidances.any(
        (entry) =>
            entry['ingredient_id'] == '00000000-0000-4000-8000-000000000001',
      ),
      isTrue,
    );
    final allergies = firstSaved['allergies'] as Map;
    expect(jsonEncode(allergies['categories']) == '["花生"]', isTrue);
    expect((allergies['ingredients'] as List).length, 1);
    expect(
      (allergies['ingredients'] as List).single['ingredient_id'] ==
          '00000000-0000-4000-8000-000000000001',
      isTrue,
    );
    expect(firstSaved['source'] == 'manual', isTrue);

    await tap(tester, key('family-view-$firstId'));
    await waitFor(tester, key('family-detail-close'));
    await waitFor(
      tester,
      find.descendant(
        of: find.byType(AlertDialog).last,
        matching: find.textContaining('孩子 · 1～3 岁'),
      ),
    );
    expect(find.text('家庭成员档案'), findsOneWidget);
    expect(detailText('辣 · 不吃辣'), findsOneWidget);
    expect(detailText('忌口 · 蔬菜'), findsOneWidget);
    expect(detailText('忌口 · 测试酱油'), findsOneWidget);
    expect(detailText('手动过敏（不会自动推断） · 测试酱油'), findsOneWidget);
    expect(detailText('手动过敏（不会自动推断） · 花生'), findsOneWidget);
    await tap(tester, key('family-detail-close'));
    await tap(tester, key('family-edit-$firstId'));
    await waitFor(tester, key('family-nickname'));
    expect(find.text('家庭成员信息单独同意'), findsNothing);
    expect(
      tester.widget<TextField>(key('family-nickname')).controller!.text == '孩子',
      isTrue,
    );
    await tap(tester, key('family-age-band'));
    await tap(tester, find.text('6～12 岁').last);
    await tap(tester, key('family-flavor-spicy'));
    await tap(tester, find.text('淡一点').last);
    await tap(tester, key('family-avoidance-add'));
    await waitFor(tester, key('taste-preference-category'));
    await tap(tester, key('taste-preference-category'));
    await tap(tester, find.text('肉类').last);
    await tap(tester, key('taste-preference-save'));
    await waitFor(tester, key('family-nickname'));
    await tap(tester, key('family-save'));
    await waitFor(tester, find.text('孩子 · 6～12 岁'));
    await reopen(tester);
    await waitFor(tester, find.text('孩子 · 6～12 岁'));
    expect(find.text('孩子 · 6～12 岁'), findsOneWidget);
    await tap(tester, key('family-view-$firstId'));
    await waitFor(
      tester,
      find.descendant(
        of: find.byType(AlertDialog).last,
        matching: find.textContaining('孩子 · 6～12 岁'),
      ),
    );
    expect(detailText('辣 · 淡一点'), findsOneWidget);
    expect(detailText('忌口 · 肉类'), findsOneWidget);
    expect(detailText('手动过敏（不会自动推断） · 花生'), findsOneWidget);
    await tap(tester, key('family-detail-close'));
    final edited = (await familyApi.getFamilyMember(
      memberId: firstId,
      headers: owner,
    )).data!.toJson();
    expect(edited['age_band'] == '6_to_12', isTrue);
    expect((edited['flavors'] as Map)['spicy'] == 0.75, isTrue);
    expect((edited['avoidances'] as List).length, 3);
    final firstHistory = (await familyApi.listFamilyMemberChanges(
      headers: owner,
    )).data!;
    expect(firstHistory.items.length, 2);
    final firstHistoryIds = firstHistory.items
        .map((change) => change.id)
        .toList();
    final change = firstHistory.items.first;
    expect(change.field == 'family_members.$firstId', isTrue);
    expect(change.reason == '你手动修改', isTrue);
    expect(change.toJson()['source'] == 'manual', isTrue);
    expect(change.toJson()['status'] == 'active', isTrue);
    expect(change.version, greaterThan(firstHistory.items.last.version));
    final oldValue = change.oldValue as Map;
    final newValue = change.newValue as Map;
    expect(oldValue['nickname'] == '孩子', isTrue);
    expect(oldValue['age_band'] == '1_to_3', isTrue);
    expect((oldValue['flavors'] as Map)['spicy'] == 0, isTrue);
    expect(newValue['nickname'] == '孩子', isTrue);
    expect(newValue['age_band'] == '6_to_12', isTrue);
    expect((newValue['flavors'] as Map)['spicy'] == 0.75, isTrue);
    final ordinary = (await api.getTasteProfileApi().listTasteProfileChanges(
      headers: owner,
    )).data!;
    expect(
      ordinary.items.any(
        (entry) =>
            entry.field.startsWith('family_members') ||
            entry.field == 'allergies',
      ),
      isFalse,
    );
    final ordinaryHistoryIds = ordinary.items.map((entry) => entry.id).toList();
    expect(ordinaryHistoryIds, isNotEmpty);
    final grant = (await familyApi.listFamilyMembers(headers: owner)).data!;
    final validBody = {
      'consent_id': grant.consentId,
      'authorization_version': grant.authorizationVersion,
      'nickname': '孩子',
      'age_band': '6_to_12',
    };
    // The generated write model cannot encode forbidden extra fields.
    for (final extra in [
      {'real_name': '不应收集'},
      {'birthday': '2020-01-01'},
      {'photo': 'https://example.com/private-child.jpg'},
    ]) {
      final response = await server.put(
        '$familyPath/$firstId',
        data: {...validBody, ...extra},
        options: Options(headers: owner, validateStatus: (_) => true),
      );
      expect(response.statusCode, 422);
    }
    expect(
      jsonEncode(
            (await familyApi.getFamilyMember(
              memberId: firstId,
              headers: owner,
            )).data!.toJson(),
          ) ==
          jsonEncode(edited),
      isTrue,
    );
    final other = await loginApi(
      'family-other-${DateTime.now().microsecondsSinceEpoch}@example.com',
    );
    expect(
      (await familyApi.listFamilyMembers(headers: other)).data!.members,
      isEmpty,
    );
    await expectStatus(
      () => familyApi.getFamilyMember(memberId: firstId, headers: other),
      404,
    );

    final why = key('family-why-${change.id}');
    await waitFor(tester, why);
    await reveal(tester, why);
    await tester.tap(why);
    await waitFor(tester, key('why-panel'));
    expect(find.text('家庭成员手动填写'), findsOneWidget);
    expect(
      find.descendant(
        of: key('why-panel'),
        matching: find.textContaining('你手动修改'),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: key('why-panel'),
        matching: find.textContaining('孩子 · 1～3 岁'),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: key('why-panel'),
        matching: find.textContaining('孩子 · 6～12 岁'),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: key('why-panel'),
        matching: find.textContaining('辣 · 不吃辣'),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: key('why-panel'),
        matching: find.textContaining('辣 · 淡一点'),
      ),
      findsWidgets,
    );
    expect(find.text('这次不用'), findsNothing);
    expect(find.text('以后别这样'), findsNothing);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    await reveal(tester, key('family-add'), -300);
    await tester.tap(key('family-add'));
    await waitFor(tester, key('family-nickname'));
    expect(find.text('家庭成员信息单独同意'), findsNothing);
    await tester.enterText(key('family-nickname'), '小家人');
    await tap(tester, key('family-age-band'));
    await tap(tester, find.text('3～6 岁').last);
    await tap(tester, key('family-flavor-spicy'));
    await tap(tester, find.text('不吃辣').last);
    await tap(tester, key('family-allergy-category-蛋类'));
    await tap(tester, key('family-save'));
    await waitFor(tester, find.text('小家人 · 3～6 岁'));
    await reopen(tester);
    await waitFor(tester, find.text('孩子 · 6～12 岁'));
    expect(find.text('孩子 · 6～12 岁'), findsOneWidget);
    expect(find.text('小家人 · 3～6 岁'), findsOneWidget);
    final secondView = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith('family-view-') &&
          widget.key != ValueKey('family-view-$firstId'),
    );
    expect(secondView, findsOneWidget);
    final secondId = (tester.widget(secondView).key! as ValueKey<String>).value
        .substring('family-view-'.length);
    final secondSaved = (await familyApi.getFamilyMember(
      memberId: secondId,
      headers: owner,
    )).data!.toJson();
    expect(secondSaved['nickname'] == '小家人', isTrue);
    expect(secondSaved['age_band'] == '3_to_6', isTrue);
    expect((secondSaved['flavors'] as Map)['spicy'] == 0, isTrue);
    expect(
      jsonEncode((secondSaved['allergies'] as Map)['categories']) == '["蛋类"]',
      isTrue,
    );
    expect(
      ((secondSaved['allergies'] as Map)['ingredients'] as List).isEmpty,
      isTrue,
    );
    final allFamilyHistory = (await familyApi.listFamilyMemberChanges(
      headers: owner,
    )).data!;
    final secondHistoryIds = allFamilyHistory.items
        .where((entry) => entry.field == 'family_members.$secondId')
        .map((entry) => entry.id)
        .toList();
    expect(secondHistoryIds, hasLength(1));
    await tap(tester, key('family-delete-$firstId'));
    await waitFor(tester, key('family-delete-confirm'));
    await tap(tester, key('family-delete-confirm'));
    await waitFor(tester, find.textContaining('家庭成员已删除（不保留身份）'));
    await reopen(tester);
    await waitFor(tester, key('family-view-$secondId'));
    expect(key('family-view-$firstId'), findsNothing);
    expect(key('family-edit-$firstId'), findsNothing);
    expect(key('family-delete-$firstId'), findsNothing);
    expect(find.textContaining('孩子'), findsNothing);
    expect(find.textContaining('测试酱油'), findsNothing);
    expect(find.textContaining('花生'), findsNothing);
    expect(find.text('小家人 · 3～6 岁'), findsOneWidget);
    final afterDelete = (await familyApi.listFamilyMembers(headers: owner))
        .data!;
    expect(afterDelete.members.length, 1);
    expect(afterDelete.members.single.id == secondId, isTrue);
    expect(
      jsonEncode(afterDelete.members.single.toJson()) ==
          jsonEncode(secondSaved),
      isTrue,
    );
    final remainingHistory = (await familyApi.listFamilyMemberChanges(
      headers: owner,
    )).data!;
    expect(
      remainingHistory.items.any(
        (entry) => entry.field == 'family_members.$secondId',
      ),
      isTrue,
    );
    const firstValues = [
      '孩子',
      '1_to_3',
      '6_to_12',
      '花生',
      '蔬菜',
      '肉类',
      '测试酱油',
      '00000000-0000-4000-8000-000000000001',
    ];
    expectAbsent(
      afterDelete.members.map((member) => member.toJson()).toList(),
      [firstId, ...firstValues],
    );
    expectAbsent(remainingHistory.toJson(), [firstId, ...firstValues]);
    await expectStatus(
      () => familyApi.getFamilyMember(memberId: firstId, headers: owner),
      404,
    );
    for (final id in firstHistoryIds) {
      await expectStatus(
        () => familyApi.getFamilyMemberChange(changeId: id, headers: owner),
        404,
      );
    }
    await tap(tester, key('family-view-$secondId'));
    await waitFor(
      tester,
      find.descendant(
        of: find.byType(AlertDialog).last,
        matching: find.textContaining('小家人 · 3～6 岁'),
      ),
    );
    expect(detailText('辣 · 不吃辣'), findsOneWidget);
    expect(detailText('手动过敏（不会自动推断） · 蛋类'), findsOneWidget);
    await tap(tester, key('family-detail-close'));

    final allergyEdit = key('allergies-edit');
    await reveal(tester, allergyEdit, -300);
    await tester.tap(allergyEdit);
    await waitFor(tester, key('allergies-save'));
    expect(find.text('过敏信息单独同意'), findsNothing);
    await tap(tester, key('allergy-category-花生'));
    await tap(tester, key('allergies-save'));
    await waitFor(tester, find.text('花生'));
    await reopen(tester);
    await reveal(tester, allergyEdit, -300);
    await waitFor(tester, find.text('花生'));
    expect(find.text('花生'), findsOneWidget);
    await waitFor(tester, keyed('allergy-why-'));
    expect(keyed('allergy-why-'), findsWidgets);
    final ownerAllergies = (await api.getAllergiesApi().getAllergies(
      headers: owner,
    )).data!;
    expect(ownerAllergies.categories.length, 1);
    expect(ownerAllergies.categories.single == '花生', isTrue);
    final allergyHistory = (await api.getAllergiesApi().listAllergyChanges(
      headers: owner,
    )).data!;
    expect(allergyHistory.items, isNotEmpty);
    final allergyHistoryIds = allergyHistory.items
        .map((entry) => entry.id)
        .toList();
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    await reveal(tester, find.text('设置'));
    await tester.tap(find.text('设置'));
    await waitFor(tester, key('sensitive-withdraw'));
    await tap(tester, key('sensitive-withdraw'));
    await tap(tester, key('sensitive-withdraw-confirm'));
    await waitFor(tester, find.text('敏感同意已撤回，过敏、家庭成员及私密历史已删除'));
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    await openProfile(tester);
    expect(find.text('咸 · 淡一点'), findsOneWidget);
    await reveal(tester, allergyEdit);
    await waitFor(tester, find.text('尚未填写本人过敏'));
    expect(find.text('尚未填写本人过敏'), findsOneWidget);
    expect(find.text('没有私密修改历史'), findsOneWidget);
    expect(keyed('allergy-why-'), findsNothing);
    await reveal(tester, key('family-add'));
    await waitFor(tester, find.text('还没有家庭成员'));
    await waitFor(tester, find.text('没有家庭成员私密修改历史'));
    expect(keyed('family-view-'), findsNothing);
    expect(keyed('family-why-'), findsNothing);
    expect(find.textContaining('孩子'), findsNothing);
    expect(find.textContaining('小家人'), findsNothing);
    expect(find.textContaining('花生'), findsNothing);
    expect(find.textContaining('蛋类'), findsNothing);
    final withdrawn = (await familyApi.listFamilyMembers(headers: owner)).data!;
    expect(withdrawn.consentId, isNull);
    expect(withdrawn.members, isEmpty);
    expectAbsent(withdrawn.members.map((member) => member.toJson()).toList(), [
      firstId,
      secondId,
      ...firstValues,
      '小家人',
      '蛋类',
    ]);
    final withdrawnAllergies = (await api.getAllergiesApi().getAllergies(
      headers: owner,
    )).data!;
    expect(withdrawnAllergies.consentId, isNull);
    expect(withdrawnAllergies.categories, isEmpty);
    expect(withdrawnAllergies.ingredients, isEmpty);
    await expectStatus(
      () => familyApi.listFamilyMemberChanges(headers: owner),
      403,
    );
    await expectStatus(
      () => api.getAllergiesApi().listAllergyChanges(headers: owner),
      403,
    );
    expect(
      (await api.getTasteProfileApi().listTasteProfileChanges(headers: owner))
          .data!
          .items
          .map((entry) => entry.id)
          .toList(),
      ordinaryHistoryIds,
    );
    await reopen(tester);
    await waitFor(tester, find.text('还没有家庭成员'));
    await waitFor(tester, find.text('没有家庭成员私密修改历史'));
    expect(keyed('family-view-'), findsNothing);
    expect(keyed('family-why-'), findsNothing);
    await tester.tap(key('family-add'));
    await waitFor(tester, key('family-consent-agree'));
    await tap(tester, key('family-consent-agree'));
    await waitFor(tester, key('family-nickname'));
    expect(
      tester.widget<TextField>(key('family-nickname')).controller!.text.isEmpty,
      isTrue,
    );
    expect(find.textContaining('测试酱油'), findsNothing);
    for (final tile in tester.widgetList<CheckboxListTile>(
      find.byType(CheckboxListTile),
    )) {
      expect(tile.value, isFalse);
    }
    expect(
      find.descendant(
        of: key('family-flavor-spicy'),
        matching: find.text('标准（不单独记录）'),
      ),
      findsOneWidget,
    );
    await tap(tester, key('family-editor-cancel'));
    await waitFor(tester, key('taste-profile-content').hitTestable());
    await reopen(tester);
    await waitFor(tester, find.text('还没有家庭成员'));
    await waitFor(tester, find.text('没有家庭成员私密修改历史'));
    expect(keyed('family-view-'), findsNothing);
    expect(keyed('family-why-'), findsNothing);
    await reveal(tester, allergyEdit, -300);
    await waitFor(tester, find.text('尚未填写本人过敏'));
    expect(find.text('尚未填写本人过敏'), findsOneWidget);
    expect(find.text('没有私密修改历史'), findsOneWidget);
    final regranted = (await familyApi.listFamilyMembers(headers: owner)).data!;
    expect(regranted.consentId, isNotNull);
    expect(regranted.consentId == grant.consentId, isFalse);
    expect(regranted.members, isEmpty);
    expect(
      (await familyApi.listFamilyMemberChanges(headers: owner)).data!.items,
      isEmpty,
    );
    expect(
      (await api.getAllergiesApi().listAllergyChanges(headers: owner))
          .data!
          .items,
      isEmpty,
    );
    for (final id in [...firstHistoryIds, ...secondHistoryIds]) {
      await expectStatus(
        () => familyApi.getFamilyMemberChange(changeId: id, headers: owner),
        404,
      );
    }
    for (final id in allergyHistoryIds) {
      await expectStatus(
        () => api.getAllergiesApi().getAllergyChange(
          changeId: id,
          headers: owner,
        ),
        404,
      );
    }
    final emptyAllergies = (await api.getAllergiesApi().getAllergies(
      headers: owner,
    )).data!;
    expect(emptyAllergies.categories, isEmpty);
    expect(emptyAllergies.ingredients, isEmpty);
    await reveal(tester, key('taste-level-salty'), -300);
    expect(find.text('咸 · 淡一点'), findsOneWidget);
    expect(
      (await api.getTasteProfileApi().listTasteProfileChanges(headers: owner))
          .data!
          .items
          .map((entry) => entry.id)
          .toList(),
      ordinaryHistoryIds,
    );
    expect(tester.takeException(), isNull);
  });
}
