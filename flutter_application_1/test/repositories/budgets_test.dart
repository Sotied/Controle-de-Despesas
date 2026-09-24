import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/repositories/accounts_repository.dart';
import 'package:flutter_application_1/src/repositories/budgets_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AccountsRepository accountsRepository;
  late BudgetsRepository budgetsRepository;
  late int accountId;
  late int foodCategoryId;
  late int transportCategoryId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    accountsRepository = AccountsRepository(db);
    budgetsRepository = BudgetsRepository(db);

    accountId = await accountsRepository.createAccount(
      AccountsCompanion.insert(name: 'Banco', type: AccountType.bank),
    );

    final categories = await db.select(db.categories).get();
    foodCategoryId = categories
        .singleWhere((category) => category.name == 'Alimentação')
        .id;
    transportCategoryId = categories
        .singleWhere((category) => category.name == 'Transporte')
        .id;
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertEntry({
    required int amountCents,
    required DateTime occurredAt,
    int? categoryId,
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
            sourceAccountId: accountId,
            categoryId: Value(categoryId),
            occurredAt: occurredAt,
            status: Value(status),
          ),
        );
  }

  test('calcula o realizado do mês por categoria', () async {
    final now = DateTime.now();

    await budgetsRepository.create(
      BudgetsCompanion.insert(
        categoryId: foodCategoryId,
        amountCents: 10000,
      ),
    );

    await insertEntry(
      amountCents: 4000,
      occurredAt: DateTime(now.year, now.month, 10),
      categoryId: foodCategoryId,
    );
    await insertEntry(
      amountCents: 500,
      occurredAt: DateTime(now.year, now.month, 11),
      categoryId: foodCategoryId,
      status: EntryStatus.pending,
    );
    await insertEntry(
      amountCents: 3000,
      occurredAt: DateTime(now.year, now.month, 12),
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

    final progress = await budgetsRepository
        .watchForMonth(DateTime(now.year, now.month))
        .first;

    expect(progress, hasLength(1));
    expect(progress.single.spentCents, 4000);
    expect(progress.single.isOver, isFalse);
    expect(progress.single.isNear, isFalse);
  });

  test('alerta quando o limite está próximo ou ultrapassado', () async {
    final now = DateTime.now();

    await budgetsRepository.create(
      BudgetsCompanion.insert(
        categoryId: foodCategoryId,
        amountCents: 1000,
      ),
    );
    await budgetsRepository.create(
      BudgetsCompanion.insert(
        categoryId: transportCategoryId,
        amountCents: 1000,
      ),
    );

    await insertEntry(
      amountCents: 850,
      occurredAt: DateTime(now.year, now.month, 5),
      categoryId: foodCategoryId,
    );
    await insertEntry(
      amountCents: 1200,
      occurredAt: DateTime(now.year, now.month, 6),
      categoryId: transportCategoryId,
    );

    final progress = await budgetsRepository
        .watchForMonth(DateTime(now.year, now.month))
        .first;

    final food = progress.singleWhere(
      (item) => item.categoryName == 'Alimentação',
    );
    final transport = progress.singleWhere(
      (item) => item.categoryName == 'Transporte',
    );

    expect(food.isNear, isTrue);
    expect(food.isOver, isFalse);

    expect(transport.isOver, isTrue);
    expect(transport.remainingCents, -200);
  });

  test('não permite orçamento duplicado para a mesma categoria', () async {
    await budgetsRepository.create(
      BudgetsCompanion.insert(
        categoryId: foodCategoryId,
        amountCents: 10000,
      ),
    );

    final duplicate = budgetsRepository.create(
      BudgetsCompanion.insert(
        categoryId: foodCategoryId,
        amountCents: 20000,
      ),
    );

    await expectLater(duplicate, throwsA(anything));
  });

  test('atualiza e exclui orçamento', () async {
    final budgetId = await budgetsRepository.create(
      BudgetsCompanion.insert(
        categoryId: foodCategoryId,
        amountCents: 10000,
      ),
    );

    await budgetsRepository.update(
      budgetId,
      const BudgetsCompanion(amountCents: Value(20000)),
    );

    final updated = await (db.select(
      db.budgets,
    )..where((tbl) => tbl.id.equals(budgetId))).getSingle();
    expect(updated.amountCents, 20000);

    await budgetsRepository.delete(budgetId);

    final budgets = await db.select(db.budgets).get();
    expect(budgets, isEmpty);
  });
}
