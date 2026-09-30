import 'package:test/test.dart';
import 'package:gramtree_api/gramtree_api.dart';


/// tests for UiProtocolApi
void main() {
  final instance = GramtreeApi().getUiProtocolApi();

  group(UiProtocolApi, () {
    // 按 App 声明的协议版本和组件清单，下发一份页面描述（需要登录）
    //
    //Future<PageDescription> compose(ComposeRequest composeRequest) async
    test('test compose', () async {
      // TODO
    });

    // \"这次不用\"：返回去掉这条来源调整后的结果，只影响这次查看，不写口味档案（需要登录）
    //
    //Future<SkipAdjustmentResult> skipAdjustment(SkipAdjustmentRequest skipAdjustmentRequest) async
    test('test skipAdjustment', () async {
      // TODO
    });

  });
}
