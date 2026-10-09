import 'package:drift/drift.dart';

import 'event_queue_test_executor_stub.dart'
    if (dart.library.io) 'event_queue_test_executor_native.dart'
    as platform;

/// Only the native persistence regression opens SQLite; page tests stay web-safe.
abstract class QueueTestDatabase {
  QueryExecutor open();
  Future<void> dispose();
}

Future<QueueTestDatabase> createQueueTestDatabase() => platform.create();
