import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/app_database_provider.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/features/home_page/home_page.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late DateTime today;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );

    today = DateTime.now();

    final bankId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Banco',
            type: AccountType.bank,
            initialBalanceCents: const Value(100000),
          ),
        );

    Future<void> insertEntry({
      required String description,
      required EntryType type,
      required int amountCents,
      required DateTime occurredAt,
      DateTime? dueAt,
      EntryStatus status = EntryStatus.completed,
    }) {
      return db
          .into(db.financialEntries)
          .insert(
            FinancialEntriesCompanion.insert(
              description: description,
              type: type,
              amountCents: amountCents,
              sourceAccountId: bankId,
              occurredAt: occurredAt,
              dueAt: Value(dueAt),
              status: Value(status),
            ),
          );
    }

    await insertEntry(
      description: 'Salário',
      type: EntryType.income,
      amountCents: 50000,
      occurredAt: DateTime(today.year, today.month, 5),
    );
    await insertEntry(
      description: 'Mercado',
      type: EntryType.expense,
      amountCents: 20000,
      occurredAt: DateTime(today.year, today.month, 10),
    );
    await insertEntry(
      description: 'Café',
      type: EntryType.expense,
      amountCents: 2500,
      occurredAt: DateTime(today.year, today.month, 24),
    );
    await insertEntry(
      description: 'Aluguel',
      type: EntryType.expense,
      amountCents: 80000,
      occurredAt: DateTime(today.year, today.month, today.day + 3),
      dueAt: DateTime(today.year, today.month, today.day + 3),
      status: EntryStatus.pending,
    );
    await insertEntry(
      description: 'Conta de luz',
      type: EntryType.expense,
      amountCents: 15000,
      occurredAt: DateTime(today.year, today.month, today.day - 2),
      dueAt: DateTime(today.year, today.month, today.day - 2),
      status: EntryStatus.pending,
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
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('exibe saldo consolidado e resumo do mês', (tester) async {
    await pumpPage(tester);

    expect(find.text('Saldo consolidado'), findsOneWidget);
    expect(find.text(r'R$ 1.275,00'), findsOneWidget);
    expect(find.text('Resumo de ${monthName(today.month)}'), findsOneWidget);
    expect(find.text('Receitas'), findsOneWidget);
    expect(find.text(r'R$ 500,00'), findsOneWidget);
    expect(find.text('Despesas'), findsOneWidget);
    expect(find.text(r'R$ 225,00'), findsOneWidget);
    expect(find.text('Saldo'), findsOneWidget);
    expect(find.text(r'R$ 275,00'), findsOneWidget);
  });

  testWidgets('mostra últimos lançamentos e navega ao detalhe', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Últimos lançamentos'), findsOneWidget);
    expect(find.text('Café'), findsOneWidget);
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('Salário'), findsOneWidget);

    await tester.tap(find.text('Café'));
    await tester.pumpAndSettle();

    expect(find.text('Lançamento'), findsOneWidget);
    expect(find.text(r'-R$ 25,00'), findsOneWidget);
  });

  testWidgets('ver todos abre a lista completa', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Ver todos'));
    await tester.pumpAndSettle();

    expect(find.text('Buscar lançamentos…'), findsOneWidget);
  });

  testWidgets('mostra próximos vencimentos pendentes e atrasados', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Próximos vencimentos'), findsOneWidget);
    expect(find.text('Aluguel'), findsNWidgets(2));
    expect(
      find.text(
        'Vence em ${formatDate(DateTime(today.year, today.month, today.day + 3))}',
      ),
      findsOneWidget,
    );
    expect(find.text('Conta de luz'), findsNWidgets(2));
    expect(find.textContaining('Atrasado'), findsOneWidget);
  });

  testWidgets('confirma vencimento pendente pela Home', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Aluguel').first);
    await tester.pumpAndSettle();

    expect(find.text('Confirmar lançamento'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Lançamento confirmado.'), findsOneWidget);

    final entries = await db.select(db.financialEntries).get();
    final rent = entries.firstWhere(
      (entry) => entry.description == 'Aluguel',
    );
    expect(rent.status, EntryStatus.completed);
  });

  testWidgets('atalho abre o novo lançamento', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Novo lançamento'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar'), findsOneWidget);
  });
}
