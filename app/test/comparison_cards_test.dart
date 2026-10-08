import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/features/recipes/comparison_cards.dart';
import 'package:gram_tree/l10n/app_localizations.dart';

import 'helpers.dart';

Future<void> pumpComparison(
  WidgetTester tester,
  Widget child, {
  TestEnv? env,
  Brightness brightness = Brightness.light,
  Size size = const Size(360, 780),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: (env ?? TestEnv.signedIn()).overrides,
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

ComparisonRuleCard ruleCard({
  bool sideBySide = false,
  bool expandDetails = false,
  String? grade = 'minor',
  Widget? details,
}) => ComparisonRuleCard(
  id: 'ingredients.salt.quantity',
  title: '盐用量',
  kindLabel: '修改用量',
  before: '3 g',
  after: '3.3 g',
  grade: grade,
  basis: '按服务端规则比较原始版本，不应用口味换算',
  ruleId: 'quantity.relative_change',
  rulesVersion: '2026-10-08',
  relativeChange: '+10%',
  sideBySide: sideBySide,
  expandDetails: expandDetails,
  details: details,
);

void main() {
  for (final entry in const {
    'excluded': '不计配方幅度',
    'minor': '微调',
    'general': '一般',
    'significant': '显著',
    'future_grade': 'future_grade',
    '': '',
  }.entries) {
    testWidgets(
      'renders server grade ${entry.key} without inferring from values',
      (tester) async {
        await pumpComparison(tester, ruleCard(grade: entry.key));
        expect(find.text('幅度：${entry.value}'), findsOneWidget);
        expect(find.text('3 g'), findsOneWidget);
        expect(find.text('3.3 g'), findsOneWidget);
      },
    );
  }

  testWidgets('renders conclusion labels and preserves unknown server values', (
    tester,
  ) async {
    await pumpComparison(
      tester,
      Column(
        children: [
          for (final conclusion in const [
            'no_change',
            'minor_only',
            'general',
            'significant',
            'future_conclusion',
          ])
            Text(comparisonConclusionLabel(conclusion)),
        ],
      ),
    );
    for (final label in const [
      '没有变化',
      '只有微调',
      '一般改动',
      '显著改动',
      'future_conclusion',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  for (final sideBySide in [false, true]) {
    testWidgets('pair displays supplied widgets with sideBySide=$sideBySide', (
      tester,
    ) async {
      await pumpComparison(
        tester,
        ComparisonPair(
          before: const Text('原版本'),
          after: const Text('目标版本'),
          sideBySide: sideBySide,
        ),
      );
      final before = tester.getTopLeft(find.text('原版本'));
      final after = tester.getTopLeft(find.text('目标版本'));
      if (sideBySide) {
        expect(after.dy, before.dy);
        expect(after.dx, greaterThan(before.dx));
      } else {
        expect(after.dx, before.dx);
        expect(after.dy, greaterThan(before.dy));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'raw details can be opened and closed without supplied extra details',
    (tester) async {
      await pumpComparison(tester, ruleCard());
      expect(find.text('字段：ingredients.salt.quantity'), findsNothing);
      await tapVisible(tester, find.text('原始明细'));
      expect(find.text('字段：ingredients.salt.quantity'), findsOneWidget);
      expect(find.text('之前原值：3 g'), findsOneWidget);
      expect(find.text('之后原值：3.3 g'), findsOneWidget);
      expect(find.text('幅度原值：minor'), findsOneWidget);
      expect(find.text('相对变化原值：+10%'), findsOneWidget);
      await tapVisible(tester, find.text('原始明细'));
      expect(find.text('字段：ingredients.salt.quantity'), findsNothing);
    },
  );

  testWidgets('detail preference updates initial expansion for the same rule', (
    tester,
  ) async {
    final env = TestEnv.signedIn();
    await pumpComparison(
      tester,
      ruleCard(details: const Text('服务端原始条目')),
      env: env,
    );
    expect(find.text('服务端原始条目'), findsNothing);
    await pumpComparison(
      tester,
      ruleCard(expandDetails: true, details: const Text('服务端原始条目')),
      env: env,
    );
    expect(find.text('服务端原始条目'), findsOneWidget);
    await pumpComparison(
      tester,
      ruleCard(details: const Text('服务端原始条目')),
      env: env,
    );
    expect(find.text('服务端原始条目'), findsNothing);
  });

  testWidgets('missing optional rule data retains the raw detail entrance', (
    tester,
  ) async {
    await pumpComparison(
      tester,
      const ComparisonRuleCard(
        id: 'title',
        title: '名称',
        kindLabel: '修改名称',
        before: '',
        after: '家常菜',
        sideBySide: false,
      ),
    );
    expect(find.text('幅度：'), findsNothing);
    await tapVisible(tester, find.text('依据'));
    expect(find.byKey(const ValueKey('why-panel')), findsOneWidget);
    expect(find.text('这次不用'), findsNothing);
    expect(find.text('以后别这样'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('原始明细'));
    expect(find.text('字段：title'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    for (final layout in const [
      (size: Size(320, 640), sideBySide: false),
      (size: Size(320, 640), sideBySide: true),
      (size: Size(780, 360), sideBySide: true),
    ]) {
      for (final scale in [1.3, 1.6]) {
        testWidgets('read-only comparison $brightness $layout at $scale text', (
          tester,
        ) async {
          final semantics = tester.ensureSemantics();
          try {
            await pumpComparison(
              tester,
              ComparisonRuleCard(
                id: 'ingredients.very-long-field-name.quantity',
                title: '一个需要换行展示的食材用量比较结论',
                kindLabel: '修改用量，保留作者填写的原始表达',
                before: '123456789.123456 g 作者填写的原始用量说明',
                after: '123456789.654321 g 作者填写的目标用量说明',
                grade: 'excluded',
                basis: '这是只读的版本比较依据，来自服务端规则而不是口味换算。',
                ruleId: 'quantity.relative_change.long-rule-identifier',
                rulesVersion: '2026-10-08-long-version-identifier',
                relativeChange: '+0.00000043%',
                sideBySide: layout.sideBySide,
                details: const Text('完整原始条目，不应被折叠入口隐藏'),
              ),
              brightness: brightness,
              size: layout.size,
              scale: scale,
            );
            final before = find.text('123456789.123456 g 作者填写的原始用量说明');
            final after = find.text('123456789.654321 g 作者填写的目标用量说明');
            final context = tester.element(before);
            final theme = Theme.of(context);
            final numberStyle = GramTreeColors.of(context)
                .numberStyle(theme.textTheme.bodyMedium!);
            expect(tester.widget<Text>(before).style, numberStyle);
            expect(tester.widget<Text>(after).style, numberStyle);
            expect(
              tester.widget<Text>(find.text('相对变化：+0.00000043%')).style,
              numberStyle,
            );
            expect(numberStyle.color, isNot(GramTreeColors.of(context).accent));
            expect(find.text('幅度：不计配方幅度'), findsOneWidget);
            final beforePosition = tester.getTopLeft(before);
            final afterPosition = tester.getTopLeft(after);
            if (layout.sideBySide) {
              expect(afterPosition.dy, beforePosition.dy);
              expect(afterPosition.dx, greaterThan(beforePosition.dx));
            } else {
              expect(afterPosition.dy, greaterThan(beforePosition.dy));
            }
            expect(tester.takeException(), isNull);
            await tapVisible(tester, find.text('依据'));
            expect(find.byKey(const ValueKey('why-panel')), findsOneWidget);
            expect(find.text('比较依据'), findsOneWidget);
            expect(find.text('这是只读的版本比较依据，来自服务端规则而不是口味换算。'), findsOneWidget);
            expect(
              find.text(
                '规则：quantity.relative_change.long-rule-identifier\n'
                '规则版本：2026-10-08-long-version-identifier',
              ),
              findsOneWidget,
            );
            final current = find.text('现在：123456789.654321 g 作者填写的目标用量说明');
            final panelContext = tester.element(current);
            expect(
              tester.widget<Text>(current).style!.color,
              Theme.of(panelContext).textTheme.bodyMedium!.color,
            );
            expect(find.text('这次不用'), findsNothing);
            expect(find.text('以后别这样'), findsNothing);
            expect(tester.takeException(), isNull);
            await tester.tapAt(const Offset(10, 10));
            await tester.pumpAndSettle();
            await tapVisible(tester, find.text('原始明细'));
            expect(find.text('完整原始条目，不应被折叠入口隐藏'), findsOneWidget);
            expect(
              find.text('字段：ingredients.very-long-field-name.quantity'),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        });
      }
    }
  }
}
