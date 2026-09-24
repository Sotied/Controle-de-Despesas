import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/repositories/accounts_repository.dart';
import 'package:flutter_application_1/src/repositories/app_preferences_repository.dart';
import 'package:flutter_application_1/src/repositories/categories_repository.dart';
import 'package:flutter_application_1/src/repositories/financial_entries_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AccountsRepository accountsRepository;
  late CategoriesRepository categoriesRepository;
  late FinancialEntriesRepository entriesRepository;
  late AppPreferencesRepository preferencesRepository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    accountsRepository = AccountsRepository(db);
    categoriesRepository = CategoriesRepository(db);
    entriesRepository = FinancialEntriesRepository(db);
    preferencesRepository = AppPreferencesRepository(db);

    await db.delete(db.categories).go();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertAccount({
    required String name,
    required AccountType type,
    int initialBalanceCents = 0,
  }) {
    return accountsRepository.createAccount(
      AccountsCompanion.insert(
        name: name,
        type: type,
        initialBalanceCents: Value(initialBalanceCents),
      ),
    );
  }

  Future<int> insertEntry({
    required EntryType type,
    required int amountCents,
    required int sourceAccountId,
    int? destinationAccountId,
    int? categoryId,
    required DateTime occurredAt,
    EntryStatus status = EntryStatus.completed,
  }) {
    return entriesRepository.createEntry(
      FinancialEntriesCompanion.insert(
        description: 'Lançamento de teste',
        type: type,
        amountCents: amountCents,
        sourceAccountId: sourceAccountId,
        destinationAccountId: Value(destinationAccountId),
        categoryId: Value(categoryId),
        occurredAt: occurredAt,
        status: Value(status),
      ),
    );
  }

  group('AccountsRepository', () {
    test('calcula saldo por conta a partir dos lançamentos', () async {
      final walletId = await insertAccount(
        name: 'Carteira',
        type: AccountType.cash,
        initialBalanceCents: 10000,
      );
      final savingsId = await insertAccount(
        name: 'Poupança',
        type: AccountType.savings,
      );

      await insertEntry(
        type: EntryType.expense,
        amountCents: 2500,
        sourceAccountId: walletId,
        occurredAt: DateTime(2026, 9, 1),
      );
      await insertEntry(
        type: EntryType.income,
        amountCents: 5000,
        sourceAccountId: walletId,
        occurredAt: DateTime(2026, 9, 2),
      );
      await insertEntry(
        type: EntryType.transfer,
        amountCents: 1000,
        sourceAccountId: walletId,
        destinationAccountId: savingsId,
        occurredAt: DateTime(2026, 9, 3),
      );
      await insertEntry(
        type: EntryType.expense,
        amountCents: 999,
        sourceAccountId: walletId,
        occurredAt: DateTime(2026, 9, 4),
        status: EntryStatus.pending,
      );

      final accounts = await accountsRepository
          .watchAllWithBalance()
          .first;

      expect(accounts, hasLength(2));

      final wallet = accounts.singleWhere(
        (item) => item.account.id == walletId,
      );
      final savings = accounts.singleWhere(
        (item) => item.account.id == savingsId,
      );

      expect(wallet.balanceCents, 11500);
      expect(savings.balanceCents, 1000);
    });

    test('saldo consolidado soma saldos de todas as contas', () async {
      final walletId = await insertAccount(
        name: 'Carteira',
        type: AccountType.cash,
        initialBalanceCents: 10000,
      );

      await insertEntry(
        type: EntryType.expense,
        amountCents: 2000,
        sourceAccountId: walletId,
        occurredAt: DateTime(2026, 9, 1),
      );
      await insertEntry(
        type: EntryType.income,
        amountCents: 3000,
        sourceAccountId: walletId,
        occurredAt: DateTime(2026, 9, 2),
      );

      final balance = await accountsRepository
          .watchConsolidatedBalance()
          .first;

      expect(balance, 11000);
    });

    test('arquivar conta a oculta da listagem padrão', () async {
      final walletId = await insertAccount(
        name: 'Carteira',
        type: AccountType.cash,
      );

      await accountsRepository.setAccountArchived(walletId, archived: true);

      final visible = await accountsRepository.watchAll().first;
      final all = await accountsRepository
          .watchAll(includeArchived: true)
          .first;

      expect(visible, isEmpty);
      expect(all, hasLength(1));
      expect(all.single.isArchived, isTrue);
    });
  });

  group('CategoriesRepository', () {
    test('filtra categorias por tipo e arquivamento', () async {
      final foodId = await categoriesRepository.createCategory(
        CategoriesCompanion.insert(
          name: 'Alimentação',
          type: CategoryType.expense,
        ),
      );
      await categoriesRepository.createCategory(
        CategoriesCompanion.insert(name: 'Salário', type: CategoryType.income),
      );

      final expenses = await categoriesRepository
          .watchCategories(type: CategoryType.expense)
          .first;
      expect(expenses.map((c) => c.name), ['Alimentação']);

      await categoriesRepository.setCategoryArchived(foodId, archived: true);

      final activeExpenses = await categoriesRepository
          .watchCategories(type: CategoryType.expense)
          .first;
      final archivedExpenses = await categoriesRepository
          .watchCategories(
            type: CategoryType.expense,
            includeArchived: true,
          )
          .first;

      expect(activeExpenses, isEmpty);
      expect(archivedExpenses, hasLength(1));
    });

    test('não permite categorias duplicadas com mesmo nome e tipo', () async {
      await categoriesRepository.createCategory(
        CategoriesCompanion.insert(
          name: 'Transporte',
          type: CategoryType.expense,
        ),
      );

      final duplicate = categoriesRepository.createCategory(
        CategoriesCompanion.insert(
          name: 'Transporte',
          type: CategoryType.expense,
        ),
      );

      await expectLater(duplicate, throwsA(anything));
    });
  });

  group('FinancialEntriesRepository', () {
    test('lista lançamentos com contas e categoria referenciadas', () async {
      final walletId = await insertAccount(
        name: 'Carteira',
        type: AccountType.cash,
      );
      final bankId = await insertAccount(
        name: 'Banco',
        type: AccountType.bank,
      );
      final categoryId = await categoriesRepository.createCategory(
        CategoriesCompanion.insert(
          name: 'Alimentação',
          type: CategoryType.expense,
        ),
      );

      await insertEntry(
        type: EntryType.expense,
        amountCents: 5000,
        sourceAccountId: walletId,
        categoryId: categoryId,
        occurredAt: DateTime(2026, 9, 10),
      );
      await insertEntry(
        type: EntryType.transfer,
        amountCents: 1200,
        sourceAccountId: walletId,
        destinationAccountId: bankId,
        occurredAt: DateTime(2026, 9, 11),
      );

      final entries = await entriesRepository.watchEntries(const EntryFilters()).first;

      expect(entries, hasLength(2));
      expect(entries.first.entry.type, EntryType.transfer);
      expect(entries.first.sourceAccount.name, 'Carteira');
      expect(entries.first.destinationAccount?.name, 'Banco');
      expect(entries.first.category, isNull);
      expect(entries.last.category?.name, 'Alimentação');
    });

    test('filtra lançamentos por tipo, conta e período', () async {
      final walletId = await insertAccount(
        name: 'Carteira',
        type: AccountType.cash,
      );
      final bankId = await insertAccount(
        name: 'Banco',
        type: AccountType.bank,
      );

      await insertEntry(
        type: EntryType.expense,
        amountCents: 1000,
        sourceAccountId: walletId,
        occurredAt: DateTime(2026, 8, 5),
      );
      await insertEntry(
        type: EntryType.expense,
        amountCents: 2000,
        sourceAccountId: bankId,
        occurredAt: DateTime(2026, 9, 5),
      );
      await insertEntry(
        type: EntryType.income,
        amountCents: 3000,
        sourceAccountId: walletId,
        occurredAt: DateTime(2026, 9, 6),
      );
      await insertEntry(
        type: EntryType.transfer,
        amountCents: 500,
        sourceAccountId: walletId,
        destinationAccountId: bankId,
        occurredAt: DateTime(2026, 9, 7),
      );

      final expenses = await entriesRepository
          .watchEntries(const EntryFilters(type: EntryType.expense))
          .first;
      expect(expenses, hasLength(2));

      final walletEntries = await entriesRepository
          .watchEntries(const EntryFilters(accountId: 1))
          .first;
      expect(walletEntries, hasLength(3));

      final september = await entriesRepository
          .watchEntries(
            EntryFilters(from: DateTime(2026, 9, 1), to: DateTime(2026, 10, 1)),
          )
          .first;
      expect(september, hasLength(3));

      final limited = await entriesRepository
          .watchEntries(const EntryFilters(limit: 2))
          .first;
      expect(limited, hasLength(2));
      expect(limited.first.entry.occurredAt, DateTime(2026, 9, 7));
    });

    test('resume receitas e despesas do mês ignorando transferências', () async {
      final walletId = await insertAccount(
        name: 'Carteira',
        type: AccountType.cash,
      );
      final bankId = await insertAccount(
        name: 'Banco',
        type: AccountType.bank,
      );

      await insertEntry(
        type: EntryType.income,
        amountCents: 50000,
        sourceAccountId: walletId,
        occurredAt: DateTime(2026, 9, 1),
      );
      await insertEntry(
        type: EntryType.expense,
        amountCents: 20000,
        sourceAccountId: walletId,
        occurredAt: DateTime(2026, 9, 15),
      );
      await insertEntry(
        type: EntryType.expense,
        amountCents: 10000,
        sourceAccountId: walletId,
        occurredAt: DateTime(2026, 9, 20),
        status: EntryStatus.pending,
      );
      await insertEntry(
        type: EntryType.transfer,
        amountCents: 5000,
        sourceAccountId: walletId,
        destinationAccountId: bankId,
        occurredAt: DateTime(2026, 9, 22),
      );
      await insertEntry(
        type: EntryType.expense,
        amountCents: 100,
        sourceAccountId: walletId,
        occurredAt: DateTime(2026, 8, 31),
      );

      final summary = await entriesRepository
          .watchMonthSummary(DateTime(2026, 9))
          .first;

      expect(summary.incomeCents, 50000);
      expect(summary.expenseCents, 20000);
      expect(summary.balanceCents, 30000);
    });

    test('filtra por busca textual ignorando maiúsculas', () async {
      final walletId = await insertAccount(
        name: 'Carteira',
        type: AccountType.cash,
      );

      final first = await insertEntry(
        type: EntryType.expense,
        amountCents: 1000,
        sourceAccountId: walletId,
        occurredAt: DateTime(2026, 9, 1),
      );
      await entriesRepository.updateEntry(
        first,
        const FinancialEntriesCompanion(description: Value('Supermercado')),
      );
      final second = await insertEntry(
        type: EntryType.expense,
        amountCents: 2000,
        sourceAccountId: walletId,
        occurredAt: DateTime(2026, 9, 2),
      );
      await entriesRepository.updateEntry(
        second,
        const FinancialEntriesCompanion(description: Value('Farmácia')),
      );
      final third = await insertEntry(
        type: EntryType.income,
        amountCents: 3000,
        sourceAccountId: walletId,
        occurredAt: DateTime(2026, 9, 3),
      );
      await entriesRepository.updateEntry(
        third,
        const FinancialEntriesCompanion(description: Value('Uber')),
      );

      final results = await entriesRepository
          .watchEntries(const EntryFilters(search: 'MERCADO'))
          .first;

      expect(results, hasLength(1));
      expect(results.single.entry.description, 'Supermercado');
    });

    test('ordena de forma ascendente quando solicitado', () async {
      final walletId = await insertAccount(
        name: 'Carteira',
        type: AccountType.cash,
      );

      await insertEntry(
        type: EntryType.expense,
        amountCents: 1000,
        sourceAccountId: walletId,
        occurredAt: DateTime(2026, 9, 1),
      );
      await insertEntry(
        type: EntryType.expense,
        amountCents: 2000,
        sourceAccountId: walletId,
        occurredAt: DateTime(2026, 9, 5),
      );
      await insertEntry(
        type: EntryType.expense,
        amountCents: 3000,
        sourceAccountId: walletId,
        occurredAt: DateTime(2026, 9, 10),
      );

      final descending = await entriesRepository
          .watchEntries(const EntryFilters())
          .first;
      expect(descending.first.entry.occurredAt, DateTime(2026, 9, 10));
      expect(descending.last.entry.occurredAt, DateTime(2026, 9, 1));

      final ascending = await entriesRepository
          .watchEntries(const EntryFilters(sortDescending: false))
          .first;
      expect(ascending.first.entry.occurredAt, DateTime(2026, 9, 1));
      expect(ascending.last.entry.occurredAt, DateTime(2026, 9, 10));
    });

    test('findEntryById retorna lançamento com referências', () async {
      final walletId = await insertAccount(
        name: 'Carteira',
        type: AccountType.cash,
      );
      final savingsId = await insertAccount(
        name: 'Poupança',
        type: AccountType.savings,
      );
      final categoryId = await categoriesRepository.createCategory(
        CategoriesCompanion.insert(
          name: 'Alimentação',
          type: CategoryType.expense,
        ),
      );

      final expenseId = await insertEntry(
        type: EntryType.expense,
        amountCents: 1500,
        sourceAccountId: walletId,
        categoryId: categoryId,
        occurredAt: DateTime(2026, 9, 3),
      );

      final expense = await entriesRepository.findEntryById(expenseId);
      expect(expense, isNotNull);
      expect(expense!.entry.id, expenseId);
      expect(expense.sourceAccount.id, walletId);
      expect(expense.category?.name, 'Alimentação');
      expect(expense.destinationAccount, isNull);

      final transferId = await insertEntry(
        type: EntryType.transfer,
        amountCents: 500,
        sourceAccountId: walletId,
        destinationAccountId: savingsId,
        occurredAt: DateTime(2026, 9, 4),
      );

      final transfer = await entriesRepository.findEntryById(transferId);
      expect(transfer!.destinationAccount?.id, savingsId);
      expect(transfer.category, isNull);
    });

    test('atualiza e exclui lançamento', () async {
      final walletId = await insertAccount(
        name: 'Carteira',
        type: AccountType.cash,
      );
      final entryId = await insertEntry(
        type: EntryType.expense,
        amountCents: 1500,
        sourceAccountId: walletId,
        occurredAt: DateTime(2026, 9, 3),
      );

      await entriesRepository.updateEntry(
        entryId,
        const FinancialEntriesCompanion(description: Value('Mercado')),
      );

      final updated = await entriesRepository.watchEntryById(entryId).first;
      expect(updated?.entry.description, 'Mercado');

      await entriesRepository.deleteEntry(entryId);

      final deleted = await entriesRepository.watchEntryById(entryId).first;
      expect(deleted, isNull);
    });
  });

  group('AppPreferencesRepository', () {
    test('lê preferências padrão e atualiza moeda', () async {
      final preferences = await preferencesRepository.get();
      expect(preferences.currencyCode, 'BRL');
      expect(preferences.locale, 'pt_BR');
      expect(preferences.firstDayOfMonth, 1);

      await preferencesRepository.update(
        const AppPreferencesCompanion(currencyCode: Value('USD')),
      );

      final updated = await preferencesRepository.watch().first;
      expect(updated.currencyCode, 'USD');
    });

    test('rejeita código de moeda com tamanho inválido', () async {
      final update = preferencesRepository.update(
        const AppPreferencesCompanion(currencyCode: Value('REAL')),
      );

      await expectLater(update, throwsA(anything));
    });
  });
}
