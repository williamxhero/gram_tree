// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_queue_mobile.dart';

// ignore_for_file: type=lint
class $QueuedEventsTable extends QueuedEvents
    with TableInfo<$QueuedEventsTable, QueuedEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueuedEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeVersionMeta = const VerificationMeta(
    'typeVersion',
  );
  @override
  late final GeneratedColumn<int> typeVersion = GeneratedColumn<int>(
    'type_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceTimeMeta = const VerificationMeta(
    'deviceTime',
  );
  @override
  late final GeneratedColumn<DateTime> deviceTime = GeneratedColumn<DateTime>(
    'device_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appVersionMeta = const VerificationMeta(
    'appVersion',
  );
  @override
  late final GeneratedColumn<String> appVersion = GeneratedColumn<String>(
    'app_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correlationJsonMeta = const VerificationMeta(
    'correlationJson',
  );
  @override
  late final GeneratedColumn<String> correlationJson = GeneratedColumn<String>(
    'correlation_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentJsonMeta = const VerificationMeta(
    'contentJson',
  );
  @override
  late final GeneratedColumn<String> contentJson = GeneratedColumn<String>(
    'content_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventType,
    typeVersion,
    deviceId,
    deviceTime,
    appVersion,
    correlationJson,
    contentJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queued_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueuedEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('type_version')) {
      context.handle(
        _typeVersionMeta,
        typeVersion.isAcceptableOrUnknown(
          data['type_version']!,
          _typeVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_typeVersionMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('device_time')) {
      context.handle(
        _deviceTimeMeta,
        deviceTime.isAcceptableOrUnknown(data['device_time']!, _deviceTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceTimeMeta);
    }
    if (data.containsKey('app_version')) {
      context.handle(
        _appVersionMeta,
        appVersion.isAcceptableOrUnknown(data['app_version']!, _appVersionMeta),
      );
    } else if (isInserting) {
      context.missing(_appVersionMeta);
    }
    if (data.containsKey('correlation_json')) {
      context.handle(
        _correlationJsonMeta,
        correlationJson.isAcceptableOrUnknown(
          data['correlation_json']!,
          _correlationJsonMeta,
        ),
      );
    }
    if (data.containsKey('content_json')) {
      context.handle(
        _contentJsonMeta,
        contentJson.isAcceptableOrUnknown(
          data['content_json']!,
          _contentJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QueuedEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueuedEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      typeVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type_version'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deviceTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}device_time'],
      )!,
      appVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_version'],
      )!,
      correlationJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correlation_json'],
      ),
      contentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_json'],
      ),
    );
  }

  @override
  $QueuedEventsTable createAlias(String alias) {
    return $QueuedEventsTable(attachedDatabase, alias);
  }
}

