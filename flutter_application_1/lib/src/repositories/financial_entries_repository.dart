import 'package:drift/drift.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';

class EntryWithRefs {
  const EntryWithRefs({
    required this.entry,
    required this.sourceAccount,
    this.destinationAccount,
    this.category,
  });

  final FinancialEntry entry;
  final Account sourceAccount;
  final Account? destinationAccount;
  final Category? category;
}

class MonthSummary {
  const MonthSummary({required this.incomeCents, required this.expenseCents});

  final int incomeCents;
  final int expenseCents;

  int get balanceCents => incomeCents - expenseCents;
}

class EntryFilters {
  const EntryFilters({
    this.type,
    this.from,
    this.to,
    this.accountId,
    this.categoryId,
    this.search,
    this.limit,
    this.sortDescending = true,
  });

  final EntryType? type;
  final DateTime? from;
  final DateTime? to;
  final int? accountId;
  final int? categoryId;
  final String? search;
  final int? limit;
  final bool sortDescending;

  bool get hasActiveFilters =>
      (search != null && search!.trim().isNotEmpty) ||
      type != null ||
      from != null ||
      to != null ||
      accountId != null ||
      categoryId != null;

  @override
  bool operator ==(Object other) =>
      other is EntryFilters &&
      other.type == type &&
      other.from == from &&
      other.to == to &&
      other.accountId == accountId &&
      other.categoryId == categoryId &&
      other.search == search &&
      other.limit == limit &&
      other.sortDescending == sortDescending;

  @override
  int get hashCode =>
      Object.hash(type, from, to, accountId, categoryId, search, limit, sortDescending);
}

class FinancialEntriesRepository {
  FinancialEntriesRepository(this.db);

  final AppDatabase db;

