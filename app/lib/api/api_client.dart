import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../config/app_config.dart';

/// 由服务端 OpenAPI 描述生成的接口客户端（packages/gramtree_api，不要手改）。
/// 服务端接口变了就运行 tool/gen_api_client.sh 重新生成。
final apiClientProvider = Provider<GramtreeApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  return GramtreeApi(dio: dio);
});
