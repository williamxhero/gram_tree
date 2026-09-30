import 'package:test/test.dart';
import 'package:gramtree_api/gramtree_api.dart';

// tests for RejectionReason
void main() {
  final instance = RejectionReasonBuilder();
  // TODO add properties to the builder and call build()

  group(RejectionReason, () {
    // 程序可判断的拒收原因代码：unknown_event_type / unsupported_version / invalid_content / invalid_correlation_id
    // String code
    test('to test the property `code`', () async {
      // TODO
    });

    // 给人看的一句话说明，不包含事件内容本身
    // String message
    test('to test the property `message`', () async {
      // TODO
    });

  });
}
