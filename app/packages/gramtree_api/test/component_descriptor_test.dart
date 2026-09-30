import 'package:test/test.dart';
import 'package:gramtree_api/gramtree_api.dart';

// tests for ComponentDescriptor
void main() {
  final instance = ComponentDescriptorBuilder();
  // TODO add properties to the builder and call build()

  group(ComponentDescriptor, () {
    // 组件类型名，必须是 App 声明支持的组件
    // String type
    test('to test the property `type`', () async {
      // TODO
    });

    // 这份描述里的组件实例 ID
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // String detail
    test('to test the property `detail`', () async {
      // TODO
    });

    // 组件数据，形状由该 type 的组件 Schema 定义
    // BuiltMap<String, JsonObject> data
    test('to test the property `data`', () async {
      // TODO
    });

    // BuiltList<ActionDescriptor> actions
    test('to test the property `actions`', () async {
      // TODO
    });

    // ComponentReason reason
    test('to test the property `reason`', () async {
      // TODO
    });

    // 是否是必显组件
    // bool required_ (default value: false)
    test('to test the property `required_`', () async {
      // TODO
    });

  });
}
