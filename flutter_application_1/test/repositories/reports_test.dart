import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/repositories/reports_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ReportsRepository reportsRepository;
  late int bankId;
  late int walletId;
  late int foodCategoryId;
  late DateTime now;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    reportsRepository = ReportsRepository(db);

    bankId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(name: 'Banco', type: AccountType.bank),
        );
    walletId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(name: 'Carteira', type: AccountType.cash),
        );

    final categories = await db.select(db.categories).get();
    foodCategoryId = categories
        .singleWhere((category) => category.name == 'Alimentação')
        .id;

    now = DateTime.now();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertEntry({
    required int amountCents,
    required DateTime occurredAt,
    int? categoryId,
    int? accountId,
    EntryType type = EntryType.expense,
    EntryStatus status = EntryStatus.completed,
  }) {
    return db
        .into(db.financialEntries)
        .insert(
          FinancialEntriesCompanion.insert(
            description: 'Lançamento de teste',
            type: type,
            amountCents: amountCents,
            sourceAccountId: accountId ?? bankId,
            categoryId: Value(categoryId),
            occurredAt: occurredAt,
            status: Value(status),
          ),
        );
  }

  test('agrupa gastos do mês por categoria', () async {
    await insertEntry(
      amountCents: 20000,
      occurredAt: DateTime(now.year, now.month, 10),
      categoryId: foodCategoryId,
    );
    await insertEntry(
      amountCents: 5000,
      occurredAt: DateTime(now.year, now.month, 11),
    );
    await insertEntry(
      amountCents: 3000,
      occurredAt: DateTime(now.year, now.month, 12),
      categoryId: foodCategoryId,
      status: EntryStatus.pending,
    );
    await insertEntry(
      amountCents: 40000,
      occurredAt: DateTime(now.year, now.month, 13),
      categoryId: foodCategoryId,
      type: EntryType.income,
    );
    await insertEntry(
      amountCents: 1000,
      occurredAt: DateTime(now.year, now.month - 1, 10),
      categoryId: foodCategoryId,
    );
    await insertEntry(
      amountCents: 2000,
      occurredAt: DateTime(now.year, now.month + 1, 10),
      categoryId: foodCategoryId,
    );

    final reports = await reportsRepository
        .watchExpensesByCategory(monthStart: DateTime(now.year, now.month))
        .first;

    expect(reports, hasLength(2));
    expect(reports.first.categoryName, 'Alimentação');
    expect(reports.first.totalCents, 20000);
    expect(reports.first.categoryId, foodCategoryId);
    expect(reports.last.categoryName, 'Sem categoria');
    expect(reports.last.totalCents, 5000);
    expect(reports.last.categoryId, isNull);
  });

  test('filtra gastos por categoria por conta', () async {
    await insertEntry(
      amountCents: 20000,
      occurredAt: DateTime(now.year, now.month, 10),
      categoryId: foodCategoryId,
      accountId: bankId,
    );
    await insertEntry(
      amountCents: 5000,
      occurredAt: DateTime(now.year, now.month, 11),
      categoryId: foodCategoryId,
      accountId: walletId,
    );

    final reports = await reportsRepository
        .watchExpensesByCategory(
          monthStart: DateTime(now.year, now.month),
          accountId: walletId,
        )
        .first;

    expect(reports.single.totalCents, 5000);
  });

  test('evolução mensal cobre a janela e preenche meses vazios', () async {
    await insertEntry(
      amountCents: 50000,
      occurredAt: DateTime(now.year, now.month, 5),
      type: EntryType.income,
    );
    await insertEntry(
      amountCents: 20000,
      occurredAt: DateTime(now.year, now.month, 6),
    );
    await insertEntry(
      amountCents: 10000,
      occurredAt: DateTime(now.year, now.month - 1, 10),
    );
    await insertEntry(
      amountCents: 9000,
      occurredAt: DateTime(now.year, now.month - 7, 10),
    );

    final totals = await reportsRepository
        .watchMonthlyTotals(
          endMonth: DateTime(now.year, now.month),
          months: 6,
        )
        .first;

    expect(totals, hasLength(6));

    final current = totals.last;
    expect(current.month.year, now.year);
    expect(current.month.month, now.month);
    expect(current.incomeCents, 50000);
    expect(current.expenseCents, 20000);

    final previous = totals[totals.length - 2];
    expect(previous.incomeCents, 0);
    expect(previous.expenseCents, 10000);

    final empty = totals.first;
    expect(empty.incomeCents, 0);
    expect(empty.expenseCents, 0);
  });

  test('evolução mensal filtra por conta', () async {
    await insertEntry(
      amountCents: 20000,
      occurredAt: DateTime(now.year, now.month, 6),
      accountId: bankId,
    );
    await insertEntry(
      amountCents: 5000,
      occurredAt: DateTime(now.year, now.month, 7),
      accountId: walletId,
    );

    final totals = await reportsRepository
        .watchMonthlyTotals(
          endMonth: DateTime(now.year, now.month),
          months: 6,
          accountId: walletId,
        )
        .first;

    expect(totals.last.expenseCents, 5000);
    expect(totals.last.incomeCents, 0);
  });

  test('totais do período somam receitas e despesas com filtro', () async {
    await insertEntry(
      amountCents: 50000,
      occurredAt: DateTime(now.year, now.month, 5),
      type: EntryType.income,
    );
    await insertEntry(
      amountCents: 20000,
      occurredAt: DateTime(now.year, now.month, 6),
    );
    await insertEntry(
      amountCents: 5000,
      occurredAt: DateTime(now.year, now.month, 7),
      accountId: walletId,
    );

    final all = await reportsRepository
        .watchPeriodTotals(
          from: DateTime(now.year, now.month),
          to: DateTime(now.year, now.month + 1),
        )
        .first;
    expect(all.incomeCents, 50000);
    expect(all.expenseCents, 25000);
    expect(all.balanceCents, 25000);

    final walletOnly = await reportsRepository
        .watchPeriodTotals(
          from: DateTime(now.year, now.month),
          to: DateTime(now.year, now.month + 1),
          accountId: walletId,
        )
        .first;
    expect(walletOnly.incomeCents, 0);
    expect(walletOnly.expenseCents, 5000);
    expect(walletOnly.balanceCents, -5000);
  });
}
