import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/router.dart';
import 'package:gram_tree/features/me/taste_profile_cache.dart';
import 'package:gram_tree/recipes/personalization.dart';
import 'package:gram_tree/storage/secure_store.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../helpers.dart';
import '../recipe_snapshot_test.dart' show recipeSnapshotFixture;
import '../taste_profile_page_test.dart' show profileFixture;

const _account = '11111111-1111-4111-8111-111111111111';
const _key = 'server-key-for-version-profile-servings-mold-equipment-diners';

RecipeSnapshot _original() => RecipeSnapshot(
  formatVersion: RecipeSnapshotFormatVersionEnum.number1,
  servings: 2,
  ingredients: [
    RecipeIngredient(
      id: 'salt',
      displayName: '盐',
      quantity: 0.03,
      unit: 'g',
      baseQuantity: 0.03,
      baseUnit: RecipeIngredientBaseUnitEnum.g,
      flavorContribution: RecipeFlavorContribution(salty: 3),
      quantitySource: ValueSource(
        source_: ValueSourceSource_Enum.authorFilled,
        original: '0.03',
      ),
    ),
    RecipeIngredient(
      id: 'sugar',
      displayName: '烘焙用糖',
      quantity: 20,
      unit: 'g',
      functional: true,
      flavorContribution: RecipeFlavorContribution(sweet: 3),
    ),
    RecipeIngredient(
      id: 'main',
      displayName: '肉',
      quantity: 100,
      unit: 'g',
      group: '主料',
      flavorContribution: RecipeFlavorContribution(salty: 3),
    ),
  ],
  steps: [RecipeStep(id: 'cook', instruction: '原版作者的步骤', cookware: '炒锅')],
);

RecipePersonalizedOut _cached({bool allergy = false, bool substituted = true}) {
  final original = _original();
  final accepted = [
    original.ingredients![0].copyWith(quantity: 0.02, baseQuantity: 0.02),
    original.ingredients![1],
    original.ingredients![2].copyWith(
      displayName: substituted ? '豆腐' : '肉',
      quantity: substituted ? 80 : 100,
      baseQuantity: substituted ? 80 : 100,
      baseUnit: RecipeIngredientBaseUnitEnum.g,
    ),
  ];
  return RecipePersonalizedOut(
    recipeId: _account,
    versionId: '22222222-2222-4222-8222-222222222222',
    view: RecipePersonalizedOutViewEnum.personalized,
    cacheKey: _key,
    profileVersion: 1,
    authorizationVersion: 1,
    effectiveFlavors: const {'salty': 0.8, 'sweet': 0.5},
    adjustmentLimit: 0.3,
    snapshotUnchanged: true,
    blocked: false,
    snapshot: original.copyWith(
      ingredients: accepted,
      steps: [
        RecipeStep(id: 'cook', instruction: '沿用已确认的烤箱步骤', cookware: '烤箱'),
      ],
    ),
    inputs: PersonalizationRequest(
      versionId: '22222222-2222-4222-8222-222222222222',
      targetServings: 2,
      equipment: const ['烤箱'],
      dinerMemberIds: const ['33333333-3333-4333-8333-333333333333'],
      primaryDinerId: '33333333-3333-4333-8333-333333333333',
      confirmAllergyRisk: allergy,
    ),
    ingredients: [
      for (var i = 0; i < accepted.length; i++)
        PersonalizedIngredientOut(
          id: accepted[i].id,
          displayName: accepted[i].displayName,
          originalName: original.ingredients![i].displayName,
          originalQuantity: original.ingredients![i].quantity,
          displayQuantity: accepted[i].quantity,
          originalUnit: 'g',
          displayUnit: 'g',
          factor: i == 0 ? 0.8 : 1,
          adaptationFactors: i == 2 && substituted ? const [0.8] : const [],
          changed: i != 1,
          rule: i == 0
              ? 'taste_filter'
              : i == 1
              ? 'functional_protected'
              : substituted
              ? 'substitution'
              : 'unchanged',
          reason: i == 0
              ? '少盐'
              : i == 1
              ? '功能性用料保护'
              : '已确认的替换',
        ),
    ],
    steps: [
      PersonalizedStepOut(
        id: 'cook',
        instruction: '沿用已确认的烤箱步骤',
        originalInstruction: '原版作者的步骤',
        changed: true,
        cookware: '烤箱',
        source_: PersonalizedStepOutSource_Enum.aiEstimated,
      ),
    ],
    notices: const ['保留服务端说明'],
    safety: RecipePersonalSafety(
      status: RecipePersonalSafetyStatusEnum.available,
      alerts: allergy
          ? [
              RecipePersonalSafetyAlert(
                person: '你',
                kind: RecipePersonalSafetyAlertKindEnum.allergy,
                target: '大豆',
                ingredient: '豆腐',
                replacement: true,
              ),
            ]
          : const [],
    ),
    foodSafety: RecipeSafetyResult(
      checkedAt: '2026-10-01T00:00:00Z',
      rulesVersion: 'safety-v1',
      findings: const [],
    ),
  );
}

