import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/app_database_provider.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/features/entries/entries_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late int bankId;
  late int savingsId;
  late int foodCategoryId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );

    bankId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(name: 'Banco', type: AccountType.bank),
        );
    savingsId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(name: 'Poupança', type: AccountType.savings),
        );

    final categories = await db.select(db.categories).get();
    foodCategoryId = categories
        .singleWhere((category) => category.name == 'Alimentação')
        .id;

    await db
        .into(db.financialEntries)
        .insert(
          FinancialEntriesCompanion.insert(
            description: 'Café',
            type: EntryType.expense,
            amountCents: 2500,
            sourceAccountId: bankId,
            categoryId: Value(foodCategoryId),
            occurredAt: DateTime(2026, 9, 24),
          ),
        );
    await db
        .into(db.financialEntries)
        .insert(
          FinancialEntriesCompanion.insert(
            description: 'Reserva mensal',
            type: EntryType.transfer,
            amountCents: 1000,
            sourceAccountId: bankId,
            destinationAccountId: Value(savingsId),
            occurredAt: DateTime(2026, 9, 20),
          ),
        );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: EntriesPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openDetail(WidgetTester tester, String description) async {
    await tester.tap(find.text(description));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra detalhes completos do lançamento', (tester) async {
    await pumpPage(tester);
    await openDetail(tester, 'Café');

    expect(find.text('Despesa'), findsOneWidget);
    expect(find.text(r'-R$ 25,00'), findsOneWidget);
    expect(find.text('Café'), findsOneWidget);
    expect(find.text('24/09/2026'), findsOneWidget);
    expect(find.text('Alimentação'), findsOneWidget);
    expect(find.text('Banco'), findsOneWidget);
    expect(find.text('Concluído'), findsOneWidget);
  });

  testWidgets('edita valor e reflete no detalhe e no banco', (tester) async {
    await pumpPage(tester);
    await openDetail(tester, 'Café');

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.text('Editar lançamento'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Valor'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '30,00');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Lançamento atualizado.'), findsOneWidget);
    expect(find.text(r'-R$ 30,00'), findsOneWidget);

    final entries = await db.select(db.financialEntries).get();
    expect(entries, hasLength(2));
    expect(entries.firstWhere((entry) => entry.id == 1).amountCents, 3000);
    expect(entries.firstWhere((entry) => entry.id == 1).categoryId, foodCategoryId);
    expect(entries.firstWhere((entry) => entry.id == 1).type, EntryType.expense);
  });

  testWidgets('edita transferência preservando origem e destino', (
    tester,
  ) async {
    await pumpPage(tester);
    await openDetail(tester, 'Reserva mensal');

    expect(find.text('Transferência'), findsOneWidget);
    expect(find.text('Conta de destino'), findsOneWidget);

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(DropdownButtonFormField<int>, 'Conta de origem'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(DropdownButtonFormField<int>, 'Conta de destino'),
      findsOneWidget,
    );

    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '15,00');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    final entries = await db.select(db.financialEntries).get();
    final transfer = entries.firstWhere((entry) => entry.id == 2);
    expect(transfer.amountCents, 1500);
    expect(transfer.type, EntryType.transfer);
    expect(transfer.sourceAccountId, bankId);
    expect(transfer.destinationAccountId, savingsId);
    expect(transfer.categoryId, isNull);
  });

  testWidgets('exclui lançamento com confirmação', (tester) async {
    await pumpPage(tester);
    await openDetail(tester, 'Café');

    await tester.tap(find.widgetWithText(FilledButton, 'Excluir').first);
    await tester.pumpAndSettle();

    expect(find.text('Excluir lançamento'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Excluir'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Café'), findsNothing);
    expect(find.text('Reserva mensal'), findsOneWidget);

    final entries = await db.select(db.financialEntries).get();
    expect(entries, hasLength(1));
  });
}
