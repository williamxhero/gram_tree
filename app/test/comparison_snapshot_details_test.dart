import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/features/recipes/comparison_snapshot_details.dart';
import 'package:gram_tree/l10n/app_localizations.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';

Future<void> pumpDetails(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: TestEnv.signedIn().overrides,
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('双方原始步骤明细完整显示引用、依赖、执行字段和原文', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ComparisonStepDetails(
                value: RecipeStep(
                  id: 'fry',
                  action: '炒',
                  instruction: '分批炒鸡肉',
                  ingredientIds: ['chicken'],
                  durationSeconds: 120,
                  unattended: false,
                  heat: '中火',
                  temperatureCelsius: 160,
                  cookware: '炒锅',
                  doneness: '中心无粉红',
                  dependsOn: ['marinate'],
                  notes: '不要堆叠',
                  why: '保持锅温',
                ),
                ingredientNames: const {'chicken': '鸡腿肉'},
                stepNumbers: const {'marinate': 1},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final text in [
      '炒',
      '分批炒鸡肉',
      '鸡腿肉',
      '120',
      '需要守着',
      '中火',
      '160',
      '炒锅',
      '中心无粉红',
      '第 1 步',
      '引用食材 ID：["chicken"]',
      '前置依赖 ID：["marinate"]',
      '不要堆叠',
      '保持锅温',
    ]) {
      expect(find.textContaining(text), findsWidgets);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('原始食材保留确认量具依据、已知零味型和全部作者来源，不泄露回执', (tester) async {
    await pumpDetails(
      tester,
      ComparisonIngredientDetails(
        value: RecipeIngredient(
          id: 'salt',
          displayName: '盐',
          ingredientId: 'salt-library',
          quantity: 3,
          unit: 'g',
          baseQuantity: 3,
          baseUnit: RecipeIngredientBaseUnitEnum.g,
          preparation: '细盐',
          group: '调味料',
          optional: false,
          scalingMode: RecipeIngredientScalingModeEnum.unchanged,
          replacement: '可换海盐',
          flavorContribution: RecipeFlavorContribution(salty: 0),
          functional: false,
          measureInputToken: 'opaque-fixture-receipt',
          quantitySource: ValueSource(
            source_: ValueSourceSource_Enum.authorFilled,
            original: '我家小勺 1 平勺',
            basis: '用户确认：小勺；3 g；盐；已确认结果',
          ),
          preparationSource: ValueSource(
            source_: ValueSourceSource_Enum.authorFilled,
            basis: '作者处理方式原始依据',
          ),
          flavorSource: ValueSource(
            source_: ValueSourceSource_Enum.authorFilled,
            basis: '已知零，不是未知',
          ),
          functionalSource: ValueSource(
            source_: ValueSourceSource_Enum.authorFilled,
            basis: '作者确认非功能用料',
          ),
        ),
      ),
    );
    for (final text in [
      'salt-library',
      '3 g',
      '细盐',
      '调味料',
      'unchanged',
      '可换海盐',
      '咸 0',
      '功能性用料：否',
    ]) {
      expect(find.textContaining(text), findsWidgets);
    }
    expect(find.textContaining('opaque-fixture-receipt'), findsNothing);
    await tester.ensureVisible(find.text('量具输入依据'));
    await tester.tap(find.text('量具输入依据'));
    await tester.pumpAndSettle();
    expect(find.textContaining('我家小勺 1 平勺'), findsWidgets);
    expect(find.textContaining('用户确认'), findsWidgets);
    expect(find.text('这次不用'), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('处理方式来源'));
    await tester.tap(find.text('处理方式来源'));
    await tester.pumpAndSettle();
    expect(find.text('作者处理方式原始依据'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('未知量和味型不显示为零，作者步骤来源仍可查看', (tester) async {
    await pumpDetails(
      tester,
      Column(
        children: [
          ComparisonIngredientDetails(
            value: RecipeIngredient(
              id: 'unknown',
              displayName: '少许盐',
              quantity: 1,
              unit: '少许',
            ),
          ),
          ComparisonStepDetails(
            value: RecipeStep(
              id: 'check',
              instruction: '观察表面',
              instructionSource: ValueSource(
                source_: ValueSourceSource_Enum.authorFilled,
                basis: '原始作者步骤说明',
                original: '看表面',
              ),
            ),
          ),
        ],
      ),
    );
    expect(find.text('味型贡献未填写'), findsOneWidget);
    expect(find.textContaining('咸 0'), findsNothing);
    await tester.ensureVisible(find.text('instruction 来源'));
    await tester.tap(find.text('instruction 来源'));
    await tester.pumpAndSettle();
    expect(find.text('原始作者步骤说明'), findsOneWidget);
    expect(find.textContaining('看表面'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
