/// 网页版没有本地文件系统持久化能力（drift 只在手机端真正落盘，按 CLAUDE.md 的
/// 约定网页端用替身），这里是空实现：跑起来直接通过，不代表验证过持久化。
/// 真正的验证在安卓模拟器上（见 event_queue_persistence_check_mobile.dart）。
Future<void> checkEventQueueSurvivesRestart() async {}
