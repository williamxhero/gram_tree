import 'package:test/test.dart';
import 'package:gramtree_api/gramtree_api.dart';


/// tests for EventsApi
void main() {
  final instance = GramtreeApi().getEventsApi();

  group(EventsApi, () {
    // 批量上传经验层事件（需要登录，按登记表校验，按事件 ID 去重，只追加存储）
    //
    //Future<EventUploadResponse> uploadEvents(EventUploadRequest eventUploadRequest) async
    test('test uploadEvents', () async {
      // TODO
    });

  });
}
