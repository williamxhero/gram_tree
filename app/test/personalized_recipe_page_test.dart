import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/api/api_client.dart';
import 'package:gram_tree/app/router.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/features/me/taste_profile_cache.dart';
import 'package:gram_tree/recipes/recipe_snapshot.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';
import 'taste_profile_page_test.dart' show profileFixture;

const _recipeId = '11111111-1111-4111-8111-111111111111';
const _versionId = '22222222-2222-4222-8222-222222222222';
const _childId = '33333333-3333-4333-8333-333333333333';
const _adultId = '44444444-4444-4444-8444-444444444444';
const _originalInstruction = '把鸡肉煮熟，再加盐和辣椒';
const _childInstruction = '先盛出小米的份，再加辣椒';

RecipeSnapshot _snapshot({num salt = 10, bool childPortion = false}) =>
    RecipeSnapshot(
      servings: 2,
      formatVersion: RecipeSnapshotFormatVersionEnum.number1,
      ingredients: [
        RecipeIngredient(
          id: 'salt',
          displayName: '盐',
          quantity: salt,
          unit: 'g',
        ),
        RecipeIngredient(
          id: 'chicken',
          displayName: '鸡肉',
          quantity: 200,
          unit: 'g',
        ),
      ],
      steps: [
        if (childPortion)
          RecipeStep(id: 'child-portion', instruction: _childInstruction),
        RecipeStep(id: 'step-1', instruction: _originalInstruction),
      ],
    );

RecipeDetail _detail() => RecipeDetail(
  id: _recipeId,
  dish: DishOut(id: _recipeId, name: '个性化验收菜', aliases: const []),
  author: RecipeAuthor(id: testUser().id, nickname: '原版作者'),
  visibility: RecipeDetailVisibilityEnum.private,
  createdAt: '2026-10-01T00:00:00Z',
  updatedAt: '2026-10-01T00:00:00Z',
  version: RecipeVersionOut(
    id: _versionId,
    versionNumber: 1,
    snapshot: _snapshot(),
    derived: RecipeDerived(activeTimeSeconds: 0, totalTimeSeconds: 0),
    images: const [],
    aiAssisted: false,
    editOperations: const [],
    changeNote: '',
    createdAt: '2026-10-01T00:00:00Z',
  ),
);

RecipePersonalizedOut _projection(
  PersonalizationRequest inputs, {
  bool original = false,
  List<RecipePersonalSafetyAlert> alerts = const [],
  bool childPortion = false,
  String? fallback,
}) => RecipePersonalizedOut(
  adjustmentLimit: 0.3,
  authorizationVersion: 1,
  blocked: alerts.isNotEmpty && inputs.confirmAllergyRisk != true,
  cacheKey:
      'projection-${original ? 'original' : 'personalized'}-${inputs.toJson()}',
  effectiveFlavors: const {'salty': 0.8},
  fallback: fallback,
  foodSafety: RecipeSafetyResult(
    checkedAt: '2026-10-01T00:00:00Z',
    rulesVersion: 'safety-v1',
    findings: const [],
  ),
  ingredients: [
    PersonalizedIngredientOut(
      id: 'salt',
      changed: !original,
      displayName: '盐',
      displayQuantity: original ? 10 : 8,
      displayUnit: 'g',
      factor: original ? 1 : 0.8,
      originalName: '盐',
      originalQuantity: 10,
      originalUnit: 'g',
      reason: inputs.primaryDinerId == _adultId ? '按主要食客爸爸的少盐设置' : '你偏好少盐',
      rule: 'flavor_filter',
    ),
    PersonalizedIngredientOut(
      id: 'chicken',
      changed: false,
      displayName: '鸡肉',
      displayQuantity: 200,
      displayUnit: 'g',
      factor: 1,
      originalName: '鸡肉',
      originalQuantity: 200,
      originalUnit: 'g',
      reason: '主料不参与味型缩放',
      rule: 'unchanged',
    ),
  ],
  inputs: inputs,
  notices: const [],
  profileVersion: 7,
  recipeId: _recipeId,
  safety: RecipePersonalSafety(
    status: RecipePersonalSafetyStatusEnum.available,
    alerts: alerts,
  ),
  snapshot: _snapshot(
    salt: original ? 10 : 8,
    childPortion: childPortion && !original,
  ),
  snapshotUnchanged: true,
  steps: [
    if (childPortion && !original)
      PersonalizedStepOut(
        id: 'child-portion',
        instruction: _childInstruction,
        originalInstruction: '',
        changed: true,
        source_: PersonalizedStepOutSource_Enum.scenarioAdjusted,
      ),
    PersonalizedStepOut(
      id: 'step-1',
      instruction: _originalInstruction,
      originalInstruction: _originalInstruction,
      source_: PersonalizedStepOutSource_Enum.recipe,
    ),
  ],
  versionId: _versionId,
  view: original
      ? RecipePersonalizedOutViewEnum.original
      : RecipePersonalizedOutViewEnum.personalized,
);

