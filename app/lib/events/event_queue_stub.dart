import 'event_queue.dart';
import 'fake_event_queue.dart';
import 'write_registry.dart';

/// 既没有 dart:io 也没有 dart:js_interop 的平台兜底（正常不会用到）。
EventQueue createEventQueue({WriteRegistry? registry}) =>
    FakeEventQueue(registry: registry);
