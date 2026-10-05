import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/l10n/app_localizations.dart';
import 'package:gram_tree/ui_protocol/composition_view.dart';
import 'package:gram_tree/ui_protocol/embedded_assets.g.dart';
import 'package:gram_tree/ui_protocol/page_types.dart';
import 'package:gram_tree/ui_protocol/protocol_schemas.dart';
import 'package:gram_tree/ui_protocol/recipe_safety.dart';

import 'helpers.dart';

const _recipeId = '11111111-1111-4111-8111-111111111111';
const _versionId = '22222222-2222-4222-8222-222222222222';

void main() {
  test('required safety protocol sample validates against embedded schemas', () async {
    final schemas = ProtocolSchemas();
    final sample = jsonDecode(
      embeddedUiProtocolSamples['assets/contracts/ui_protocol/samples/valid/recipe_safety_required.json']!,
    ) as Map<String, dynamic>;

    expect(await schemas.validatePageDescription('1.0', sample), isEmpty);
    for (final raw in sample['components'] as List<dynamic>) {
      final component = raw as Map<String, dynamic>;
      expect(
        component['required'],
        isTrue,
        reason: component['type'] as String,
      );
      expect(
        await schemas.validateComponentData(
          '1.0',
          component['type'] as String,
          Map<String, dynamic>.from(component['data'] as Map),
        ),
        isEmpty,
        reason: component['type'] as String,
      );
    }
    expect(defaultRequiredComponentTypes['recipe_detail'], {
      'food_safety',
      'allergen_notice',
    });
    expect(defaultRequiredComponentTypes['recipe_editor'], {
      'food_safety',
      'allergen_notice',
    });
  });

  testWidgets(
    'missing required recipe safety components fall back to accessible safety cards',
    (tester) async {
      final server = FakeServer();
      server.on('POST', '/v1/ui/compositions', (_) {
        return (
          200,
          {
            'protocol': '1.0',
            'page_type': 'recipe_detail',
            'composition_id': '7c9e6679-7425-40de-944b-e07fc1f90ae7',
            'generated_at': '2026-10-05T10:30:00Z',
            'cache': {'depends_on': {}, 'ttl_s': 0},
            'experiment': null,
            'components': <Object?>[],
          },
        );
      });
      final env = TestEnv.signedIn(server: server);
      await tester.pumpWidget(
        ProviderScope(
          overrides: env.overrides,
          child: MaterialApp(
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
              body: CompositionView(
                pageType: 'recipe_detail',
                recipeId: _recipeId,
                versionId: _versionId,
                standardLayoutBuilder: (_) => ListView(
                  children: const [
                    FoodSafetyCard(errorMessage: '安全服务暂不可用'),
                    AllergenCard(errorMessage: '安全服务暂不可用'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('recipe-food-safety-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('recipe-allergen-card')),
        findsOneWidget,
      );
      expect(find.textContaining('安全服务暂不可用'), findsNWidgets(2));
      expect(find.bySemanticsLabel('食品安全提醒'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('recipe-allergen-card')),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp(r'^过敏原提示')), findsOneWidget);

      final request =
          server.calls('POST', '/v1/ui/compositions').single.body as Map;
      expect(request['recipe_id'], _recipeId);
      expect(request['version_id'], _versionId);
      expect(
        request['supported_components'],
        containsAll(['food_safety', 'allergen_notice']),
      );
      expect(request['page_type'], 'recipe_detail');
    },
  );

  testWidgets(
    'valid protocol findings retain rule attribution and numeric guidance',
    (tester) async {
      final server = FakeServer();
      server.on('POST', '/v1/ui/compositions', (_) {
        return (
          200,
          {
            'protocol': '1.0',
            'page_type': 'recipe_detail',
            'composition_id': '7c9e6679-7425-40de-944b-e07fc1f90ae7',
            'generated_at': '2026-10-05T10:30:00Z',
            'cache': {'depends_on': {}, 'ttl_s': 0},
            'experiment': null,
            'components': [
              {
                'type': 'food_safety',
                'id': 'safety-1',
                'detail': 'standard',
                'data': {
                  'status': 'available',
                  'conclusion': '猪肉应充分加热',
                  'basis': '根据食品安全规则 test-v1 检查。',
                  'result': {
                    'rules_version': 'test-v1',
                    'checked_at': '2026-10-05T10:30:00Z',
                    'high_risk': false,
                    'findings': [
                      {
                        'rule_id': 'pork-cook-through',
                        'severity': 'warning',
                        'message': '猪肉中心温度至少 63°C，并静置至少 3 分钟。',
                        'basis': '猪肉安全加热依据',
                        'step_ids': ['step-1'],
                        'ingredient_ids': ['ingredient-1'],
                        'threshold_celsius': 63,
                        'rest_minutes': 3,
                      },
                    ],
                  },
                },
                'actions': [],
                'reason': {'code': 'recipe_safety', 'text': '根据保存版本检查'},
                'required': true,
              },
              {
                'type': 'allergen_notice',
                'id': 'allergen-1',
                'detail': 'standard',
                'data': {
                  'status': 'available',
                  'conclusion': '未从已收录信息中识别出过敏原',
                  'basis': '根据食材信息推导。',
                  'result': {
                    'rules_version': 'test-v1',
                    'checked_at': '2026-10-05T10:30:00Z',
                    'allergens': <String>[],
                    'allergens_incomplete': false,
                    'replacement_allergens': <Object?>[],
                  },
                },
                'actions': [],
                'reason': {'code': 'recipe_safety', 'text': '根据保存版本检查'},
                'required': true,
              },
            ],
          },
        );
      });
      final env = TestEnv.signedIn(server: server);
      await tester.pumpWidget(
        ProviderScope(
          overrides: env.overrides,
          child: MaterialApp(
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
              body: CompositionView(
                pageType: 'recipe_detail',
                recipeId: _recipeId,
                versionId: _versionId,
                standardLayoutBuilder: (_) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('猪肉中心温度至少 63°C，并静置至少 3 分钟。'), findsOneWidget);
      expect(find.text('猪肉安全加热依据'), findsOneWidget);
      expect(find.textContaining('中心温度至少 63°C'), findsNWidgets(2));
      expect(find.textContaining('静置至少 3 分钟'), findsNWidgets(2));
      expect(find.textContaining('安全服务'), findsNothing);
    },
  );
}
