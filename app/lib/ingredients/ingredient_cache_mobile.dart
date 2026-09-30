import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../storage/local_store.dart';
import 'ingredient_repository.dart';

part 'ingredient_cache_mobile.g.dart';

@DataClassName('IngredientCacheDetailRow')
class IngredientCacheDetails extends Table {
  TextColumn get id => text()();
  TextColumn get detailJson => text().named('detail_json')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('IngredientCacheVersionRow')
class IngredientCacheVersions extends Table {
  TextColumn get id => text()();
  TextColumn get version => text()();
  TextColumn get mergedJson => text().named('merged_json')();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [IngredientCacheDetails, IngredientCacheVersions])
class IngredientCacheDatabase extends _$IngredientCacheDatabase {
  IngredientCacheDatabase() : super(driftDatabase(name: 'ingredient_cache'));

  IngredientCacheDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 1;
}

/// Mobile implementation: a complete snapshot is replaced in one SQLite
/// transaction, so a failed sync cannot leave a mixed version of the catalogue.
class DriftIngredientCache implements CloseableIngredientCacheStore {
  DriftIngredientCache(this.database);

  static const _versionRowId = 'current';

  final IngredientCacheDatabase database;

  @override
  Future<IngredientCacheSnapshot?> read() async {
    return database.transaction(() async {
      final versionRow = await (database.select(
        database.ingredientCacheVersions,
      )..where((row) => row.id.equals(_versionRowId))).getSingleOrNull();
      if (versionRow == null) return null;

      final detailRows = await database
          .select(database.ingredientCacheDetails)
          .get();
      final ingredients = <String, dynamic>{};
      for (final row in detailRows) {
        final decoded = jsonDecode(row.detailJson);
        if (decoded is! Map) {
          throw const FormatException('invalid ingredient cache');
        }
        ingredients[row.id] = Map<String, dynamic>.from(decoded);
      }
      final merged = jsonDecode(versionRow.mergedJson);
      if (merged is! Map) {
        throw const FormatException('invalid ingredient merges');
      }
      return IngredientCacheSnapshot.fromJson({
        'version': versionRow.version,
        'ingredients': ingredients,
        'merged': Map<String, dynamic>.from(merged),
      });
    });
  }

  @override
  Future<void> write(IngredientCacheSnapshot snapshot) async {
    await database.transaction(() async {
      await database.delete(database.ingredientCacheDetails).go();
      await database.delete(database.ingredientCacheVersions).go();
      await database
          .into(database.ingredientCacheVersions)
          .insert(
            IngredientCacheVersionsCompanion.insert(
              id: _versionRowId,
              version: snapshot.version,
              mergedJson: jsonEncode(snapshot.merged),
            ),
          );
      await database.batch((batch) {
        batch.insertAll(database.ingredientCacheDetails, [
          for (final entry in snapshot.ingredients.entries)
            IngredientCacheDetailsCompanion.insert(
              id: entry.key,
              detailJson: jsonEncode(entry.value.toJson()),
            ),
        ]);
      });
    });
  }

  @override
  Future<void> close() => database.close();
}

IngredientCacheStore createPlatformIngredientCacheStore(LocalStore _) =>
    DriftIngredientCache(IngredientCacheDatabase());
