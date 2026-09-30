import 'package:test/test.dart';
import 'package:gramtree_api/gramtree_api.dart';


/// tests for AnalyticsApi
void main() {
  final instance = GramtreeApi().getAnalyticsApi();

  group(AnalyticsApi, () {
    // 上传产品埋点（页面访问 / 入口点击 / 加载耗时）
    //
    // 同意隐私政策前、或关闭“产品改进统计”开关后，客户端不应调用这个接口。服务端只按登记好的字段接收，多余字段一律拒收；不接受第三方分析服务转发。
    //
    //Future uploadAnalyticsEvents(AnalyticsUploadRequest analyticsUploadRequest) async
    test('test uploadAnalyticsEvents', () async {
      // TODO
    });

  });
}
