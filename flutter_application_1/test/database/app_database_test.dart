import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('cria as preferências locais padrão', () async {
    final preferences = await database
        .select(database.appPreferences)
        .getSingle();

    expect(preferences.id, 1);
    expect(preferences.currencyCode, 'BRL');
    expect(preferences.locale, 'pt_BR');
    expect(preferences.firstDayOfMonth, 1);
  });

  test('semeia categorias iniciais de despesa e receita', () async {
    final categories = await database.select(database.categories).get();

    final expenseNames = categories
        .where((category) => category.type == CategoryType.expense)
        .map((category) => category.name)
        .toList();
    final incomeNames = categories
        .where((category) => category.type == CategoryType.income)
        .map((category) => category.name)
        .toList();

    expect(expenseNames, hasLength(8));
    expect(
      expenseNames,
      containsAll(['Alimentação', 'Transporte', 'Moradia', 'Outros']),
    );

    expect(incomeNames, hasLength(3));
    expect(incomeNames, containsAll(['Salário', 'Investimentos', 'Outros']));
  });

  test('salva transferência em centavos entre contas diferentes', () async {
    final sourceAccountId = await database
        .into(database.accounts)
        .insert(
          AccountsCompanion.insert(name: 'Banco', type: AccountType.bank),
        );
    final destinationAccountId = await database
        .into(database.accounts)
        .insert(
          AccountsCompanion.insert(name: 'Poupança', type: AccountType.savings),
        );

    await database
        .into(database.financialEntries)
        .insert(
          FinancialEntriesCompanion.insert(
            description: 'Reserva mensal',
            type: EntryType.transfer,
            amountCents: 12050,
            sourceAccountId: sourceAccountId,
            destinationAccountId: Value(destinationAccountId),
            occurredAt: DateTime(2026, 9, 24),
          ),
        );

    final entry = await database.select(database.financialEntries).getSingle();

    expect(entry.amountCents, 12050);
    expect(entry.type, EntryType.transfer);
    expect(entry.sourceAccountId, sourceAccountId);
    expect(entry.destinationAccountId, destinationAccountId);
    expect(entry.categoryId, null);
  });

  test('impede transferência para a mesma conta', () async {
    final accountId = await database
        .into(database.accounts)
        .insert(
          AccountsCompanion.insert(name: 'Carteira', type: AccountType.cash),
        );

    final insert = database
        .into(database.financialEntries)
        .insert(
          FinancialEntriesCompanion.insert(
            description: 'Transferência inválida',
            type: EntryType.transfer,
            amountCents: 100,
            sourceAccountId: accountId,
            destinationAccountId: Value(accountId),
            occurredAt: DateTime(2026, 9, 24),
          ),
        );

    await expectLater(insert, throwsA(anything));
  });
}
