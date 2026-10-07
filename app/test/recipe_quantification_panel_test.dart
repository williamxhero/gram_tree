import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/l10n/app_localizations.dart';
import 'package:gram_tree/features/recipes/quantification_panel.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final scale in [1.3, 1.6]) {
      for (final detail in ComponentDescriptorDetailEnum.values) {
        testWidgets('quantification layers $detail $brightness $scale', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final env = TestEnv.signedIn();
          var accepted = false;
          final semantics = tester.ensureSemantics();
          await tester.pumpWidget(
            ProviderScope(
              overrides: env.overrides,
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: buildTheme(brightness),
                home: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Scaffold(
                    body: ListView(
                      children: [
                        QuantificationPanel(
                          proposal: RecipeQuantificationOut.fromJson({
                            'detail': detail.value,
                            'id': '33333333-3333-4333-8333-333333333333',
                            'base_version_id':
                                '22222222-2222-4222-8222-222222222222',
                            'problems': [
                              {
                                'id': 'salt',
                                'type': 'ambiguous',
                                'status': 'unresolved',
                                'message': '盐量待确定',
                                'original': '0 少许',
                                'position': {
                                  'collection': 'ingredients',
                                  'item_id': 'salt',
                                  'field': 'quantity',
                                },
                              },
                            ],
                            'suggestions': [
                              {
                                'problem_id': 'salt',
                                'value': '3',
                                'unit': 'g',
                                'basis': '按两人份主料量估算',
                                'confidence': 'medium',
                                'baseline': '两人份盐 3 克',
                                'adjustment': '偏淡每次补 1 克',
                              },
                            ],
                          }),
                          onDecide: (_, all) async {
                            accepted = all;
                          },
                          onCancel: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('逐条确定 · 不会自动替换'), findsOneWidget);
          expect(find.bySemanticsLabel(RegExp('逐条确定')), findsOneWidget);
          expect(
            find.bySemanticsLabel(RegExp('按两人份主料量估算')),
            detail == ComponentDescriptorDetailEnum.brief
                ? findsNothing
                : findsOneWidget,
          );
          expect(
            find.bySemanticsLabel(RegExp('两人份盐 3 克')),
            detail == ComponentDescriptorDetailEnum.detailed
                ? findsOneWidget
                : findsNothing,
          );
          final why = find.byKey(const ValueKey('quantification-why-salt'));
          if (detail == ComponentDescriptorDetailEnum.brief) {
            expect(why, findsNothing);
            expect(find.text('按两人份主料量估算'), findsNothing);
            expect(find.text('全部接受'), findsOneWidget);
          } else {
            await tester.scrollUntilVisible(why, 150, maxScrolls: 20);
            await tester.pumpAndSettle();
            expect(why.hitTestable(), findsOneWidget);
            final expanded = find.textContaining('把握程度：中');
            expect(
              expanded,
              detail == ComponentDescriptorDetailEnum.detailed
                  ? findsOneWidget
                  : findsNothing,
            );
            await tester.tap(why);
            await tester.pumpAndSettle();
            expect(find.textContaining('0 少许'), findsOneWidget);
            expect(find.textContaining('两人份盐 3 克'), findsWidgets);
            expect(find.textContaining('偏淡每次补 1 克'), findsWidgets);
            await tester.tapAt(const Offset(10, 10));
            await tester.pumpAndSettle();
          }
          final all = find.text('全部接受');
          await tester.ensureVisible(all);
          await tester.pumpAndSettle();
          expect(all.hitTestable(), findsOneWidget);
          await tester.tap(all);
          await tester.pumpAndSettle();
          expect(accepted, isTrue);
          expect(tester.takeException(), isNull);
          semantics.dispose();
        });
      }
    }
  }
}
