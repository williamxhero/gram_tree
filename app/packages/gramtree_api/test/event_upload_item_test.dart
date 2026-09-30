import 'package:test/test.dart';
import 'package:gramtree_api/gramtree_api.dart';

// tests for EventUploadItem
void main() {
  final instance = EventUploadItemBuilder();
  // TODO add properties to the builder and call build()

  group(EventUploadItem, () {
    // 客户端生成的事件 ID（UUID v4），全局唯一，按它去重
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // String eventType
    test('to test the property `eventType`', () async {
      // TODO
    });

    // 事件类型的版本号
    // int typeVersion
    test('to test the property `typeVersion`', () async {
      // TODO
    });

    // String deviceId
    test('to test the property `deviceId`', () async {
      // TODO
    });

    // 设备本地时间，必须带时区
    // DateTime deviceTime
    test('to test the property `deviceTime`', () async {
      // TODO
    });

    // String appVersion
    test('to test the property `appVersion`', () async {
      // TODO
    });

    // EventCorrelationIds correlation
    test('to test the property `correlation`', () async {
      // TODO
    });

    // 事件内容。用户 ID 只按登录状态填入，这里出现的任何 user_id 字段都不采信
    // BuiltMap<String, JsonObject> content
    test('to test the property `content`', () async {
      // TODO
    });

  });
}
