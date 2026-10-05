import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtree_api/gramtree_api.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/l10n/app_localizations.dart';
import 'package:gram_tree/ui_protocol/recipe_safety.dart';

void main() {
  Future<void> pumpSafetyCards(
    WidgetTester tester, {
    RecipeSafetyResult? result,
    RecipeDerived? legacyDerived,
    bool loading = false,
    bool awaitingCheck = false,
    String? errorMessage,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        locale: const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
        ),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: ListView(
            children: [
              FoodSafetyCard(
                result: result,
                legacyDerived: legacyDerived,
                loading: loading,
                awaitingCheck: awaitingCheck,
                errorMessage: errorMessage,
              ),
              AllergenCard(
                result: result,
                legacyDerived: legacyDerived,
                loading: loading,
                awaitingCheck: awaitingCheck,
                errorMessage: errorMessage,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'mandatory cards remain visible while safety data is unavailable',
    (tester) async {
      await pumpSafetyCards(tester, loading: true);

      expect(
        find.byKey(const ValueKey('recipe-food-safety-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('recipe-allergen-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('recipe-safety-status')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('recipe-allergen-status')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.hourglass_top), findsNWidgets(2));
      expect(find.textContaining('未检测到已知过敏原'), findsNothing);
    },
  );

  testWidgets('high-risk findings show text, icon, basis, and threshold', (
    tester,
  ) async {
    final result = RecipeSafetyResult(
      checkedAt: '2026-10-01T00:00:00+00:00',
      findings: [
        RecipeSafetyFinding(
          basis: '依据来源',
          message: '鸡肉中心温度不足',
          ruleId: 'poultry-temperature',
          severity: RecipeSafetyFindingSeverityEnum.highRisk,
          stepIds: const ['step-1'],
          thresholdCelsius: 74,
          restMinutes: 2,
        ),
      ],
      highRisk: true,
      rulesVersion: 'test-rules-v1',
    );
    await pumpSafetyCards(tester, result: result);

    expect(find.textContaining('高风险'), findsWidgets);
    expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
    expect(find.text('鸡肉中心温度不足'), findsOneWidget);
    expect(find.text('依据来源'), findsOneWidget);
    expect(find.textContaining('74'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('recipe-safety-finding-poultry-temperature')),
      findsOneWidget,
    );
  });

  testWidgets('legacy allergens and replacement allergens stay explicit', (
    tester,
  ) async {
    final result = RecipeSafetyResult(
      allergens: const ['牛奶'],
      allergensIncomplete: true,
      checkedAt: '2026-10-01T00:00:00+00:00',
      replacementAllergens: [
        RecipeReplacementAllergens(
          allergens: const ['大豆'],
          displayName: '豆乳',
          incomplete: true,
          ingredientId: 'ingredient-1',
        ),
      ],
      rulesVersion: 'test-rules-v1',
    );
    await pumpSafetyCards(tester, result: result);

    expect(find.textContaining('牛奶'), findsOneWidget);
    expect(find.textContaining('不完整'), findsWidgets);
    expect(
      find.byKey(const ValueKey('recipe-replacement-allergens-ingredient-1')),
      findsOneWidget,
    );
    expect(find.textContaining('豆乳'), findsOneWidget);
    expect(find.textContaining('大豆'), findsOneWidget);
  });

  testWidgets('stale results remain visible with a recheck warning', (
    tester,
  ) async {
    final result = RecipeSafetyResult(
      allergens: const ['牛奶'],
      checkedAt: '2026-10-01T00:00:00+00:00',
      findings: [
        RecipeSafetyFinding(
          basis: '安全基准',
          message: '加热不足',
          ruleId: 'heating',
          severity: RecipeSafetyFindingSeverityEnum.warning,
        ),
      ],
      rulesVersion: 'old-rules',
      stale: true,
    );
    await pumpSafetyCards(tester, result: result);

    expect(find.textContaining('可能已过期'), findsNWidgets(2));
    expect(find.text('加热不足'), findsOneWidget);
    expect(find.textContaining('牛奶'), findsOneWidget);
  });

  testWidgets('legacy derived allergens render when no safety result exists', (
    tester,
  ) async {
    final derived = RecipeDerived(
      activeTimeSeconds: 0,
      allergens: const ['花生'],
      allergensIncomplete: true,
      cookware: null,
      nutritionPerServing: null,
      totalTimeSeconds: 0,
    );
    await pumpSafetyCards(
      tester,
      legacyDerived: derived,
      errorMessage: 'offline',
    );

    expect(
      find.byKey(const ValueKey('recipe-food-safety-card')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('recipe-allergen-card')), findsOneWidget);
    expect(find.textContaining('花生'), findsOneWidget);
    expect(find.textContaining('offline'), findsNWidgets(2));
  });
}
