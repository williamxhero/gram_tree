import 'package:test/test.dart';
import 'package:gramtree_api/gramtree_api.dart';

// tests for ComposeRequest
void main() {
  final instance = ComposeRequestBuilder();
  // TODO add properties to the builder and call build()

  group(ComposeRequest, () {
    // 要哪个页面类型的组合，例如 today
    // String pageType
    test('to test the property `pageType`', () async {
      // TODO
    });

    // App 自己实现的协议版本，例如 1.0
    // String protocolVersion
    test('to test the property `protocolVersion`', () async {
      // TODO
    });

    // App 已登记、认识的组件类型清单；服务端只会下发这里面的类型
    // BuiltList<String> supportedComponents
    test('to test the property `supportedComponents`', () async {
      // TODO
    });

  });
}