class QueuedEventRow extends DataClass implements Insertable<QueuedEventRow> {
  final String id;
  final String eventType;
  final int typeVersion;
  final String deviceId;
  final DateTime deviceTime;
  final String appVersion;
  final String? correlationJson;
  final String? contentJson;
  const QueuedEventRow({
    required this.id,
    required this.eventType,
    required this.typeVersion,
    required this.deviceId,
    required this.deviceTime,
    required this.appVersion,
    this.correlationJson,
    this.contentJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_type'] = Variable<String>(eventType);
    map['type_version'] = Variable<int>(typeVersion);
    map['device_id'] = Variable<String>(deviceId);
    map['device_time'] = Variable<DateTime>(deviceTime);
    map['app_version'] = Variable<String>(appVersion);
    if (!nullToAbsent || correlationJson != null) {
      map['correlation_json'] = Variable<String>(correlationJson);
    }
    if (!nullToAbsent || contentJson != null) {
      map['content_json'] = Variable<String>(contentJson);
    }
    return map;
  }

  QueuedEventsCompanion toCompanion(bool nullToAbsent) {
    return QueuedEventsCompanion(
      id: Value(id),
      eventType: Value(eventType),
      typeVersion: Value(typeVersion),
      deviceId: Value(deviceId),
      deviceTime: Value(deviceTime),
      appVersion: Value(appVersion),
      correlationJson: correlationJson == null && nullToAbsent
          ? const Value.absent()
          : Value(correlationJson),
      contentJson: contentJson == null && nullToAbsent
          ? const Value.absent()
          : Value(contentJson),
    );
  }

  factory QueuedEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueuedEventRow(
      id: serializer.fromJson<String>(json['id']),
      eventType: serializer.fromJson<String>(json['eventType']),
      typeVersion: serializer.fromJson<int>(json['typeVersion']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deviceTime: serializer.fromJson<DateTime>(json['deviceTime']),
      appVersion: serializer.fromJson<String>(json['appVersion']),
      correlationJson: serializer.fromJson<String?>(json['correlationJson']),
      contentJson: serializer.fromJson<String?>(json['contentJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventType': serializer.toJson<String>(eventType),
      'typeVersion': serializer.toJson<int>(typeVersion),
      'deviceId': serializer.toJson<String>(deviceId),
      'deviceTime': serializer.toJson<DateTime>(deviceTime),
      'appVersion': serializer.toJson<String>(appVersion),
      'correlationJson': serializer.toJson<String?>(correlationJson),
      'contentJson': serializer.toJson<String?>(contentJson),
    };
  }

  QueuedEventRow copyWith({
    String? id,
    String? eventType,
    int? typeVersion,
    String? deviceId,
    DateTime? deviceTime,
    String? appVersion,
    Value<String?> correlationJson = const Value.absent(),
    Value<String?> contentJson = const Value.absent(),
  }) => QueuedEventRow(
    id: id ?? this.id,
    eventType: eventType ?? this.eventType,
    typeVersion: typeVersion ?? this.typeVersion,
    deviceId: deviceId ?? this.deviceId,
    deviceTime: deviceTime ?? this.deviceTime,
    appVersion: appVersion ?? this.appVersion,
    correlationJson: correlationJson.present
        ? correlationJson.value
        : this.correlationJson,
    contentJson: contentJson.present ? contentJson.value : this.contentJson,
  );
  QueuedEventRow copyWithCompanion(QueuedEventsCompanion data) {
    return QueuedEventRow(
      id: data.id.present ? data.id.value : this.id,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      typeVersion: data.typeVersion.present
          ? data.typeVersion.value
          : this.typeVersion,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deviceTime: data.deviceTime.present
          ? data.deviceTime.value
          : this.deviceTime,
      appVersion: data.appVersion.present
          ? data.appVersion.value
          : this.appVersion,
      correlationJson: data.correlationJson.present
          ? data.correlationJson.value
          : this.correlationJson,
      contentJson: data.contentJson.present
          ? data.contentJson.value
          : this.contentJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueuedEventRow(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('typeVersion: $typeVersion, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceTime: $deviceTime, ')
          ..write('appVersion: $appVersion, ')
          ..write('correlationJson: $correlationJson, ')
          ..write('contentJson: $contentJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    eventType,
    typeVersion,
    deviceId,
    deviceTime,
    appVersion,
    correlationJson,
    contentJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueuedEventRow &&
          other.id == this.id &&
          other.eventType == this.eventType &&
          other.typeVersion == this.typeVersion &&
          other.deviceId == this.deviceId &&
          other.deviceTime == this.deviceTime &&
          other.appVersion == this.appVersion &&
          other.correlationJson == this.correlationJson &&
          other.contentJson == this.contentJson);
}

class QueuedEventsCompanion extends UpdateCompanion<QueuedEventRow> {
  final Value<String> id;
  final Value<String> eventType;
  final Value<int> typeVersion;
  final Value<String> deviceId;
  final Value<DateTime> deviceTime;
  final Value<String> appVersion;
  final Value<String?> correlationJson;
  final Value<String?> contentJson;
  final Value<int> rowid;
  const QueuedEventsCompanion({
    this.id = const Value.absent(),
    this.eventType = const Value.absent(),
    this.typeVersion = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deviceTime = const Value.absent(),
    this.appVersion = const Value.absent(),
    this.correlationJson = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QueuedEventsCompanion.insert({
    required String id,
    required String eventType,
    required int typeVersion,
    required String deviceId,
    required DateTime deviceTime,
    required String appVersion,
    this.correlationJson = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eventType = Value(eventType),
       typeVersion = Value(typeVersion),
       deviceId = Value(deviceId),
       deviceTime = Value(deviceTime),
       appVersion = Value(appVersion);
  static Insertable<QueuedEventRow> custom({
    Expression<String>? id,
    Expression<String>? eventType,
    Expression<int>? typeVersion,
    Expression<String>? deviceId,
    Expression<DateTime>? deviceTime,
    Expression<String>? appVersion,
    Expression<String>? correlationJson,
    Expression<String>? contentJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventType != null) 'event_type': eventType,
      if (typeVersion != null) 'type_version': typeVersion,
      if (deviceId != null) 'device_id': deviceId,
      if (deviceTime != null) 'device_time': deviceTime,
      if (appVersion != null) 'app_version': appVersion,
      if (correlationJson != null) 'correlation_json': correlationJson,
      if (contentJson != null) 'content_json': contentJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QueuedEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? eventType,
    Value<int>? typeVersion,
    Value<String>? deviceId,
    Value<DateTime>? deviceTime,
    Value<String>? appVersion,
    Value<String?>? correlationJson,
    Value<String?>? contentJson,
    Value<int>? rowid,
  }) {
    return QueuedEventsCompanion(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      typeVersion: typeVersion ?? this.typeVersion,
      deviceId: deviceId ?? this.deviceId,
      deviceTime: deviceTime ?? this.deviceTime,
      appVersion: appVersion ?? this.appVersion,
      correlationJson: correlationJson ?? this.correlationJson,
      contentJson: contentJson ?? this.contentJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (typeVersion.present) {
      map['type_version'] = Variable<int>(typeVersion.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deviceTime.present) {
      map['device_time'] = Variable<DateTime>(deviceTime.value);
    }
    if (appVersion.present) {
      map['app_version'] = Variable<String>(appVersion.value);
    }
    if (correlationJson.present) {
      map['correlation_json'] = Variable<String>(correlationJson.value);
    }
    if (contentJson.present) {
      map['content_json'] = Variable<String>(contentJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueuedEventsCompanion(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('typeVersion: $typeVersion, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceTime: $deviceTime, ')
          ..write('appVersion: $appVersion, ')
          ..write('correlationJson: $correlationJson, ')
          ..write('contentJson: $contentJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$EventQueueDatabase extends GeneratedDatabase {
  _$EventQueueDatabase(QueryExecutor e) : super(e);
  $EventQueueDatabaseManager get managers => $EventQueueDatabaseManager(this);
  late final $QueuedEventsTable queuedEvents = $QueuedEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [queuedEvents];
}

typedef $$QueuedEventsTableCreateCompanionBuilder =
    QueuedEventsCompanion Function({
      required String id,
      required String eventType,
      required int typeVersion,
      required String deviceId,
      required DateTime deviceTime,
      required String appVersion,
      Value<String?> correlationJson,
      Value<String?> contentJson,
      Value<int> rowid,
    });
typedef $$QueuedEventsTableUpdateCompanionBuilder =
    QueuedEventsCompanion Function({
      Value<String> id,
      Value<String> eventType,
      Value<int> typeVersion,
      Value<String> deviceId,
      Value<DateTime> deviceTime,
      Value<String> appVersion,
      Value<String?> correlationJson,
      Value<String?> contentJson,
      Value<int> rowid,
    });

class $$QueuedEventsTableFilterComposer
    extends Composer<_$EventQueueDatabase, $QueuedEventsTable> {
  $$QueuedEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get typeVersion => $composableBuilder(
    column: $table.typeVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deviceTime => $composableBuilder(
    column: $table.deviceTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correlationJson => $composableBuilder(
    column: $table.correlationJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QueuedEventsTableOrderingComposer
    extends Composer<_$EventQueueDatabase, $QueuedEventsTable> {
  $$QueuedEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get typeVersion => $composableBuilder(
    column: $table.typeVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deviceTime => $composableBuilder(
    column: $table.deviceTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correlationJson => $composableBuilder(
    column: $table.correlationJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QueuedEventsTableAnnotationComposer
    extends Composer<_$EventQueueDatabase, $QueuedEventsTable> {
  $$QueuedEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<int> get typeVersion => $composableBuilder(
    column: $table.typeVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get deviceTime => $composableBuilder(
    column: $table.deviceTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get correlationJson => $composableBuilder(
    column: $table.correlationJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => column,
  );
}

class $$QueuedEventsTableTableManager
    extends
        RootTableManager<
          _$EventQueueDatabase,
          $QueuedEventsTable,
          QueuedEventRow,
          $$QueuedEventsTableFilterComposer,
          $$QueuedEventsTableOrderingComposer,
          $$QueuedEventsTableAnnotationComposer,
          $$QueuedEventsTableCreateCompanionBuilder,
          $$QueuedEventsTableUpdateCompanionBuilder,
          (
            QueuedEventRow,
            BaseReferences<
              _$EventQueueDatabase,
              $QueuedEventsTable,
              QueuedEventRow
            >,
          ),
          QueuedEventRow,
          PrefetchHooks Function()
        > {
  $$QueuedEventsTableTableManager(
    _$EventQueueDatabase db,
    $QueuedEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueuedEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueuedEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueuedEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<int> typeVersion = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime> deviceTime = const Value.absent(),
                Value<String> appVersion = const Value.absent(),
                Value<String?> correlationJson = const Value.absent(),
                Value<String?> contentJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueuedEventsCompanion(
                id: id,
                eventType: eventType,
                typeVersion: typeVersion,
                deviceId: deviceId,
                deviceTime: deviceTime,
                appVersion: appVersion,
                correlationJson: correlationJson,
                contentJson: contentJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String eventType,
                required int typeVersion,
                required String deviceId,
                required DateTime deviceTime,
                required String appVersion,
                Value<String?> correlationJson = const Value.absent(),
                Value<String?> contentJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueuedEventsCompanion.insert(
                id: id,
                eventType: eventType,
                typeVersion: typeVersion,
                deviceId: deviceId,
                deviceTime: deviceTime,
                appVersion: appVersion,
                correlationJson: correlationJson,
                contentJson: contentJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QueuedEventsTable, QueuedEventRow>(table),
                  BaseReferences<
                    _$EventQueueDatabase,
                    $QueuedEventsTable,
                    QueuedEventRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QueuedEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$EventQueueDatabase,
      $QueuedEventsTable,
      QueuedEventRow,
      $$QueuedEventsTableFilterComposer,
      $$QueuedEventsTableOrderingComposer,
      $$QueuedEventsTableAnnotationComposer,
      $$QueuedEventsTableCreateCompanionBuilder,
      $$QueuedEventsTableUpdateCompanionBuilder,
      (
        QueuedEventRow,
        BaseReferences<
          _$EventQueueDatabase,
          $QueuedEventsTable,
          QueuedEventRow
        >,
      ),
      QueuedEventRow,
      PrefetchHooks Function()
    >;

class $EventQueueDatabaseManager {
  final _$EventQueueDatabase _db;
  $EventQueueDatabaseManager(this._db);
  $$QueuedEventsTableTableManager get queuedEvents =>
      $$QueuedEventsTableTableManager(_db, _db.queuedEvents);
}
