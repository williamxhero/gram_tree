import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/api/api_client.dart';
import 'package:gram_tree/recipes/recipe_draft.dart';
import 'package:gram_tree/recipes/recipe_repository.dart';
import 'package:gram_tree/storage/local_store.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';
import 'login_test.dart' show enterEmail, enterCode;
import 'settings_test.dart' show openSettings;
import 'offline_recipe_editor_test.dart' show navigate;
import 'recipe_snapshot_test.dart' show recipeSnapshotFixture;

void main() {
  for (final operation in ['logout', 'withdrawal', 'deletion']) {
    testWidgets('$operation 对未保存菜谱草稿遵守保留与注销清理区别', (tester) async {
      final env = await pumpApp(tester);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('primary-create-button')),
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('create-recipe-entry')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('recipe-dish-name')),
        '账号私有草稿菜',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await goBack(tester);
      await openSettings(tester);
      if (operation == 'logout') {
        await tapVisible(tester, find.text('退出登录'));
        await tapVisible(tester, find.widgetWithText(FilledButton, '退出登录'));
      } else if (operation == 'withdrawal') {
        await tapVisible(tester, find.text('撤回同意'));
        await tapVisible(tester, find.text('撤回并退出'));
        await tapVisible(tester, find.byKey(const ValueKey('consent-agree')));
      } else {
        await tapVisible(tester, find.text('注销账号'));
        await tapVisible(tester, find.text('发送验证码'));
        await tester.enterText(
          find.byKey(const ValueKey('code-input')),
          goodCode,
        );
        await tester.pumpAndSettle();
        await tapVisible(tester, find.byKey(const ValueKey('delete-check')));
        await tapVisible(tester, find.byKey(const ValueKey('delete-confirm')));
      }
      // Only the fake identity boundary permits reentering a deleted owner so
      // the editor can demonstrate that its old local content was erased.
      await enterEmail(tester, testEmail);
      await enterCode(tester, goodCode);
      await restartApp(tester, env);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('primary-create-button')),
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('create-recipe-entry')),
      );
      if (operation == 'deletion') {
        expect(find.text('恢复未保存修改？'), findsNothing);
        expect(find.text('账号私有草稿菜'), findsNothing);
      } else {
        expect(find.text('恢复未保存修改？'), findsOneWidget);
        await tapVisible(tester, find.text('恢复'));
        expect(find.text('账号私有草稿菜'), findsOneWidget);
      }
    });
  }

  testWidgets('成功注销等待旧草稿写入并清理所有基线，迟到旧编辑器不能复活且保留其他账号', (tester) async {
    final local = _DelayedDraftStore(consentedStore());
    addTearDown(() {
      if (!local.release.isCompleted) local.release.complete();
    });
    final env = TestEnv.signedIn(local: local);
    final alice = env.server.user;
    const bobId = 'd54b2956-2f93-4ea9-a1d4-7701d258ae45';
    const firstRecipe = 'eeeeeeee-eeee-4eee-8eee-000000000001';
    const secondRecipe = 'eeeeeeee-eeee-4eee-8eee-000000000002';
    const firstVersion = 'ffffffff-ffff-4fff-8fff-000000000001';
    const secondVersion = 'ffffffff-ffff-4fff-8fff-000000000002';
    final oldHandle = RecipeDraftStore(local);
    RecipeDraft draft(String owner, String recipe, String version) {
      final detail = recipeSnapshotFixture(version, recipe: recipe).copyWith(
        author: RecipeAuthor(id: owner, nickname: '作者'),
      );
      return RecipeDraft(
        accountId: owner,
        recipeKey: recipe,
        baselineVersionId: version,
        baselineDetail: detail.toJson(),
        payload: RecipeForm.fromSnapshot(
          detail.version.snapshot,
          '已注销账号私有基线草稿',
        ).toDraft(),
      );
    }

    for (final item in [
      (firstRecipe, firstVersion),
      (firstRecipe, secondVersion),
      (secondRecipe, firstVersion),
    ]) {
      await oldHandle.save(draft(alice.id, item.$1, item.$2));
    }
    await RecipeDraftStore(local).save(
      RecipeDraft(
        accountId: bobId,
        recipeKey: 'new',
        baselineVersionId: null,
        payload: RecipeForm(dishName: '其他账号草稿').toDraft(),
      ),
    );
    await pumpApp(tester, env: env);
    local.hold = true;
    await tapVisible(
      tester,
      find.byKey(const ValueKey('primary-create-button')),
    );
    await tapVisible(tester, find.byKey(const ValueKey('create-recipe-entry')));
    await tester.enterText(
      find.byKey(const ValueKey('recipe-dish-name')),
      '在途未保存私有菜',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await local.started.future;
    await goBack(tester);
    await openSettings(tester);
    await tapVisible(tester, find.text('注销账号'));
    await tapVisible(tester, find.text('发送验证码'));
    await tester.enterText(find.byKey(const ValueKey('code-input')), goodCode);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('delete-check')));
    await tester.tap(find.byKey(const ValueKey('delete-confirm')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(env.server.calls('POST', '/v1/me/deletion'), hasLength(1));
    expect(find.text('登录味谱'), findsNothing);
    // Another pre-deletion editor handle attempts a late baseline+pointer save.
    final lateSave = oldHandle.save(draft(alice.id, firstRecipe, firstVersion));
    local.release.complete();
    await tester.pumpAndSettle();
    await lateSave;
    expect(find.text('登录味谱'), findsOneWidget);
    env.server.user = UserOut.fromJson({
      ...alice.toJson(),
      'id': bobId,
      'nickname': 'Bob',
    });
    await enterEmail(tester, testEmail);
    await enterCode(tester, goodCode);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('primary-create-button')),
    );
    await tapVisible(tester, find.byKey(const ValueKey('create-recipe-entry')));
    expect(find.text('恢复未保存修改？'), findsOneWidget);
    await tapVisible(tester, find.text('恢复'));
    expect(find.text('其他账号草稿'), findsOneWidget);
    await goBack(tester);
    await openSettings(tester);
    await tapVisible(tester, find.text('退出登录'));
    await tapVisible(tester, find.widgetWithText(FilledButton, '退出登录'));
    env.server.user = alice;
    await enterEmail(tester, testEmail);
    await enterCode(tester, goodCode);
    await restartApp(tester, env);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    container.read(offlineSimulationProvider.notifier).set(true);
    for (final route in [
      '/recipes/$firstRecipe/edit',
      '/recipes/$firstRecipe/edit?versionId=$firstVersion',
      '/recipes/$firstRecipe/edit?versionId=$secondVersion',
      '/recipes/$secondRecipe/edit',
      '/recipes/$secondRecipe/edit?versionId=$firstVersion',
    ]) {
      navigate(tester, route);
      await tester.pumpAndSettle();
      expect(find.text('菜谱暂时加载不了'), findsOneWidget);
      expect(find.text('恢复未保存修改？'), findsNothing);
      expect(find.text('已注销账号私有基线草稿'), findsNothing);
    }
    navigate(tester, '/recipes/new');
    await tester.pumpAndSettle();
    expect(find.text('恢复未保存修改？'), findsNothing);
    expect(find.text('在途未保存私有菜'), findsNothing);
  });

  testWidgets('unsaved editor draft recovers after app restart', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('primary-create-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create-recipe-entry')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('recipe-dish-name')),
      '重启后仍在的菜',
    );
    await tester.pump(const Duration(milliseconds: 400));

    await restartApp(tester, env);
    await tester.tap(find.byKey(const ValueKey('primary-create-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create-recipe-entry')));
    await tester.pumpAndSettle();

    expect(find.text('恢复未保存修改？'), findsOneWidget);
    await tester.tap(find.text('恢复'));
    await tester.pumpAndSettle();
    expect(find.text('重启后仍在的菜'), findsOneWidget);
  });

  testWidgets('discarding an editor draft prevents a later restore', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('primary-create-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create-recipe-entry')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('recipe-dish-name')),
      '放弃的菜',
    );
    await tester.pump(const Duration(milliseconds: 400));

    await tapVisible(
      tester,
      find.byKey(const ValueKey('discard-recipe-draft')),
    );
    await tester.tap(find.byKey(const ValueKey('primary-create-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create-recipe-entry')));
    await tester.pumpAndSettle();

    expect(find.text('恢复未保存修改？'), findsNothing);
  });
}

class _DelayedDraftStore extends MemoryLocalStore {
  _DelayedDraftStore(super.values);
  bool hold = false;
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> setString(String key, String value) async {
    if (hold && key.startsWith(RecipeDraftStore.keyPrefix)) {
      started.complete();
      await release.future;
      hold = false;
    }
    await super.setString(key, value);
  }
}