AllergiesOut _allergies({
  String? consent = 'consent',
  int version = 1,
  int authorization = 1,
}) => AllergiesOut(
  consentId: consent,
  consentVersion: 'allergies-v1',
  authorizationVersion: authorization,
  profileVersion: version,
  availableCategories: const ['大豆'],
  categories: const [],
  ingredients: const [],
);

FamilyMembersOut _family({
  String? consent = 'consent',
  int version = 1,
  int authorization = 1,
}) => FamilyMembersOut(
  consentId: consent,
  consentVersion: 'allergies-v1',
  authorizationVersion: authorization,
  profileVersion: version,
  availableAgeBands: const [],
  availableAllergenCategories: const [],
  items: const [],
);

Future<TasteProfileCache> _seed(
  MemorySecureStore secure, {
  bool sensitive = false,
}) async {
  final cache = TasteProfileCache(secure);
  await cache.writeProfile(
    _account,
    profileFixture(),
    stillCurrent: () => true,
  );
  if (sensitive) {
    await cache.writeAllergies(
      _account,
      _allergies(),
      stillCurrent: () => true,
    );
    await cache.writeFamily(_account, _family(), stillCurrent: () => true);
  }
  await cache.writePersonalization(
    _account,
    _key,
    _cached().toJson(),
    stillCurrent: () => true,
  );
  return cache;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _openDetail(WidgetTester tester, TestEnv env) async {
  await pumpApp(tester, env: env);
  ProviderScope.containerOf(tester.element(find.byType(Scaffold).first))
      .read(routerProvider)
      .push('/recipes/$_account');
  await _settle(tester);
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  final body = find.byKey(const ValueKey('recipe-detail-content'));
  if (finder.evaluate().isEmpty) {
    for (var i = 0; i < 10; i++) {
      await tester.drag(body, const Offset(0, 500));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.drag(body, const Offset(0, -250));
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await _settle(tester);
}

FakeServer _pageServer({bool allergy = false, RecipeSnapshot? author}) {
  final source = author ?? _original();
  final server = FakeServer();
  final detail = recipeSnapshotFixture(
    '22222222-2222-4222-8222-222222222222',
    recipe: _account,
  );
  server.on(
    'GET',
    '/v1/recipes/$_account',
    (_) => (
      200,
      detail.copyWith
          .version(detail.version.copyWith.snapshot(source))
          .toJson(),
    ),
  );
  server.on(
    'GET',
    '/v1/me/taste-profile',
    (_) => (200, profileFixture().toJson()),
  );
  server.on('POST', '/v1/recipes/$_account/personalized', (request) {
    final inputs = PersonalizationRequest.fromJson(
      Map<String, dynamic>.from(request.body as Map),
    );
    var result = _cached(allergy: allergy).copyWith(
      inputs: inputs,
      blocked: allergy && inputs.confirmAllergyRisk != true,
    );
    if (request.query['view'] == 'original') {
      result = result.copyWith(
        view: RecipePersonalizedOutViewEnum.original,
        cacheKey: 'original-key',
        snapshot: source,
        ingredients: [
          for (final item in result.ingredients)
            item.copyWith(
              displayName: item.originalName,
              originalQuantity: source.ingredients!
                  .firstWhere((row) => row.id == item.id)
                  .quantity,
              displayQuantity: source.ingredients!
                  .firstWhere((row) => row.id == item.id)
                  .quantity,
              rule: 'unchanged',
              changed: false,
              adaptationFactors: const [],
            ),
        ],
      );
    }
    return (200, result.toJson());
  });
  return server;
}

void main() {
  testWidgets('旧敏感切片不丢弃最新档案投影，离线重开仍显示已接受替代', (tester) async {
    final server = _pageServer();
    final profile = profileFixture(manual: true);
    server.on('GET', '/v1/me/taste-profile', (_) => (200, profile.toJson()));
    server.on('POST', '/v1/recipes/$_account/personalized', (request) {
      final inputs = PersonalizationRequest.fromJson(
        Map<String, dynamic>.from(request.body as Map),
      );
      return (200, _cached().copyWith(
        profileVersion: profile.version,
        inputs: inputs,
      ).toJson());
    });
    final online = TestEnv.signedIn(server: server);
    final cache = TasteProfileCache(online.secure);
    await cache.writeAllergies(_account, _allergies(), stillCurrent: () => true);
    await cache.writeFamily(_account, _family(), stillCurrent: () => true);
    await _openDetail(tester, online);
    await _reveal(tester, find.byKey(const ValueKey('personalized-detail-main')));
    expect(find.text('豆腐  80 g'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await _settle(tester);
    await _openDetail(tester, TestEnv(
      server: server,
      local: online.local,
      secure: online.secure,
      offline: true,
    ));
    await _reveal(tester, find.byKey(const ValueKey('personalized-detail-main')));
    expect(find.text('豆腐  80 g'), findsOneWidget);
    expect(server.calls('POST', '/v1/recipes/$_account/personalized').length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline reopen never restores an allergy confirmation', (
    tester,
  ) async {
    final server = _pageServer(allergy: true);
    final online = TestEnv.signedIn(server: server);
    await _openDetail(tester, online);
    final start = find.byKey(const ValueKey('start-cooking-button'));
    await _reveal(tester, start);
    expect(tester.widget<FilledButton>(start).onPressed, isNull);
    final confirm = find.byKey(
      const ValueKey('confirm-personalized-allergy-risk'),
    );
    await _reveal(tester, confirm);
    await tester.tap(confirm);
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('confirm-allergy-risk-dialog')));
    await _settle(tester);
    await _reveal(tester, start);
    expect(tester.widget<FilledButton>(start).onPressed, isNotNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await _settle(tester);
    await _openDetail(
      tester,
      TestEnv(
        server: server,
        local: online.local,
        secure: online.secure,
        offline: true,
      ),
    );
    await _reveal(
      tester,
      find.byKey(const ValueKey('personalized-detail-main')),
    );
    expect(find.text('豆腐  80 g'), findsOneWidget);
    await _reveal(tester, start);
    expect(tester.widget<FilledButton>(start).onPressed, isNull);
    expect(
      server.calls('POST', '/v1/recipes/$_account/personalized').length,
      2,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await _settle(tester);
  });

  testWidgets('offline original serving changes reach cooking preparation', (
    tester,
  ) async {
    final authored = _original();
    final server = _pageServer(
      author: authored.copyWith(
        ingredients: [
          authored.ingredients!.first.copyWith(
            quantity: 0.003,
            baseQuantity: 0.003,
            scalingMode: RecipeIngredientScalingModeEnum.unchanged,
          ),
          ...authored.ingredients!.skip(1),
        ],
      ),
    );
    final online = TestEnv.signedIn(server: server);
    await _openDetail(tester, online);
    await _reveal(tester, find.text('原版'));
    await tester.tap(find.text('原版'));
    await _settle(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await _settle(tester);
    await _openDetail(
      tester,
      TestEnv(
        server: server,
        local: online.local,
        secure: online.secure,
        offline: true,
      ),
    );
    await _reveal(tester, find.byType(SegmentedButton<bool>));
    expect(
      tester
          .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
          .selected,
      {true},
    );
    final increase = find.byKey(const ValueKey('recipe-serving-increase'));
    await _reveal(tester, increase);
    await tester.tap(increase);
    await _settle(tester);
    final start = find.byKey(const ValueKey('start-cooking-button'));
    await _reveal(tester, start);
    await tester.tap(start);
    await _settle(tester);
    expect(find.text('先准备食材'), findsOneWidget);
    expect(find.text('150 g'), findsOneWidget);
    expect(find.text('120 g'), findsNothing);
    expect(find.text('30 g'), findsOneWidget);
    expect(find.text('0.003 g'), findsOneWidget);
    expect(
      server.calls('POST', '/v1/recipes/$_account/personalized').length,
      2,
    );
    await tester.tap(find.byTooltip('暂离'));
    await _settle(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await _settle(tester);
  });

  testWidgets(
    'offline reopening shows the accepted result and recomputes servings without changing the author',
    (tester) async {
      final server = FakeServer();
      final detail = recipeSnapshotFixture(
        '22222222-2222-4222-8222-222222222222',
        recipe: _account,
      );
      final authored = detail.copyWith.version(
        detail.version.copyWith.snapshot(_original()),
      );
      server.on(
        'GET',
        '/v1/recipes/$_account',
        (_) => (200, authored.toJson()),
      );
      server.on(
        'GET',
        '/v1/me/taste-profile',
        (_) => (200, profileFixture().toJson()),
      );
      server.on('POST', '/v1/recipes/$_account/personalized', (request) {
        final inputs = PersonalizationRequest.fromJson(
          Map<String, dynamic>.from(request.body as Map),
        );
        final result = _cached().copyWith(inputs: inputs);
        return (
          200,
          request.query['view'] == 'original'
              ? result
                    .copyWith(
                      view: RecipePersonalizedOutViewEnum.original,
                      cacheKey: 'original-key',
                      snapshot: _original(),
                    )
                    .toJson()
              : result.toJson(),
        );
      });
      final online = TestEnv.signedIn(server: server);
      await _openDetail(tester, online);
      await _reveal(
        tester,
        find.byKey(const ValueKey('personalized-detail-main')),
      );
      expect(find.text('豆腐  80 g'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await _settle(tester);
      final offline = TestEnv(
        server: server,
        local: online.local,
        secure: online.secure,
        offline: true,
      );
      await _openDetail(tester, offline);
      expect(find.textContaining('离线快照'), findsOneWidget);
      await _reveal(
        tester,
        find.byKey(const ValueKey('personalized-detail-main')),
      );
      expect(find.text('豆腐  80 g'), findsOneWidget);
      final increase = find.byKey(const ValueKey('recipe-serving-increase'));
      await _reveal(tester, increase);
      await tester.tap(increase);
      await _settle(tester);
      await _reveal(
        tester,
        find.byKey(const ValueKey('personalized-detail-main')),
      );
      expect(find.textContaining('豆腐  120'), findsOneWidget);
      await _reveal(
        tester,
        find.byKey(const ValueKey('personalized-detail-salt')),
      );
      expect(find.textContaining('盐  0.04'), findsOneWidget);
      await _reveal(
        tester,
        find.byKey(const ValueKey('personalized-detail-sugar')),
      );
      expect(find.textContaining('烘焙用糖  30'), findsOneWidget);
      await _reveal(tester, find.textContaining('离线已重算份数和口味'));
      expect(find.textContaining('离线已重算份数和口味'), findsOneWidget);
      expect(
        server.calls('POST', '/v1/recipes/$_account/personalized').length,
        1,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await _settle(tester);
    },
  );

  test('offline recompile starts from author amounts and retains accepted substitution and equipment steps', () async {
    final secure = MemorySecureStore();
    await _seed(secure);
    final restored = RecipePersonalizedOut.fromJson(
      (await TasteProfileCache(secure).readPersonalization(_account, _key))!,
    );
    final original = _original();
    final authorBefore = jsonDecode(jsonEncode(original.toJson()));
    final cachedBefore = jsonDecode(jsonEncode(restored.toJson()));
    final three = recompilePersonalizedServings(
      original: original,
      cached: restored,
      targetServings: 3,
      minServings: 1,
      maxServings: 20,
    );
    expect(
      [for (final row in three.ingredients) row.displayQuantity],
      [0.04, 30, 120],
    );
    expect(
      [for (final row in three.snapshot.ingredients!) row.quantity],
      [0.04, 30, 120],
    );
    expect(three.snapshot.ingredients!.first.baseQuantity, 0.04);
    expect(three.snapshot.ingredients!.last.baseQuantity, 120);
    expect(three.snapshot.ingredients!.last.displayName, '豆腐');
    expect(three.ingredients[1].rule, 'functional_protected');
    expect(three.ingredients[2].rule, 'substitution');
    expect(three.snapshot.steps, restored.snapshot.steps);
    expect(three.steps, restored.steps);
    expect(three.inputs.equipment, ['烤箱']);
    expect(three.inputs.dinerMemberIds, restored.inputs.dinerMemberIds);
    expect(three.inputs.primaryDinerId, restored.inputs.primaryDinerId);
    expect(three.inputs.targetServings, 3);
    expect(three.profileVersion, restored.profileVersion);
    expect(three.versionId, restored.versionId);
    expect(three.cacheKey, isNot(restored.cacheKey));
    expect(three.fallback, contains('离线已重算份数和口味'));
    final back = recompilePersonalizedServings(
      original: original,
      cached: three,
      targetServings: 2,
      minServings: 1,
      maxServings: 20,
    );
    expect(
      [for (final row in back.ingredients) row.displayQuantity],
      [0.02, 20, 80],
    );
    expect(original.toJson(), authorBefore);
    expect(restored.toJson(), cachedBefore);
    expect(
      [for (final row in three.ingredients) row.originalQuantity],
      [0.03, 20, 100],
    );
  });

  test('offline recompile preserves AI and child adaptation ratios', () {
    for (final rule in ['ai_substitution', 'child_portion']) {
      final raw = _cached().toJson();
      final ingredients = raw['ingredients'] as List<dynamic>;
      (ingredients[2] as Map<String, dynamic>)['rule'] = rule;
      final cached = RecipePersonalizedOut.fromJson(raw);
      final updated = recompilePersonalizedServings(
        original: _original(),
        cached: cached,
        targetServings: 3,
        minServings: 1,
        maxServings: 20,
      );
      expect(updated.ingredients[2].displayQuantity, 120, reason: rule);
      expect(updated.snapshot.ingredients![2].quantity, 120, reason: rule);
    }
  });

  test('offline substitutions use exact factors rather than ratios of rounded amounts', () {
    final original = _original().copyWith(
      ingredients: [_original().ingredients!.last.copyWith(quantity: 0.03)],
    );
    final raw = _cached().toJson();
    raw['ingredients'] = [
      {
        ...Map<String, dynamic>.from((raw['ingredients'] as List).last as Map),
        'original_quantity': 0.03,
        'display_quantity': 0.02,
        'adaptation_factors': [0.5],
      },
    ];
    raw['snapshot'] = original
        .copyWith(
          ingredients: [
            original.ingredients!.single.copyWith(
              displayName: '豆腐',
              quantity: 0.02,
            ),
          ],
        )
        .toJson();
    final updated = recompilePersonalizedServings(
      original: original,
      cached: RecipePersonalizedOut.fromJson(raw),
      targetServings: 4,
      minServings: 1,
      maxServings: 20,
    );
    expect(updated.ingredients.single.displayQuantity, 0.03);
    expect(updated.snapshot.ingredients!.single.quantity, 0.03);
  });

  test('offline serving change withdraws a previous allergy confirmation', () {
    final updated = recompilePersonalizedServings(
      original: _original(),
      cached: _cached(allergy: true),
      targetServings: 3,
      minServings: 1,
      maxServings: 20,
    );
    expect(updated.blocked, isTrue);
    expect(updated.inputs.confirmAllergyRisk, isFalse);
    expect(updated.safety.alerts!.single.ingredient, '豆腐');
    expect(updated.fallback, contains('安全检查需联网更新'));
  });

  test('private projections survive reopening and stay isolated by account and input key', () async {
    final secure = MemorySecureStore();
    final cache = await _seed(secure);
    final another = _cached(substituted: false)
        .copyWith(cacheKey: 'other-inputs');
    await cache.writePersonalization(
      _account,
      another.cacheKey,
      another.toJson(),
      stillCurrent: () => true,
    );
    final reopened = TasteProfileCache(secure);
    expect(
      (await reopened.readPersonalization(
        _account,
        _key,
      ))!['ingredients'][2]['display_name'],
      '豆腐',
    );
    expect(
      (await reopened.readPersonalization(
        _account,
        another.cacheKey,
      ))!['ingredients'][2]['display_name'],
      '肉',
    );
    expect(
      await reopened.readPersonalization(_account, 'unknown-inputs'),
      isNull,
    );
    expect(await reopened.readPersonalization('another-account', _key), isNull);
  });

  test('same profile keeps projections; changed profile invalidates all old input keys', () async {
    final secure = MemorySecureStore();
    final cache = await _seed(secure);
    await cache.writeProfile(
      _account,
      profileFixture(),
      stillCurrent: () => true,
    );
    expect(await cache.readPersonalization(_account, _key), isNotNull);
    await cache.writeProfile(
      _account,
      profileFixture(manual: true),
      stillCurrent: () => true,
    );
    expect(
      await TasteProfileCache(secure).readPersonalization(_account, _key),
      isNull,
    );
    await cache.writePersonalization(
      _account,
      'late-old-profile',
      _cached().toJson(),
      stillCurrent: () => true,
    );
    expect(
      await cache.readPersonalization(_account, 'late-old-profile'),
      isNull,
    );
  });

  for (final kind in ['explicit', 'allergies', 'family']) {
    test(
      'sensitive withdrawal through $kind removes private projections',
      () async {
        final secure = MemorySecureStore();
        final cache = await _seed(secure, sensitive: true);
        expect(await cache.readPersonalization(_account, _key), isNotNull);
        switch (kind) {
          case 'explicit':
            await cache.clearSensitive(_account, stillCurrent: () => true);
          case 'allergies':
            await cache.writeAllergies(
              _account,
              _allergies(consent: null, authorization: 2),
              stillCurrent: () => true,
            );
          case 'family':
            await cache.writeFamily(
              _account,
              _family(consent: null, authorization: 2),
              stillCurrent: () => true,
            );
        }
        expect(
          await TasteProfileCache(secure).readPersonalization(_account, _key),
          isNull,
        );
        expect((await cache.read(_account))!.profile!.version, 1);
        // Late callbacks from the old screen cannot resurrect private results.
        await cache.writePersonalization(
          _account,
          'late-after-withdrawal',
          _cached().toJson(),
          stillCurrent: () => true,
        );
        expect(
          await cache.readPersonalization(_account, 'late-after-withdrawal'),
          isNull,
        );
        final fresh = _cached(substituted: false).copyWith(
          authorizationVersion: 2,
          inputs: PersonalizationRequest(targetServings: 2),
        );
        await cache.writePersonalization(
          _account,
          'fresh-without-sensitive-consent',
          fresh.toJson(),
          stillCurrent: () => true,
        );
        expect(
          await cache.readPersonalization(
            _account,
            'fresh-without-sensitive-consent',
          ),
          isNotNull,
        );
      },
    );
  }

  test(
    'new authorization version rejects projections produced under old consent',
    () async {
      final cache = await _seed(MemorySecureStore(), sensitive: true);
      await cache.writeAllergies(
        _account,
        _allergies(authorization: 2),
        stillCurrent: () => true,
      );
      expect(await cache.readPersonalization(_account, _key), isNull);
      await cache.writePersonalization(
        _account,
        'late-old-authorization',
        _cached().toJson(),
        stillCurrent: () => true,
      );
      expect(
        await cache.readPersonalization(_account, 'late-old-authorization'),
        isNull,
      );
    },
  );
}