  Stream<List<EntryWithRefs>> watchEntries(EntryFilters filters) {
    final sourceAccounts = db.alias(db.accounts, 'source_accounts');
    final destinationAccounts = db.alias(db.accounts, 'destination_accounts');
    final entryCategories = db.alias(db.categories, 'entry_categories');

    final conditions = <Expression<bool>>[];
    if (filters.type != null) {
      conditions.add(db.financialEntries.type.equalsValue(filters.type!));
    }
    if (filters.from != null) {
      conditions.add(
        db.financialEntries.occurredAt.isBiggerOrEqualValue(filters.from!),
      );
    }
    if (filters.to != null) {
      conditions.add(
        db.financialEntries.occurredAt.isSmallerThanValue(filters.to!),
      );
    }
    if (filters.accountId != null) {
      conditions.add(
        db.financialEntries.sourceAccountId.equals(filters.accountId!) |
            db.financialEntries.destinationAccountId.equals(
              filters.accountId!,
            ),
      );
    }
    if (filters.categoryId != null) {
      conditions.add(
        db.financialEntries.categoryId.equals(filters.categoryId!),
      );
    }

    final search = filters.search?.trim();
    if (search != null && search.isNotEmpty) {
      conditions.add(
        db.financialEntries.description.lower().like('%${search.toLowerCase()}%'),
      );
    }

    var query = db.select(db.financialEntries).join([
      innerJoin(
        sourceAccounts,
        sourceAccounts.id.equalsExp(db.financialEntries.sourceAccountId),
      ),
      leftOuterJoin(
        destinationAccounts,
        destinationAccounts.id.equalsExp(
          db.financialEntries.destinationAccountId,
        ),
      ),
      leftOuterJoin(
        entryCategories,
        entryCategories.id.equalsExp(db.financialEntries.categoryId),
      ),
    ]);

    if (conditions.isNotEmpty) {
      query.where(conditions.reduce((a, b) => a & b));
    }

    query.orderBy([
      if (filters.sortDescending) ...[
        OrderingTerm.desc(db.financialEntries.occurredAt),
        OrderingTerm.desc(db.financialEntries.id),
      ] else ...[
        OrderingTerm.asc(db.financialEntries.occurredAt),
        OrderingTerm.asc(db.financialEntries.id),
      ],
    ]);

    if (filters.limit != null) {
      query.limit(filters.limit!);
    }

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => EntryWithRefs(
              entry: row.readTable(db.financialEntries),
              sourceAccount: row.readTable(sourceAccounts),
              destinationAccount: row.readTableOrNull(destinationAccounts),
              category: row.readTableOrNull(entryCategories),
            ),
          )
          .toList(),
    );
  }

  Stream<EntryWithRefs?> watchEntryById(int id) {
    final sourceAccounts = db.alias(db.accounts, 'source_accounts');
    final destinationAccounts = db.alias(db.accounts, 'destination_accounts');
    final entryCategories = db.alias(db.categories, 'entry_categories');

    return (db.select(db.financialEntries)
          ..where((tbl) => tbl.id.equals(id)))
        .join([
      innerJoin(
        sourceAccounts,
        sourceAccounts.id.equalsExp(db.financialEntries.sourceAccountId),
      ),
      leftOuterJoin(
        destinationAccounts,
        destinationAccounts.id.equalsExp(
          db.financialEntries.destinationAccountId,
        ),
      ),
      leftOuterJoin(
        entryCategories,
        entryCategories.id.equalsExp(db.financialEntries.categoryId),
      ),
    ]).watchSingleOrNull().map(
      (row) => row == null
          ? null
          : EntryWithRefs(
              entry: row.readTable(db.financialEntries),
              sourceAccount: row.readTable(sourceAccounts),
              destinationAccount: row.readTableOrNull(destinationAccounts),
              category: row.readTableOrNull(entryCategories),
            ),
    );
  }

  Future<EntryWithRefs?> findEntryById(int id) {
    final sourceAccounts = db.alias(db.accounts, 'source_accounts');
    final destinationAccounts = db.alias(db.accounts, 'destination_accounts');
    final entryCategories = db.alias(db.categories, 'entry_categories');

    return (db.select(db.financialEntries)
          ..where((tbl) => tbl.id.equals(id)))
        .join([
      innerJoin(
        sourceAccounts,
        sourceAccounts.id.equalsExp(db.financialEntries.sourceAccountId),
      ),
      leftOuterJoin(
        destinationAccounts,
        destinationAccounts.id.equalsExp(
          db.financialEntries.destinationAccountId,
        ),
      ),
      leftOuterJoin(
        entryCategories,
        entryCategories.id.equalsExp(db.financialEntries.categoryId),
      ),
    ]).getSingleOrNull().then(
      (row) => row == null
          ? null
          : EntryWithRefs(
              entry: row.readTable(db.financialEntries),
              sourceAccount: row.readTable(sourceAccounts),
              destinationAccount: row.readTableOrNull(destinationAccounts),
              category: row.readTableOrNull(entryCategories),
            ),
    );
  }

  Stream<List<EntryWithRefs>> watchUpcomingDueEntries({int limit = 5}) {
    final sourceAccounts = db.alias(db.accounts, 'source_accounts');
    final destinationAccounts = db.alias(db.accounts, 'destination_accounts');
    final entryCategories = db.alias(db.categories, 'entry_categories');

    return (db.select(db.financialEntries)
          ..where(
            (tbl) =>
                tbl.status.equalsValue(EntryStatus.pending) &
                tbl.dueAt.isNotNull(),
          )
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.dueAt)])
          ..limit(limit))
        .join([
      innerJoin(
        sourceAccounts,
        sourceAccounts.id.equalsExp(db.financialEntries.sourceAccountId),
      ),
      leftOuterJoin(
        destinationAccounts,
        destinationAccounts.id.equalsExp(
          db.financialEntries.destinationAccountId,
        ),
      ),
      leftOuterJoin(
        entryCategories,
        entryCategories.id.equalsExp(db.financialEntries.categoryId),
      ),
    ]).watch().map(
      (rows) => rows
          .map(
            (row) => EntryWithRefs(
              entry: row.readTable(db.financialEntries),
              sourceAccount: row.readTable(sourceAccounts),
              destinationAccount: row.readTableOrNull(destinationAccounts),
              category: row.readTableOrNull(entryCategories),
            ),
          )
          .toList(),
    );
  }

  Stream<MonthSummary> watchMonthSummary(DateTime monthStart) {
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1);

    return db
        .customSelect(
          '''
          SELECT
            COALESCE(SUM(CASE WHEN type = 'income' THEN amount_cents ELSE 0 END), 0) AS income_cents,
            COALESCE(SUM(CASE WHEN type = 'expense' THEN amount_cents ELSE 0 END), 0) AS expense_cents
          FROM financial_entries
          WHERE status = 'completed'
            AND type <> 'transfer'
            AND occurred_at >= ? AND occurred_at < ?
        ''',
          variables: [
            Variable.withDateTime(monthStart),
            Variable.withDateTime(monthEnd),
          ],
          readsFrom: {db.financialEntries},
        )
        .watchSingle()
        .map(
          (row) => MonthSummary(
            incomeCents: row.read<int>('income_cents'),
            expenseCents: row.read<int>('expense_cents'),
          ),
        );
  }

  Future<int> createEntry(FinancialEntriesCompanion entry) =>
      db.into(db.financialEntries).insert(entry);

  Future<int> updateEntry(int id, FinancialEntriesCompanion entry) => (db
      .update(db.financialEntries)..where((tbl) => tbl.id.equals(id))).write(
    entry.copyWith(updatedAt: Value(DateTime.now())),
  );

  Future<int> deleteEntry(int id) =>
      (db.delete(db.financialEntries)..where((tbl) => tbl.id.equals(id))).go();
}