FamilyMemberOut _member(String id, String name, {bool child = false}) =>
    FamilyMemberOut(
      id: id,
      nickname: name,
      ageBand: child
          ? FamilyMemberOutAgeBandEnum.n3to6
          : FamilyMemberOutAgeBandEnum.adult,
      allergies: FamilyAllergiesOut(
        categories: const [],
        ingredients: const [],
      ),
      avoidances: const [],
      flavors: {'spicy': child ? 0 : 1},
      source_: FamilyMemberOutSource_Enum.manual,
    );

FakeServer _server({
  List<RecipePersonalSafetyAlert> alerts = const [],
  List<RecipePersonalSafetyAlert>? originalAlerts,
  bool family = false,
  String? fallback,
  FutureOr<RecipePersonalizedOut> Function(PersonalizationRequest, bool)?
  response,
}) {
  final server = FakeServer();
  server.on('GET', '/v1/recipes/$_recipeId', (_) => (200, _detail().toJson()));
  server.on('POST', '/v1/recipes/$_recipeId/personalized', (request) async {
    final inputs = PersonalizationRequest.fromJson(
      Map<String, dynamic>.from(request.body as Map),
    );
    final original = request.query['view'] == 'original';
    final result = response == null
        ? _projection(
            inputs,
            original: original,
            alerts: original ? (originalAlerts ?? alerts) : alerts,
            childPortion: inputs.dinerMemberIds?.contains(_childId) == true,
            fallback: fallback,
          )
        : await response(inputs, original);
    return (200, result.toJson());
  });
  if (family) {
    server.on(
      'GET',
      '/v1/me/taste-profile/family-members',
      (_) => (
        200,
        FamilyMembersOut(
          authorizationVersion: 1,
          availableAgeBands: const [],
          availableAllergenCategories: const ['花生'],
          consentId: 'consent',
          consentVersion: 'allergies-v1',
          profileVersion: 7,
          items: [
            _member(_childId, '小米', child: true),
            _member(_adultId, '爸爸'),
          ],
        ).toJson(),
      ),
    );
  }
  return server;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(WidgetTester tester, FakeServer server) async {
  await pumpApp(tester, env: TestEnv.signedIn(server: server));
  ProviderScope.containerOf(tester.element(find.byType(Scaffold).first))
      .read(routerProvider)
      .push('/recipes/$_recipeId');
  await _settle(tester);
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  final body = find.byKey(const ValueKey('recipe-detail-content'));
  if (finder.evaluate().isEmpty) {
    for (var i = 0; i < 10; i++) {
      await tester.drag(body, const Offset(0, 500));
      await tester.pump(const Duration(milliseconds: 50));
    }
    for (var i = 0; i < 45 && finder.evaluate().isEmpty; i++) {
      await tester.drag(body, const Offset(0, -250));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await _settle(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.tap(finder);
  await _settle(tester);
}

Finder _key(String key) => find.byKey(ValueKey(key));
Finder _start() => _key('start-cooking-button');

void main() {
  for (final neutral in [true, false]) {
    testWidgets('个性化详情保留作者味型和用量来源，普通份数换算仍用量具显示 $neutral', (tester) async {
      final salt = _snapshot().ingredients!.first.copyWith(
        flavorContribution: RecipeFlavorContribution(salty: 3, umami: 2),
        flavorSource: ValueSource(source_: ValueSourceSource_Enum.authorFilled),
        quantitySource: ValueSource(
          source_: ValueSourceSource_Enum.aiEstimated,
          original: '一小撮',
          basis: '合成量化依据',
        ),
      );
      final snapshot = _snapshot().copyWith(
        ingredients: [salt, _snapshot().ingredients!.last],
      );
      final server = _server(
        response: (inputs, original) {
          final result = _projection(inputs, original: neutral || original);
          final servings = inputs.targetServings ?? 2;
          return result.copyWith(
            view: RecipePersonalizedOutViewEnum.personalized,
            ingredients: [
              for (final item in result.ingredients)
                item.copyWith(
                  displayQuantity: item.displayQuantity * servings / 2,
                  changed: item.changed || servings != 2,
                  rule: neutral
                      ? (servings == 2 ? 'unchanged' : 'servings')
                      : item.rule,
                ),
            ],
          );
        },
      );
      final detail = _detail();
      server.on(
        'GET',
        '/v1/recipes/$_recipeId',
        (_) => (
          200,
          detail
              .copyWith(version: detail.version.copyWith(snapshot: snapshot))
              .toJson(),
        ),
      );
      await _open(tester, server);
      final flavor = find.descendant(
        of: _key('recipe-flavor-detail-salt'),
        matching: find.textContaining('咸 3'),
      );
      await _reveal(tester, flavor);
      expect(flavor, findsOneWidget);
      await _tap(tester, _key('recipe-flavor-source-salt'));
      expect(find.textContaining('作者按这道菜'), findsWidgets);
      await tester.tapAt(const Offset(10, 10));
      await _settle(tester);
      if (neutral) {
        await _tap(tester, _key('recipe-source-mark-salt'));
        expect(find.text('原来：一小撮'), findsOneWidget);
        expect(find.textContaining('合成量化依据'), findsWidgets);
        await tester.tapAt(const Offset(10, 10));
        await _settle(tester);
        await _tap(tester, _key('recipe-serving-increase'));
        await _reveal(tester, _key('recipe-ingredient-amount-salt'));
        expect(find.text('15 克'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('中性口味的功能性用料仍可切换自家量具并查看显示依据', (tester) async {
    final ingredient = RecipeIngredient(
      id: 'salt',
      displayName: '功能性液体',
      quantity: 30,
      unit: 'ml',
      functional: true,
    );
    final detail = _detail();
    final server = _server(
      response: (inputs, original) {
        final result = _projection(inputs, original: true);
        return result.copyWith(
          view: RecipePersonalizedOutViewEnum.personalized,
          ingredients: [
            result.ingredients.first.copyWith(
              displayName: ingredient.displayName,
              originalName: ingredient.displayName,
              displayQuantity: 30,
              originalQuantity: 30,
              displayUnit: 'ml',
              originalUnit: 'ml',
              rule: 'functional_protected',
              reason: '功能性用料保护',
            ),
          ],
        );
      },
    );
    server.on(
      'GET',
      '/v1/recipes/$_recipeId',
      (_) => (
        200,
        detail
            .copyWith(
              version: detail.version.copyWith(
                snapshot: _snapshot().copyWith(ingredients: [ingredient]),
              ),
            )
            .toJson(),
      ),
    );
    server.on(
      'GET',
      '/v1/me/measures',
      (_) => (
        200,
        {
          'items': [
            {
              'id': '66666666-6666-4666-8666-666666666666',
              'name': '白瓷勺',
              'kind': 'spoon',
              'capacity_ml': 15,
              'created_at': '2026-10-02T00:00:00Z',
              'updated_at': '2026-10-02T00:00:00Z',
            },
          ],
          'next_cursor': null,
        },
      ),
    );
    await _open(tester, server);
    await _tap(tester, _key('recipe-display-mode-home'));
    await _tap(tester, _key('recipe-measure-picker'));
    await tester.tap(find.textContaining('白瓷勺').last);
    await _settle(tester);
    await _reveal(tester, _key('recipe-ingredient-amount-salt'));
    expect(find.text('约 2 白瓷勺（30 毫升） · 功能性用料'), findsOneWidget);
    await _tap(tester, _key('recipe-source-mark-salt'));
    expect(find.text('现在：约 2 白瓷勺（30 毫升）'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('首个换算请求等待时修改档案，迟到旧响应不能恢复做菜权限', (tester) async {
    final oldResponse = Completer<RecipePersonalizedOut>();
    PersonalizationRequest? oldInputs;
    var profile = profileFixture().copyWith(version: 7);
    final alert = RecipePersonalSafetyAlert(
      person: '你',
      ingredient: '盐',
      kind: RecipePersonalSafetyAlertKindEnum.allergy,
      target: '当前档案风险',
    );
    final server = _server(
      response: (inputs, original) {
        if (oldInputs == null) {
          oldInputs = inputs;
          return oldResponse.future;
        }
        return _projection(inputs, alerts: [alert]).copyWith(profileVersion: 8);
      },
    );
    server.on('GET', '/v1/me/taste-profile', (_) => (200, profile.toJson()));
    server.on('PATCH', '/v1/me/taste-profile', (_) {
      profile = profileFixture(
        saltyLevel: 1,
        manual: true,
      ).copyWith(version: 8);
      return (200, profile.toJson());
    });
    await _open(tester, server);
    await _reveal(tester, _start());
    expect(tester.widget<FilledButton>(_start()).onPressed, isNull);
    final router = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    ).read(routerProvider);
    router.push('/me/taste-profile');
    await _settle(tester);
    await _tap(tester, _key('taste-level-salty'));
    await _tap(tester, find.text('淡一点').last);
    router.pop();
    await _settle(tester);
    await _reveal(tester, _start());
    expect(tester.widget<FilledButton>(_start()).onPressed, isNull);
    oldResponse.complete(_projection(oldInputs!));
    await _settle(tester);
    await _reveal(tester, _start());
    expect(tester.widget<FilledButton>(_start()).onPressed, isNull);
    await _reveal(tester, find.textContaining('当前档案风险'));
    expect(
      server.calls('POST', '/v1/recipes/$_recipeId/personalized').length,
      2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('切回原版后调整份数仍保持本次查看的原版选择和作者步骤', (tester) async {
    await _open(tester, _server());
    await _tap(tester, find.text('原版'));
    await _reveal(tester, _key('recipe-serving-increase'));
    await tester.tap(_key('recipe-serving-increase'));
    await _settle(tester);
    await _reveal(tester, find.byType(SegmentedButton<bool>));
    expect(
      tester
          .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
          .selected,
      {true},
    );
    await _reveal(tester, find.text('原版作者'));
    await _reveal(tester, find.textContaining(_originalInstruction));
    expect(_key('personalized-detail-salt'), findsNothing);
    await _tap(tester, find.text('按我的口味'));
    await _reveal(tester, _key('personalized-detail-salt'));
    expect(
      find.descendant(
        of: _key('personalized-detail-salt'),
        matching: find.text('盐  8 g'),
      ),
      findsOneWidget,
    );
  });

  for (final person in ['你', '小米']) {
    testWidgets('$person 的花生过敏阻断做菜，取消仍阻断，具体风险确认后才允许开始', (tester) async {
      final alert = RecipePersonalSafetyAlert(
        ingredient: '花生油',
        kind: RecipePersonalSafetyAlertKindEnum.allergy,
        person: person,
        target: '花生',
      );
      await _open(tester, _server(alerts: [alert]));
      await _reveal(tester, _key('personalized-allergy-花生油'));
      expect(find.text('含过敏原：$person · 花生'), findsOneWidget);
      await _reveal(tester, _start());
      expect(tester.widget<FilledButton>(_start()).onPressed, isNull);
      await _tap(tester, _key('confirm-personalized-allergy-risk'));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('$person：花生（花生油）'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await _settle(tester);
      expect(tester.widget<FilledButton>(_start()).onPressed, isNull);
      await _tap(tester, _key('confirm-personalized-allergy-risk'));
      await tester.tap(_key('confirm-allergy-risk-dialog'));
      await _settle(tester);
      await _reveal(tester, _start());
      expect(tester.widget<FilledButton>(_start()).onPressed, isNotNull);
      await _tap(tester, _start());
      expect(find.text('先准备食材'), findsOneWidget);
      await tester.tap(find.byTooltip('暂离'));
      await _settle(tester);
      await _reveal(tester, _start());
      expect(tester.widget<FilledButton>(_start()).onPressed, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await _settle(tester);
    });
  }

  testWidgets('安全替代后的个性化视图切回含过敏原的原版仍须确认', (tester) async {
    final alert = RecipePersonalSafetyAlert(
      ingredient: '花生油',
      kind: RecipePersonalSafetyAlertKindEnum.allergy,
      person: '小米',
      target: '花生',
    );
    await _open(tester, _server(originalAlerts: [alert]));
    await _tap(tester, find.text('原版'));
    await _reveal(tester, _start());
    expect(tester.widget<FilledButton>(_start()).onPressed, isNull);
    await _tap(tester, _key('confirm-personalized-allergy-risk'));
    expect(find.textContaining('小米：花生（花生油）'), findsOneWidget);
    await tester.tap(_key('confirm-allergy-risk-dialog'));
    await _settle(tester);
    await _reveal(tester, _start());
    expect(tester.widget<FilledButton>(_start()).onPressed, isNotNull);
  });

  testWidgets('选择同吃成员、主要食客和折中，分盛步骤与原始步骤同时可见', (tester) async {
    await _open(tester, _server(family: true));
    await _tap(tester, _key('personalized-diner-$_childId'));
    await _tap(tester, _key('personalized-diner-$_adultId'));
    await _reveal(tester, _key('personalized-primary-diner'));
    expect(find.text('折中口味'), findsOneWidget);
    await _tap(tester, _key('personalized-primary-diner'));
    await tester.tap(find.text('爸爸').last);
    await _settle(tester);
    await _reveal(tester, _key('personalized-primary-diner'));
    expect(
      find.descendant(
        of: _key('personalized-primary-diner'),
        matching: find.text('爸爸'),
      ),
      findsOneWidget,
    );
    await _reveal(tester, _key('personalized-detail-salt'));
    expect(
      find.descendant(
        of: _key('personalized-detail-salt'),
        matching: find.textContaining('按主要食客爸爸的少盐设置'),
      ),
      findsOneWidget,
    );
    await _reveal(tester, find.textContaining(_childInstruction));
    await _reveal(tester, find.textContaining(_originalInstruction));
    await _tap(tester, _key('personalized-primary-diner'));
    await tester.tap(find.text('折中口味').last);
    await _settle(tester);
    await _reveal(tester, find.textContaining(_childInstruction));
    await _reveal(tester, find.textContaining(_originalInstruction));
    await _tap(tester, find.text('原版'));
    await _reveal(tester, find.textContaining(_originalInstruction));
    expect(find.textContaining(_childInstruction), findsNothing);
  });

  testWidgets('做菜模式使用详情相同的少盐用量和儿童分盛步骤', (tester) async {
    await _open(tester, _server(family: true));
    await _tap(tester, _key('personalized-diner-$_childId'));
    await _reveal(tester, _key('personalized-detail-salt'));
    expect(
      find.descendant(
        of: _key('personalized-detail-salt'),
        matching: find.text('盐  8 g'),
      ),
      findsOneWidget,
    );
    await _reveal(tester, find.textContaining(_childInstruction));
    await _tap(tester, _start());
    expect(find.text('先准备食材'), findsOneWidget);
    expect(find.text('8 g'), findsOneWidget);
    expect(find.text('10 g'), findsNothing);
    await tester.tap(find.text('开始第一步'));
    await _settle(tester);
    expect(find.text(_childInstruction), findsWidgets);
    await tester.tap(find.text('下一步'));
    await _settle(tester);
    expect(find.text(_originalInstruction), findsWidgets);
    await tester.tap(find.byTooltip('暂离'));
    await _settle(tester);
    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('原版安全结果请求未完成前不能开始做菜', (tester) async {
    final pending = Completer<RecipePersonalizedOut>();
    await _open(
      tester,
      _server(
        response: (inputs, original) =>
            original ? pending.future : _projection(inputs),
      ),
    );
    await _tap(tester, find.text('原版'));
    await _reveal(tester, _start());
    expect(tester.widget<FilledButton>(_start()).onPressed, isNull);
    pending.complete(_projection(PersonalizationRequest(), original: true));
    await _settle(tester);
    expect(tester.widget<FilledButton>(_start()).onPressed, isNotNull);
  });

  testWidgets('离线改同吃成员后迟到的旧安全结果不能恢复做菜权限', (tester) async {
    final pending = Completer<RecipePersonalizedOut>();
    PersonalizationRequest? oldInputs;
    await _open(
      tester,
      _server(
        family: true,
        response: (inputs, original) {
          if (inputs.dinerMemberIds?.contains(_adultId) == true) {
            oldInputs = inputs;
            return pending.future;
          }
          return _projection(inputs, original: original);
        },
      ),
    );
    await _tap(tester, _key('personalized-diner-$_adultId'));
    expect(oldInputs, isNotNull);
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first))
        .read(offlineSimulationProvider.notifier)
        .set(true);
    await _settle(tester);
    await _tap(tester, _key('personalized-diner-$_childId'));
    pending.complete(_projection(oldInputs!));
    await _settle(tester);
    await _reveal(tester, _start());
    expect(tester.widget<FilledButton>(_start()).onPressed, isNull);
    expect(_key('personalized-detail-salt'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await _settle(tester);
  });

  testWidgets('AI 不可用时仍显示规则换算和可见降级原因', (tester) async {
    await _open(tester, _server(fallback: 'AI 不可用，忌口替换与厨具改写暂缺，前三步规则仍可用。'));
    await _reveal(tester, find.textContaining('AI 不可用'));
    await _reveal(tester, _key('personalized-detail-salt'));
    expect(
      find.descendant(
        of: _key('personalized-detail-salt'),
        matching: find.text('盐  8 g'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('只有菜谱和档案缓存时离线换算少盐和份数，但安全未检查不能做菜', (tester) async {
    final env = TestEnv.signedIn(server: _server(), offline: true);
    final detail = _detail().copyWith.version(
      _detail().version.copyWith.snapshot(
        _snapshot().copyWith(
          ingredients: [
            RecipeIngredient(
              id: 'salt',
              displayName: '盐',
              quantity: 10,
              unit: 'g',
              flavorContribution: RecipeFlavorContribution(salty: 3),
            ),
            RecipeIngredient(
              id: 'sugar',
              displayName: '发面糖',
              quantity: 20,
              unit: 'g',
              functional: true,
              flavorContribution: RecipeFlavorContribution(sweet: 3),
            ),
          ],
        ),
      ),
    );
    await RecipeSnapshotStore(env.local, accountId: testUser().id).save(
      FrozenRecipeSnapshot(
        detail: detail,
        capturedAt: DateTime.utc(2026, 10, 1),
        inputs: const {'target_servings': 2},
        render: null,
        dependencies: const {},
      ),
    );
    await TasteProfileCache(env.secure).writeProfile(
      testUser().id,
      profileFixture(saltyLevel: 1, manual: true),
      stillCurrent: () => true,
    );
    await pumpApp(tester, env: env);
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first))
        .read(routerProvider)
        .push('/recipes/$_recipeId');
    await _settle(tester);
    await _reveal(tester, _key('personalized-detail-salt'));
    expect(find.text('盐  7.5 g'), findsWidgets);
    await _reveal(tester, _key('personalized-detail-sugar'));
    // JavaScript omits .0 for whole doubles; both spellings must remain 20 g.
    expect(
      find.descendant(
        of: _key('personalized-detail-sugar'),
        matching: find.textContaining(RegExp(r'^发面糖  20(?:\.0)? g$')),
      ),
      findsOneWidget,
    );
    await _tap(tester, _key('recipe-serving-increase'));
    await _reveal(tester, _key('personalized-detail-salt'));
    expect(find.text('盐  11.25 g'), findsWidgets);
    await _reveal(tester, _start());
    expect(tester.widget<FilledButton>(_start()).onPressed, isNull);
    await _reveal(tester, find.textContaining('联网前不能开始做菜'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('换算摘要也高亮数值并打开共用为什么面板', (tester) async {
    await _open(tester, _server());
    final summary = _key('personalized-summary-salt');
    await _reveal(tester, summary);
    final icon = tester.widget<Icon>(
      find.descendant(of: summary, matching: find.byIcon(Icons.tune)),
    );
    expect(icon.color, GramTreeColors.of(tester.element(summary)).accent);
    await tester.tap(
      find.descendant(of: summary, matching: find.text('按你的口味换算')),
    );
    await _settle(tester);
    expect(_key('why-panel'), findsOneWidget);
    expect(find.text('原来：盐 10 g'), findsOneWidget);
    expect(find.text('现在：盐 8 g'), findsOneWidget);
  });

  testWidgets('默认少盐数值高亮，为什么面板显示原值、规则、原因和档案版本', (tester) async {
    await _open(tester, _server());
    await _reveal(tester, find.byType(SegmentedButton<bool>));
    expect(
      tester
          .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
          .selected,
      {false},
    );
    await _reveal(tester, _key('personalized-detail-salt'));
    final salt = _key('personalized-detail-salt');
    expect(
      find.descendant(of: salt, matching: find.text('盐  8 g')),
      findsOneWidget,
    );
    final icon = tester.widget<Icon>(
      find.descendant(of: salt, matching: find.byIcon(Icons.tune)),
    );
    expect(icon.color, GramTreeColors.of(tester.element(salt)).accent);
    await tester.tap(find.descendant(of: salt, matching: find.text('按你的口味换算')));
    await _settle(tester);
    final panel = _key('why-panel');
    expect(panel, findsOneWidget);
    expect(
      find.descendant(of: panel, matching: find.text('原来：盐 10 g')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: panel, matching: find.text('现在：盐 8 g')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: panel,
        matching: find.textContaining('flavor_filter'),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(of: panel, matching: find.textContaining('你偏好少盐')),
      findsWidgets,
    );
    expect(
      find.descendant(of: panel, matching: find.textContaining('口味档案第 7 版')),
      findsWidgets,
    );
  });
}
