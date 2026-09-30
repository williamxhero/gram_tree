import 'package:test/test.dart';
import 'package:gramtree_api/gramtree_api.dart';


/// tests for HealthApi
void main() {
  final instance = GramtreeApi().getHealthApi();

  group(HealthApi, () {
    // 健康检查：服务、数据库、Redis 是否可用
    //
    //Future<HealthResponse> health() async
    test('test health', () async {
      // TODO
    });

  });
}
