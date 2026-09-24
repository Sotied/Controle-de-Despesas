import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/app_database_provider.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/features/reports/reports_page.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late DateTime now;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );

    now = DateTime.now();

    final bankId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(name: 'Banco', type: AccountType.bank),
        );
    final walletId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(name: 'Carteira', type: AccountType.cash),
        );

    final categories = await db.select(db.categories).get();
    final foodId = categories
        .singleWhere((category) => category.name == 'Alimentação')
        .id;

    Future<void> insertEntry({
      required int amountCents,
      required int accountId,
      int? categoryId,
      EntryType type = EntryType.expense,
      EntryStatus status = EntryStatus.completed,
      DateTime? occurredAt,
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
              occurredAt: occurredAt ?? DateTime(now.year, now.month, 10),
              status: Value(status),
            ),
          );
    }

    await insertEntry(
      amountCents: 50000,
      accountId: bankId,
      type: EntryType.income,
    );
    await insertEntry(amountCents: 20000, accountId: bankId, categoryId: foodId);
    await insertEntry(amountCents: 5000, accountId: walletId);
    await insertEntry(
      amountCents: 3000,
      accountId: bankId,
      categoryId: foodId,
      status: EntryStatus.pending,
    );
    await insertEntry(
      amountCents: 10000,
      accountId: bankId,
      categoryId: foodId,
      occurredAt: DateTime(now.year, now.month - 1, 10),
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
        child: const MaterialApp(home: ReportsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('navega entre meses nos filtros', (tester) async {
    await pumpPage(tester);

    expect(
      find.text('${monthName(now.month)} ${now.year}'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Mês anterior'));
    await tester.pumpAndSettle();

    final previous = DateTime(now.year, now.month - 1);
    expect(find.text('${monthName(previous.month)} ${previous.year}'),
        findsOneWidget);

    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();

    expect(find.text('${monthName(now.month)} ${now.year}'), findsOneWidget);
  });

  testWidgets('exibe gastos por categoria com participação no total', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Alimentação'), findsOneWidget);
    expect(find.text('Sem categoria'), findsOneWidget);
    expect(find.text(r'R$ 200,00'), findsOneWidget);
    expect(find.text(r'R$ 50,00'), findsOneWidget);
    expect(find.text('80% do total'), findsOneWidget);
    expect(find.text('20% do total'), findsOneWidget);
  });

  testWidgets('exibe evolução mensal dos últimos 6 meses', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Evolução mensal'));
    await tester.pumpAndSettle();

    expect(find.text('Últimos 6 meses'), findsOneWidget);
    expect(
      find.text(monthNames[now.month - 1].substring(0, 3)),
      findsOneWidget,
    );
    final previous = DateTime(now.year, now.month - 1);
    expect(
      find.text(monthNames[previous.month - 1].substring(0, 3)),
      findsOneWidget,
    );
  });

  testWidgets('compara receitas x despesas do mês', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Receitas x despesas'));
    await tester.pumpAndSettle();

    expect(find.text('Receitas'), findsOneWidget);
    expect(find.text(r'R$ 500,00'), findsOneWidget);
    expect(find.text('Despesas'), findsOneWidget);
    expect(find.text(r'R$ 250,00'), findsNWidgets(2));
  });

  testWidgets('filtra os relatórios por conta', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Receitas x despesas'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<int>, 'Conta'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carteira').last);
    await tester.pumpAndSettle();

    expect(find.text(r'R$ 0,00'), findsOneWidget);
    expect(find.text(r'R$ 50,00'), findsOneWidget);
    expect(find.text(r'-R$ 50,00'), findsOneWidget);
  });
}
