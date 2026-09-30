import 'package:test/test.dart';
import 'package:gramtree_api/gramtree_api.dart';


/// tests for ConfigApi
void main() {
  final instance = GramtreeApi().getConfigApi();

  group(ConfigApi, () {
    // App 用的能力开关和参数
    //
    //Future<ClientConfig> clientConfig() async
    test('test clientConfig', () async {
      // TODO
    });

  });
}
