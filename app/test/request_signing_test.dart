import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/api/api_client.dart';
import 'package:gram_tree/app/router.dart';
import 'package:gram_tree/recipes/recipe_repository.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';
import 'sharing_support.dart';

// Independent API-side verifier. It accepts the bytes actually delivered by Dio,
// not RequestSigner helpers, and rejects a wrong digest, escaping or reused nonce.
class _SignedServer extends FakeServer {
  _SignedServer(this.expectedEscapedQuery, this.path, this.expectedEscapedPath);
  final String expectedEscapedQuery;
  final String path;
  final String expectedEscapedPath;
  final _nonces = <String>{};

  static String quote(String value) =>
      Uri.encodeComponent(value)
          .replaceAll('%2F', '/')
          .replaceAll('%3D', '=')
          .replaceAll('%26', '&');

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.uri.path == Uri.parse(path).path) {
      final timestamp =
          options.headers['X-Request-Timestamp']?.toString() ?? '';
      final nonce = options.headers['X-Request-Nonce']?.toString() ?? '';
      final signature =
          options.headers['X-Request-Signature']?.toString() ?? '';
      final body = options.data;
      final bytes = body == null
          ? <int>[]
          : body is List<int>
          ? body
          : utf8.encode(body.toString());
      final digest = (await Sha256().hash(bytes)).bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      final query = quote(options.uri.query);
      final escapedPath = quote(options.uri.path);
      final message =
          '${options.method.toUpperCase()}\n$escapedPath\n$query\n$timestamp\n${quote(nonce)}\n$digest';
      final mac = await Hmac.sha256().calculateMac(
        utf8.encode(message),
        secretKey: SecretKey(utf8.encode('test-signing-key-0')),
      );
      final expected = mac.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      if (escapedPath != expectedEscapedPath ||
          query != expectedEscapedQuery ||
          timestamp.isEmpty ||
          int.tryParse(timestamp) == null ||
          nonce.isEmpty ||
          !_nonces.add(nonce) ||
          signature != expected ||
          (options.method == 'POST' && utf8.decode(bytes) != '{"value":1}')) {
        handler.reject(
          DioException.badResponse(
            statusCode: 401,
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 401,
              data: {
                'error': {'code': 'signature_invalid', 'message': '签名无效'},
              },
            ),
          ),
          true,
        );
        return;
      }
    }
    await super.onRequest(options, handler);
  }
}

/// Page-facing API fixture supplies the raw query/body used by a real request.
/// Authentication, signing, consent and Dio transformation stay production code.
class _ProbeRecipeApi extends RecipeRepository {
  _ProbeRecipeApi(this.dio, this.query, this.method, this.path)
    : super(GramtreeApi(dio: dio, interceptors: const []));
  final Dio dio;
  final String query;
  final String method;
  final String path;
  @override
  Future<RecipeList> listPage({String? cursor}) async {
    final response = await dio.request<Map<String, dynamic>>(
      '$path?$query',
      data: method == 'POST' ? '{"value":1}' : null,
      options: Options(method: method),
    );
    return RecipeList.fromJson(response.data!);
  }
}

class _SigningEnv extends TestEnv {
  _SigningEnv({
    required this.query,
    required String escapedQuery,
    this.method = 'GET',
    this.path = '/v1/signing-probe',
    String escapedPath = '/v1/signing-probe',
  }) : super(server: _SignedServer(escapedQuery, path, escapedPath)) {
    local.values.addAll(consentedStore());
    secure.values.addAll(signedInSecure(testUser()));
    final detail = sharedDetail();
    server.on(
      'GET',
      Uri.parse(path).path,
      (_) => (
        200,
        RecipeList(
          items: [
            RecipeListItem(
              id: detail.id,
              dish: detail.dish,
              visibility: RecipeListItemVisibilityEnum.private,
              versionNumber: 1,
              servings: detail.version.snapshot.servings,
              updatedAt: detail.updatedAt,
              totalTimeSeconds: 0,
              activeTimeSeconds: 0,
            ),
          ],
          nextCursor: 'next',
        ).toJson(),
      ),
    );
    server.on(
      'POST',
      Uri.parse(path).path,
      (_) => (
        200,
        RecipeList(
          items: [
            RecipeListItem(
              id: detail.id,
              dish: detail.dish,
              visibility: RecipeListItemVisibilityEnum.private,
              versionNumber: 1,
              servings: detail.version.snapshot.servings,
              updatedAt: detail.updatedAt,
              totalTimeSeconds: 0,
              activeTimeSeconds: 0,
            ),
          ],
          nextCursor: 'next',
        ).toJson(),
      ),
    );
  }
  final String query;
  final String method;
  final String path;
  @override
  List<Override> get overrides => [
    ...super.overrides,
    recipeRepositoryProvider.overrideWith(
      (ref) => _ProbeRecipeApi(ref.watch(dioProvider), query, method, path),
    ),
  ];
}

Future<void> _openList(WidgetTester tester, _SigningEnv env) async {
  await pumpApp(tester, env: env);
  final container = ProviderScope.containerOf(
    tester.element(find.byType(Scaffold).first),
  );
  container.read(routerProvider).go('/recipes');
  await tester.pumpAndSettle();
  expect(
    find.byKey(ValueKey('recipe-card-${sharedDetail().id}')),
    findsOneWidget,
  );
  expect(find.text('菜谱暂时加载不了'), findsNothing);
}

void main() {
  testWidgets('Unicode wire paths retain independent UTF-8 escaping coverage', (
    tester,
  ) async {
    await _openList(
      tester,
      _SigningEnv(
        query: 'q=a%20b&x=1',
        escapedQuery: 'q=a%2520b&x=1',
        path: '/v1/signing-probe/菜谱',
        escapedPath: '/v1/signing-probe/%25E8%258F%259C%25E8%25B0%25B1',
      ),
    );
  });

  testWidgets(
    'canonical bytes keep raw query and match server field escaping',
    (tester) async {
      await _openList(
        tester,
        _SigningEnv(query: 'q=a%20b&x=1', escapedQuery: 'q=a%2520b&x=1'),
      );
    },
  );

  testWidgets(
    'canonical fields percent-encode literal percent to avoid collisions',
    (tester) async {
      await _openList(
        tester,
        _SigningEnv(query: 'q=a+b', escapedQuery: 'q=a%2Bb'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await _openList(
        tester,
        _SigningEnv(query: 'q=a%2Bb', escapedQuery: 'q=a%252Bb'),
      );
    },
  );

  testWidgets(
    'signing adds a fresh nonce and an HMAC over the exact request body',
    (tester) async {
      final env = _SigningEnv(query: '', escapedQuery: '', method: 'POST');
      await _openList(tester, env);
      await tester.tap(find.byKey(const ValueKey('recipe-load-more')));
      await tester.pumpAndSettle();
      // The verifier rejects reused nonce or a nonmatching wire-body HMAC. Both
      // page loads succeeded; no direct signer calls or private state assertions.
      expect(
        find.byKey(ValueKey('recipe-card-${sharedDetail().id}')),
        findsNWidgets(2),
      );
      expect(find.text('加载失败，重试'), findsNothing);
    },
  );
}
