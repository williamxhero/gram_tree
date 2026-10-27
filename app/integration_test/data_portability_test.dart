import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:integration_test/integration_test.dart';

import 'event_pipeline_support.dart';

/// Real HTTP, isolated PostgreSQL/Redis and the production background drain.
/// Web verifies the download boundary; Android instrumentation verifies saving.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('本人异步导出、登录下载、他人隔离、单条删除和注销', (tester) async {
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);
    final actor = await signInFreshUser(tester);
    final container = containerOf(tester);
    final token = accessTokenOf(container);
    final auth = Options(headers: {'Authorization': 'Bearer $token'});
    final record = (await devServer.post<Map<String, dynamic>>(
      '/v1/records',
      options: auth,
      data: {
        'client_id': 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
        'dish_name': '只属于本人的导出记录',
        'source': 'external_cooking',
        'verification': 'unverified',
        'snapshot': {'format_version': 1, 'dish_name': '只属于本人的导出记录'},
        'adjustments': [
          {'text': '少盐'},
        ],
        'source_context': {'entry': 'manual'},
      },
    )).data!;
    await tapText(tester, '我的');
    await waitFor(tester, find.text('设置'));
    await tapText(tester, '设置');
    await tapPortabilitySettingsItem(tester, '导出我的数据');
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(const ValueKey('export-start')),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );
    await tapText(tester, '发送验证码');
    await waitFor(tester, find.byKey(const ValueKey('code-input')));
    await tester.enterText(
      find.byKey(const ValueKey('code-input')),
      await latestEmailCode(actor.email),
    );
    await waitFor(tester, find.text('已重新验证身份。后台打包，不必停留在本页。'));
    await tapText(tester, '发起导出');
    // A persistent task is processed outside the HTTP request by the real worker.
    await waitUntil(
      tester,
      () => find.text('下载并保存 ZIP').evaluate().isNotEmpty,
      tries: 300,
      step: const Duration(milliseconds: 200),
    );
    if (kIsWeb) {
      await tapText(tester, '下载并保存 ZIP');
      await waitFor(tester, find.text('ZIP 已下载（网页测试替身，不保存到磁盘）'));
    } // Native save is asserted by the separate Android DocumentsUI test.
    final jobs =
        (await devServer.get<Map<String, dynamic>>(
              '/v1/me/exports',
              options: auth,
            )).data!['items']
            as List;
    expect(jobs, hasLength(1));
    final job = jobs.single as Map;
    expect(job['status'], 'completed');
    final url = job['download_url'] as String;
    expect(Uri.parse(url).hasAuthority, isFalse);
    final zip = await devServer.get<List<int>>(
      url,
      options: Options(headers: auth.headers, responseType: ResponseType.bytes),
    );
    expect(zip.data!.take(4), [80, 75, 3, 4]);
    final expires = DateTime.parse(job['expires_at'] as String);
    final completed = DateTime.parse(job['completed_at'] as String);
    expect(expires.difference(completed), const Duration(hours: 24));
    final unauthenticated = await devServer.get<Object>(
      url,
      options: Options(validateStatus: (_) => true),
    );
    expect(unauthenticated.statusCode, 401);

    final foreignEmail =
        'e2e-portability-foreign-${DateTime.now().microsecondsSinceEpoch}@example.com';
    await devServer.post<Object>(
      '/v1/auth/email/code',
      data: {'email': foreignEmail, 'purpose': 'login'},
    );
    final foreign = (await devServer.post<Map<String, dynamic>>(
      '/v1/auth/email/login',
      data: {
        'email': foreignEmail,
        'code': await latestEmailCode(foreignEmail),
      },
    )).data!;
    final foreignAuth = Options(
      headers: {'Authorization': 'Bearer ${foreign['access_token']}'},
      validateStatus: (_) => true,
    );
    expect(
      (await devServer.get<Object>(url, options: foreignAuth)).statusCode,
      404,
    );
    expect(
      (await devServer.delete<Object>(
        '/v1/records/${record['id']}',
        options: foreignAuth,
      )).statusCode,
      404,
    );
    expect(
      (await devServer.get<Object>(
        '/v1/records/${record['id']}',
        options: auth,
      )).statusCode,
      200,
    );

    // UI cancellation makes no deletion; the explicit confirmation deletes only
    // the selected owner's record, and the foreign user's history is unaffected.
    await tester.tap(find.byTooltip('返回').last);
    await settle(tester);
    await tester.tap(find.byTooltip('返回').last);
    await settle(tester);
    await tapText(tester, '记录');
    await waitFor(tester, find.text('只属于本人的导出记录'));
    final recordCard = find.byKey(ValueKey('record-${record['id']}'));
    await waitUntil(tester, () => recordCard.evaluate().isNotEmpty);
    final recordJson = (await devServer.get<Map<String, dynamic>>(
      '/v1/records/${record['id']}',
      options: auth,
    )).data!;
    expect(recordJson['id'], record['id']);
    final deleteButton = find.byKey(ValueKey('record-delete-${record['id']}'));
    await waitUntil(
      tester,
      () =>
          deleteButton.evaluate().isNotEmpty &&
          tester.widget<IconButton>(deleteButton).onPressed != null,
    );
    await tester.tap(deleteButton);
    await settle(tester);
    await tapText(tester, '取消');
    expect(
      (await devServer.get<Object>(
        '/v1/records/${record['id']}',
        options: auth,
      )).statusCode,
      200,
    );
    await waitUntil(
      tester,
      () =>
          deleteButton.evaluate().isNotEmpty &&
          tester.widget<IconButton>(deleteButton).onPressed != null,
    );
    await tester.tap(deleteButton);
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('record-delete-confirm')));
    await waitFor(tester, find.text('还没有做菜记录'));
    expect(
      (await devServer.get<Object>(
        '/v1/records/${record['id']}',
        options: Options(headers: auth.headers, validateStatus: (_) => true),
      )).statusCode,
      404,
    );

    await tapText(tester, '我的');
    await tapText(tester, '设置');
    await tapPortabilitySettingsItem(tester, '注销账号');
    await tapText(tester, '发送验证码');
    await waitFor(tester, find.byKey(const ValueKey('code-input')));
    await tester.enterText(
      find.byKey(const ValueKey('code-input')),
      await latestEmailCode(actor.email),
    );
    await waitFor(tester, find.text('先导出我的数据'));
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('delete-confirm')))
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('delete-check')));
    await tester.tap(find.byKey(const ValueKey('delete-check')));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('delete-confirm')));
    await tester.tap(find.byKey(const ValueKey('delete-confirm')));
    await waitFor(tester, find.text('登录味谱'));
    expect(container.read(sessionStoreProvider).current, isNull);
    expect(
      (await devServer.get<Object>(
        url,
        options: Options(headers: auth.headers, validateStatus: (_) => true),
      )).statusCode,
      401,
    );
    expect(
      (await devServer.get<Object>('/v1/me', options: foreignAuth)).statusCode,
      200,
    );
  });
}
