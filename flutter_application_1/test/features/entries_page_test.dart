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

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );

    final bankId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(name: 'Banco', type: AccountType.bank),
        );
    final savingsId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(name: 'Poupança', type: AccountType.savings),
        );

    Future<void> insertEntry({
      required String description,
      required EntryType type,
      required int amountCents,
      required DateTime occurredAt,
      int? destinationAccountId,
    }) {
      return db
          .into(db.financialEntries)
          .insert(
            FinancialEntriesCompanion.insert(
              description: description,
              type: type,
              amountCents: amountCents,
              sourceAccountId: bankId,
              destinationAccountId: Value(destinationAccountId),
              occurredAt: occurredAt,
            ),
          );
    }

    await insertEntry(
      description: 'Café',
      type: EntryType.expense,
      amountCents: 2500,
      occurredAt: DateTime(2026, 9, 24),
    );
    await insertEntry(
      description: 'Reserva mensal',
      type: EntryType.transfer,
      amountCents: 10000,
      occurredAt: DateTime(2026, 9, 20),
      destinationAccountId: savingsId,
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

  testWidgets('lista lançamentos ordenados por data decrescente', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Café'), findsOneWidget);
    expect(find.text('Reserva mensal'), findsOneWidget);
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('Salário'), findsOneWidget);

    final cafeY = tester.getTopLeft(find.text('Café')).dy;
    final mercadoY = tester.getTopLeft(find.text('Mercado')).dy;
    expect(cafeY, lessThan(mercadoY));

    expect(find.text(r'-R$ 25,00'), findsOneWidget);
    expect(find.text(r'+R$ 5.000,00'), findsOneWidget);
    expect(find.textContaining('Banco → Poupança'), findsOneWidget);
  });

  testWidgets('busca textual filtra a lista em tempo real', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField), 'mercado');
    await tester.pumpAndSettle();

    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('Café'), findsNothing);
    expect(find.text('Salário'), findsNothing);
  });

  testWidgets('limpa a busca pelo botão', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField), 'mercado');
    await tester.pumpAndSettle();
    expect(find.text('Café'), findsNothing);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(find.text('Café'), findsOneWidget);
    expect(find.text('Salário'), findsOneWidget);
  });

  testWidgets('filtra por tipo pelo sheet de filtros', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Receitas'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(find.text('Salário'), findsOneWidget);
    expect(find.text('Café'), findsNothing);
    expect(find.text('Mercado'), findsNothing);
    expect(find.text('Reserva mensal'), findsNothing);
  });

  testWidgets('limpa filtros pelo sheet', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transferências'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(find.text('Reserva mensal'), findsOneWidget);
    expect(find.text('Café'), findsNothing);

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpar filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(find.text('Café'), findsOneWidget);
    expect(find.text('Salário'), findsOneWidget);
  });

  testWidgets('alterna a ordenação da lista', (tester) async {
    await pumpPage(tester);

    expect(
      tester.getTopLeft(find.text('Café')).dy,
      lessThan(tester.getTopLeft(find.text('Salário')).dy),
    );

    await tester.tap(find.byTooltip('Mais recentes primeiro'));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Salário')).dy,
      lessThan(tester.getTopLeft(find.text('Café')).dy),
    );
  });

  testWidgets('mostra estado vazio quando filtros não encontram nada', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhum lançamento encontrado\ncom os filtros atuais.'),
      findsOneWidget,
    );
  });

  testWidgets('FAB abre o novo lançamento', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Novo lançamento'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar'), findsOneWidget);
  });
}
