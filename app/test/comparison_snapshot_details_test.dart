import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/features/recipes/comparison_snapshot_details.dart';
import 'package:gram_tree/l10n/app_localizations.dart';
import 'package:gramtree_api/gramtree_api.dart';

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
      '不要堆叠',
      '保持锅温',
    ]) {
      expect(find.textContaining(text), findsWidgets);
    }
    expect(tester.takeException(), isNull);
  });
}
