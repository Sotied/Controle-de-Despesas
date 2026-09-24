import 'package:drift/drift.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';

class CategoriesRepository {
  CategoriesRepository(this.db);

  final AppDatabase db;

  Stream<List<Category>> watchCategories({
    CategoryType? type,
    bool includeArchived = false,
  }) {
    final query = db.select(db.categories);
    if (type != null) {
      query.where((tbl) => tbl.type.equalsValue(type));
    }
    if (!includeArchived) {
      query.where((tbl) => tbl.isArchived.equals(false));
    }
    query.orderBy([(tbl) => OrderingTerm.asc(tbl.name.collate(Collate.noCase))]);
    return query.watch();
  }

  Future<Category?> findById(int id) {
    return (db.select(db.categories)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> createCategory(CategoriesCompanion entry) =>
      db.into(db.categories).insert(entry);

  Future<int> updateCategory(int id, CategoriesCompanion entry) => (db
      .update(db.categories)..where((tbl) => tbl.id.equals(id))).write(
    entry.copyWith(updatedAt: Value(DateTime.now())),
  );

  Future<int> setCategoryArchived(int id, {required bool archived}) =>
      updateCategory(id, CategoriesCompanion(isArchived: Value(archived)));

  Future<int> deleteCategory(int id) =>
      (db.delete(db.categories)..where((tbl) => tbl.id.equals(id))).go();
}
