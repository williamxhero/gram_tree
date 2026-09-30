import 'package:test/test.dart';
import 'package:gramtree_api/gramtree_api.dart';

// tests for EventUploadResultItem
void main() {
  final instance = EventUploadResultItemBuilder();
  // TODO add properties to the builder and call build()

  group(EventUploadResultItem, () {
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // accepted：已接收入库；duplicate：这个 ID 之前已经收到过，原记录未改动；rejected：没通过登记表校验，未入库，见 reason
    // String status
    test('to test the property `status`', () async {
      // TODO
    });

    // RejectionReason reason
    test('to test the property `reason`', () async {
      // TODO
    });

  });
}
