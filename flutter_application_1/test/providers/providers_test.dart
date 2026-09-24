import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/app_database_provider.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/providers/accounts_providers.dart';
import 'package:flutter_application_1/src/providers/app_preferences_providers.dart';
import 'package:flutter_application_1/src/providers/categories_providers.dart';
import 'package:flutter_application_1/src/providers/financial_entries_providers.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );

    await db.delete(db.categories).go();
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> waitUntil(bool Function() condition) async {
    for (var iteration = 0; iteration < 200; iteration++) {
      if (condition()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('Condição não atingida em tempo razoável');
  }

  test('providers de repositórios usam o banco injetado', () {
    expect(
      container.read(accountsRepositoryProvider).db,
      same(db),
    );
    expect(
      container.read(categoriesRepositoryProvider).db,
      same(db),
    );
    expect(
      container.read(financialEntriesRepositoryProvider).db,
      same(db),
    );
    expect(
      container.read(appPreferencesRepositoryProvider).db,
      same(db),
    );
  });

  test('accountsWithBalanceProvider emite saldo reativo', () async {
    final subscription = container.listen(accountsWithBalanceProvider, (_, __) {});

    final walletId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Carteira',
            type: AccountType.cash,
            initialBalanceCents: const Value(1000),
          ),
        );

    await waitUntil(
      () => container.read(accountsWithBalanceProvider).value?.isNotEmpty ??
          false,
    );

    final first = await container.read(accountsWithBalanceProvider.future);
    expect(first.single.account.id, walletId);
    expect(first.single.balanceCents, 1000);

    await db
        .into(db.financialEntries)
        .insert(
          FinancialEntriesCompanion.insert(
            description: 'Café',
            type: EntryType.expense,
            amountCents: 400,
            sourceAccountId: walletId,
            occurredAt: DateTime(2026, 9, 24),
          ),
        );

    await waitUntil(
      () =>
          container
              .read(accountsWithBalanceProvider)
              .value
              ?.single
              .balanceCents ==
          600,
    );

    final second = await container.read(accountsWithBalanceProvider.future);
    expect(second.single.balanceCents, 600);
    subscription.close();
  });  test('consolidatedBalanceProvider emite saldo total', () async {
    final subscription = container.listen(consolidatedBalanceProvider, (_, __) {});

    final walletId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Carteira',
            type: AccountType.cash,
            initialBalanceCents: const Value(5000),
          ),
        );

    await db
        .into(db.financialEntries)
        .insert(
          FinancialEntriesCompanion.insert(
            description: 'Salário',
            type: EntryType.income,
            amountCents: 20000,
            sourceAccountId: walletId,
            occurredAt: DateTime(2026, 9, 5),
          ),
        );

    await waitUntil(
      () => container.read(consolidatedBalanceProvider).value == 25000,
    );

    final balance = await container.read(consolidatedBalanceProvider.future);
    expect(balance, 25000);
    subscription.close();
  });

  test('recentEntriesProvider e monthSummaryProvider refletem lançamentos', () async {
    final monthStart = DateTime(2026, 9);
    final subscriptions = [
      container.listen(recentEntriesProvider, (_, __) {}),
      container.listen(monthSummaryProvider(monthStart), (_, __) {}),
    ];

    final walletId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(name: 'Carteira', type: AccountType.cash),
        );

    await db
        .into(db.financialEntries)
        .insert(
          FinancialEntriesCompanion.insert(
            description: 'Supermercado',
            type: EntryType.expense,
            amountCents: 30000,
            sourceAccountId: walletId,
            occurredAt: DateTime(2026, 9, 10),
          ),
        );

    await waitUntil(
      () =>
          container.read(recentEntriesProvider).value?.length == 1 &&
          container
              .read(monthSummaryProvider(monthStart))
              .value
              ?.expenseCents ==
          30000,
    );

    final recent = await container.read(recentEntriesProvider.future);
    expect(recent, hasLength(1));
    expect(recent.single.sourceAccount.id, walletId);
    expect(recent.single.entry.description, 'Supermercado');

    final summary = await container.read(
      monthSummaryProvider(monthStart).future,
    );
    expect(summary.incomeCents, 0);
    expect(summary.expenseCents, 30000);
    expect(summary.balanceCents, -30000);
    for (final subscription in subscriptions) {
      subscription.close();
    }
  });

  test('categoriesByTypeProvider emite categorias do tipo informado', () async {
    const scope = (CategoryType.expense, includeArchived: false);
    final subscription = container.listen(
      categoriesByTypeProvider(scope),
      (_, __) {},
    );

    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            name: 'Alimentação',
            type: CategoryType.expense,
          ),
        );

    await waitUntil(
      () =>
          container.read(categoriesByTypeProvider(scope)).value?.isNotEmpty ??
          false,
    );

    final expenses = await container.read(
      categoriesByTypeProvider(scope).future,
    );
    expect(expenses.single.name, 'Alimentação');
    subscription.close();
  });

  test('entryListProvider reage aos filtros do notifier', () async {
    final subscription = container.listen(entryListProvider, (_, __) {});

    final walletId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(name: 'Carteira', type: AccountType.cash),
        );

    Future<void> insertEntry({
      required String description,
      required EntryType type,
      required int amountCents,
      required DateTime occurredAt,
    }) {
      return db
          .into(db.financialEntries)
          .insert(
            FinancialEntriesCompanion.insert(
              description: description,
              type: type,
              amountCents: amountCents,
              sourceAccountId: walletId,
              occurredAt: occurredAt,
            ),
          );
    }

    await insertEntry(
      description: 'Café',
      type: EntryType.expense,
      amountCents: 500,
      occurredAt: DateTime(2026, 9, 24),
    );
    await insertEntry(
      description: 'Mercado',
      type: EntryType.expense,
      amountCents: 20000,
      occurredAt: DateTime(2026, 9, 10),
    );
    await insertEntry(
      description: 'Salário',
      type: EntryType.income,
      amountCents: 500000,
      occurredAt: DateTime(2026, 9, 5),
    );

    final notifier = container.read(entryListFiltersProvider.notifier);

    await waitUntil(
      () => container.read(entryListProvider).value?.length == 3,
    );

    notifier.setType(EntryType.income);
    await waitUntil(() {
      final list = container.read(entryListProvider).value;
      return list != null &&
          list.length == 1 &&
          list.first.entry.description == 'Salário';
    });

    notifier.setType(null);
    notifier.setSearch('mercado');
    await waitUntil(() {
      final list = container.read(entryListProvider).value;
      return list != null &&
          list.length == 1 &&
          list.first.entry.description == 'Mercado';
    });

    notifier.setSearch('');
    notifier.toggleSort();
    await waitUntil(() {
      final list = container.read(entryListProvider).value;
      return list != null &&
          list.isNotEmpty &&
          list.first.entry.description == 'Salário';
    });

    notifier.setSearch('inexistente');
    await waitUntil(
      () => container.read(entryListProvider).value?.isEmpty ?? false,
    );

    notifier.clearAll();
    await waitUntil(
      () => container.read(entryListProvider).value?.length == 3,
    );

    subscription.close();
  });

  test('edição e exclusão de lançamento mantêm saldos consistentes', () async {
    final subscription = container.listen(accountsWithBalanceProvider, (_, __) {});

    final walletId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Carteira',
            type: AccountType.cash,
            initialBalanceCents: const Value(100000),
          ),
        );

    final entryId = await db
        .into(db.financialEntries)
        .insert(
          FinancialEntriesCompanion.insert(
            description: 'Café',
            type: EntryType.expense,
            amountCents: 25000,
            sourceAccountId: walletId,
            occurredAt: DateTime(2026, 9, 24),
          ),
        );

    await waitUntil(
      () =>
          container
              .read(accountsWithBalanceProvider)
              .value
              ?.single
              .balanceCents ==
          75000,
    );

    await container
        .read(financialEntriesRepositoryProvider)
        .updateEntry(
          entryId,
          const FinancialEntriesCompanion(amountCents: Value(50000)),
        );

    await waitUntil(
      () =>
          container
              .read(accountsWithBalanceProvider)
              .value
              ?.single
              .balanceCents ==
          50000,
    );

    await container
        .read(financialEntriesRepositoryProvider)
        .deleteEntry(entryId);

    await waitUntil(
      () =>
          container
              .read(accountsWithBalanceProvider)
              .value
              ?.single
              .balanceCents ==
          100000,
    );

    subscription.close();
  });

  test('appPreferencesProvider emite preferências padrão', () async {
    final subscription = container.listen(appPreferencesProvider, (_, __) {});

    final preferences = await container.read(appPreferencesProvider.future);
    expect(preferences.currencyCode, 'BRL');
    expect(preferences.locale, 'pt_BR');
    subscription.close();
  });
}
