import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/config/app_config.dart';
import 'package:gram_tree/main.dart' as app;
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final server = Dio(
    BaseOptions(baseUrl: AppConfig.fromEnvironment().apiBaseUrl),
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
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
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

  final edit = find.byKey(const ValueKey('allergies-edit'));
  Future<void> openProfile(WidgetTester tester) async {
    final entry = find.byKey(const ValueKey('taste-profile-entry'));
    await reveal(tester, entry, -300);
    await tester.tap(entry);
    await waitFor(tester, find.byKey(const ValueKey('taste-profile-content')));
  }

  Future<void> reopen(WidgetTester tester) async {
    // Text may also exist in the editor; wait for the page to be unobscured.
    await waitFor(
      tester,
      find.byKey(const ValueKey('taste-profile-content')).hitTestable(),
    );
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    await openProfile(tester);
    await reveal(tester, edit);
  }

  Finder keyed(String prefix) => find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith(prefix),
  );

  testWidgets('本人过敏拒绝、单独同意、标准食材编辑、私密历史、撤回与空状态重新同意', (tester) async {
    // Never attach page text, raw errors, responses or screenshots to diagnostics.
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);
    await app.main();
    await waitFor(tester, find.byKey(const ValueKey('consent-agree')));
    await tester.tap(find.byKey(const ValueKey('consent-agree')));
    await waitFor(tester, find.byKey(const ValueKey('login-email')));
    final email =
        'allergies-e2e-${DateTime.now().microsecondsSinceEpoch}@example.com';
    await tester.enterText(find.byKey(const ValueKey('login-email')), email);
    await tester.tap(find.text('发送验证码'));
    await waitFor(tester, find.byKey(const ValueKey('code-input')));
    final code = await server.get(
      '/v1/dev/latest-email-code',
      queryParameters: {'email': email},
    );
    await tester.enterText(
      find.byKey(const ValueKey('code-input')),
      code.data['code'] as String,
    );
    await waitFor(tester, find.text('先添加一道你常做的菜'));
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await openProfile(tester);
    await tester.tap(find.byKey(const ValueKey('taste-level-salty')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('淡一点').last);
    await waitFor(tester, find.text('咸 · 淡一点'));
    await reveal(tester, edit);
    await tester.tap(edit);
    await waitFor(tester, find.byKey(const ValueKey('allergies-refuse')));
    expect(find.textContaining('不代表同意外部 AI'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('allergies-refuse')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('taste-level-salty')), -300);
    expect(find.text('咸 · 淡一点'), findsOneWidget);
    await reveal(tester, edit);
    await tester.tap(edit);
    await waitFor(tester, find.byKey(const ValueKey('allergies-agree')));
    await tester.tap(find.byKey(const ValueKey('allergies-agree')));
    await waitFor(tester, find.byKey(const ValueKey('allergies-save')));
    await tap(tester, find.byKey(const ValueKey('allergy-category-花生')));
    await tap(tester, find.byKey(const ValueKey('allergy-search')));
    await tester.enterText(
      find.byKey(const ValueKey('allergy-search')),
      '测试酱油',
    );
    await tap(tester, find.byKey(const ValueKey('allergy-search-submit')));
    await waitFor(tester, keyed('allergy-result-'));
    await tap(tester, keyed('allergy-result-').first);
    await tester.tap(find.byKey(const ValueKey('allergies-save')));
    await waitFor(tester, find.text('花生、测试酱油'));
    await reopen(tester);
    expect(find.text('花生、测试酱油'), findsOneWidget);
    final why = keyed('allergy-why-');
    await reveal(tester, why.first);
    await tester.tap(why.first);
    await waitFor(tester, find.byKey(const ValueKey('why-panel')));
    expect(find.text('本人手动填写'), findsOneWidget);
    expect(find.textContaining('花生、测试酱油'), findsWidgets);
    expect(find.text('这次不用'), findsNothing);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    await reveal(tester, edit, -300);
    await tester.tap(edit);
    await waitFor(tester, find.byKey(const ValueKey('allergies-save')));
    expect(find.text('过敏信息单独同意'), findsNothing);
    await tap(tester, find.byKey(const ValueKey('allergy-category-花生')));
    await tap(tester, find.byKey(const ValueKey('allergy-category-蛋类')));
    await tap(tester, keyed('allergy-delete-').first);
    await tester.tap(find.byKey(const ValueKey('allergies-save')));
    await waitFor(tester, find.text('蛋类'));
    await reopen(tester);
    expect(find.text('蛋类'), findsOneWidget);
    expect(find.text('花生、测试酱油 → 蛋类'), findsOneWidget);
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    await reveal(tester, find.text('设置'));
    await tester.tap(find.text('设置'));
    await waitFor(tester, find.byKey(const ValueKey('sensitive-withdraw')));
    await tap(tester, find.byKey(const ValueKey('sensitive-withdraw')));
    await tap(tester, find.byKey(const ValueKey('sensitive-withdraw-confirm')));
    await waitFor(tester, find.text('敏感同意已撤回，过敏及私密历史已删除'));
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    await openProfile(tester);
    expect(find.text('咸 · 淡一点'), findsOneWidget);
    await reveal(tester, edit);
    await waitFor(tester, find.text('尚未填写本人过敏'));
    expect(find.text('没有私密修改历史'), findsOneWidget);
    expect(find.text('蛋类'), findsNothing);
    expect(keyed('allergy-why-'), findsNothing);
    await tester.tap(edit);
    await waitFor(tester, find.byKey(const ValueKey('allergies-agree')));
    await tester.tap(find.byKey(const ValueKey('allergies-agree')));
    await waitFor(tester, find.byKey(const ValueKey('allergies-save')));
    for (final tile in tester.widgetList<CheckboxListTile>(
      find.byType(CheckboxListTile),
    )) {
      expect(tile.value, isFalse);
    }
    expect(keyed('allergy-delete-'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('allergies-save')));
    await reopen(tester);
    expect(find.text('尚未填写本人过敏'), findsOneWidget);
    expect(find.text('没有私密修改历史'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
