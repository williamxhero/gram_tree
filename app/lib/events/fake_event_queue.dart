import 'event_queue.dart';

/// 测试和网页替身用：存在内存里，进程结束（或测试结束）就丢。
class FakeEventQueue implements EventQueue {
  final List<QueuedEvent> _items = [];

  /// 测试断言用：当前队列里还有什么，不保证顺序。
  List<QueuedEvent> get items => List.unmodifiable(_items);

  @override
  Future<void> enqueue(QueuedEvent event) async {
    _items.removeWhere((e) => e.id == event.id);
    _items.add(event);
  }

  @override
  Future<List<QueuedEvent>> pending({int? limit}) async {
    final sorted = [..._items]
      ..sort((a, b) => a.deviceTime.compareTo(b.deviceTime));
    return limit == null ? sorted : sorted.take(limit).toList();
  }

  @override
  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> removeAll(Iterable<String> ids) async {
    final idSet = ids.toSet();
    _items.removeWhere((e) => idSet.contains(e.id));
  }

  @override
  Future<void> close() async {}
}
