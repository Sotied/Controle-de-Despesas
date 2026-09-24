import 'package:drift/drift.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';

class CategoryExpenseReport {
  const CategoryExpenseReport({
    required this.categoryId,
    required this.categoryName,
    required this.totalCents,
  });

  final int? categoryId;
  final String categoryName;
  final int totalCents;
}

class MonthlyTotals {
  const MonthlyTotals({
    required this.month,
    required this.incomeCents,
    required this.expenseCents,
  });

  final DateTime month;
  final int incomeCents;
  final int expenseCents;

  int get balanceCents => incomeCents - expenseCents;
}

class PeriodTotals {
  const PeriodTotals({required this.incomeCents, required this.expenseCents});

  final int incomeCents;
  final int expenseCents;

  int get balanceCents => incomeCents - expenseCents;
}

class ReportsRepository {
  ReportsRepository(this.db);

  final AppDatabase db;

  Stream<List<CategoryExpenseReport>> watchExpensesByCategory({
    required DateTime monthStart,
    int? accountId,
  }) {
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1);
    final accountFilter = accountId == null
        ? ''
        : 'AND fe.source_account_id = ?';

    return db
        .customSelect(
          '''
          SELECT fe.category_id AS category_id,
            COALESCE(c.name, 'Sem categoria') AS category_name,
            COALESCE(SUM(fe.amount_cents), 0) AS total_cents
          FROM financial_entries fe
          LEFT JOIN categories c ON c.id = fe.category_id
          WHERE fe.type = 'expense'
            AND fe.status = 'completed'
            AND fe.occurred_at >= ? AND fe.occurred_at < ?
            $accountFilter
          GROUP BY fe.category_id
          ORDER BY total_cents DESC
        ''',
          variables: [
            Variable.withDateTime(monthStart),
            Variable.withDateTime(monthEnd),
            if (accountId != null) Variable(accountId),
          ],
          readsFrom: {db.financialEntries, db.categories},
        )
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => CategoryExpenseReport(
                  categoryId: row.readNullable<int>('category_id'),
                  categoryName: row.read<String>('category_name'),
                  totalCents: row.read<int>('total_cents'),
                ),
              )
              .toList(),
        );
  }

  Stream<List<MonthlyTotals>> watchMonthlyTotals({
    required DateTime endMonth,
    required int months,
    int? accountId,
  }) {
    final start = DateTime(endMonth.year, endMonth.month - (months - 1));
    final end = DateTime(endMonth.year, endMonth.month + 1);

    final conditions = <Expression<bool>>[
      db.financialEntries.status.equalsValue(EntryStatus.completed),
      db.financialEntries.type.equalsValue(EntryType.income) |
          db.financialEntries.type.equalsValue(EntryType.expense),
      db.financialEntries.occurredAt.isBiggerOrEqualValue(start),
      db.financialEntries.occurredAt.isSmallerThanValue(end),
    ];
    if (accountId != null) {
      conditions.add(db.financialEntries.sourceAccountId.equals(accountId));
    }

    return (db.select(db.financialEntries)
          ..where((tbl) => conditions.reduce((a, b) => a & b)))
        .watch()
        .map((entries) {
          final byMonth = <String, MonthlyTotals>{};
          for (final entry in entries) {
            final occurred = entry.occurredAt;
            final key = '${occurred.year}-${occurred.month}';
            final current =
                byMonth[key] ??
                MonthlyTotals(
                  month: DateTime(occurred.year, occurred.month),
                  incomeCents: 0,
                  expenseCents: 0,
                );

            byMonth[key] = MonthlyTotals(
              month: current.month,
              incomeCents: current.incomeCents +
                  (entry.type == EntryType.income ? entry.amountCents : 0),
              expenseCents: current.expenseCents +
                  (entry.type == EntryType.expense ? entry.amountCents : 0),
            );
          }

          final result = <MonthlyTotals>[];
          for (var i = 0; i < months; i++) {
            final month = DateTime(start.year, start.month + i);
            result.add(
              byMonth['${month.year}-${month.month}'] ??
                  MonthlyTotals(
                    month: month,
                    incomeCents: 0,
                    expenseCents: 0,
                  ),
            );
          }
          return result;
        });
  }

  Stream<PeriodTotals> watchPeriodTotals({
    required DateTime from,
    required DateTime to,
    int? accountId,
  }) {
    final accountFilter = accountId == null
        ? ''
        : 'AND fe.source_account_id = ?';

    return db
        .customSelect(
          '''
          SELECT
            COALESCE(SUM(CASE WHEN fe.type = 'income' THEN fe.amount_cents ELSE 0 END), 0) AS income_cents,
            COALESCE(SUM(CASE WHEN fe.type = 'expense' THEN fe.amount_cents ELSE 0 END), 0) AS expense_cents
          FROM financial_entries fe
          WHERE fe.status = 'completed'
            AND fe.type <> 'transfer'
            AND fe.occurred_at >= ? AND fe.occurred_at < ?
            $accountFilter
        ''',
          variables: [
            Variable.withDateTime(from),
            Variable.withDateTime(to),
            if (accountId != null) Variable(accountId),
          ],
          readsFrom: {db.financialEntries},
        )
        .watchSingle()
          .map(
          (row) => PeriodTotals(
            incomeCents: row.read<int>('income_cents'),
            expenseCents: row.read<int>('expense_cents'),
          ),
        );
  }
}
