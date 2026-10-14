import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/router.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';
import 'taste_profile_page_test.dart' show profileFixture;

const _recipeId = '11111111-1111-4111-8111-111111111111';
const _versionId = '22222222-2222-4222-8222-222222222222';
const _recordId = '33333333-3333-4333-8333-333333333333';
const _changeId = '44444444-4444-4444-8444-444444444444';
const _date = '2026-10-10T08:00:00Z';
const _instruction = '煮熟鸡肉后加盐';
const _stepNote = '关火前试味，再决定是否补盐';
const _differenceId = 'scene:difference:$_recipeId';
const _tasteId = 'scene:taste:$_changeId';
const _failureId = 'scene:failure:$_recipeId:too-salty:cook:at';

Map<String, dynamic> _source(String value) => {
  'source_type': 'scenario_adjusted',
  'value': value,
  'basis': {
    'reason_code': 'dish_history',
    'text': '根据上次做过记录与本次用量比较',
    'citation': '做过记录 $_recordId · 2026-10-10',
  },
};

RecipeDetail _detail() => RecipeDetail.fromJson({
  'id': _recipeId,
  'dish': {'id': _recipeId, 'name': '场景验收鸡肉', 'aliases': <String>[]},
  'author': {'id': testUser().id, 'nickname': '原版作者'},
  'visibility': 'private',
  'created_at': _date,
  'updated_at': _date,
  'version': {
    'id': _versionId,
    'version_number': 1,
    'snapshot': {
      'format_version': 1,
      'servings': 2,
      'ingredients': [
        {'id': 'salt', 'display_name': '盐', 'quantity': 10, 'unit': 'g'},
        {'id': 'chicken', 'display_name': '鸡肉', 'quantity': 200, 'unit': 'g'},
      ],
      'steps': [
        {
          'id': 'cook',
          'instruction': _instruction,
          'notes': _stepNote,
          'ingredient_ids': ['chicken', 'salt'],
        },
      ],
    },
    'derived': {'active_time_seconds': 0, 'total_time_seconds': 0},
    'images': <Object>[],
    'ai_assisted': false,
    'edit_operations': <Object>[],
    'change_note': '',
    'created_at': _date,
  },
});

RecipePersonalizedOut _projection(Map inputs, {num salt = 8}) {
  final snapshot = _detail().version.snapshot.toJson();
  (snapshot['ingredients'] as List).first['quantity'] = salt;
  return RecipePersonalizedOut.fromJson({
    'adjustment_limit': 0.3,
    'authorization_version': 1,
    'blocked': false,
    'cache_key': 'scene-salt-$salt',
    'effective_flavors': {'salty': salt / 10},
    'food_safety': {
      'checked_at': _date,
      'rules_version': 'test-v1',
      'findings': <Object>[],
    },
    'ingredients': [
      for (final ingredient in _detail().version.snapshot.ingredients!)
        {
          'id': ingredient.id,
          'changed': ingredient.id == 'salt',
          'display_name': ingredient.displayName,
          'display_quantity': ingredient.id == 'salt' ? salt : 200,
          'display_unit': 'g',
          'factor': ingredient.id == 'salt' ? salt / 10 : 1,
          'original_name': ingredient.displayName,
          'original_quantity': ingredient.id == 'salt' ? 10 : 200,
          'original_unit': 'g',
          'reason': '按口味档案换算',
          'rule': ingredient.id == 'salt' ? 'flavor_filter' : 'unchanged',
        },
    ],
    'inputs': Map<String, dynamic>.from(inputs),
    'notices': <Object>[],
    'profile_version': 7,
    'recipe_id': _recipeId,
    'safety': {'status': 'available', 'alerts': <Object>[]},
    'snapshot': snapshot,
    'snapshot_unchanged': true,
    'steps': [
      {
        'id': 'cook',
        'instruction': _instruction,
        'original_instruction': _instruction,
        'source': 'recipe',
      },
    ],
    'version_id': _versionId,
    'view': 'personalized',
  });
}

Map<String, dynamic> _component(
  String type,
  String id,
  Map<String, dynamic> data, {
  String detail = 'brief',
  bool required = false,
  List<Map<String, dynamic>> actions = const [],
}) => ComponentDescriptor.fromJson({
  'type': type,
  'id': id,
  'detail': detail,
  'data': data,
  'actions': actions,
  'reason': {'code': 'dish_history', 'text': '根据本人的做过记录'},
  'required': required,
}).toJson();

