import 'package:test/test.dart';
import 'package:gramtree_api/gramtree_api.dart';


/// tests for ExamplesApi
void main() {
  final instance = GramtreeApi().getExamplesApi();

  group(ExamplesApi, () {
    // 故意抛出未处理异常，用来测试统一错误格式
    //
    //Future<JsonObject> boom() async
    test('test boom', () async {
      // TODO
    });

    // 读取一条示例
    //
    //Future<SampleOut> getSample(String sampleId) async
    test('test getSample', () async {
      // TODO
    });

    // 示例后台任务写下的记录（最近 20 条）
    //
    //Future<BuiltList<HeartbeatOut>> listHeartbeats() async
    test('test listHeartbeats', () async {
      // TODO
    });

    // 示例列表（游标分页，新的在前）
    //
    //Future<PageSampleOut> listSamples({ String cursor, int limit }) async
    test('test listSamples', () async {
      // TODO
    });

    // 创建示例（同一个 ID 重复提交返回已有记录）
    //
    //Future<SampleOut> putSample(SampleCreate sampleCreate) async
    test('test putSample', () async {
      // TODO
    });

    // 触发示例后台任务
    //
    //Future<TaskAccepted> triggerHeartbeat() async
    test('test triggerHeartbeat', () async {
      // TODO
    });

  });
}
