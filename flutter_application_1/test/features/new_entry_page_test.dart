import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/app_database_provider.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/features/home_page/home_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late int bankId;
  late int savingsId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );

    bankId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Banco principal',
            type: AccountType.bank,
          ),
        );
    savingsId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(name: 'Reserva', type: AccountType.savings),
        );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openNewEntry(WidgetTester tester) async {
    await tester.tap(find.text('Novo lançamento'));
    await tester.pumpAndSettle();
  }

  Future<void> selectDropdown(
    WidgetTester tester,
    String label,
    String option,
  ) async {
    await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  testWidgets('cria despesa com categoria, conta e data de hoje', (
    tester,
  ) async {
    await pumpApp(tester);
    await openNewEntry(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '25,00');
    await tester.enterText(
      find.widgetWithText(TextField, 'Descrição'),
      'Café',
    );
    await selectDropdown(tester, 'Categoria', 'Alimentação');
    await selectDropdown(tester, 'Conta', 'Banco principal');

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Lançamento adicionado.'), findsOneWidget);
    expect(find.text('Confirmar'), findsNothing);

    final entries = await db.select(db.financialEntries).get();
    expect(entries, hasLength(1));
    expect(entries.single.type, EntryType.expense);
    expect(entries.single.amountCents, 2500);
    expect(entries.single.description, 'Café');
    expect(entries.single.sourceAccountId, bankId);
    expect(entries.single.destinationAccountId, isNull);

    final categories = await db.select(db.categories).get();
    final foodId = categories
        .singleWhere((category) => category.name == 'Alimentação')
        .id;
    expect(entries.single.categoryId, foodId);
  });

  testWidgets('valida campos obrigatórios em sequência', (tester) async {
    await pumpApp(tester);
    await openNewEntry(tester);

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um valor válido.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '25,00');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe a descrição.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Descrição'),
      'Café',
    );
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('Selecione a categoria.'), findsOneWidget);

    await selectDropdown(tester, 'Categoria', 'Alimentação');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('Selecione a conta.'), findsOneWidget);
  });

  testWidgets('cria receita informando origem', (tester) async {
    await pumpApp(tester);
    await openNewEntry(tester);

    await tester.tap(find.text('Receita'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Origem'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Descrição'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Valor'),
      '1.000,00',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Origem'),
      'Empresa X',
    );
    await selectDropdown(tester, 'Conta', 'Banco principal');

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    final entries = await db.select(db.financialEntries).get();
    expect(entries, hasLength(1));
    expect(entries.single.type, EntryType.income);
    expect(entries.single.amountCents, 100000);
    expect(entries.single.description, 'Empresa X');
    expect(entries.single.categoryId, isNull);
    expect(entries.single.sourceAccountId, bankId);
  });

  testWidgets('cria transferência entre contas diferentes', (tester) async {
    await pumpApp(tester);
    await openNewEntry(tester);

    await tester.tap(find.text('Transferência'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(DropdownButtonFormField<int>, 'Conta'), findsNothing);
    expect(
      find.widgetWithText(DropdownButtonFormField<int>, 'Conta de origem'),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Valor'),
      '10,00',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Descrição'),
      'Reserva mensal',
    );
    await selectDropdown(tester, 'Conta de origem', 'Banco principal');
    await selectDropdown(tester, 'Conta de destino', 'Reserva');

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    final entries = await db.select(db.financialEntries).get();
    expect(entries, hasLength(1));
    expect(entries.single.type, EntryType.transfer);
    expect(entries.single.amountCents, 1000);
    expect(entries.single.sourceAccountId, bankId);
    expect(entries.single.destinationAccountId, savingsId);
    expect(entries.single.categoryId, isNull);
  });

  testWidgets('impede transferência para a mesma conta', (tester) async {
    await pumpApp(tester);
    await openNewEntry(tester);

    await tester.tap(find.text('Transferência'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '10,00');
    await tester.enterText(
      find.widgetWithText(TextField, 'Descrição'),
      'Reserva mensal',
    );
    await selectDropdown(tester, 'Conta de origem', 'Banco principal');
    await selectDropdown(tester, 'Conta de destino', 'Banco principal');

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Selecione contas diferentes.'), findsOneWidget);

    final entries = await db.select(db.financialEntries).get();
    expect(entries, isEmpty);
  });

  testWidgets('mudar de tipo limpa categoria e destino', (tester) async {
    await pumpApp(tester);
    await openNewEntry(tester);

    await selectDropdown(tester, 'Categoria', 'Alimentação');
    await tester.tap(find.text('Transferência'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(DropdownButtonFormField<int>, 'Categoria'), findsNothing);

    await tester.tap(find.text('Despesa'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '5,00');
    await tester.enterText(
      find.widgetWithText(TextField, 'Descrição'),
      'Lanche',
    );
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Selecione a categoria.'), findsOneWidget);
  });
}