List<Map<String, dynamic>> _safety() => [
  _component(
    'food_safety',
    'scene:safety:$_recipeId',
    {
      'status': 'available',
      'conclusion': '鸡肉须充分加热',
      'basis': '根据食品安全规则检查',
      'result': {
        'rules_version': 'test-v1',
        'checked_at': _date,
        'high_risk': false,
        'findings': <Object>[],
      },
    },
    required: true,
    detail: 'standard',
  ),
  _component(
    'allergen_notice',
    'scene:allergens:$_recipeId',
    {
      'status': 'available',
      'conclusion': '未从已收录信息中识别出过敏原',
      'basis': '根据食材信息推导',
      'result': {
        'rules_version': 'test-v1',
        'checked_at': _date,
        'allergens': <String>[],
        'allergens_incomplete': false,
        'replacement_allergens': <Object>[],
      },
    },
    required: true,
    detail: 'standard',
  ),
];

Map<String, dynamic> _page(
  String detail, {
  bool frequent = false,
  bool notices = false,
  bool taste = false,
  List<String> skipped = const [],
}) => PageDescription.fromJson({
  'protocol': '1.0',
  'page_type': 'recipe_detail',
  'composition_id': '55555555-5555-4555-8555-555555555555',
  'generated_at': _date,
  'cache': {'depends_on': <String, String>{}, 'ttl_s': 0},
  'components': [
    ..._safety(),
    _component(
      'scenario_summary',
      'scene:detail:$_recipeId',
      {
        'conclusion': detail == 'detailed' ? '第一次做，完整展开' : '常做这道菜，先看本次变化',
        'steps_collapsed': frequent && detail == 'brief',
        'layout': 'phone',
        'source': _source('本页$detail'),
      },
      detail: detail,
      actions: [
        for (final value in ['brief', 'detailed', 'auto'])
          {
            'intent': 'set_scenario_detail',
            'params': {'detail': value},
          },
      ],
    ),
    if (notices && !skipped.contains(_differenceId))
      _component('scenario_difference', _differenceId, {
        'conclusion': '与上次相比，盐减少了',
        'record_id': _recordId,
        'record_date': _date,
        'differences': [
          {'kind': 'quantity', 'label': '盐', 'before': '9 g', 'after': '8 g'},
        ],
        'source': _source('盐由 9 g 变为 8 g'),
      }, detail: detail),
    if (notices && !skipped.contains(_failureId))
      _component('failure_reminder', _failureId, {
        'conclusion': '上次偏咸，这一步留意加盐',
        'rule_id': 'too-salty',
        'problem': '上次加盐过多',
        'advice': '先少放盐，试味后再补',
        'record_id': _recordId,
        'record_date': _date,
        'step_id': 'cook',
        'placement': 'at',
        'source': _source('先少放盐，试味后再补'),
      }, detail: detail),
    if (taste && !skipped.contains(_tasteId))
      _component(
        'taste_change_notice',
        _tasteId,
        {
          'conclusion': '最近口味变淡，本次盐量跟着调整',
          'change_id': _changeId,
          'change_date': _date,
          'source': _source('本次按最近的口味变化换算'),
        },
        detail: detail,
        actions: [
          {
            'intent': 'show_before_taste_change',
            'params': {'change_id': _changeId},
          },
          {
            'intent': 'open_taste_change',
            'params': {'change_id': _changeId},
          },
        ],
      ),
  ],
}).toJson();

