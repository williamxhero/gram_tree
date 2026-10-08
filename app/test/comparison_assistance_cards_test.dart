import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/features/recipes/comparison_assistance_cards.dart';
import 'package:gram_tree/features/recipes/comparison_cards.dart';
import 'package:gram_tree/l10n/app_localizations.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';

Future<void> pumpAssistance(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  Size size = const Size(360, 780),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: TestEnv.signedIn().overrides,
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildTheme(brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(body: ListView(children: [child])),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'AI interpretation is general experience, opens shared read-only Why, and leaves the rule grade intact',
    (tester) async {
      await pumpAssistance(
        tester,
        Column(
          children: [
            const ComparisonRuleCard(
              id: 'step-0-doneness',
              title: '成熟判断',
              kindLabel: '字段变化 · 确定性对齐',
              before: '表面变色',
              after: '中心无粉红',
              grade: 'general',
              basis: '执行字段发生变化，按确定规则判为一般',
              rulesVersion: 'rules-test-1',
              sideBySide: false,
            ),
            ComparisonInterpretationCard(
              interpretation: SourcedValue(
                value: 'B 延长加热，适合希望口感更熟的人。',
                sourceType: SourcedValueSourceTypeEnum.aiEstimated,
                basis: SourceBasis(
                  reasonCode: 'general_experience',
                  text: '仅依据已授权版本差异；属于一般经验，不是已验证结论。',
                  citation: 'comparison replay',
                ),
              ),
              rulesVersion: 'rules-test-1',
            ),
          ],
        ),
      );
      expect(find.text('B 延长加热，适合希望口感更熟的人。'), findsOneWidget);
      expect(find.text('AI · 一般经验'), findsOneWidget);
      expect(find.text('幅度：一般'), findsOneWidget);
      expect(find.text('中心无粉红'), findsOneWidget);
      final why = find.byKey(const ValueKey('comparison-interpretation-why'));
      await tester.ensureVisible(why);
      await tester.tap(why);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('why-panel')), findsOneWidget);
      expect(find.text('AI 解读依据'), findsOneWidget);
      expect(find.textContaining('仅依据已授权版本差异；属于一般经验，不是已验证结论。'), findsOneWidget);
      expect(find.textContaining('general_experience'), findsOneWidget);
      expect(find.textContaining('rules-test-1'), findsWidgets);
      expect(find.textContaining('comparison replay'), findsOneWidget);
      expect(find.text('这次不用'), findsNothing);
      expect(find.text('以后别这样'), findsNothing);
      expect(find.text('已验证'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
