import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';
import 'taste_profile_page_test.dart'
    show installProfile, profileFixture, openTaste;

const constraintsPath = '/v1/me/taste-profile/cooking-constraints';

Map<String, dynamic> constraintsFixture({Map<String, dynamic>? values}) => {
  'profile_version': 1,
  'constraints':
      values ??
      {
        'household_servings': null,
        'equipment': [],
        'meal_times': [],
        'meal_templates': [],
      },
  'equipment_vocabulary': [
    {
      'id': 'wok',
      'label': '炒锅',
      'aliases': ['炒菜锅'],
    },
    {'id': 'oven', 'label': '烤箱', 'aliases': []},
  ],
  'dish_types': ['meat', 'vegetable', 'soup', 'staple', 'other'],
  'servings_min': 1,
  'servings_max': 20,
};

void main() {
  testWidgets(
    'cooking history and why show actual old and new settings with configured names',
    (tester) async {
      final server = FakeServer();
      installProfile(server, () => profileFixture());
      final current = constraintsFixture();
      (current['equipment_vocabulary'] as List)[1]['label'] = '台式烤箱';
      server.on('GET', constraintsPath, (_) => (200, current));
      server.on(
        'GET',
        '/v1/me/taste-profile/changes',
        (_) => (
          200,
          {
            'items': [
              {
                'id': '88888888-8888-4888-8888-888888888888',
                'version': 2,
                'field': 'cooking_constraints',
                'old_value': {
                  'household_servings': 4,
                  'equipment': ['wok'],
                  'meal_times': [
                    {'day_type': 'weekday', 'meal': 'dinner', 'minutes': 30},
                  ],
                  'meal_templates': [
                    {
                      'day_type': 'weekday',
                      'meal': 'dinner',
                      'dish_count': 3,
                      'composition': ['meat', 'vegetable', 'soup'],
                    },
                  ],
                },
                'new_value': {
                  'household_servings': 4,
                  'equipment': ['oven'],
                  'meal_times': [
                    {'day_type': 'weekday', 'meal': 'dinner', 'minutes': 60},
                  ],
                  'meal_templates': [
                    {
                      'day_type': 'weekday',
                      'meal': 'dinner',
                      'dish_count': 3,
                      'composition': ['vegetable', 'vegetable', 'vegetable'],
                    },
                  ],
                },
                'reason': '你手动修改',
                'source': 'manual',
                'status': 'active',
                'created_at': '2026-10-08T10:00:00Z',
              },
            ],
            'next_cursor': null,
          },
        ),
      );
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await openTaste(tester);
      final why = find.byKey(
        const ValueKey(
          'taste-history-why-88888888-8888-4888-8888-888888888888',
        ),
      );
      await tester.scrollUntilVisible(why, 450);
      const oldLabel = '4 人、厨具：炒锅、工作日晚餐：30 分钟、工作日晚餐：3 道（荤菜、素菜、汤）';
      const newLabel = '4 人、厨具：台式烤箱、工作日晚餐：60 分钟、工作日晚餐：3 道（素菜、素菜、素菜）';
      expect(find.text('做菜约束：$oldLabel → $newLabel'), findsOneWidget);
      await tapVisible(tester, why);
      expect(find.text('原来：做菜约束 · $oldLabel'), findsOneWidget);
      expect(find.text('现在：做菜约束 · $newLabel'), findsOneWidget);
      expect(find.text('这次不用'), findsNothing);
      expect(find.text('以后别这样'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cooking settings reuse read-only why without private telemetry',
    (tester) async {
      final server = FakeServer();
      installProfile(server, () => profileFixture());
      server.on('GET', constraintsPath, (_) => (200, constraintsFixture()));
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await openTaste(tester);
      final why = find.byKey(const ValueKey('cooking-constraints-why'));
      await tester.scrollUntilVisible(why, 450);
      await tapVisible(tester, why);
      expect(find.byKey(const ValueKey('why-panel')), findsOneWidget);
      expect(find.text('这次不用'), findsNothing);
      expect(find.text('以后别这样'), findsNothing);
      final events = server
          .calls('POST', '/v1/sync/writes')
          .expand(
            (request) => ((request.body as Map)['writes'] as List).cast<Map>(),
          )
          .map((write) {
            expect(write['write_type'], 'experience.event');
            expect(write['owner_id'], server.user.id);
            return write['payload'] as Map;
          })
          .where((event) => event['event_type'] == 'ui.why_panel_opened')
          .toList();
      expect(events, hasLength(1));
      expect(events.single['content'], {
        'component_id': 'cooking-constraints',
        'source_type': 'author_filled',
      });
      expect(events.single['correlation'], <String, dynamic>{});
    },
  );

  testWidgets(
    'invalid household input stays editable and makes no partial save',
    (tester) async {
      final server = FakeServer();
      installProfile(server, () => profileFixture());
      server.on('GET', constraintsPath, (_) => (200, constraintsFixture()));
      server.on(
        'GET',
        '/v1/me/measures',
        (_) => (200, {'items': [], 'next_cursor': null}),
      );
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await openTaste(tester);
      final edit = find.byKey(const ValueKey('cooking-constraints-edit'));
      await tester.scrollUntilVisible(edit, 450);
      await tapVisible(tester, edit);
      await tester.enterText(
        find.byKey(const ValueKey('household-servings')),
        '0',
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('cooking-constraints-save')),
      );
      expect(find.text('请输入 1～20 的整数；留空清除'), findsOneWidget);
      expect(server.calls('PUT', constraintsPath), isEmpty);
      await tester.tap(find.widgetWithText(TextButton, '取消').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('taste-measures-manage')),
        450,
      );
      expect(find.text('还没有登记量具'), findsOneWidget);
    },
  );

  testWidgets('my taste shows own measures and reuses calibration manager', (
    tester,
  ) async {
    final server = FakeServer();
    installProfile(server, () => profileFixture());
    server.on('GET', constraintsPath, (_) => (200, constraintsFixture()));
    var measure = {
      'id': '55555555-5555-4555-8555-555555555555',
      'name': '我的勺',
      'kind': 'spoon',
      'capacity_ml': 12.0,
      'created_at': '2026-10-08T00:00:00Z',
      'updated_at': '2026-10-08T00:00:00Z',
    };
    server.on(
      'GET',
      '/v1/me/measures',
      (_) => (
        200,
        {
          'items': [
            measure,
            {
              ...measure,
              'id': '77777777-7777-4777-8777-777777777777',
              'name': '我的量杯',
              'capacity_ml': 12.125,
            },
          ],
          'next_cursor': null,
        },
      ),
    );
    server.on('POST', '/v1/sync/writes', (request) {
      return (
        200,
        {
          'results': [
            for (final write in (request.body as Map)['writes'] as List)
              (() {
                if (write['write_type'] == 'personal_measure.change') {
                  final fields = write['payload']['fields'] as Map;
                  measure = {
                    ...measure,
                    for (final field in fields.entries)
                      field.key as String: (field.value as Map)['value'],
                  };
                  return {
                    'write_id': write['write_id'],
                    'status': 'confirmed',
                    'result': {
                      'resource_type': 'personal_measure',
                      'resource_id': measure['id'],
                      'values': {
                        ...measure,
                        'deleted': false,
                        'applied': true,
                        'field_outcomes': {'capacity_ml': 'won'},
                      },
                    },
                  };
                }
                return {
                  'write_id': write['write_id'],
                  'status': 'confirmed',
                  'result': {
                    'resource_type': 'experience.event',
                    'resource_id': write['write_id'],
                  },
                };
              })(),
          ],
        },
      );
    });
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await openTaste(tester);
    final manager = find.byKey(const ValueKey('taste-measures-manage'));
    await tester.scrollUntilVisible(manager, 450);
    expect(find.text('我的勺 · 12.0 毫升'), findsOneWidget);
    expect(find.text('我的量杯 · 12.125 毫升'), findsOneWidget);
    await tapVisible(tester, manager);
    expect(find.byKey(const ValueKey('measure-add')), findsOneWidget);
    await tester.tap(find.text('我的勺'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('measure-capacity')),
      '15',
    );
    await tapVisible(tester, find.byKey(const ValueKey('measure-save')));
    final measureWrites = server
        .calls('POST', '/v1/sync/writes')
        .expand(
          (request) => ((request.body as Map)['writes'] as List).cast<Map>(),
        )
        .where((write) => write['write_type'] == 'personal_measure.change')
        .toList();
    expect(measureWrites, hasLength(1));
    expect(measureWrites.single['owner_id'], server.user.id);
    expect(measureWrites.single['payload']['resource_id'], measure['id']);
    expect(measureWrites.single['payload']['action'], 'update');
    expect((measureWrites.single['payload']['fields'] as Map).keys, [
      'capacity_ml',
    ]);
    expect(
      measureWrites.single['payload']['fields']['capacity_ml']['value'],
      15.0,
    );
    expect(
      DateTime.parse(
        measureWrites.single['payload']['fields']['capacity_ml']['device_time']
            as String,
      ).isUtc,
      isTrue,
    );
    await goBack(tester);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(manager, 450);
    expect(find.text('我的勺 · 15.0 毫升'), findsOneWidget);
    expect(server.calls('POST', '/v1/recipes'), isEmpty);
    final actions = server
        .calls('POST', '/v1/sync/writes')
        .expand(
          (request) => ((request.body as Map)['writes'] as List).cast<Map>(),
        )
        .where((write) => write['write_type'] == 'experience.event')
        .map((write) {
          expect(write['write_type'], 'experience.event');
          expect(write['owner_id'], server.user.id);
          return write['payload'] as Map;
        })
        .where((event) => event['event_type'] == 'ui.component_action')
        .toList();
    expect(actions.map((event) => event['content']).toList(), [
      {
        'component_id': 'personal-measures',
        'intent': 'personal_measures_manage',
      },
    ]);
    // Native settings are not rendered from a server composition. Do not invent
    // a non-UUID correlation ID or carry private account/measure identifiers.
    expect(actions.single['correlation'], <String, dynamic>{});
  });

  testWidgets(
    'household constraints save, reopen, and clear on my taste page',
    (tester) async {
      final server = FakeServer();
      installProfile(server, () => profileFixture());
      var current = constraintsFixture();
      server.on('GET', constraintsPath, (_) => (200, current));
      server.on('PUT', constraintsPath, (request) {
        final values = Map<String, dynamic>.from(request.body as Map);
        current = constraintsFixture(values: values.isEmpty ? null : values);
        return (200, current);
      });
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await openTaste(tester);
      final edit = find.byKey(const ValueKey('cooking-constraints-edit'));
      await tester.scrollUntilVisible(edit, 450);
      await tapVisible(tester, edit);
      await tester.enterText(
        find.byKey(const ValueKey('household-servings')),
        '4',
      );
      await tester.tap(find.byKey(const ValueKey('equipment-wok')));
      await tester.enterText(
        find.byKey(const ValueKey('meal-minutes-weekday-dinner')),
        '30',
      );
      await tester.enterText(
        find.byKey(const ValueKey('meal-template-weekday-dinner')),
        '荤菜,素菜,汤',
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('cooking-constraints-save')),
      );
      expect(server.calls('PUT', constraintsPath), hasLength(1));
      final saved = server.calls('PUT', constraintsPath).single.body as Map;
      expect(saved['household_servings'], 4);
      expect(saved['equipment'], ['wok']);
      expect(saved['meal_times'], [
        {'day_type': 'weekday', 'meal': 'dinner', 'minutes': 30},
      ]);
      expect(saved['meal_templates'], [
        {
          'day_type': 'weekday',
          'meal': 'dinner',
          'dish_count': 3,
          'composition': ['meat', 'vegetable', 'soup'],
        },
      ]);
      expect(find.text('家庭默认：4 人'), findsOneWidget);
      await goBack(tester);
      await tester.tap(find.byKey(const ValueKey('taste-profile-entry')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(edit, 450);
      expect(find.text('家庭默认：4 人'), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('cooking-constraints-clear')),
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('cooking-constraints-clear-confirm')),
      );
      expect(jsonEncode(server.calls('PUT', constraintsPath).last.body), '{}');
      expect(find.text('人数未设置，菜谱沿用作者份数'), findsOneWidget);
      final actions = server
          .calls('POST', '/v1/sync/writes')
          .expand(
            (request) => ((request.body as Map)['writes'] as List).cast<Map>(),
          )
          .map((write) {
            expect(write['write_type'], 'experience.event');
            expect(write['owner_id'], server.user.id);
            return write['payload'] as Map;
          })
          .where((event) => event['event_type'] == 'ui.component_action')
          .toList();
      expect(actions.map((event) => event['content']).toList(), [
        {
          'component_id': 'cooking-constraints',
          'intent': 'cooking_constraints_edit',
        },
        {
          'component_id': 'cooking-constraints',
          'intent': 'cooking_constraints_save',
        },
        {
          'component_id': 'cooking-constraints',
          'intent': 'cooking_constraints_clear',
        },
        {
          'component_id': 'cooking-constraints',
          'intent': 'cooking_constraints_confirm_clear',
        },
      ]);
      for (final action in actions) {
        expect(action['correlation'], <String, dynamic>{});
      }
    },
  );
}
