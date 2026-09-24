import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/database/tables/accounts.dart';
import 'package:flutter_application_1/src/database/tables/app_preferences.dart';
import 'package:flutter_application_1/src/database/tables/budgets.dart';
import 'package:flutter_application_1/src/database/tables/categories.dart';
import 'package:flutter_application_1/src/database/tables/financial_entries.dart';
import 'package:flutter_application_1/src/database/tables/goals.dart';
import 'package:flutter_application_1/src/database/tables/recurring_entries.dart';
import 'package:path_provider/path_provider.dart';

part "app_database.g.dart";

@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    FinancialEntries,
    AppPreferences,
    RecurringEntries,
    Budgets,
    Goals,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _seedCategoriesIfEmpty();
    },
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createIndexes();
      await _ensurePreferences();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(accounts);
        await migrator.createTable(categories);
        await migrator.createTable(financialEntries);
        await migrator.createTable(appPreferences);

        await _migrateLegacyExpenses();
        await customStatement('DROP TABLE IF EXISTS gastos_table');
        await _createIndexes();
        await _ensurePreferences();
      }

      if (from < 3) {
        await migrator.createTable(recurringEntries);

        if (from >= 2) {
          await customStatement(
            'ALTER TABLE financial_entries ADD COLUMN recurring_id '
            'INTEGER NULL REFERENCES recurring_entries (id) ON DELETE SET NULL',
          );
        }
      }

      if (from < 4) {
        await migrator.createTable(budgets);
      }

      if (from < 5) {
        await migrator.createTable(goals);
      }
    },
  );

  static const _defaultExpenseCategories = [
    'Alimentação',
    'Transporte',
    'Moradia',
    'Saúde',
    'Lazer',
    'Educação',
    'Compras',
    'Outros',
  ];

  static const _defaultIncomeCategories = ['Salário', 'Investimentos', 'Outros'];

  Future<void> _seedCategoriesIfEmpty() async {
    final totalExpression = categories.id.count();
    final countQuery = selectOnly(categories)..addColumns([totalExpression]);
    final total = await countQuery
        .map((row) => row.read(totalExpression) ?? 0)
        .getSingle();

    if (total > 0) {
      return;
    }

    await batch((batch) {
      batch.insertAll(categories, [
        for (final name in _defaultExpenseCategories)
          CategoriesCompanion.insert(
            name: name,
            type: CategoryType.expense,
          ),
        for (final name in _defaultIncomeCategories)
          CategoriesCompanion.insert(
            name: name,
            type: CategoryType.income,
          ),
      ]);
    });
  }

  Future<void> _migrateLegacyExpenses() async {
    await customStatement('''
      INSERT INTO accounts (
        name,
        type,
        initial_balance_cents,
        is_archived,
        created_at,
        updated_at
      )
      SELECT
        'Carteira principal',
        'cash',
        0,
        0,
        CAST(strftime('%s', 'now') AS INTEGER),
        CAST(strftime('%s', 'now') AS INTEGER)
      WHERE EXISTS (SELECT 1 FROM gastos_table)
    ''');

    await customStatement('''
      INSERT INTO financial_entries (
        description,
        type,
        status,
        amount_cents,
        source_account_id,
        occurred_at,
        created_at,
        updated_at
      )
      SELECT
        descricao,
        'expense',
        'completed',
        MAX(
          1,
          CASE
            WHEN instr(valor, ',') > 0 THEN CAST(
              ROUND(
                CAST(REPLACE(REPLACE(valor, '.', ''), ',', '.') AS REAL) * 100
              ) AS INTEGER
            )
            ELSE CAST(ROUND(CAST(valor AS REAL) * 100) AS INTEGER)
          END
        ),
        (SELECT id FROM accounts ORDER BY id LIMIT 1),
        data,
        CAST(strftime('%s', 'now') AS INTEGER),
        CAST(strftime('%s', 'now') AS INTEGER)
      FROM gastos_table
    ''');
  }

  Future<void> _createIndexes() async {
    await customStatement('''
      CREATE INDEX IF NOT EXISTS financial_entries_occurred_at_idx
      ON financial_entries (occurred_at)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS financial_entries_source_account_idx
      ON financial_entries (source_account_id)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS financial_entries_category_idx
      ON financial_entries (category_id)
    ''');
  }

  Future<void> _ensurePreferences() async {
    await customStatement('''
      INSERT OR IGNORE INTO app_preferences (
        id,
        currency_code,
        locale,
        first_day_of_month
      ) VALUES (1, 'BRL', 'pt_BR', 1)
    ''');
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'my_database',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
