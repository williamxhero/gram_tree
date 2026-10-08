import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'event_queue_persistence_check_stub.dart'
    if (dart.library.io) 'event_queue_persistence_check_mobile.dart';

/// drift 落盘队列的数据库连接重建回归；不代表真实 OS 杀进程验收。
///
/// 手机专有能力（本地数据库），按 CLAUDE.md 的约定放在接口后面：这里用条件导入选
/// 手机端真实实现或网页端空实现，跟 lib/events/event_queue.dart 是同一套模式。
///
/// 在哪跑（见 CLAUDE.md 测试一节第 4 层）：
/// * 安卓模拟器（CI 的 `android-e2e`）：真正验证 drift 落盘和重开后还在。
/// * 网页版（`tool/web_test.sh`）：编译到的是空实现，跑起来直接通过，不代表验证过。
/// * 云端开发线程没有 KVM，跑不了安卓模拟器，这个用例本身也没法在这里验证；
///   逻辑已经用真实 sqlite（drift + NativeDatabase 指向临时文件）在 `flutter test`
///   的 VM 模式下手动验证过，跟这里的实现是同一份代码。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('关闭重开数据库连接后，账号归属待同步内容仍在并按入队顺序排列', (tester) async {
    await checkEventQueueSurvivesRestart();
  });
}