FakeServer _server({
  String preference = 'auto',
  bool frequent = false,
  bool notices = false,
  bool taste = false,
  bool fallback = false,
}) {
  final server = FakeServer();
  server.on(
    'GET',
    '/v1/me/taste-profile/changes',
    (_) => (
      200,
      PageTasteProfileChangeOut(
        items: [
          TasteProfileChangeOut.fromJson({
            'id': _changeId,
            'version': 7,
            'field': 'flavors.salty',
            'old_value': {'coefficient': 0.9, 'confidence': 'high'},
            'new_value': {'coefficient': 0.8, 'confidence': 'high'},
            'reason': '最近做过后口味变淡',
            'origin': 'auto',
            'source': 'learning',
            'status': 'active',
            'created_at': _date,
          }),
        ],
      ).toJson(),
    ),
  );
  server.on('GET', '/v1/recipes/$_recipeId', (_) => (200, _detail().toJson()));
  server.on(
    'GET',
    '/v1/me/taste-profile',
    (_) => (200, profileFixture().copyWith(version: 7).toJson()),
  );
  server.on('GET', '/v1/ui/preferences', (_) => (200, {'detail': preference}));
  server.on('PUT', '/v1/ui/preferences', (request) {
    preference = (request.body as Map)['detail'] as String;
    return (200, {'detail': preference});
  });
  server.on(
    'POST',
    '/v1/recipes/$_recipeId/personalized',
    (request) => (200, _projection(request.body as Map).toJson()),
  );
  server.on(
    'POST',
    '/v1/recipes/$_recipeId/personalized/before-change/$_changeId',
    (request) => (200, _projection(request.body as Map, salt: 9).toJson()),
  );
  server.on(
    'POST',
    '/v1/ui/scenario-feedback',
    (_) => (200, {'status': 'suppressed'}),
  );
  server.on('POST', '/v1/ui/compositions', (request) {
    if (fallback) return FakeServer.error(503, 'unavailable', '组合暂不可用');
    final body = request.body as Map;
    final override = body['detail_override'] as String?;
    final detail = override != null && override != 'auto'
        ? override
        : preference == 'auto'
        ? (frequent ? 'brief' : 'detailed')
        : preference;
    return (
      200,
      _page(
        detail,
        frequent: frequent,
        notices: notices,
        taste: taste,
        skipped: ((body['skipped_components'] as List?) ?? const [])
            .cast<String>(),
      ),
    );
  });
  return server;
}

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _pump(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(WidgetTester tester, FakeServer server) async {
  await pumpApp(tester, env: TestEnv.signedIn(server: server), settle: false);
  await _pump(tester);
  ProviderScope.containerOf(tester.element(find.byType(Scaffold).first))
      .read(routerProvider)
      .push('/recipes/$_recipeId');
  await _pump(tester);
}

Future<void> _reveal(WidgetTester tester, Finder target) async {
  final scroll = _key('recipe-detail-content');
  if (target.evaluate().isEmpty) {
    for (var i = 0; i < 12; i++) {
      await tester.drag(scroll, const Offset(0, 500));
      await tester.pump(const Duration(milliseconds: 50));
    }
    for (var i = 0; i < 45 && target.evaluate().isEmpty; i++) {
      await tester.drag(scroll, const Offset(0, -250));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }
  expect(target, findsWidgets);
  await tester.ensureVisible(target.last);
  await _pump(tester);
  expect(target.last.hitTestable(), findsOneWidget);
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await _reveal(tester, target);
  await tester.tap(target.last.hitTestable());
  await _pump(tester);
}

Future<void> _sourcePanel(WidgetTester tester, String id) =>
    _tap(tester, find.descendant(of: _key(id), matching: find.text('按场景调整')));

void main() {
  testWidgets('第一次做展开步骤，页面临时简洁不写默认设置，重新打开恢复详细', (tester) async {
    final server = _server();
    await _open(tester, server);
    await _reveal(tester, find.text('第一次做，完整展开'));
    await _reveal(tester, find.textContaining(_stepNote));
    await _tap(tester, _key('scenario-detail-brief'));
    await _reveal(tester, find.text('常做这道菜，先看本次变化'));
    expect(server.calls('PUT', '/v1/ui/preferences'), isEmpty);
    final router = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    ).read(routerProvider);
    router.pop();
    await _pump(tester);
    router.push('/recipes/$_recipeId');
    await _pump(tester);
    await _reveal(tester, find.text('第一次做，完整展开'));
    await _reveal(tester, find.textContaining(_stepNote));
    expect(tester.takeException(), isNull);
  });

  testWidgets('设置固定简洁持久保存，但页面详细切换不改保存值', (tester) async {
    final server = _server();
    await pumpApp(tester, env: TestEnv.signedIn(server: server), settle: false);
    await _pump(tester);
    await tester.tap(find.text('我的').hitTestable());
    await _pump(tester);
    await tester.tap(find.text('设置').hitTestable());
    await _pump(tester);
    final chip = _key('detail-preference-brief');
    await tester.ensureVisible(chip);
    await tester.tap(chip.hitTestable());
    await _pump(tester);
    expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
    expect(server.calls('PUT', '/v1/ui/preferences').single.body, {
      'detail': 'brief',
    });
    final router = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    ).read(routerProvider);
    router.push('/recipes/$_recipeId');
    await _pump(tester);
    await _tap(tester, _key('scenario-detail-detailed'));
    await _reveal(tester, find.text('第一次做，完整展开'));
    expect(server.calls('PUT', '/v1/ui/preferences').length, 1);
    router.pop();
    await _pump(tester);
    expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('常做先展示差异结论，展开看上次本次数值，完整步骤仍可展开', (tester) async {
    await _open(tester, _server(frequent: true, notices: true));
    await _reveal(tester, find.text('与上次相比，盐减少了'));
    expect(find.textContaining('上次 9 g'), findsNothing);
    await _tap(tester, _key('$_differenceId:expand'));
    await _reveal(tester, find.textContaining('上次 9 g'));
    expect(find.textContaining('本次 8 g'), findsWidgets);
    await _reveal(tester, _key('scenario-expand-steps'));
    expect(find.textContaining(_instruction), findsNothing);
    await _tap(tester, _key('scenario-expand-steps'));
    await _reveal(tester, find.textContaining(_instruction));
    expect(tester.takeException(), isNull);
  });

  testWidgets('场景来源共用为什么，跳过只影响本页，永久反馈走接口且安全不能跳过', (tester) async {
    final server = _server(frequent: true, notices: true);
    await _open(tester, server);
    await _sourcePanel(tester, _differenceId);
    expect(_key('why-panel'), findsOneWidget);
    expect(find.text('根据上次做过记录与本次用量比较'), findsOneWidget);
    expect(find.textContaining('做过记录 $_recordId'), findsOneWidget);
    await tester.tap(find.text('这次不用').hitTestable());
    await _pump(tester);
    await _reveal(tester, _key('scenario-detail-brief'));
    expect(_key(_differenceId), findsNothing);
    expect(server.calls('POST', '/v1/ui/scenario-feedback'), isEmpty);
    final router = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    ).read(routerProvider);
    router.pop();
    await _pump(tester);
    router.push('/recipes/$_recipeId');
    await _pump(tester);
    await _sourcePanel(tester, _differenceId);
    await tester.tap(find.text('以后别这样').hitTestable());
    await _pump(tester);
    final feedback =
        server.calls('POST', '/v1/ui/scenario-feedback').single.body as Map;
    expect(feedback['component_id'], _differenceId);
    expect(feedback['source_type'], 'scenario_adjusted');
    await _reveal(tester, _key('recipe-food-safety-card'));
    await _reveal(tester, _key('recipe-allergen-card'));
    expect(server.calls('PATCH', '/v1/me/taste-profile'), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('变化前口味是旧档案9克而非作者10克，预览和取消撤销不改档案', (tester) async {
    final server = _server(taste: true);
    await _open(tester, server);
    await _reveal(tester, find.text('盐  8 g'));
    await _tap(tester, _key('$_tasteId:show_before_taste_change'));
    await _reveal(tester, find.text('盐  9 g'));
    expect(find.text('盐  10 g'), findsNothing);
    expect(
      server
          .calls(
            'POST',
            '/v1/recipes/$_recipeId/personalized/before-change/$_changeId',
          )
          .length,
      1,
    );
    expect(server.calls('PATCH', '/v1/me/taste-profile'), isEmpty);
    expect(
      server.calls('POST', '/v1/me/taste-profile/changes/$_changeId/revert'),
      isEmpty,
    );
    await _tap(tester, _key('scenario-restore-current-taste'));
    await _reveal(tester, find.text('盐  8 g'));
    await _tap(tester, _key('$_tasteId:open_taste_change'));
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('取消').hitTestable());
    await _pump(tester);
    expect(
      server.calls('POST', '/v1/me/taste-profile/changes/$_changeId/revert'),
      isEmpty,
    );
    await _reveal(tester, find.text('盐  8 g'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('恢复当前口味失败时不把旧档案用量冒充当前，也不能用旧预览开始做菜', (tester) async {
    final server = _server(taste: true);
    await _open(tester, server);
    await _tap(tester, _key('$_tasteId:show_before_taste_change'));
    await _reveal(tester, find.text('盐  9 g'));
    server.on(
      'POST',
      '/v1/recipes/$_recipeId/personalized',
      (_) => FakeServer.error(503, 'unavailable', '当前口味换算暂不可用'),
    );
    await _tap(tester, _key('scenario-restore-current-taste'));
    await _reveal(tester, _key('start-cooking-button'));
    expect(
      tester.widget<FilledButton>(_key('start-cooking-button')).onPressed,
      isNull,
    );
    expect(find.text('盐  9 g'), findsNothing);
    expect(_key('scenario-restore-current-taste'), findsNothing);
    expect(
      server.calls('POST', '/v1/me/taste-profile/changes/$_changeId/revert'),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('场景服务降级仍保留食品安全、过敏卡与原始步骤', (tester) async {
    await _open(tester, _server(fallback: true));
    await _reveal(tester, _key('recipe-food-safety-card'));
    await _reveal(tester, _key('recipe-allergen-card'));
    await _reveal(tester, find.textContaining(_instruction));
    expect(_key(_differenceId), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
