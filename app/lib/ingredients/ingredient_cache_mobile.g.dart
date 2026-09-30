// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_cache_mobile.dart';

// ignore_for_file: type=lint
class $IngredientCacheDetailsTable extends IngredientCacheDetails
    with TableInfo<$IngredientCacheDetailsTable, IngredientCacheDetailRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientCacheDetailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailJsonMeta = const VerificationMeta(
    'detailJson',
  );
  @override
  late final GeneratedColumn<String> detailJson = GeneratedColumn<String>(
    'detail_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, detailJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredient_cache_details';
  @override
  VerificationContext validateIntegrity(
    Insertable<IngredientCacheDetailRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('detail_json')) {
      context.handle(
        _detailJsonMeta,
        detailJson.isAcceptableOrUnknown(data['detail_json']!, _detailJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_detailJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IngredientCacheDetailRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientCacheDetailRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      detailJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail_json'],
      )!,
    );
  }

  @override
  $IngredientCacheDetailsTable createAlias(String alias) {
    return $IngredientCacheDetailsTable(attachedDatabase, alias);
  }
}

class IngredientCacheDetailRow extends DataClass
    implements Insertable<IngredientCacheDetailRow> {
  final String id;
  final String detailJson;
  const IngredientCacheDetailRow({required this.id, required this.detailJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['detail_json'] = Variable<String>(detailJson);
    return map;
  }

  IngredientCacheDetailsCompanion toCompanion(bool nullToAbsent) {
    return IngredientCacheDetailsCompanion(
      id: Value(id),
      detailJson: Value(detailJson),
    );
  }

  factory IngredientCacheDetailRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientCacheDetailRow(
      id: serializer.fromJson<String>(json['id']),
      detailJson: serializer.fromJson<String>(json['detailJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'detailJson': serializer.toJson<String>(detailJson),
    };
  }

  IngredientCacheDetailRow copyWith({String? id, String? detailJson}) =>
      IngredientCacheDetailRow(
        id: id ?? this.id,
        detailJson: detailJson ?? this.detailJson,
      );
  IngredientCacheDetailRow copyWithCompanion(
    IngredientCacheDetailsCompanion data,
  ) {
    return IngredientCacheDetailRow(
      id: data.id.present ? data.id.value : this.id,
      detailJson: data.detailJson.present
          ? data.detailJson.value
          : this.detailJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientCacheDetailRow(')
          ..write('id: $id, ')
          ..write('detailJson: $detailJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, detailJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientCacheDetailRow &&
          other.id == this.id &&
          other.detailJson == this.detailJson);
}

class IngredientCacheDetailsCompanion
    extends UpdateCompanion<IngredientCacheDetailRow> {
  final Value<String> id;
  final Value<String> detailJson;
  final Value<int> rowid;
  const IngredientCacheDetailsCompanion({
    this.id = const Value.absent(),
    this.detailJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IngredientCacheDetailsCompanion.insert({
    required String id,
    required String detailJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       detailJson = Value(detailJson);
  static Insertable<IngredientCacheDetailRow> custom({
    Expression<String>? id,
    Expression<String>? detailJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (detailJson != null) 'detail_json': detailJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IngredientCacheDetailsCompanion copyWith({
    Value<String>? id,
    Value<String>? detailJson,
    Value<int>? rowid,
  }) {
    return IngredientCacheDetailsCompanion(
      id: id ?? this.id,
      detailJson: detailJson ?? this.detailJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (detailJson.present) {
      map['detail_json'] = Variable<String>(detailJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientCacheDetailsCompanion(')
          ..write('id: $id, ')
          ..write('detailJson: $detailJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IngredientCacheVersionsTable extends IngredientCacheVersions
    with TableInfo<$IngredientCacheVersionsTable, IngredientCacheVersionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientCacheVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mergedJsonMeta = const VerificationMeta(
    'mergedJson',
  );
  @override
  late final GeneratedColumn<String> mergedJson = GeneratedColumn<String>(
    'merged_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, version, mergedJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredient_cache_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<IngredientCacheVersionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('merged_json')) {
      context.handle(
        _mergedJsonMeta,
        mergedJson.isAcceptableOrUnknown(data['merged_json']!, _mergedJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_mergedJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IngredientCacheVersionRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientCacheVersionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      mergedJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merged_json'],
      )!,
    );
  }

  @override
  $IngredientCacheVersionsTable createAlias(String alias) {
    return $IngredientCacheVersionsTable(attachedDatabase, alias);
  }
}

class IngredientCacheVersionRow extends DataClass
    implements Insertable<IngredientCacheVersionRow> {
  final String id;
  final String version;
  final String mergedJson;
  const IngredientCacheVersionRow({
    required this.id,
    required this.version,
    required this.mergedJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['version'] = Variable<String>(version);
    map['merged_json'] = Variable<String>(mergedJson);
    return map;
  }

  IngredientCacheVersionsCompanion toCompanion(bool nullToAbsent) {
    return IngredientCacheVersionsCompanion(
      id: Value(id),
      version: Value(version),
      mergedJson: Value(mergedJson),
    );
  }

  factory IngredientCacheVersionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientCacheVersionRow(
      id: serializer.fromJson<String>(json['id']),
      version: serializer.fromJson<String>(json['version']),
      mergedJson: serializer.fromJson<String>(json['mergedJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'version': serializer.toJson<String>(version),
      'mergedJson': serializer.toJson<String>(mergedJson),
    };
  }

  IngredientCacheVersionRow copyWith({
    String? id,
    String? version,
    String? mergedJson,
  }) => IngredientCacheVersionRow(
    id: id ?? this.id,
    version: version ?? this.version,
    mergedJson: mergedJson ?? this.mergedJson,
  );
  IngredientCacheVersionRow copyWithCompanion(
    IngredientCacheVersionsCompanion data,
  ) {
    return IngredientCacheVersionRow(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      mergedJson: data.mergedJson.present
          ? data.mergedJson.value
          : this.mergedJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientCacheVersionRow(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('mergedJson: $mergedJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, version, mergedJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientCacheVersionRow &&
          other.id == this.id &&
          other.version == this.version &&
          other.mergedJson == this.mergedJson);
}

class IngredientCacheVersionsCompanion
    extends UpdateCompanion<IngredientCacheVersionRow> {
  final Value<String> id;
  final Value<String> version;
  final Value<String> mergedJson;
  final Value<int> rowid;
  const IngredientCacheVersionsCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.mergedJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IngredientCacheVersionsCompanion.insert({
    required String id,
    required String version,
    required String mergedJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       version = Value(version),
       mergedJson = Value(mergedJson);
  static Insertable<IngredientCacheVersionRow> custom({
    Expression<String>? id,
    Expression<String>? version,
    Expression<String>? mergedJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (mergedJson != null) 'merged_json': mergedJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IngredientCacheVersionsCompanion copyWith({
    Value<String>? id,
    Value<String>? version,
    Value<String>? mergedJson,
    Value<int>? rowid,
  }) {
    return IngredientCacheVersionsCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      mergedJson: mergedJson ?? this.mergedJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (mergedJson.present) {
      map['merged_json'] = Variable<String>(mergedJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientCacheVersionsCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('mergedJson: $mergedJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$IngredientCacheDatabase extends GeneratedDatabase {
  _$IngredientCacheDatabase(QueryExecutor e) : super(e);
  $IngredientCacheDatabaseManager get managers =>
      $IngredientCacheDatabaseManager(this);
  late final $IngredientCacheDetailsTable ingredientCacheDetails =
      $IngredientCacheDetailsTable(this);
  late final $IngredientCacheVersionsTable ingredientCacheVersions =
      $IngredientCacheVersionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    ingredientCacheDetails,
    ingredientCacheVersions,
  ];
}

typedef $$IngredientCacheDetailsTableCreateCompanionBuilder =
    IngredientCacheDetailsCompanion Function({
      required String id,
      required String detailJson,
      Value<int> rowid,
    });
typedef $$IngredientCacheDetailsTableUpdateCompanionBuilder =
    IngredientCacheDetailsCompanion Function({
      Value<String> id,
      Value<String> detailJson,
      Value<int> rowid,
    });

class $$IngredientCacheDetailsTableFilterComposer
    extends Composer<_$IngredientCacheDatabase, $IngredientCacheDetailsTable> {
  $$IngredientCacheDetailsTableFilterComposer({
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

  ColumnFilters<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IngredientCacheDetailsTableOrderingComposer
    extends Composer<_$IngredientCacheDatabase, $IngredientCacheDetailsTable> {
  $$IngredientCacheDetailsTableOrderingComposer({
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

  ColumnOrderings<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IngredientCacheDetailsTableAnnotationComposer
    extends Composer<_$IngredientCacheDatabase, $IngredientCacheDetailsTable> {
  $$IngredientCacheDetailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => column,
  );
}

class $$IngredientCacheDetailsTableTableManager
    extends
        RootTableManager<
          _$IngredientCacheDatabase,
          $IngredientCacheDetailsTable,
          IngredientCacheDetailRow,
          $$IngredientCacheDetailsTableFilterComposer,
          $$IngredientCacheDetailsTableOrderingComposer,
          $$IngredientCacheDetailsTableAnnotationComposer,
          $$IngredientCacheDetailsTableCreateCompanionBuilder,
          $$IngredientCacheDetailsTableUpdateCompanionBuilder,
          (
            IngredientCacheDetailRow,
            BaseReferences<
              _$IngredientCacheDatabase,
              $IngredientCacheDetailsTable,
              IngredientCacheDetailRow
            >,
          ),
          IngredientCacheDetailRow,
          PrefetchHooks Function()
        > {
  $$IngredientCacheDetailsTableTableManager(
    _$IngredientCacheDatabase db,
    $IngredientCacheDetailsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientCacheDetailsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$IngredientCacheDetailsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$IngredientCacheDetailsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> detailJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IngredientCacheDetailsCompanion(
                id: id,
                detailJson: detailJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String detailJson,
                Value<int> rowid = const Value.absent(),
              }) => IngredientCacheDetailsCompanion.insert(
                id: id,
                detailJson: detailJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $IngredientCacheDetailsTable,
                    IngredientCacheDetailRow
                  >(table),
                  BaseReferences<
                    _$IngredientCacheDatabase,
                    $IngredientCacheDetailsTable,
                    IngredientCacheDetailRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IngredientCacheDetailsTableProcessedTableManager =
    ProcessedTableManager<
      _$IngredientCacheDatabase,
      $IngredientCacheDetailsTable,
      IngredientCacheDetailRow,
      $$IngredientCacheDetailsTableFilterComposer,
      $$IngredientCacheDetailsTableOrderingComposer,
      $$IngredientCacheDetailsTableAnnotationComposer,
      $$IngredientCacheDetailsTableCreateCompanionBuilder,
      $$IngredientCacheDetailsTableUpdateCompanionBuilder,
      (
        IngredientCacheDetailRow,
        BaseReferences<
          _$IngredientCacheDatabase,
          $IngredientCacheDetailsTable,
          IngredientCacheDetailRow
        >,
      ),
      IngredientCacheDetailRow,
      PrefetchHooks Function()
    >;
typedef $$IngredientCacheVersionsTableCreateCompanionBuilder =
    IngredientCacheVersionsCompanion Function({
      required String id,
      required String version,
      required String mergedJson,
      Value<int> rowid,
    });
typedef $$IngredientCacheVersionsTableUpdateCompanionBuilder =
    IngredientCacheVersionsCompanion Function({
      Value<String> id,
      Value<String> version,
      Value<String> mergedJson,
      Value<int> rowid,
    });

class $$IngredientCacheVersionsTableFilterComposer
    extends Composer<_$IngredientCacheDatabase, $IngredientCacheVersionsTable> {
  $$IngredientCacheVersionsTableFilterComposer({
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

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mergedJson => $composableBuilder(
    column: $table.mergedJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IngredientCacheVersionsTableOrderingComposer
    extends Composer<_$IngredientCacheDatabase, $IngredientCacheVersionsTable> {
  $$IngredientCacheVersionsTableOrderingComposer({
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

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mergedJson => $composableBuilder(
    column: $table.mergedJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IngredientCacheVersionsTableAnnotationComposer
    extends Composer<_$IngredientCacheDatabase, $IngredientCacheVersionsTable> {
  $$IngredientCacheVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get mergedJson => $composableBuilder(
    column: $table.mergedJson,
    builder: (column) => column,
  );
}

class $$IngredientCacheVersionsTableTableManager
    extends
        RootTableManager<
          _$IngredientCacheDatabase,
          $IngredientCacheVersionsTable,
          IngredientCacheVersionRow,
          $$IngredientCacheVersionsTableFilterComposer,
          $$IngredientCacheVersionsTableOrderingComposer,
          $$IngredientCacheVersionsTableAnnotationComposer,
          $$IngredientCacheVersionsTableCreateCompanionBuilder,
          $$IngredientCacheVersionsTableUpdateCompanionBuilder,
          (
            IngredientCacheVersionRow,
            BaseReferences<
              _$IngredientCacheDatabase,
              $IngredientCacheVersionsTable,
              IngredientCacheVersionRow
            >,
          ),
          IngredientCacheVersionRow,
          PrefetchHooks Function()
        > {
  $$IngredientCacheVersionsTableTableManager(
    _$IngredientCacheDatabase db,
    $IngredientCacheVersionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientCacheVersionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$IngredientCacheVersionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$IngredientCacheVersionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<String> mergedJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IngredientCacheVersionsCompanion(
                id: id,
                version: version,
                mergedJson: mergedJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String version,
                required String mergedJson,
                Value<int> rowid = const Value.absent(),
              }) => IngredientCacheVersionsCompanion.insert(
                id: id,
                version: version,
                mergedJson: mergedJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $IngredientCacheVersionsTable,
                    IngredientCacheVersionRow
                  >(table),
                  BaseReferences<
                    _$IngredientCacheDatabase,
                    $IngredientCacheVersionsTable,
                    IngredientCacheVersionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IngredientCacheVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$IngredientCacheDatabase,
      $IngredientCacheVersionsTable,
      IngredientCacheVersionRow,
      $$IngredientCacheVersionsTableFilterComposer,
      $$IngredientCacheVersionsTableOrderingComposer,
      $$IngredientCacheVersionsTableAnnotationComposer,
      $$IngredientCacheVersionsTableCreateCompanionBuilder,
      $$IngredientCacheVersionsTableUpdateCompanionBuilder,
      (
        IngredientCacheVersionRow,
        BaseReferences<
          _$IngredientCacheDatabase,
          $IngredientCacheVersionsTable,
          IngredientCacheVersionRow
        >,
      ),
      IngredientCacheVersionRow,
      PrefetchHooks Function()
    >;

class $IngredientCacheDatabaseManager {
  final _$IngredientCacheDatabase _db;
  $IngredientCacheDatabaseManager(this._db);
  $$IngredientCacheDetailsTableTableManager get ingredientCacheDetails =>
      $$IngredientCacheDetailsTableTableManager(
        _db,
        _db.ingredientCacheDetails,
      );
  $$IngredientCacheVersionsTableTableManager get ingredientCacheVersions =>
      $$IngredientCacheVersionsTableTableManager(
        _db,
        _db.ingredientCacheVersions,
      );
}
