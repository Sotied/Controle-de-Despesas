import 'package:drift/drift.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';

class RecurringEntryWithRefs {
  const RecurringEntryWithRefs({required this.rule, required this.account, this.category});

  final RecurringEntry rule;
  final Account account;
  final Category? category;
}

class RecurringEntriesRepository {
  RecurringEntriesRepository(this.db);

  final AppDatabase db;

  Stream<List<RecurringEntryWithRefs>> watchAll() {
    final ruleAccounts = db.alias(db.accounts, 'rule_accounts');
    final ruleCategories = db.alias(db.categories, 'rule_categories');

    return (db.select(db.recurringEntries).join([
      innerJoin(
        ruleAccounts,
        ruleAccounts.id.equalsExp(db.recurringEntries.accountId),
      ),
      leftOuterJoin(
        ruleCategories,
        ruleCategories.id.equalsExp(db.recurringEntries.categoryId),
      ),
    ])
          ..orderBy([OrderingTerm.asc(db.recurringEntries.description)]))
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => RecurringEntryWithRefs(
                  rule: row.readTable(db.recurringEntries),
                  account: row.readTable(ruleAccounts),
                  category: row.readTableOrNull(ruleCategories),
                ),
              )
              .toList(),
        );
  }

  Future<RecurringEntry?> findById(int id) {
    return (db.select(
      db.recurringEntries,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> create(RecurringEntriesCompanion entry) async {
    final id = await db.into(db.recurringEntries).insert(entry);
    final rule = await findById(id);

    if (rule != null && rule.active) {
      await _generateForRule(rule, _today());
    }

    return id;
  }

  Future<int> update(int id, RecurringEntriesCompanion entry) => (db.update(
    db.recurringEntries,
  )..where((tbl) => tbl.id.equals(id))).write(
    entry.copyWith(updatedAt: Value(DateTime.now())),
  );

  Future<int> setActive(int id, {required bool active}) =>
      update(id, RecurringEntriesCompanion(active: Value(active)));

  Future<int> delete(int id) =>
      (db.delete(db.recurringEntries)..where((tbl) => tbl.id.equals(id))).go();

  Future<void> confirmDueEntry(int entryId) async {
    await (db.update(
      db.financialEntries,
    )..where((tbl) => tbl.id.equals(entryId))).write(
      FinancialEntriesCompanion(
        status: const Value(EntryStatus.completed),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> generateDueInstances() async {
    final today = _today();
    final rules = await (db.select(
      db.recurringEntries,
    )..where((tbl) => tbl.active.equals(true))).get();

    for (final rule in rules) {
      await _generateForRule(rule, today);
    }
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _firstOccurrence(RecurringEntry rule) {
    final cursor = rule.lastGeneratedDueAt;
    if (cursor != null) {
      return DateTime(cursor.year, cursor.month + 1, rule.dayOfMonth);
    }

    final start = rule.startDate;
    final first = DateTime(start.year, start.month, rule.dayOfMonth);
    if (first.isBefore(DateTime(start.year, start.month, start.day))) {
      return DateTime(start.year, start.month + 1, rule.dayOfMonth);
    }
    return first;
  }

  Future<void> _generateForRule(RecurringEntry rule, DateTime today) async {
    var next = _firstOccurrence(rule);
    var lastGenerated = rule.lastGeneratedDueAt;
    var created = 0;

    for (var i = 0; i < 240; i++) {
      final endDate = rule.endDate;
      if (endDate != null && next.isAfter(endDate)) {
        return;
      }

      if (next.isAfter(today)) {
        break;
      }

      if (!(await _occurrenceExists(rule.id, next))) {
        await _insertOccurrence(rule, next);
        created++;
      }
      lastGenerated = next;

      next = DateTime(next.year, next.month + 1, rule.dayOfMonth);
    }

    final endDate = rule.endDate;
    final canPreview = endDate == null || !next.isAfter(endDate);
    if (canPreview && !(await _occurrenceExists(rule.id, next))) {
      await _insertOccurrence(rule, next);
      created++;
    }

    if (created > 0 &&
        lastGenerated != null &&
        (rule.lastGeneratedDueAt == null ||
            lastGenerated.isAfter(rule.lastGeneratedDueAt!))) {
      await (db.update(
        db.recurringEntries,
      )..where((tbl) => tbl.id.equals(rule.id))).write(
        RecurringEntriesCompanion(lastGeneratedDueAt: Value(lastGenerated)),
      );
    }
  }

  Future<bool> _occurrenceExists(int ruleId, DateTime dueAt) async {
    final query = db.selectOnly(db.financialEntries)
      ..addColumns([db.financialEntries.id])
      ..where(
        db.financialEntries.recurringId.equals(ruleId) &
            db.financialEntries.dueAt.year.equals(dueAt.year) &
            db.financialEntries.dueAt.month.equals(dueAt.month) &
            db.financialEntries.dueAt.day.equals(dueAt.day),
      )
      ..limit(1);

    return await query.getSingleOrNull() != null;
  }

  Future<void> _insertOccurrence(RecurringEntry rule, DateTime dueAt) async {
    await db
        .into(db.financialEntries)
        .insert(
          FinancialEntriesCompanion.insert(
            description: rule.description,
            type: rule.type,
            amountCents: rule.amountCents,
            sourceAccountId: rule.accountId,
            categoryId: Value(rule.categoryId),
            occurredAt: dueAt,
            dueAt: Value(dueAt),
            status: const Value(EntryStatus.pending),
            recurringId: Value(rule.id),
          ),
        );
  }
}
