import 'package:drift/drift.dart';
import 'package:flutter_application_1/src/database/app_database.dart';

class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.categoryName,
    required this.spentCents,
  });

  final Budget budget;
  final String categoryName;
  final int spentCents;

  int get remainingCents => budget.amountCents - spentCents;

  double get usage =>
      budget.amountCents == 0 ? 0 : spentCents / budget.amountCents;

  bool get isOver => spentCents > budget.amountCents;

  bool get isNear => !isOver && usage >= 0.8;
}

class BudgetsRepository {
  BudgetsRepository(this.db);

  final AppDatabase db;

  Stream<List<BudgetProgress>> watchForMonth(DateTime monthStart) {
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1);

    return db
        .customSelect(
          '''
          SELECT budgets.*, categories.name AS category_name,
            COALESCE((
              SELECT SUM(fe.amount_cents)
              FROM financial_entries fe
              WHERE fe.category_id = budgets.category_id
                AND fe.type = 'expense'
                AND fe.status = 'completed'
                AND fe.occurred_at >= ? AND fe.occurred_at < ?
            ), 0) AS spent_cents
          FROM budgets
          JOIN categories ON categories.id = budgets.category_id
          ORDER BY categories.name COLLATE NOCASE
        ''',
          variables: [
            Variable.withDateTime(monthStart),
            Variable.withDateTime(monthEnd),
          ],
          readsFrom: {db.budgets, db.categories, db.financialEntries},
        )
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => BudgetProgress(
                  budget: db.budgets.map(row.data),
                  categoryName: row.read<String>('category_name'),
                  spentCents: row.read<int>('spent_cents'),
                ),
              )
              .toList(),
        );
  }

  Future<int> create(BudgetsCompanion entry) =>
      db.into(db.budgets).insert(entry);

  Future<int> update(int id, BudgetsCompanion entry) => (db.update(
    db.budgets,
  )..where((tbl) => tbl.id.equals(id))).write(
    entry.copyWith(updatedAt: Value(DateTime.now())),
  );

  Future<int> delete(int id) =>
      (db.delete(db.budgets)..where((tbl) => tbl.id.equals(id))).go();
}
