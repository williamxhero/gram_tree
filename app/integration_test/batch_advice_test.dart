import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/config/app_config.dart';
import 'package:gram_tree/main.dart' as app;
import 'package:integration_test/integration_test.dart';

import 'event_pipeline_support.dart' as support;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final server = Dio(
    BaseOptions(baseUrl: AppConfig.fromEnvironment().apiBaseUrl),
  );

  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 300 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(finder, findsWidgets);
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    final body = find.byKey(const ValueKey('recipe-detail-content'));
    for (var i = 0; i < 15; i++) {
      await tester.drag(body, const Offset(0, 500));
      await tester.pump(const Duration(milliseconds: 50));
    }
    for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
      await tester.drag(body, const Offset(0, -250));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(finder, findsWidgets);
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
  }

  Future<void> runWithDiagnostics(
    WidgetTester tester,
    Future<void> Function() body,
  ) async {
    try {
      await body();
    } catch (error, stack) {
      final binding = IntegrationTestWidgetsFlutterBinding.instance;
      binding.reportData = {
        ...?binding.reportData,
        'e2e_error': error.toString(),
        'e2e_stack': stack.toString(),
        'page_text': tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .toList(),
      };
      rethrow;
    }
  }

  testWidgets(
    '大份量主动请求、只读建议、切换份数和旧版后不串用',
    (tester) => runWithDiagnostics(tester, () async {
      tester.testTextInput.register();
      addTearDown(tester.testTextInput.unregister);
      await app.main();
      await waitFor(tester, find.byKey(const ValueKey('consent-agree')));
      await tester.tap(find.byKey(const ValueKey('consent-agree')));
      await waitFor(tester, find.byKey(const ValueKey('login-email')));
      final email =
          'batch-e2e-${DateTime.now().microsecondsSinceEpoch}@example.com';
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
      server.options.headers['Authorization'] =
          'Bearer ${support.accessTokenOf(support.containerOf(tester))}';

      // Public API setup matches the sanitized server batch_advice_corpus.json.
      final created = await server.post(
        '/v1/recipes',
        data: {
          'dish_name': '大份量回放鸡丁',
          'snapshot': {
            'servings': 2,
            'ingredients': [
              {
                'id': 'chicken',
                'display_name': '鸡腿肉',
                'quantity': 300,
                'unit': 'g',
              },
            ],
            'steps': [
              {
                'id': 'marinate',
                'action': '腌',
                'instruction': '鸡肉冷藏腌制',
                'ingredient_ids': ['chicken'],
                'duration_seconds': 900,
                'unattended': true,
                'cookware': '碗',
                'doneness': '入味',
              },
              {
                'id': 'cook',
                'action': '炒',
                'instruction': '中火炒熟鸡肉，用食品温度计确认中心温度达到 74°C',
                'ingredient_ids': ['chicken'],
                'duration_seconds': 300,
                'heat': '中火',
                'cookware': '炒锅',
                'doneness': '中心温度达到 74°C',
                'depends_on': ['marinate'],
              },
            ],
          },
          'change_note': '合成测试菜谱',
        },
      );
      final recipeId = created.data['id'] as String;
      final firstVersionId = created.data['version']['id'] as String;
      final originalSnapshot = created.data['version']['snapshot'];
      await server.post(
        '/v1/recipes/$recipeId/versions',
        data: {
          'base_version_id': firstVersionId,
          'snapshot': originalSnapshot,
          'change_note': '同配方历史对照',
        },
      );
      final before = await server.get('/v1/recipes/$recipeId/versions');
      final currentBefore = await server.get('/v1/recipes/$recipeId');
      final snapshotBefore = jsonEncode(
        currentBefore.data['version']['snapshot'],
      );

      await tester.tap(find.text('我的').last);
      await tester.pumpAndSettle();
      await waitFor(tester, find.text('我的菜谱'));
      await tester.tap(find.text('我的菜谱'));
      await waitFor(tester, find.byKey(ValueKey('recipe-card-$recipeId')));
      await tester.tap(find.byKey(ValueKey('recipe-card-$recipeId')));
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-history-button')),
      );
      await reveal(
        tester,
        find.byKey(const ValueKey('recipe-serving-increase')),
      );
      await tester.tap(find.byKey(const ValueKey('recipe-serving-increase')));
      await tester.pumpAndSettle();
      expect(find.text('AI 建议时间'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('recipe-serving-increase')));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('AI 建议时间'));
      expect(find.text('AI 建议 · 只读，不修改菜谱'), findsNothing);
      await tester.tap(find.text('AI 建议时间'));
      await waitFor(tester, find.text('AI 建议 · 只读，不修改菜谱'));
      await reveal(tester, find.textContaining('每批约 360 秒'));
      expect(find.textContaining('成熟判断：每批用食品温度计'), findsOneWidget);
      expect(find.text('原时长：300 秒'), findsOneWidget);
      expect(find.text('建议时长：900 秒'), findsOneWidget);
      expect(find.textContaining('腌制不按份数加倍'), findsOneWidget);
      expect(find.text('AI 估算'), findsNWidgets(2));
      await reveal(tester, find.text('AI 估算'));
      expect(find.text('AI 估算').first.hitTestable(), findsOneWidget);
      await tester.tap(find.text('AI 估算').first);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('why-panel')), findsOneWidget);
      expect(find.text('原来：900 秒'), findsOneWidget);
      expect(find.text('现在：900 秒，分 1 批'), findsOneWidget);
      expect(find.text('腌制时间主要取决于肉块大小，不是总重量。'), findsOneWidget);
      expect(find.text('这次不用'), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await reveal(tester, find.byKey(const ValueKey('recipe-serving-reset')));
      await tester.tap(find.byKey(const ValueKey('recipe-serving-reset')));
      await tester.pumpAndSettle();
      expect(find.text('AI 建议时间'), findsNothing);
      expect(find.text('AI 建议 · 只读，不修改菜谱'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('recipe-history-button')));
      await waitFor(tester, find.byKey(const ValueKey('recipe-version-1')));
      await tester.tap(find.byKey(const ValueKey('recipe-version-1')));
      await waitFor(
        tester,
        find.byKey(const ValueKey('edit-old-recipe-button')),
      );
      await reveal(
        tester,
        find.byKey(const ValueKey('recipe-serving-increase')),
      );
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const ValueKey('recipe-serving-increase')));
        await tester.pumpAndSettle();
      }
      await reveal(tester, find.text('AI 建议时间'));
      expect(find.text('AI 建议 · 只读，不修改菜谱'), findsNothing);
      await tester.tap(find.text('AI 建议时间'));
      await waitFor(tester, find.text('AI 建议 · 只读，不修改菜谱'));

      final after = await server.get('/v1/recipes/$recipeId/versions');
      expect(after.data['items'].length, before.data['items'].length);
      final currentAfter = await server.get('/v1/recipes/$recipeId');
      expect(
        jsonEncode(currentAfter.data['version']['snapshot']),
        snapshotBefore,
      );
      final oldAfter = await server.get(
        '/v1/recipes/$recipeId/versions/$firstVersionId',
      );
      expect(
        jsonEncode(oldAfter.data['version']['snapshot']),
        jsonEncode(originalSnapshot),
      );
      expect(tester.takeException(), isNull);
    }),
  );
}
