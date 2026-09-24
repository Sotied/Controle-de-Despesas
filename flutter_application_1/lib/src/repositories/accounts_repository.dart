import 'package:drift/drift.dart';
import 'package:flutter_application_1/src/database/app_database.dart';

class AccountWithBalance {
  const AccountWithBalance({required this.account, required this.balanceCents});

  final Account account;
  final int balanceCents;

  bool get isOverdrawn => balanceCents < 0;
}

class AccountsRepository {
  AccountsRepository(this.db);

  final AppDatabase db;

  Stream<List<Account>> watchAll({bool includeArchived = false}) {
    final query = db.select(db.accounts);
    if (!includeArchived) {
      query.where((tbl) => tbl.isArchived.equals(false));
    }
    query.orderBy([(tbl) => OrderingTerm.asc(tbl.name.collate(Collate.noCase))]);
    return query.watch();
  }

  Stream<Account?> watchById(int id) {
    return (db.select(db.accounts)..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull();
  }

  Stream<List<AccountWithBalance>> watchAllWithBalance({
    bool includeArchived = false,
  }) {
    final sql = StringBuffer('''
      SELECT accounts.*, accounts.initial_balance_cents + COALESCE(SUM(
        CASE
          WHEN financial_entries.type = 'income'
            AND financial_entries.source_account_id = accounts.id
            THEN financial_entries.amount_cents
          WHEN financial_entries.type = 'expense'
            AND financial_entries.source_account_id = accounts.id
            THEN -financial_entries.amount_cents
          WHEN financial_entries.type = 'transfer'
            AND financial_entries.source_account_id = accounts.id
            THEN -financial_entries.amount_cents
          WHEN financial_entries.type = 'transfer'
            AND financial_entries.destination_account_id = accounts.id
            THEN financial_entries.amount_cents
          ELSE 0
        END
      ), 0) AS balance_cents
      FROM accounts
      LEFT JOIN financial_entries
        ON financial_entries.status = 'completed'
        AND (
          financial_entries.source_account_id = accounts.id
          OR financial_entries.destination_account_id = accounts.id
        )
    ''');

    if (!includeArchived) {
      sql.write('WHERE accounts.is_archived = 0\n');
    }

    sql.write('GROUP BY accounts.id\nORDER BY accounts.name COLLATE NOCASE');

    return db
        .customSelect(
          sql.toString(),
          readsFrom: {db.accounts, db.financialEntries},
        )
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => AccountWithBalance(
                  account: db.accounts.map(row.data),
                  balanceCents: row.read<int>('balance_cents'),
                ),
              )
              .toList(),
        );
  }

  Stream<int> watchConsolidatedBalance({bool includeArchived = false}) {
    final archivedFilter = includeArchived ? '' : 'WHERE is_archived = 0';

    return db
        .customSelect(
          '''
          SELECT
            (
              SELECT COALESCE(SUM(initial_balance_cents), 0)
              FROM accounts
              $archivedFilter
            ) + (
              SELECT COALESCE(SUM(
                CASE
                  WHEN financial_entries.type = 'income'
                    THEN financial_entries.amount_cents
                  WHEN financial_entries.type = 'expense'
                    THEN -financial_entries.amount_cents
                  ELSE 0
                END
              ), 0)
              FROM financial_entries
              JOIN accounts ON accounts.id = financial_entries.source_account_id
              WHERE financial_entries.status = 'completed'
                AND financial_entries.type <> 'transfer'
                ${includeArchived ? '' : 'AND accounts.is_archived = 0'}
            ) AS balance_cents
        ''',
          readsFrom: {db.accounts, db.financialEntries},
        )
        .watchSingle()
        .map((row) => row.read<int>('balance_cents'));
  }

  Future<int> createAccount(AccountsCompanion entry) =>
      db.into(db.accounts).insert(entry);

  Future<int> updateAccount(int id, AccountsCompanion entry) => (db.update(
    db.accounts,
  )..where((tbl) => tbl.id.equals(id))).write(
    entry.copyWith(updatedAt: Value(DateTime.now())),
  );

  Future<int> setAccountArchived(int id, {required bool archived}) =>
      updateAccount(id, AccountsCompanion(isArchived: Value(archived)));

  Future<int> deleteAccount(int id) =>
      (db.delete(db.accounts)..where((tbl) => tbl.id.equals(id))).go();
}
