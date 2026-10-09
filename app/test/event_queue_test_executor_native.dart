import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'event_queue_test_executor.dart';

Future<QueueTestDatabase> create() async => _NativeQueueTestDatabase(
  await Directory.systemTemp.createTemp('queue-test-'),
);

class _NativeQueueTestDatabase implements QueueTestDatabase {
  _NativeQueueTestDatabase(this.directory);
  final Directory directory;

  @override
  QueryExecutor open() =>
      NativeDatabase(File('${directory.path}/queue.sqlite'));

  @override
  Future<void> dispose() => directory.delete(recursive: true);
}
