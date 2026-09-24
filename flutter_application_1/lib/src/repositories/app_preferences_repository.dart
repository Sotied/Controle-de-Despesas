import 'package:flutter_application_1/src/database/app_database.dart';

class AppPreferencesRepository {
  AppPreferencesRepository(this.db);

  final AppDatabase db;

  Stream<AppPreference> watch() {
    return (db.select(
      db.appPreferences,
    )..where((tbl) => tbl.id.equals(1))).watchSingle();
  }

  Future<AppPreference> get() {
    return (db.select(
      db.appPreferences,
    )..where((tbl) => tbl.id.equals(1))).getSingle();
  }

  Future<int> update(AppPreferencesCompanion entry) => (db
      .update(db.appPreferences)..where((tbl) => tbl.id.equals(1))).write(entry);
}
