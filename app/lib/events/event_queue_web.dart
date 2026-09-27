import 'event_queue.dart';
import 'fake_event_queue.dart';

/// 网页版：本地数据库用内存替身代替（按项目约定，drift 只在手机端真正落盘；
/// 网页版只是测试目标，重开页面本来就会丢状态）。
EventQueue createEventQueue() => FakeEventQueue();
